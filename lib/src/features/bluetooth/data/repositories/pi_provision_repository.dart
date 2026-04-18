import 'dart:async';
import 'dart:convert';

import 'package:app_iot/src/core/ulits/logger_ulits.dart';
import 'package:app_iot/src/features/bluetooth/domain/models/pi_response.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pi_provision_repository.g.dart';

@riverpod
PiProvisionRepository piProvisionRepository(PiProvisionRepositoryRef ref) {
  final repository = PiProvisionRepository();
  ref.onDispose(repository.dispose);
  return repository;
}

class PiProvisionException implements Exception {
  const PiProvisionException(this.message, {this.technicalDetail});

  final String message;
  final String? technicalDetail;

  @override
  String toString() =>
      'PiProvisionException($message${technicalDetail == null ? '' : ' | $technicalDetail'})';
}

enum BleRepositoryEventType { disconnected }

enum BlePreparationStep { discoveringServices, subscribingStatus }

class BleRepositoryEvent {
  const BleRepositoryEvent({
    required this.type,
    this.message,
    this.technicalDetail,
  });

  final BleRepositoryEventType type;
  final String? message;
  final String? technicalDetail;
}

class PiProvisionRepository {
  static const String serviceUuidStr = '0f5c0001-95c7-43f1-b1d5-28f9f0dca001';
  static const String commandCharUuidStr =
      '0f5c0002-95c7-43f1-b1d5-28f9f0dca001';
  static const String resultCharUuidStr =
      '0f5c0003-95c7-43f1-b1d5-28f9f0dca001';
  static const String statusCharUuidStr =
      '0f5c0004-95c7-43f1-b1d5-28f9f0dca001';

  static final Guid serviceGuid = Guid(serviceUuidStr);
  static final Guid commandCharGuid = Guid(commandCharUuidStr);
  static final Guid resultCharGuid = Guid(resultCharUuidStr);
  static final Guid statusCharGuid = Guid(statusCharUuidStr);

  static const Duration _statusNotifyTimeout = Duration(seconds: 10);

  final StreamController<BleRepositoryEvent> _eventController =
      StreamController<BleRepositoryEvent>.broadcast();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _commandChar;
  BluetoothCharacteristic? _resultChar;
  BluetoothCharacteristic? _statusChar;

  StreamSubscription<List<int>>? _statusSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  Completer<void>? _pendingStatusCompleter;
  int _statusVersion = 0;
  String? _latestStatusToken;
  bool _isReady = false;

  Stream<BleRepositoryEvent> get events => _eventController.stream;

  bool get isReady =>
      _isReady &&
      _device != null &&
      _commandChar != null &&
      _resultChar != null &&
      _statusChar != null;

  Future<void> prepareConnectedDevice(
    BluetoothDevice device, {
    void Function(BlePreparationStep step)? onStepChanged,
  }) async {
    LoggerUtils.i('BLE prepare start for ${device.remoteId.str}');
    await _cleanupSession(keepDevice: false);
    _device = device;

    try {
      onStepChanged?.call(BlePreparationStep.discoveringServices);
      final services = await device.discoverServices();
      LoggerUtils.i(
        'BLE service discovery complete: ${services.length} services',
      );

      BluetoothService? piService;
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuidStr) {
          piService = service;
          break;
        }
      }

      if (piService == null) {
        throw const PiProvisionException(
          'Không tìm thấy BLE service của khanhpi.',
          technicalDetail: 'Expected service UUID not discovered.',
        );
      }

      for (final characteristic in piService.characteristics) {
        final uuid = characteristic.uuid.toString().toLowerCase();
        if (uuid == commandCharUuidStr) {
          _commandChar = characteristic;
        } else if (uuid == resultCharUuidStr) {
          _resultChar = characteristic;
        } else if (uuid == statusCharUuidStr) {
          _statusChar = characteristic;
        }
      }

      if (_commandChar == null || _resultChar == null || _statusChar == null) {
        throw const PiProvisionException(
          'Pi chưa cung cấp đủ command/result/status characteristic.',
          technicalDetail: 'One or more required characteristics are missing.',
        );
      }

      LoggerUtils.i('BLE characteristics discovered successfully');

      _connectionSubscription = device.connectionState.listen((
        connectionState,
      ) {
        if (connectionState == BluetoothConnectionState.disconnected) {
          LoggerUtils.e(
            'BLE disconnected unexpectedly',
            'remoteId=${device.remoteId.str}',
          );
          _eventController.add(
            const BleRepositoryEvent(
              type: BleRepositoryEventType.disconnected,
              message: 'Kết nối BLE đã bị ngắt.',
              technicalDetail: 'BluetoothConnectionState.disconnected',
            ),
          );
          unawaited(_cleanupSession(keepDevice: false));
        }
      });

      onStepChanged?.call(BlePreparationStep.subscribingStatus);
      await _statusChar!.setNotifyValue(true);
      _statusSubscription = _statusChar!.lastValueStream.listen(
        _handleStatusValue,
        onError: (Object error, StackTrace stackTrace) {
          LoggerUtils.e('BLE status notify stream error', error, stackTrace);
        },
      );

      LoggerUtils.i('BLE status notify subscribed');

      try {
        final currentStatus = await _statusChar!.read();
        if (currentStatus.isNotEmpty) {
          _handleStatusValue(currentStatus, emitLog: false);
        }
      } catch (error, stackTrace) {
        LoggerUtils.e('BLE initial status read failed', error, stackTrace);
      }

      _isReady = true;
    } catch (error, stackTrace) {
      LoggerUtils.e('BLE prepare failed', error, stackTrace);
      await _cleanupSession(keepDevice: false);
      rethrow;
    }
  }

  Future<PiResponse> ping() => sendCommandAndReadResult('ping');

  Future<List<PiWifiNetwork>> scanWifi() async {
    final response = await sendCommandAndReadResult(
      'scan_wifi',
      payload: const {'limit': 12},
      timeout: const Duration(seconds: 12),
    );
    _ensureOk(response, fallbackMessage: 'Pi không quét được danh sách Wi-Fi.');
    return response.networks;
  }

  Future<PiWifiStatus> wifiStatus() async {
    final response = await sendCommandAndReadResult(
      'wifi_status',
      timeout: const Duration(seconds: 8),
    );
    _ensureOk(
      response,
      fallbackMessage: 'Pi không trả về trạng thái Wi-Fi hiện tại.',
    );

    final status = response.status;
    if (status == null) {
      throw const PiProvisionException(
        'Pi không trả về trạng thái Wi-Fi hợp lệ.',
        technicalDetail: 'Response status field is null.',
      );
    }

    return status;
  }

  Future<PiWifiStatus> connectWifi({
    required String ssid,
    required String password,
  }) async {
    final response = await sendCommandAndReadResult(
      'connect_wifi',
      payload: <String, dynamic>{'ssid': ssid, 'password': password},
      timeout: const Duration(seconds: 12),
    );

    _ensureOk(response, fallbackMessage: 'Pi báo lỗi khi kết nối Wi-Fi.');

    final status = response.status;
    if (status == null) {
      throw const PiProvisionException(
        'Pi chưa trả về trạng thái mạng sau khi kết nối.',
        technicalDetail: 'Response status field is null after connect_wifi.',
      );
    }

    return status;
  }

  Future<PiResponse> deviceStatus() =>
      sendCommandAndReadResult('device_status');

  Future<PiResponse> sendCommandAndReadResult(
    String action, {
    Map<String, dynamic>? payload,
    Duration timeout = _statusNotifyTimeout,
  }) async {
    if (!isReady) {
      throw const PiProvisionException(
        'Chưa sẵn sàng BLE.',
        technicalDetail: 'Repository is not in ready state.',
      );
    }

    if (_pendingStatusCompleter != null) {
      throw const PiProvisionException(
        'Pi đang xử lý lệnh khác, vui lòng thử lại.',
        technicalDetail: 'Pending status waiter already exists.',
      );
    }

    final requestPayload = <String, dynamic>{'action': action, ...?payload};
    final rawCommand = '${jsonEncode(requestPayload)}\n';
    final baselineVersion = _statusVersion;
    final statusCompleter = Completer<void>();
    _pendingStatusCompleter = statusCompleter;

    try {
      LoggerUtils.i('BLE command send start: $action');
      await _commandChar!.write(
        utf8.encode(rawCommand),
        withoutResponse: false,
        allowLongWrite: true,
      );
      LoggerUtils.i('BLE command sent: $action');

      await statusCompleter.future.timeout(
        timeout,
        onTimeout: () {
          throw PiProvisionException(
            'Pi không phản hồi kịp cho lệnh $action.',
            technicalDetail:
                'Status notify timeout after $timeout. baseline=$baselineVersion latest=$_statusVersion token=$_latestStatusToken',
          );
        },
      );

      final resultBytes = await _resultChar!.read();
      if (resultBytes.isEmpty) {
        throw PiProvisionException(
          'Pi chưa trả dữ liệu cho lệnh $action.',
          technicalDetail: 'Result characteristic returned empty bytes.',
        );
      }

      final response = _parseResult(resultBytes);
      LoggerUtils.i('BLE result parsed for $action: ok=${response.ok}');
      return response;
    } catch (error, stackTrace) {
      LoggerUtils.e('BLE command failed: $action', error, stackTrace);
      if (error is PiProvisionException) {
        rethrow;
      }
      throw PiProvisionException(
        'Không gửi được lệnh $action tới Pi.',
        technicalDetail: error.toString(),
      );
    } finally {
      if (identical(_pendingStatusCompleter, statusCompleter)) {
        _pendingStatusCompleter = null;
      }
    }
  }

  Future<void> disconnect() async {
    LoggerUtils.i('BLE disconnect requested');
    await _cleanupSession(keepDevice: false);
  }

  void _handleStatusValue(List<int> value, {bool emitLog = true}) {
    if (value.isEmpty) {
      return;
    }

    final token = utf8.decode(value, allowMalformed: true).trim();
    if (token.isEmpty) {
      return;
    }

    if (_latestStatusToken == token) {
      return;
    }

    _latestStatusToken = token;
    _statusVersion += 1;

    if (emitLog) {
      LoggerUtils.i('BLE status changed: token=$token version=$_statusVersion');
    }

    final completer = _pendingStatusCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  PiResponse _parseResult(List<int> bytes) {
    final decoded = utf8.decode(bytes, allowMalformed: true).trim();
    try {
      final parsed = jsonDecode(decoded);
      if (parsed is Map<String, dynamic>) {
        return PiResponse.fromJson(parsed);
      }
      if (parsed is Map) {
        return PiResponse.fromJson(Map<String, dynamic>.from(parsed));
      }
    } catch (error) {
      LoggerUtils.e('BLE result JSON decode failed', error);
    }

    throw PiProvisionException(
      'Pi trả dữ liệu không hợp lệ.',
      technicalDetail: 'Decoded result is not valid JSON: $decoded',
    );
  }

  void _ensureOk(PiResponse response, {required String fallbackMessage}) {
    if (response.ok) {
      return;
    }

    throw PiProvisionException(
      response.error ?? fallbackMessage,
      technicalDetail: jsonEncode(response.raw),
    );
  }

  Future<void> _cleanupSession({required bool keepDevice}) async {
    _isReady = false;

    final completer = _pendingStatusCompleter;
    _pendingStatusCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(
        const PiProvisionException(
          'Phiên BLE đã bị đóng.',
          technicalDetail: 'Pending status waiter cancelled during cleanup.',
        ),
      );
    }

    await _statusSubscription?.cancel();
    _statusSubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    if (!keepDevice && _device != null) {
      try {
        await _device!.disconnect();
      } catch (error, stackTrace) {
        LoggerUtils.e('BLE best-effort disconnect failed', error, stackTrace);
      }
      _device = null;
    }

    _commandChar = null;
    _resultChar = null;
    _statusChar = null;
    _latestStatusToken = null;
    _statusVersion = 0;
  }

  void dispose() {
    unawaited(_cleanupSession(keepDevice: false));
    unawaited(_eventController.close());
  }
}
