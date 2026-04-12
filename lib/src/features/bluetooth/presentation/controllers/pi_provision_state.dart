import 'package:app_iot/src/features/bluetooth/domain/models/bt_classic_device.dart';
import 'package:app_iot/src/features/bluetooth/domain/models/pi_response.dart';

enum ProvisionFlowStatus {
  idle,
  scanningBt,
  connectingBt,
  connectedBt,
  scanningWifi,
  connectingWifi,
  success,
  error,
}

class PiProvisionState {
  const PiProvisionState({
    this.isSupported = true,
    this.isInitialized = false,
    this.permissionsGranted = false,
    this.permissionsPermanentlyDenied = false,
    this.bluetoothEnabled = false,
    this.isBluetoothConnected = false,
    this.status = ProvisionFlowStatus.idle,
    this.devices = const [],
    this.selectedDevice,
    this.wifiNetworks = const [],
    this.selectedWifiNetwork,
    this.wifiStatus,
    this.wifiPassword = '',
    this.infoMessage,
    this.errorMessage,
  });

  final bool isSupported;
  final bool isInitialized;
  final bool permissionsGranted;
  final bool permissionsPermanentlyDenied;
  final bool bluetoothEnabled;
  final bool isBluetoothConnected;
  final ProvisionFlowStatus status;
  final List<BtClassicDevice> devices;
  final BtClassicDevice? selectedDevice;
  final List<PiWifiNetwork> wifiNetworks;
  final PiWifiNetwork? selectedWifiNetwork;
  final PiWifiStatus? wifiStatus;
  final String wifiPassword;
  final String? infoMessage;
  final String? errorMessage;

  static const Object _sentinel = Object();

  bool get isBusy =>
      status == ProvisionFlowStatus.scanningBt ||
      status == ProvisionFlowStatus.connectingBt ||
      status == ProvisionFlowStatus.scanningWifi ||
      status == ProvisionFlowStatus.connectingWifi;

  PiProvisionState copyWith({
    bool? isSupported,
    bool? isInitialized,
    bool? permissionsGranted,
    bool? permissionsPermanentlyDenied,
    bool? bluetoothEnabled,
    bool? isBluetoothConnected,
    ProvisionFlowStatus? status,
    List<BtClassicDevice>? devices,
    Object? selectedDevice = _sentinel,
    List<PiWifiNetwork>? wifiNetworks,
    Object? selectedWifiNetwork = _sentinel,
    Object? wifiStatus = _sentinel,
    String? wifiPassword,
    Object? infoMessage = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return PiProvisionState(
      isSupported: isSupported ?? this.isSupported,
      isInitialized: isInitialized ?? this.isInitialized,
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      permissionsPermanentlyDenied:
          permissionsPermanentlyDenied ?? this.permissionsPermanentlyDenied,
      bluetoothEnabled: bluetoothEnabled ?? this.bluetoothEnabled,
      isBluetoothConnected: isBluetoothConnected ?? this.isBluetoothConnected,
      status: status ?? this.status,
      devices: devices ?? this.devices,
      selectedDevice: selectedDevice == _sentinel
          ? this.selectedDevice
          : selectedDevice as BtClassicDevice?,
      wifiNetworks: wifiNetworks ?? this.wifiNetworks,
      selectedWifiNetwork: selectedWifiNetwork == _sentinel
          ? this.selectedWifiNetwork
          : selectedWifiNetwork as PiWifiNetwork?,
      wifiStatus: wifiStatus == _sentinel
          ? this.wifiStatus
          : wifiStatus as PiWifiStatus?,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      infoMessage: infoMessage == _sentinel
          ? this.infoMessage
          : infoMessage as String?,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
