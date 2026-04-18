import 'dart:async';
import 'dart:math' as math;

import 'package:app_iot/src/core/ulits/logger_ulits.dart';
import 'package:app_iot/src/features/bluetooth/data/repositories/pi_provision_repository.dart';
import 'package:app_iot/src/features/bluetooth/data/services/bluetooth_service.dart';
import 'package:app_iot/src/features/bluetooth/domain/models/pi_response.dart';
import 'package:app_iot/src/features/bluetooth/presentation/controllers/pi_provision_state.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pi_provision_controller.g.dart';

@riverpod
class PiProvisionController extends _$PiProvisionController {
  static const Duration _scanTimeout = Duration(seconds: 5);
  static const Duration _connectTimeout = Duration(seconds: 10);
  static const int _maxConnectAttempts = 3;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BleRepositoryEvent>? _repositoryEventSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  bool _mounted = true;

  @override
  PiProvisionState build() {
    _repositoryEventSubscription = _repository.events.listen(
      _handleRepositoryEvent,
    );
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen(
      _handleAdapterState,
    );

    ref.onDispose(() async {
      _mounted = false;
      await _scanSubscription?.cancel();
      await _repositoryEventSubscription?.cancel();
      await _adapterStateSubscription?.cancel();
    });

    return const PiProvisionState();
  }

  BluetoothService get _bluetoothService => ref.read(bluetoothServiceProvider);
  PiProvisionRepository get _repository =>
      ref.read(piProvisionRepositoryProvider);

  void _setState(PiProvisionState newState) {
    if (_mounted) {
      state = newState;
    }
  }

  void _transition({
    required ProvisionBleStage stage,
    String? infoMessage,
    String? errorMessage,
    String? technicalDetail,
    String? lastCommandAction,
    String? statusDebugValue,
    bool clearError = false,
  }) {
    if (errorMessage != null) {
      LoggerUtils.e('BLE UI error: $errorMessage', technicalDetail);
    } else {
      LoggerUtils.i(
        'BLE UI transition -> ${stage.name}${infoMessage == null ? '' : ' | $infoMessage'}',
      );
    }

    _setState(
      state.copyWith(
        bleStage: stage,
        infoMessage: infoMessage ?? state.infoMessage,
        errorMessage: clearError ? null : errorMessage ?? state.errorMessage,
        lastCommandAction: lastCommandAction ?? state.lastCommandAction,
        statusDebugValue: statusDebugValue ?? state.statusDebugValue,
      ),
    );
  }

  Future<void> initialize() async {
    if (!_bluetoothService.isSupported) {
      _setState(
        state.copyWith(
          isSupported: false,
          isInitialized: true,
          bleStage: ProvisionBleStage.error,
          infoMessage: 'Thiết bị không hỗ trợ BLE.',
          errorMessage: null,
        ),
      );
      return;
    }

    await syncSystemState();
    if (!_mounted) return;

    _setState(
      state.copyWith(
        infoMessage: state.permissionsGranted
            ? state.bluetoothEnabled
                  ? 'Sẵn sàng quét và kết nối BLE tới khanhpi.'
                  : 'Bluetooth đang tắt. Bật Bluetooth để tiếp tục.'
            : 'Cấp quyền Bluetooth và vị trí để bắt đầu cấu hình.',
        errorMessage: null,
      ),
    );
  }

  Future<void> syncSystemState() async {
    if (!_bluetoothService.isSupported) {
      return;
    }

    final permissions = await _bluetoothService.getPermissionSnapshot();
    final enabled = permissions.isGranted
        ? await _safeBluetoothEnabled()
        : false;

    if (!_mounted) return;

    _setState(
      state.copyWith(
        isSupported: true,
        isInitialized: true,
        permissionsGranted: permissions.isGranted,
        permissionsPermanentlyDenied: permissions.isPermanentlyDenied,
        bluetoothEnabled: enabled,
      ),
    );

    if (!enabled && state.hasConnectedBleSession) {
      await _repository.disconnect();
      if (!_mounted) return;
      _transition(
        stage: ProvisionBleStage.disconnected,
        infoMessage: 'Bluetooth đã tắt. Bạn có thể bật lại rồi kết nối lại.',
        clearError: true,
      );
    }
  }

  Future<void> requestPermissions() async {
    if (!_bluetoothService.isSupported) {
      await initialize();
      return;
    }

    final permissions = await _bluetoothService.requestPermissions();
    final enabled = permissions.isGranted
        ? await _safeBluetoothEnabled()
        : false;

    if (!_mounted) return;

    _setState(
      state.copyWith(
        isInitialized: true,
        permissionsGranted: permissions.isGranted,
        permissionsPermanentlyDenied: permissions.isPermanentlyDenied,
        bluetoothEnabled: enabled,
        errorMessage: permissions.isGranted
            ? null
            : permissions.isPermanentlyDenied
            ? 'Quyền Bluetooth/Vị trí đang bị chặn vĩnh viễn. Hãy mở Settings để cấp lại.'
            : 'Bạn cần cấp đủ quyền Bluetooth/Vị trí để quét và kết nối Raspberry Pi.',
        infoMessage: permissions.isGranted
            ? enabled
                  ? 'Quyền đã sẵn sàng. Bạn có thể quét thiết bị khanhpi.'
                  : 'Quyền đã sẵn sàng. Hãy bật Bluetooth để tiếp tục.'
            : state.infoMessage,
      ),
    );
  }

  Future<void> enableBluetooth() async {
    if (!state.permissionsGranted) {
      _transition(
        stage: ProvisionBleStage.error,
        errorMessage: 'Hãy cấp quyền Bluetooth trước khi bật Bluetooth.',
        technicalDetail: 'enableBluetooth called without permissionsGranted',
      );
      return;
    }

    try {
      await _bluetoothService.requestEnableBluetooth();

      var enabled = false;
      for (var attempt = 0; attempt < 10; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        enabled = await _safeBluetoothEnabled();
        if (enabled) {
          break;
        }
      }

      if (!_mounted) return;

      if (!enabled) {
        _transition(
          stage: ProvisionBleStage.error,
          errorMessage:
              'Bluetooth vẫn đang tắt. Hãy bật từ hộp thoại hệ thống rồi thử lại.',
          technicalDetail: 'Adapter did not turn on within polling window',
        );
        return;
      }

      _transition(
        stage: ProvisionBleStage.idle,
        infoMessage:
            'Bluetooth đã bật. Bạn có thể quét và kết nối tới khanhpi.',
        clearError: true,
      );
      _setState(state.copyWith(bluetoothEnabled: true));
    } catch (error, stackTrace) {
      LoggerUtils.e('Enable Bluetooth failed', error, stackTrace);
      _transition(
        stage: ProvisionBleStage.error,
        errorMessage:
            'Không thể bật Bluetooth tự động. Hãy bật thủ công rồi thử lại.',
        technicalDetail: error.toString(),
      );
    }
  }

  Future<void> scanBluetoothDevices() async {
    if (!_canStartBlePreparation(requireSelectedDevice: false)) {
      return;
    }

    LoggerUtils.i('BLE scan start');
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();

    _transition(
      stage: ProvisionBleStage.scanning,
      infoMessage: 'Đang tìm Raspberry Pi khanhpi qua BLE...',
      clearError: true,
    );

    _setState(state.copyWith(devices: const [], selectedDevice: null));

    try {
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        final matchedDevices = results.toList(growable: false);

        matchedDevices.sort((a, b) {
          final aPreferred = a.device.advName.toLowerCase() == 'khanhpi';
          final bPreferred = b.device.advName.toLowerCase() == 'khanhpi';
          if (aPreferred != bPreferred) {
            return aPreferred ? -1 : 1;
          }
          return a.device.remoteId.str.compareTo(b.device.remoteId.str);
        });

        if (matchedDevices.isEmpty || !_mounted) {
          return;
        }

        final preferred = matchedDevices.first;
        _setState(
          state.copyWith(
            devices: matchedDevices,
            selectedDevice: preferred,
            bleStage: ProvisionBleStage.deviceFound,
            infoMessage:
                'Đã tìm thấy khanhpi. Bạn có thể bấm "Kết nối BLE" để chuẩn bị provisioning.',
            errorMessage: null,
          ),
        );
        LoggerUtils.i('BLE device found: ${preferred.device.remoteId.str}');
      });

      await FlutterBluePlus.startScan(
        withServices: [PiProvisionRepository.serviceGuid],
        timeout: _scanTimeout,
      );
      await Future<void>.delayed(_scanTimeout);
    } catch (error, stackTrace) {
      LoggerUtils.e('BLE scan failed', error, stackTrace);
      _transition(
        stage: ProvisionBleStage.error,
        errorMessage: 'Không quét được thiết bị BLE. Hãy thử lại.',
        technicalDetail: error.toString(),
      );
      return;
    } finally {
      await FlutterBluePlus.stopScan();
      LoggerUtils.i('BLE scan stop');
    }

    if (!_mounted) return;

    if (state.selectedDevice == null) {
      _transition(
        stage: ProvisionBleStage.idle,
        infoMessage:
            'Không tìm thấy khanhpi. Hãy đưa Pi lại gần, kiểm tra BLE trên Pi rồi quét lại.',
        clearError: true,
      );
    }
  }

  void selectDevice(ScanResult device) {
    LoggerUtils.i('BLE device selected: ${device.device.remoteId.str}');
    _setState(
      state.copyWith(
        selectedDevice: device,
        bleStage: ProvisionBleStage.deviceFound,
        errorMessage: null,
        infoMessage: 'Đã chọn ${device.device.advName}. Sẵn sàng kết nối BLE.',
      ),
    );
  }

  Future<void> connectSelectedDevice([ScanResult? device]) async {
    await connectAndPrepareBle(preferredDevice: device ?? state.selectedDevice);
  }

  Future<void> connectAndPrepareBle({ScanResult? preferredDevice}) async {
    if (!_canStartBlePreparation(requireSelectedDevice: false)) {
      return;
    }

    var target = preferredDevice ?? state.selectedDevice;
    if (target == null) {
      await scanBluetoothDevices();
      target = state.selectedDevice;
    }

    if (target == null) {
      _transition(
        stage: ProvisionBleStage.error,
        errorMessage: 'Chưa tìm thấy thiết bị khanhpi để kết nối.',
        technicalDetail: 'No selectedDevice after scan',
      );
      return;
    }

    await FlutterBluePlus.stopScan();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    for (var attempt = 0; attempt < _maxConnectAttempts; attempt++) {
      final backoffMs = math.pow(2, attempt).toInt() * 400;
      try {
        _transition(
          stage: ProvisionBleStage.connecting,
          infoMessage:
              'Đang kết nối BLE tới ${target.device.advName} (lần ${attempt + 1}/$_maxConnectAttempts)...',
          clearError: true,
        );
        LoggerUtils.i(
          'BLE connect attempt ${attempt + 1}/$_maxConnectAttempts: ${target.device.remoteId.str}',
        );

        await _repository.disconnect();

        final currentConnectionState =
            await target.device.connectionState.first;
        if (currentConnectionState != BluetoothConnectionState.disconnected) {
          await target.device.disconnect();
          await Future<void>.delayed(const Duration(milliseconds: 400));
        }

        await target.device.connect(
          autoConnect: false,
          timeout: _connectTimeout,
          mtu: null,
        );
        LoggerUtils.i('BLE connect success');

        await _repository.prepareConnectedDevice(
          target.device,
          onStepChanged: (step) {
            switch (step) {
              case BlePreparationStep.discoveringServices:
                _transition(
                  stage: ProvisionBleStage.discoveringServices,
                  infoMessage: 'Đã kết nối BLE. Đang dò BLE services...',
                  clearError: true,
                );
                LoggerUtils.i('BLE discovering services');
                break;
              case BlePreparationStep.subscribingStatus:
                _transition(
                  stage: ProvisionBleStage.subscribingStatus,
                  infoMessage: 'Đang subscribe status notify từ Pi...',
                  clearError: true,
                );
                LoggerUtils.i('BLE subscribing status characteristic');
                break;
            }
          },
        );

        if (!_mounted) return;

        _setState(
          state.copyWith(
            selectedDevice: target,
            bleStage: ProvisionBleStage.ready,
            wifiNetworks: const [],
            selectedWifiNetwork: null,
            wifiPassword: '',
            errorMessage: null,
            infoMessage:
                'BLE đã sẵn sàng. Bạn có thể bấm "Scan Wi-Fi" để lấy danh sách mạng.',
          ),
        );

        LoggerUtils.i('BLE ready');
        return;
      } catch (error, stackTrace) {
        LoggerUtils.e('BLE connectAndPrepare failed', error, stackTrace);
        await _repository.disconnect();

        if (attempt == _maxConnectAttempts - 1) {
          _transition(
            stage: ProvisionBleStage.error,
            errorMessage:
                'Không thể chuẩn bị BLE với khanhpi. Hãy thử lại hoặc khởi động lại Pi.',
            technicalDetail: error.toString(),
          );
          return;
        }

        await Future<void>.delayed(Duration(milliseconds: backoffMs));
      }
    }
  }

  Future<void> pingDevice() async {
    await _runBusinessCommand<PiResponse>(
      action: 'ping',
      waitingInfoMessage: 'Đang gửi ping tới Raspberry Pi...',
      command: _repository.ping,
      onSuccess: (_) {
        _transition(
          stage: ProvisionBleStage.ready,
          infoMessage: 'Pi phản hồi ping thành công.',
          clearError: true,
        );
      },
    );
  }

  Future<void> scanWifiNetworks() async {
    await _runBusinessCommand<List<PiWifiNetwork>>(
      action: 'scan_wifi',
      waitingInfoMessage: 'Pi đang quét danh sách Wi-Fi xung quanh...',
      command: _repository.scanWifi,
      onSuccess: (networks) {
        final selectedNetwork =
            _findCurrentSelectedNetwork(networks) ??
            (networks.isNotEmpty ? networks.first : null);

        _setState(
          state.copyWith(
            bleStage: ProvisionBleStage.ready,
            wifiNetworks: networks,
            selectedWifiNetwork: selectedNetwork,
            errorMessage: null,
            infoMessage: networks.isEmpty
                ? 'Pi không tìm thấy Wi-Fi nào trong vùng phủ.'
                : 'Đã lấy danh sách Wi-Fi. Chọn SSID và nhập mật khẩu để kết nối.',
          ),
        );
      },
    );
  }

  Future<void> refreshWifiStatus() async {
    await _runBusinessCommand<PiWifiStatus>(
      action: 'wifi_status',
      waitingInfoMessage: 'Đang lấy trạng thái Wi-Fi hiện tại từ Pi...',
      command: _repository.wifiStatus,
      onSuccess: (status) {
        _setState(
          state.copyWith(
            bleStage: ProvisionBleStage.ready,
            wifiStatus: status,
            errorMessage: null,
            infoMessage: 'Đã cập nhật trạng thái Wi-Fi từ Raspberry Pi.',
          ),
        );
      },
    );
  }

  void selectWifiNetwork(PiWifiNetwork network) {
    _setState(
      state.copyWith(
        selectedWifiNetwork: network,
        errorMessage: null,
        infoMessage: 'Đã chọn SSID ${network.ssid}.',
      ),
    );
  }

  void updateWifiPassword(String value) {
    _setState(state.copyWith(wifiPassword: value));
  }

  Future<void> connectWifi() async {
    final network = state.selectedWifiNetwork;

    if (!_ensureReadyForBusinessAction('connect_wifi')) {
      return;
    }

    if (network == null) {
      _transition(
        stage: ProvisionBleStage.error,
        errorMessage: 'Hãy chọn một SSID trước khi kết nối Wi-Fi.',
        technicalDetail: 'connectWifi called with null selectedWifiNetwork',
      );
      return;
    }

    if (network.requiresPassword && state.wifiPassword.trim().isEmpty) {
      _transition(
        stage: ProvisionBleStage.error,
        errorMessage: 'SSID này yêu cầu mật khẩu Wi-Fi.',
        technicalDetail: 'Password required but wifiPassword is empty',
      );
      return;
    }

    await _runBusinessCommand<PiWifiStatus>(
      action: 'connect_wifi',
      waitingInfoMessage: 'Pi đang kết nối tới Wi-Fi ${network.ssid}...',
      command: () => _repository.connectWifi(
        ssid: network.ssid,
        password: state.wifiPassword,
      ),
      onSuccess: (status) {
        _setState(
          state.copyWith(
            bleStage: ProvisionBleStage.ready,
            wifiStatus: status,
            errorMessage: null,
            infoMessage:
                'Đã cấu hình Wi-Fi thành công cho ${network.ssid}. IP: ${status.ip.isEmpty ? 'chưa có' : status.ip}',
          ),
        );
      },
    );
  }

  Future<void> disconnect() async {
    await _repository.disconnect();
    if (!_mounted) return;

    _setState(
      state.copyWith(
        bleStage: ProvisionBleStage.disconnected,
        wifiNetworks: const [],
        selectedWifiNetwork: null,
        wifiStatus: null,
        wifiPassword: '',
        infoMessage:
            'Đã ngắt kết nối BLE với Raspberry Pi. Bạn có thể bấm kết nối lại.',
        errorMessage: null,
      ),
    );
  }

  Future<void> _runBusinessCommand<T>({
    required String action,
    required String waitingInfoMessage,
    required Future<T> Function() command,
    required void Function(T result) onSuccess,
  }) async {
    if (!_ensureReadyForBusinessAction(action)) {
      return;
    }

    _transition(
      stage: ProvisionBleStage.sendingCommand,
      infoMessage: waitingInfoMessage,
      clearError: true,
      lastCommandAction: action,
    );

    try {
      _transition(
        stage: ProvisionBleStage.waitingResult,
        infoMessage: waitingInfoMessage,
        clearError: true,
        lastCommandAction: action,
      );
      final result = await command();
      if (!_mounted) return;
      onSuccess(result);
    } catch (error, stackTrace) {
      LoggerUtils.e('Business BLE command failed: $action', error, stackTrace);
      _transition(
        stage: ProvisionBleStage.error,
        errorMessage: _friendlyCommandError(action, error),
        technicalDetail: error.toString(),
        lastCommandAction: action,
      );
    }
  }

  bool _ensureReadyForBusinessAction(String action) {
    if (state.canIssueBusinessCommands) {
      return true;
    }

    _transition(
      stage: state.bleStage == ProvisionBleStage.disconnected
          ? ProvisionBleStage.disconnected
          : ProvisionBleStage.error,
      errorMessage:
          'BLE chưa sẵn sàng. Hãy kết nối BLE với khanhpi trước khi thao tác.',
      technicalDetail:
          'Blocked action=$action because bleStage=${state.bleStage.name}',
      lastCommandAction: action,
    );
    return false;
  }

  bool _canStartBlePreparation({required bool requireSelectedDevice}) {
    if (!state.permissionsGranted) {
      _transition(
        stage: ProvisionBleStage.error,
        errorMessage: 'Hãy cấp quyền Bluetooth trước khi tiếp tục.',
        technicalDetail: 'permissionsGranted=false',
      );
      return false;
    }

    if (!state.bluetoothEnabled) {
      _transition(
        stage: ProvisionBleStage.error,
        errorMessage: 'Hãy bật Bluetooth trước khi quét hoặc kết nối BLE.',
        technicalDetail: 'bluetoothEnabled=false',
      );
      return false;
    }

    if (state.isBusy) {
      return false;
    }

    if (requireSelectedDevice && state.selectedDevice == null) {
      _transition(
        stage: ProvisionBleStage.error,
        errorMessage: 'Hãy chọn thiết bị khanhpi trước khi kết nối.',
        technicalDetail: 'selectedDevice=null',
      );
      return false;
    }

    return true;
  }

  String _friendlyCommandError(String action, Object error) {
    switch (action) {
      case 'scan_wifi':
        return 'Quét Wi-Fi thất bại. Hãy kiểm tra BLE với Pi rồi thử lại.';
      case 'connect_wifi':
        return 'Kết nối Wi-Fi thất bại. Hãy kiểm tra SSID, mật khẩu và thử lại.';
      case 'wifi_status':
        return 'Không lấy được trạng thái Wi-Fi từ Pi.';
      case 'ping':
        return 'Pi chưa phản hồi ping. Hãy thử kết nối lại BLE.';
      default:
        return 'Thao tác BLE thất bại. Hãy thử lại.';
    }
  }

  PiWifiNetwork? _findCurrentSelectedNetwork(List<PiWifiNetwork> networks) {
    final current = state.selectedWifiNetwork;
    if (current == null) {
      return null;
    }

    for (final network in networks) {
      if (network.ssid == current.ssid) {
        return network;
      }
    }
    return null;
  }

  Future<bool> _safeBluetoothEnabled() async {
    try {
      return await _bluetoothService.isBluetoothEnabled();
    } catch (error, stackTrace) {
      LoggerUtils.e('Bluetooth enabled check failed', error, stackTrace);
      return false;
    }
  }

  void _handleRepositoryEvent(BleRepositoryEvent event) {
    switch (event.type) {
      case BleRepositoryEventType.disconnected:
        if (!_mounted) return;
        _setState(
          state.copyWith(
            bleStage: ProvisionBleStage.disconnected,
            wifiNetworks: const [],
            selectedWifiNetwork: null,
            wifiStatus: null,
            wifiPassword: '',
            infoMessage:
                event.message ??
                'Kết nối BLE đã bị ngắt. Bạn có thể bấm kết nối lại.',
            errorMessage: null,
          ),
        );
        break;
    }
  }

  void _handleAdapterState(BluetoothAdapterState adapterState) {
    LoggerUtils.i('BLE adapter state changed: ${adapterState.name}');
    final enabled = adapterState == BluetoothAdapterState.on;

    if (!_mounted) return;
    _setState(state.copyWith(bluetoothEnabled: enabled));

    if (!enabled && state.hasConnectedBleSession) {
      unawaited(_repository.disconnect());
      _setState(
        state.copyWith(
          bleStage: ProvisionBleStage.disconnected,
          wifiNetworks: const [],
          selectedWifiNetwork: null,
          wifiStatus: null,
          infoMessage:
              'Bluetooth đã bị tắt giữa chừng. Hãy bật lại rồi kết nối BLE lại.',
          errorMessage: null,
        ),
      );
    }
  }
}
