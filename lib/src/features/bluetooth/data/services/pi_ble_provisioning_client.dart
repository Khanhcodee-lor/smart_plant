import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_iot/src/features/bluetooth/data/parsers/json_line_parser.dart';
import 'package:app_iot/src/features/bluetooth/domain/models/pi_response.dart';

enum PiBleState {
  idle,
  scanning,
  connecting,
  subscribed,
  sending,
  success,
  error,
}

class PiBleProvisioningClient extends ChangeNotifier {
  // ── BLE UUIDs ──────────────────────────────────────────────────────────────
  static const _svcUuid = '0f5c0001-95c7-43f1-b1d5-28f9f0dca001';
  static const _cmdUuid = '0f5c0002-95c7-43f1-b1d5-28f9f0dca001';
  static const _resUuid = '0f5c0003-95c7-43f1-b1d5-28f9f0dca001';
  static const _stUuid = '0f5c0004-95c7-43f1-b1d5-28f9f0dca001';

  // ── Timeouts ────────────────────────────────────────────────────────────────
  static const _scanDuration = Duration(seconds: 15);
  static const _connectTimeout = Duration(seconds: 15);
  // scan_wifi tốn thời gian trên Pi → 25s để tránh drop BLE khi Pi đang scan
  static const _commandTimeout = Duration(seconds: 25);
  static const _discoverDelay = Duration(milliseconds: 1200);
  static const _retryDelay = Duration(milliseconds: 1500);
  static const _discoverTimeout = Duration(seconds: 20);
  static const _maxRetries = 2;
  static const _readAfterStatusDelay = Duration(milliseconds: 150);
  static const _defaultBleMtu = 23;
  static const _fallbackBlePayloadSize = 20;

  // ── Public state ────────────────────────────────────────────────────────────
  PiBleState get state => _state;
  String? get errorMessage => _error;
  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);
  BluetoothDevice? get connectedDevice => _device;

  // ── Private ─────────────────────────────────────────────────────────────────
  PiBleState _state = PiBleState.idle;
  String? _error;
  List<ScanResult> _scanResults = [];
  BluetoothDevice? _device;
  BluetoothCharacteristic? _cmdChar;
  BluetoothCharacteristic? _resChar;
  BluetoothCharacteristic? _stChar;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<List<int>>? _resSub;
  StreamSubscription<List<int>>? _stSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  // Dùng Completer để chờ ĐÚNG 1 notify mới (không phải cached value)
  Completer<void>? _pendingNotify;
  Completer<PiResponse>? _pendingResponse;
  final JsonLineParser _responseParser = JsonLineParser();

  bool _disposed = false;

  final bool enableDebugLogs;
  PiBleProvisioningClient({this.enableDebugLogs = true});

  void _log(String msg) {
    if (enableDebugLogs) debugPrint('[PiBle] $msg');
  }

  void _set(PiBleState s, {String? error, bool clearError = false}) {
    if (_disposed) return;
    _state = s;
    if (clearError) _error = null;
    if (error != null) _error = error;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. PERMISSIONS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<bool> requestPermissions() async {
    _log('Requesting BLE permissions…');
    final perms = Platform.isAndroid
        ? [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.locationWhenInUse,
          ]
        : [Permission.bluetooth, Permission.locationWhenInUse];
    final result = await perms.request();
    final granted = result.values.every((s) => s.isGranted);
    _log('Permissions granted: $granted');
    if (granted && Platform.isAndroid) {
      try {
        if (await FlutterBluePlus.adapterState.first ==
            BluetoothAdapterState.off) {
          await FlutterBluePlus.turnOn();
        }
      } catch (e) {
        _log('turnOn ignored: $e');
      }
    }
    return granted;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. SCAN
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> scanDevices() async {
    _log('Scan start (UUID filter)…');
    _scanResults = [];
    _set(PiBleState.scanning, error: null);

    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;

    _scanSub = FlutterBluePlus.scanResults.listen(
      (results) {
        if (_disposed) return;
        _scanResults = results;
        notifyListeners();
        _log('Scan: ${results.length} device(s)');
      },
      onError: (Object e) => _log('Scan stream error: $e'),
      cancelOnError: false,
    );

    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(_svcUuid)],
        timeout: _scanDuration,
        androidUsesFineLocation: false,
      );
      // startScan() hoàn thành ngay khi bắt đầu scan — PHẢI chờ isScanning=false
      await FlutterBluePlus.isScanning
          .where((v) => v == false)
          .first
          .timeout(
            _scanDuration + const Duration(seconds: 3),
            onTimeout: () => false,
          );

      _log('Scan done: ${_scanResults.length} device(s).');
    } catch (e, st) {
      _log('Scan error: $e\n$st');
      _set(PiBleState.error, error: 'Lỗi quét BLE: $e');
      return;
    } finally {
      await _scanSub?.cancel();
      _scanSub = null;
      await FlutterBluePlus.stopScan();
    }

    // ✅ FIX: Chỉ về idle nếu ĐANG ở trạng thái scanning
    // KHÔNG override subscribed/success/sending —
    // user có thể đã connect trong khi scan vẫn đang chạy ngầm
    if (_state == PiBleState.scanning) {
      _set(PiBleState.idle, clearError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. CONNECT + DISCOVER + SUBSCRIBE
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> connect(BluetoothDevice device) async {
    _log('Connecting to ${device.remoteId}…');
    await _cleanup(disconnect: false);
    _device = device;
    _set(PiBleState.connecting, error: null);

    try {
      // Đảm bảo device đã disconnect trước
      final cs = await device.connectionState.first;
      if (cs != BluetoothConnectionState.disconnected) {
        await device.disconnect();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }

      await device.connect(
        autoConnect: false,
        timeout: _connectTimeout,
        mtu: null,
      );
      _log('Connected. Waiting for GATT stable…');
      await Future<void>.delayed(_discoverDelay);

      // Listen disconnect events
      _connSub = device.connectionState.listen((cs) {
        if (cs == BluetoothConnectionState.disconnected && !_disposed) {
          _log('Unexpected disconnect!');
          _cleanup(disconnect: false).then((_) {
            _set(
              PiBleState.error,
              error: 'Mất kết nối BLE. Vui lòng kết nối lại.',
            );
          });
        }
      });

      final services = await _discoverWithRetry(device);
      _log('Services: ${services.map((s) => s.uuid).join(', ')}');

      BluetoothService? svc;
      for (final s in services) {
        if (s.uuid.toString().toLowerCase() == _svcUuid) {
          svc = s;
          break;
        }
      }
      if (svc == null) {
        throw Exception('Provisioning service không tìm thấy: $_svcUuid');
      }

      for (final c in svc.characteristics) {
        final u = c.uuid.toString().toLowerCase();
        if (u == _cmdUuid) _cmdChar = c;
        if (u == _resUuid) _resChar = c;
        if (u == _stUuid) _stChar = c;
        _log('Char: $u  props: ${c.properties}');
      }

      if (_cmdChar == null || _resChar == null || _stChar == null) {
        throw Exception(
          'Thiếu characteristic: cmd=${_cmdChar != null} res=${_resChar != null} st=${_stChar != null}',
        );
      }

      // Subscribe status TRƯỚC khi ready
      final canNotifyResult =
          _resChar!.properties.notify || _resChar!.properties.indicate;
      if (canNotifyResult) {
        _log('Subscribing result notify…');
        await _resChar!.setNotifyValue(true);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        _resSub = _resChar!.onValueReceived.listen(
          _onResponseChunk,
          onError: (Object e) => _log('Result stream error: $e'),
          cancelOnError: false,
        );
      } else {
        _log(
          'Result characteristic has no notify/indicate. Fallback to read().',
        );
      }

      _log('Subscribing status notify…');
      await _stChar!.setNotifyValue(true);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // ✅ FIX: Dùng onValueReceived thay vì lastValueStream
      // onValueReceived CHỈ fire khi có notification MỚI từ peripheral
      // lastValueStream fire ngay với cached value → completer complete sai thời điểm
      _stSub = _stChar!.onValueReceived.listen(
        _onStatus,
        onError: (Object e) => _log('Status stream error: $e'),
        cancelOnError: false,
      );

      // Xóa error cũ từ lần kết nối trước
      _set(PiBleState.subscribed, clearError: true);
      _log('BLE READY.');
    } catch (e, st) {
      _log('Connect failed: $e\n$st');
      await _cleanup(disconnect: true);
      _set(PiBleState.error, error: 'Kết nối thất bại: ${e.toString()}');
    }
  }

  Future<List<BluetoothService>> _discoverWithRetry(
    BluetoothDevice device,
  ) async {
    Object? lastErr;
    for (var i = 0; i < 3; i++) {
      // Không retry nếu device đã bị ngắt kết nối
      if (!device.isConnected) {
        throw Exception(
          'Device bị ngắt kết nối trong quá trình discover services.',
        );
      }
      try {
        _log('discoverServices attempt ${i + 1}…');
        return await device.discoverServices(
          subscribeToServicesChanged: false,
          timeout: _discoverTimeout.inSeconds,
        );
      } catch (e) {
        lastErr = e;
        _log('discoverServices failed (attempt ${i + 1}): $e');
        // Nếu device disconnect rồi thì dừng retry luôn
        if (!device.isConnected) {
          throw Exception('Device bị ngắt kết nối: $e');
        }
        if (Platform.isAndroid) {
          try {
            await device.clearGattCache();
          } catch (_) {}
        }
        if (i < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 600));
        }
      }
    }
    throw Exception('discoverServices thất bại sau 3 lần: $lastErr');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. STATUS NOTIFY HANDLER
  // ═══════════════════════════════════════════════════════════════════════════
  void _onStatus(List<int> value) {
    if (value.isEmpty) return;
    final text = utf8.decode(value, allowMalformed: true).trim();
    _log('Status notify → "$text"');

    // Chỉ complete nếu đang chờ (idempotent)
    final c = _pendingNotify;
    if (c != null && !c.isCompleted) {
      c.complete();
    }
  }

  void _onResponseChunk(List<int> value) {
    if (value.isEmpty) return;

    final chunk = utf8.decode(value, allowMalformed: true);
    _log(
      'Result chunk (${value.length} bytes): ${chunk.replaceAll('\n', r'\n')}',
    );

    try {
      final parsedItems = _responseParser.append(chunk);
      if (parsedItems.isEmpty) {
        return;
      }

      final completer = _pendingResponse;
      if (completer == null || completer.isCompleted) {
        return;
      }

      final response = PiResponse.fromJson(parsedItems.last);
      completer.complete(response);
    } catch (e, st) {
      final completer = _pendingResponse;
      if (completer != null && !completer.isCompleted) {
        completer.completeError(e, st);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. SEND COMMAND
  // ═══════════════════════════════════════════════════════════════════════════
  Future<PiResponse> sendCommand(
    String action, {
    Map<String, dynamic>? payload,
  }) async {
    if (_cmdChar == null || _resChar == null || _stChar == null) {
      throw Exception('BLE chưa sẵn sàng. Hãy kết nối trước.');
    }
    if (_pendingNotify != null && !_pendingNotify!.isCompleted) {
      throw Exception('Đang xử lý lệnh khác, thử lại sau.');
    }

    _set(PiBleState.sending);

    final frame = _buildCommandFrame(action, payload: payload);
    final bytes = utf8.encode(frame);
    _log('Command: $frame (${bytes.length} bytes)');

    Object? lastErr;

    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      _log('Attempt ${attempt + 1}/$_maxRetries…');

      // Reset completer MỚI cho mỗi lần thử — TRƯỚC khi write
      // Đảm bảo không bỏ sót notify nào đến ngay sau write
      _pendingNotify = Completer<void>();
      _pendingResponse = Completer<PiResponse>();
      _responseParser.reset();

      try {
        await _writeCommandBytes(bytes);
        _log('Command written (${bytes.length} bytes).');

        // Chờ notify từ status char với timeout đủ dài cho WiFi scan
        _log(
          'Waiting for status notify (timeout: ${_commandTimeout.inSeconds}s)…',
        );
        await _pendingNotify!.future.timeout(
          _commandTimeout,
          onTimeout: () {
            throw TimeoutException(
              'Pi không gửi status notify sau ${_commandTimeout.inSeconds}s cho "$action"',
            );
          },
        );
        _log('Status notify OK. Reading result…');

        final response = await _readResponse(action);
        _log('OK: action=${response.action} ok=${response.ok}');

        _pendingNotify = null;
        _pendingResponse = null;
        _set(PiBleState.subscribed, clearError: true);
        return response;
      } catch (e, st) {
        lastErr = e;
        _pendingNotify = null;
        _pendingResponse = null;
        _log('Attempt ${attempt + 1} error: $e\n$st');

        if (attempt < _maxRetries - 1) {
          _log('Retry in ${_retryDelay.inMilliseconds}ms…');
          await Future<void>.delayed(_retryDelay);
        }
      }
    }

    final msg = 'Lệnh "$action" thất bại sau $_maxRetries lần: $lastErr';
    _set(PiBleState.error, error: msg);
    throw Exception(msg);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. COMMAND HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<PiResponse> ping() => sendCommand('ping');
  Future<PiResponse> deviceStatus() => sendCommand('device_status');

  Future<List<PiWifiNetwork>> scanWifi({int limit = 8}) async {
    final limits = <int>{
      limit,
      if (limit > 8) 8,
      if (limit > 6) 6,
      if (limit > 4) 4,
      if (limit > 3) 3,
    }.where((value) => value > 0).toList(growable: false);

    Object? lastErr;
    for (final currentLimit in limits) {
      try {
        _log('scan_wifi with limit=$currentLimit');
        final r = await sendCommand(
          'scan_wifi',
          payload: {'limit': currentLimit},
        );
        if (!r.ok) throw Exception(r.error ?? 'scan_wifi thất bại');
        return r.networks;
      } catch (e) {
        lastErr = e;
        if (!_isLikelyTruncatedScanWifiError(e)) {
          rethrow;
        }
        _log(
          'scan_wifi response likely exceeded BLE payload at limit=$currentLimit. Retrying smaller limit…',
        );
      }
    }

    throw Exception(
      'scan_wifi bị cắt dữ liệu qua BLE. Đã thử giảm số mạng trả về nhưng vẫn lỗi: $lastErr',
    );
  }

  Future<PiWifiStatus> wifiStatus() async {
    final r = await sendCommand('wifi_status');
    if (!r.ok) throw Exception(r.error ?? 'wifi_status thất bại');
    return r.status ?? (throw Exception('Pi không trả về status field'));
  }

  Future<PiWifiStatus> connectWifi({
    required String ssid,
    required String password,
  }) async {
    final r = await sendCommand(
      'connect_wifi',
      payload: {'ssid': ssid, 'password': password},
    );
    if (!r.ok) throw Exception(r.error ?? 'connect_wifi thất bại');
    return r.status ??
        (throw Exception('Pi không trả về status sau connect_wifi'));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. DISCONNECT / CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> disconnect() async {
    _log('Disconnecting…');
    await _cleanup(disconnect: true);
    _set(PiBleState.idle);
  }

  Future<void> _cleanup({required bool disconnect}) async {
    // Cancel pending notify
    final c = _pendingNotify;
    _pendingNotify = null;
    if (c != null && !c.isCompleted) {
      c.completeError(Exception('BLE cleaned up.'));
    }
    final responseCompleter = _pendingResponse;
    _pendingResponse = null;
    if (responseCompleter != null && !responseCompleter.isCompleted) {
      responseCompleter.completeError(Exception('BLE cleaned up.'));
    }
    _responseParser.reset();

    // Cancel subscriptions (order: result/status → scan → conn để tránh event mới sau cleanup)
    await _resSub?.cancel();
    _resSub = null;
    await _stSub?.cancel();
    _stSub = null;
    await _scanSub?.cancel();
    _scanSub = null;
    await _connSub?.cancel();
    _connSub = null;

    _cmdChar = null;
    _resChar = null;
    _stChar = null;

    if (disconnect && _device != null) {
      try {
        await _device!.disconnect();
        _log('Disconnected.');
      } catch (e) {
        _log('Disconnect error (ignored): $e');
      }
    }
    _device = null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 8. DISPOSE
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  void dispose() {
    _disposed = true;
    final c = _pendingNotify;
    _pendingNotify = null;
    if (c != null && !c.isCompleted) c.completeError(Exception('Disposed.'));
    final responseCompleter = _pendingResponse;
    _pendingResponse = null;
    if (responseCompleter != null && !responseCompleter.isCompleted) {
      responseCompleter.completeError(Exception('Disposed.'));
    }
    _responseParser.reset();

    _resSub?.cancel();
    _stSub?.cancel();
    _scanSub?.cancel();
    _connSub?.cancel();
    _device?.disconnect().catchError((_) {});

    super.dispose();
  }

  Future<PiResponse> _readResponse(String action) async {
    final pendingResponse = _pendingResponse;
    if (pendingResponse != null && pendingResponse.isCompleted) {
      return pendingResponse.future;
    }

    await Future<void>.delayed(_readAfterStatusDelay);

    if (pendingResponse != null && pendingResponse.isCompleted) {
      return pendingResponse.future;
    }

    final resBytes = await _resChar!.read();
    if (resBytes.isEmpty) throw Exception('Result characteristic trả về rỗng.');

    final resStr = utf8.decode(resBytes, allowMalformed: true).trim();
    _log('Result read (${resBytes.length} bytes): $resStr');

    try {
      final dynamic parsed = jsonDecode(resStr);
      if (parsed is! Map) {
        throw FormatException('Không phải JSON object: $resStr');
      }
      return PiResponse.fromJson(Map<String, dynamic>.from(parsed));
    } on FormatException catch (e) {
      if (_looksLikeTruncatedBlePayload(action, resBytes.length, resStr)) {
        throw Exception(
          'Phản hồi "$action" bị cắt cụt qua BLE (${resBytes.length} bytes). '
          'Thường do payload scan_wifi quá dài cho 1 characteristic.',
        );
      }
      throw Exception('JSON phản hồi "$action" không hợp lệ: $e');
    }
  }

  bool _looksLikeTruncatedBlePayload(
    String action,
    int byteLength,
    String raw,
  ) {
    final text = raw.trimRight();
    if (text.isEmpty || text.endsWith('}') || text.endsWith(']')) {
      return false;
    }
    if (byteLength >= 500) {
      return true;
    }
    return action == 'scan_wifi' && text.contains('"networks"');
  }

  bool _isLikelyTruncatedScanWifiError(Object error) {
    final text = error.toString();
    return text.contains('bị cắt cụt qua BLE') ||
        text.contains('Unterminated string') ||
        text.contains('Unexpected end of input') ||
        text.contains('character 513');
  }

  String _buildCommandFrame(String action, {Map<String, dynamic>? payload}) {
    final normalizedPayload = payload ?? const <String, dynamic>{};

    // scan_wifi là lệnh rất ngắn, giữ frame dưới 20 byte để tránh phải long-write.
    if (action == 'scan_wifi' &&
        normalizedPayload.keys.every((key) => key == 'limit')) {
      final limit = normalizedPayload['limit'];
      if (limit == null) {
        return 'scan_wifi\n';
      }
      return 'scan_wifi?limit=${Uri.encodeQueryComponent(limit.toString())}\n';
    }

    final body = <String, dynamic>{'action': action, ...normalizedPayload};
    return '${jsonEncode(body)}\n';
  }

  Future<void> _writeCommandBytes(List<int> bytes) async {
    final cmdChar = _cmdChar;
    final device = _device;
    if (cmdChar == null || device == null) {
      throw Exception('BLE chưa sẵn sàng để gửi command.');
    }

    final supportsWriteWithResp = cmdChar.properties.write;
    final supportsWriteNoResp = cmdChar.properties.writeWithoutResponse;
    if (!supportsWriteWithResp && !supportsWriteNoResp) {
      throw Exception('Command characteristic không hỗ trợ write.');
    }

    final mtu = device.mtuNow;
    final chunkSize = _commandChunkSize(mtu);

    if (supportsWriteWithResp) {
      final useLongWrite = bytes.length > chunkSize;
      _log(
        'Write mode: withResponse${useLongWrite ? " + longWrite" : ""} '
        '(mtu=$mtu, payload=$chunkSize)',
      );
      await cmdChar.write(
        bytes,
        withoutResponse: false,
        allowLongWrite: useLongWrite,
      );
      return;
    }

    _log(
      'Write mode: withoutResponse chunked '
      '(mtu=$mtu, payload=$chunkSize, bytes=${bytes.length})',
    );
    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = offset + chunkSize < bytes.length
          ? offset + chunkSize
          : bytes.length;
      final chunk = bytes.sublist(offset, end);
      await cmdChar.write(chunk, withoutResponse: true, allowLongWrite: false);
    }
  }

  int _commandChunkSize(int mtu) {
    final normalizedMtu = mtu > 0 ? mtu : _defaultBleMtu;
    final payloadSize = normalizedMtu - 3;
    return payloadSize >= _fallbackBlePayloadSize
        ? payloadSize
        : _fallbackBlePayloadSize;
  }
}
