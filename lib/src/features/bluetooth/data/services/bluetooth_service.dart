import 'dart:async';

import 'package:app_iot/src/features/bluetooth/domain/models/bt_classic_device.dart';
import 'package:bluetooth_serial_android/bluetooth_serial_android.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final bluetoothServiceProvider = Provider.autoDispose<BluetoothService>((ref) {
  final service = BluetoothService();
  ref.onDispose(service.dispose);
  return service;
});

enum RfcommEventType { data, disconnected, error }

class RfcommEvent {
  const RfcommEvent._({required this.type, this.chunk, this.message});

  const RfcommEvent.data(String chunk)
    : this._(type: RfcommEventType.data, chunk: chunk);

  const RfcommEvent.disconnected() : this._(type: RfcommEventType.disconnected);

  const RfcommEvent.error(String message)
    : this._(type: RfcommEventType.error, message: message);

  final RfcommEventType type;
  final String? chunk;
  final String? message;
}

class BluetoothPermissionSnapshot {
  const BluetoothPermissionSnapshot({
    required this.scan,
    required this.connect,
    required this.location,
    this.isSupported = true,
  });

  const BluetoothPermissionSnapshot.unsupported()
    : scan = PermissionStatus.denied,
      connect = PermissionStatus.denied,
      location = PermissionStatus.denied,
      isSupported = false;

  final PermissionStatus scan;
  final PermissionStatus connect;
  final PermissionStatus location;
  final bool isSupported;

  bool get isGranted =>
      isSupported && scan.isGranted && connect.isGranted && location.isGranted;

  bool get isPermanentlyDenied =>
      scan.isPermanentlyDenied ||
      connect.isPermanentlyDenied ||
      location.isPermanentlyDenied;
}

class BluetoothService {
  static const MethodChannel _bluetoothChannel = MethodChannel(
    'app_iot/bluetooth',
  );
  static const EventChannel _rfcommEventChannel = EventChannel(
    'app_iot/rfcomm_events',
  );

  final StreamController<RfcommEvent> _rfcommEventsController =
      StreamController<RfcommEvent>.broadcast();

  StreamSubscription<dynamic>? _rfcommSubscription;

  bool get isAndroidSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Stream<RfcommEvent> get rfcommEvents => _rfcommEventsController.stream;

  List<Permission> get _requiredPermissions => const [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse,
  ];

  BluetoothService() {
    if (isAndroidSupported) {
      _rfcommSubscription = _rfcommEventChannel.receiveBroadcastStream().listen(
        _handleRfcommEvent,
        onError: (Object error) {
          _rfcommEventsController.add(RfcommEvent.error(error.toString()));
        },
      );
    }
  }

  Future<BluetoothPermissionSnapshot> getPermissionSnapshot() async {
    if (!isAndroidSupported) {
      return const BluetoothPermissionSnapshot.unsupported();
    }

    final statuses = await Future.wait(
      _requiredPermissions.map((permission) => permission.status),
    );

    return BluetoothPermissionSnapshot(
      scan: statuses[0],
      connect: statuses[1],
      location: statuses[2],
    );
  }

  Future<BluetoothPermissionSnapshot> requestPermissions() async {
    if (!isAndroidSupported) {
      return const BluetoothPermissionSnapshot.unsupported();
    }

    final result = await _requiredPermissions.request();

    return BluetoothPermissionSnapshot(
      scan: result[Permission.bluetoothScan] ?? PermissionStatus.denied,
      connect: result[Permission.bluetoothConnect] ?? PermissionStatus.denied,
      location: result[Permission.locationWhenInUse] ?? PermissionStatus.denied,
    );
  }

  Future<bool> isBluetoothEnabled() async {
    if (!isAndroidSupported) {
      return false;
    }

    final enabled = await _bluetoothChannel.invokeMethod<bool>(
      'isBluetoothEnabled',
    );
    return enabled ?? false;
  }

  Future<void> requestEnableBluetooth() async {
    if (!isAndroidSupported) {
      throw UnsupportedError('RFCOMM Classic chỉ hỗ trợ Android.');
    }

    await _bluetoothChannel.invokeMethod<void>('requestEnableBluetooth');
  }

  Future<List<BtClassicDevice>> scanDevices({
    String preferredDeviceName = 'khanhpi',
  }) async {
    if (!isAndroidSupported) {
      throw UnsupportedError('RFCOMM Classic chỉ hỗ trợ Android.');
    }

    final pairedDevices = await FlutterBluetoothSerial.getPairedDevices();
    final scannedDevices = await FlutterBluetoothSerial.scanDevices();

    final mergedDevices = <String, BtClassicDevice>{};

    for (final device in pairedDevices) {
      final mapped = BtClassicDevice.fromPluginMap(device, isBonded: true);
      if (mapped.address.isNotEmpty) {
        mergedDevices[mapped.address] = mapped;
      }
    }

    for (final device in scannedDevices) {
      final mapped = BtClassicDevice.fromPluginMap(
        device,
        isBonded: mergedDevices[device['address']]?.isBonded ?? false,
      );
      if (mapped.address.isNotEmpty) {
        mergedDevices[mapped.address] = mapped;
      }
    }

    final devices = mergedDevices.values.toList()
      ..sort((left, right) {
        final leftPreferred = left.matchesAlias(preferredDeviceName);
        final rightPreferred = right.matchesAlias(preferredDeviceName);

        if (leftPreferred != rightPreferred) {
          return leftPreferred ? -1 : 1;
        }

        if (left.isBonded != right.isBonded) {
          return left.isBonded ? -1 : 1;
        }

        return left.displayName.toLowerCase().compareTo(
          right.displayName.toLowerCase(),
        );
      });

    return devices;
  }

  Future<void> connectRfcomm({
    required BtClassicDevice device,
    int channel = 4,
  }) async {
    if (!isAndroidSupported) {
      throw UnsupportedError('RFCOMM Classic chỉ hỗ trợ Android.');
    }

    await _bluetoothChannel.invokeMethod<void>('connectRfcommChannel', {
      'address': device.address,
      'name': device.name,
      'channel': channel,
    });
  }

  Future<void> disconnectRfcomm() async {
    if (!isAndroidSupported) {
      return;
    }

    await _bluetoothChannel.invokeMethod<void>('disconnectRfcomm');
  }

  Future<void> writeLine(String line) async {
    if (!isAndroidSupported) {
      throw UnsupportedError('RFCOMM Classic chỉ hỗ trợ Android.');
    }

    await _bluetoothChannel.invokeMethod<void>('writeRfcomm', {
      'message': line,
    });
  }

  void _handleRfcommEvent(dynamic event) {
    if (event is String) {
      _rfcommEventsController.add(RfcommEvent.data(event));
      return;
    }

    if (event is! Map) {
      return;
    }

    final type = event['type']?.toString();
    switch (type) {
      case 'data':
        final chunk = event['data']?.toString();
        if (chunk != null && chunk.isNotEmpty) {
          _rfcommEventsController.add(RfcommEvent.data(chunk));
        }
        break;
      case 'disconnected':
        _rfcommEventsController.add(const RfcommEvent.disconnected());
        break;
      case 'error':
        _rfcommEventsController.add(
          RfcommEvent.error(
            event['message']?.toString() ?? 'Kết nối RFCOMM bị gián đoạn.',
          ),
        );
        break;
    }
  }

  void dispose() {
    if (_rfcommSubscription != null) {
      unawaited(_rfcommSubscription!.cancel());
    }
    unawaited(disconnectRfcomm());
    unawaited(_rfcommEventsController.close());
  }
}
