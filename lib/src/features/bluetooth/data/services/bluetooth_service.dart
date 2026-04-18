import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bluetooth_service.g.dart';

@riverpod
BluetoothService bluetoothService(BluetoothServiceRef ref) {
  return BluetoothService();
}

class BluetoothPermissionSnapshot {
  const BluetoothPermissionSnapshot({
    required this.scan,
    required this.connect,
    required this.location,
    this.isSupported = true,
  });

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
  bool get isSupported => Platform.isAndroid || Platform.isIOS;

  List<Permission> get _requiredPermissions {
    if (Platform.isAndroid) {
      return [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ];
    } else if (Platform.isIOS) {
      return [
        Permission.bluetooth,
        Permission.locationWhenInUse,
      ];
    }
    return [];
  }

  Future<BluetoothPermissionSnapshot> getPermissionSnapshot() async {
    if (!isSupported) {
      return const BluetoothPermissionSnapshot(
        scan: PermissionStatus.denied,
        connect: PermissionStatus.denied,
        location: PermissionStatus.denied,
        isSupported: false,
      );
    }

    final statuses = await Future.wait(
      _requiredPermissions.map((permission) => permission.status),
    );

    if (Platform.isAndroid) {
      return BluetoothPermissionSnapshot(
        scan: statuses[0],
        connect: statuses[1],
        location: statuses[2],
      );
    } else {
      return BluetoothPermissionSnapshot(
        scan: statuses[0],
        connect: statuses[0],
        location: statuses[1],
      );
    }
  }

  Future<BluetoothPermissionSnapshot> requestPermissions() async {
    if (!isSupported) {
      return const BluetoothPermissionSnapshot(
        scan: PermissionStatus.denied,
        connect: PermissionStatus.denied,
        location: PermissionStatus.denied,
        isSupported: false,
      );
    }

    final result = await _requiredPermissions.request();

    if (Platform.isAndroid) {
      return BluetoothPermissionSnapshot(
        scan: result[Permission.bluetoothScan] ?? PermissionStatus.denied,
        connect: result[Permission.bluetoothConnect] ?? PermissionStatus.denied,
        location: result[Permission.locationWhenInUse] ?? PermissionStatus.denied,
      );
    } else {
      return BluetoothPermissionSnapshot(
        scan: result[Permission.bluetooth] ?? PermissionStatus.denied,
        connect: result[Permission.bluetooth] ?? PermissionStatus.denied,
        location: result[Permission.locationWhenInUse] ?? PermissionStatus.denied,
      );
    }
  }

  Future<bool> isBluetoothEnabled() async {
    if (!isSupported) return false;
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  Future<void> requestEnableBluetooth() async {
    if (!isSupported) throw UnsupportedError('Hệ điều hành hiện tại không hỗ trợ BLE.');
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    } else {
      throw UnsupportedError('iOS không hỗ trợ bật bluetooth qua ứng dụng. Vui lòng bật thủ công.');
    }
  }
}
