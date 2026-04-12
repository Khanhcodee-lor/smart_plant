import 'dart:async';

import 'package:app_iot/src/features/bluetooth/data/parsers/json_line_parser.dart';
import 'package:app_iot/src/features/bluetooth/data/services/bluetooth_service.dart';
import 'package:app_iot/src/features/bluetooth/domain/models/bt_classic_device.dart';
import 'package:app_iot/src/features/bluetooth/domain/models/pi_request.dart';
import 'package:app_iot/src/features/bluetooth/domain/models/pi_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final piProvisionRepositoryProvider =
    Provider.autoDispose<PiProvisionRepository>((ref) {
      final bluetoothService = ref.watch(bluetoothServiceProvider);
      final repository = PiProvisionRepository(bluetoothService);
      ref.onDispose(repository.dispose);
      return repository;
    });

class PiProvisionException implements Exception {
  const PiProvisionException(this.message);

  final String message;

  @override
  String toString() => 'PiProvisionException($message)';
}

class PiProvisionRepository {
  PiProvisionRepository(this._bluetoothService)
    : _rfcommSubscription = _bluetoothService.rfcommEvents.listen(
        _noopRfcommListener,
      ) {
    _rfcommSubscription
      ..onData(_handleRfcommEvent)
      ..onError((Object error, StackTrace stackTrace) {
        _failPending(PiProvisionException('Kênh RFCOMM bị lỗi: $error'));
      });
  }

  final BluetoothService _bluetoothService;
  final JsonLineParser _parser = JsonLineParser();
  final StreamController<PiResponse> _responsesController =
      StreamController<PiResponse>.broadcast();
  final StreamSubscription<RfcommEvent> _rfcommSubscription;

  Completer<PiResponse>? _pendingCompleter;
  String? _pendingAction;

  Stream<PiResponse> get responses => _responsesController.stream;

  static void _noopRfcommListener(RfcommEvent _) {}

  Future<void> connectToDevice(
    BtClassicDevice device, {
    int channel = 4,
    int retries = 2,
  }) async {
    Object? lastError;

    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        _parser.clear();
        await _bluetoothService.connectRfcomm(device: device, channel: channel);
        return;
      } catch (error) {
        lastError = error;
        await _bluetoothService.disconnectRfcomm();
        if (attempt < retries) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    throw PiProvisionException(
      'Không thể kết nối Bluetooth tới ${device.displayName}. ${lastError ?? ''}'
          .trim(),
    );
  }

  Future<void> disconnect() async {
    _clearPending();
    _parser.clear();
    await _bluetoothService.disconnectRfcomm();
  }

  Future<PiResponse> ping() => _sendRequest(const PingPiRequest());

  Future<List<PiWifiNetwork>> scanWifi() async {
    final response = await _sendRequest(const ScanWifiPiRequest());
    _ensureOk(response, fallbackMessage: 'Pi không quét được danh sách Wi-Fi.');
    return response.networks;
  }

  Future<PiWifiStatus> wifiStatus() async {
    final response = await _sendRequest(const WifiStatusPiRequest());
    _ensureOk(
      response,
      fallbackMessage: 'Pi không trả về trạng thái Wi-Fi hiện tại.',
    );

    final status = response.status;
    if (status == null) {
      throw const PiProvisionException(
        'Pi không trả về trạng thái Wi-Fi hợp lệ.',
      );
    }

    return status;
  }

  Future<PiWifiStatus> connectWifi({
    required String ssid,
    required String password,
  }) async {
    final response = await _sendRequest(
      ConnectWifiPiRequest(ssid: ssid, password: password),
      timeout: const Duration(seconds: 35),
    );

    _ensureOk(response, fallbackMessage: 'Pi báo lỗi khi kết nối Wi-Fi.');

    final status = response.status;
    if (status == null) {
      throw const PiProvisionException(
        'Pi chưa trả về trạng thái mạng sau khi kết nối.',
      );
    }

    return status;
  }

  Future<PiResponse> _sendRequest(
    PiRequest request, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_pendingCompleter != null) {
      throw const PiProvisionException(
        'Đang có lệnh khác chờ phản hồi từ Raspberry Pi.',
      );
    }

    final completer = Completer<PiResponse>();
    _pendingCompleter = completer;
    _pendingAction = request.action;

    try {
      await _bluetoothService.writeLine(request.toLine());
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          throw PiProvisionException(
            'Hết thời gian chờ phản hồi cho lệnh ${request.action}.',
          );
        },
      );
    } finally {
      _clearPending();
    }
  }

  void _handleRfcommEvent(RfcommEvent event) {
    switch (event.type) {
      case RfcommEventType.data:
        final chunk = event.chunk;
        if (chunk == null || chunk.isEmpty) {
          return;
        }

        final parsedMessages = _parser.append(chunk);
        for (final message in parsedMessages) {
          final response = PiResponse.fromJson(message);
          _responsesController.add(response);

          if (_pendingCompleter != null &&
              _pendingAction != null &&
              response.action == _pendingAction &&
              !_pendingCompleter!.isCompleted) {
            _pendingCompleter!.complete(response);
          }
        }
        break;
      case RfcommEventType.disconnected:
        _failPending(
          const PiProvisionException('Kết nối Bluetooth đã bị ngắt.'),
        );
        break;
      case RfcommEventType.error:
        _failPending(
          PiProvisionException(
            event.message ?? 'Kênh RFCOMM gặp lỗi không xác định.',
          ),
        );
        break;
    }
  }

  void _ensureOk(PiResponse response, {required String fallbackMessage}) {
    if (response.ok) {
      return;
    }

    throw PiProvisionException(response.error ?? fallbackMessage);
  }

  void _failPending(Object error) {
    if (_pendingCompleter != null && !_pendingCompleter!.isCompleted) {
      _pendingCompleter!.completeError(error);
    }
    _clearPending();
  }

  void _clearPending() {
    _pendingCompleter = null;
    _pendingAction = null;
  }

  void dispose() {
    _failPending(const PiProvisionException('Đã đóng phiên cấu hình.'));
    unawaited(_rfcommSubscription.cancel());
    unawaited(_responsesController.close());
    unawaited(_bluetoothService.disconnectRfcomm());
  }
}
