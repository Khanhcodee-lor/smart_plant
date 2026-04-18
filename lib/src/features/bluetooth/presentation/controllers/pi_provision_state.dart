import 'package:app_iot/src/features/bluetooth/domain/models/pi_response.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pi_provision_state.freezed.dart';

enum ProvisionBleStage {
  idle,
  scanning,
  deviceFound,
  connecting,
  discoveringServices,
  subscribingStatus,
  ready,
  sendingCommand,
  waitingResult,
  disconnected,
  error,
}

@freezed
class PiProvisionState with _$PiProvisionState {
  const factory PiProvisionState({
    @Default(true) bool isSupported,
    @Default(false) bool isInitialized,
    @Default(false) bool permissionsGranted,
    @Default(false) bool permissionsPermanentlyDenied,
    @Default(false) bool bluetoothEnabled,
    @Default(ProvisionBleStage.idle) ProvisionBleStage bleStage,
    @Default([]) List<ScanResult> devices,
    ScanResult? selectedDevice,
    @Default([]) List<PiWifiNetwork> wifiNetworks,
    PiWifiNetwork? selectedWifiNetwork,
    PiWifiStatus? wifiStatus,
    @Default('') String wifiPassword,
    String? lastCommandAction,
    String? infoMessage,
    String? errorMessage,
    String? statusDebugValue,
  }) = _PiProvisionState;

  const PiProvisionState._();

  bool get isBusy =>
      bleStage == ProvisionBleStage.scanning ||
      bleStage == ProvisionBleStage.connecting ||
      bleStage == ProvisionBleStage.discoveringServices ||
      bleStage == ProvisionBleStage.subscribingStatus ||
      bleStage == ProvisionBleStage.sendingCommand ||
      bleStage == ProvisionBleStage.waitingResult;

  bool get isReady => bleStage == ProvisionBleStage.ready;

  bool get hasConnectedBleSession =>
      bleStage == ProvisionBleStage.ready ||
      bleStage == ProvisionBleStage.sendingCommand ||
      bleStage == ProvisionBleStage.waitingResult;

  bool get canIssueBusinessCommands => isReady;

  bool get canStartConnect =>
      permissionsGranted &&
      bluetoothEnabled &&
      !isBusy &&
      selectedDevice != null;

  bool get showPiActions =>
      selectedDevice != null ||
      hasConnectedBleSession ||
      bleStage == ProvisionBleStage.disconnected;

  String get bleStageLabel {
    switch (bleStage) {
      case ProvisionBleStage.idle:
        return 'Idle';
      case ProvisionBleStage.scanning:
        return 'Scanning';
      case ProvisionBleStage.deviceFound:
        return 'Device Found';
      case ProvisionBleStage.connecting:
        return 'Connecting';
      case ProvisionBleStage.discoveringServices:
        return 'Discovering Services';
      case ProvisionBleStage.subscribingStatus:
        return 'Subscribing Status';
      case ProvisionBleStage.ready:
        return 'Ready';
      case ProvisionBleStage.sendingCommand:
        return 'Sending Command';
      case ProvisionBleStage.waitingResult:
        return 'Waiting Result';
      case ProvisionBleStage.disconnected:
        return 'Disconnected';
      case ProvisionBleStage.error:
        return 'Error';
    }
  }
}
