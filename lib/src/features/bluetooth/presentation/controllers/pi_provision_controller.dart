import 'package:app_iot/src/features/bluetooth/data/repositories/pi_provision_repository.dart';
import 'package:app_iot/src/features/bluetooth/data/services/bluetooth_service.dart';
import 'package:app_iot/src/features/bluetooth/domain/models/bt_classic_device.dart';
import 'package:app_iot/src/features/bluetooth/domain/models/pi_response.dart';
import 'package:app_iot/src/features/bluetooth/presentation/controllers/pi_provision_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final piProvisionControllerProvider =
    StateNotifierProvider.autoDispose<PiProvisionController, PiProvisionState>((
      ref,
    ) {
      final bluetoothService = ref.watch(bluetoothServiceProvider);
      final repository = ref.watch(piProvisionRepositoryProvider);
      return PiProvisionController(
        bluetoothService: bluetoothService,
        repository: repository,
      );
    });

class PiProvisionController extends StateNotifier<PiProvisionState> {
  PiProvisionController({
    required BluetoothService bluetoothService,
    required PiProvisionRepository repository,
  }) : _bluetoothService = bluetoothService,
       _repository = repository,
       super(const PiProvisionState());

  final BluetoothService _bluetoothService;
  final PiProvisionRepository _repository;

  Future<void> initialize() async {
    if (!state.isSupported && state.isInitialized) {
      return;
    }

    if (!_bluetoothService.isAndroidSupported) {
      state = state.copyWith(
        isSupported: false,
        isInitialized: true,
        status: ProvisionFlowStatus.idle,
        infoMessage: 'RFCOMM Bluetooth Classic chỉ hỗ trợ Android.',
        errorMessage: null,
      );
      return;
    }

    await syncSystemState();

    if (!mounted) {
      return;
    }

    state = state.copyWith(
      infoMessage: state.permissionsGranted
          ? state.bluetoothEnabled
                ? 'Sẵn sàng quét thiết bị khanhpi qua Bluetooth Classic.'
                : 'Bluetooth đang tắt. Bật Bluetooth để tiếp tục.'
          : 'Cấp quyền Bluetooth và vị trí để bắt đầu cấu hình.',
      errorMessage: null,
    );
  }

  Future<void> syncSystemState() async {
    if (!_bluetoothService.isAndroidSupported) {
      return;
    }

    final permissions = await _bluetoothService.getPermissionSnapshot();
    final enabled = permissions.isGranted
        ? await _safeBluetoothEnabled()
        : false;

    if (!mounted) {
      return;
    }

    state = state.copyWith(
      isSupported: true,
      isInitialized: true,
      permissionsGranted: permissions.isGranted,
      permissionsPermanentlyDenied: permissions.isPermanentlyDenied,
      bluetoothEnabled: enabled,
    );
  }

  Future<void> requestPermissions() async {
    if (!_bluetoothService.isAndroidSupported) {
      await initialize();
      return;
    }

    final permissions = await _bluetoothService.requestPermissions();
    final enabled = permissions.isGranted
        ? await _safeBluetoothEnabled()
        : false;

    if (!mounted) {
      return;
    }

    state = state.copyWith(
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
                : 'Quyền đã sẵn sàng. Bật Bluetooth để quét thiết bị.'
          : state.infoMessage,
    );
  }

  Future<void> enableBluetooth() async {
    if (!state.permissionsGranted) {
      state = state.copyWith(
        status: ProvisionFlowStatus.error,
        errorMessage: 'Hãy cấp quyền Bluetooth trước khi bật Bluetooth.',
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

      if (!mounted) {
        return;
      }

      if (!enabled) {
        state = state.copyWith(
          status: ProvisionFlowStatus.error,
          bluetoothEnabled: false,
          errorMessage:
              'Bluetooth vẫn đang tắt. Hãy bật từ hộp thoại hệ thống rồi thử lại.',
        );
        return;
      }

      state = state.copyWith(
        bluetoothEnabled: true,
        status: ProvisionFlowStatus.idle,
        errorMessage: null,
        infoMessage: 'Bluetooth đã bật. Bạn có thể quét thiết bị khanhpi.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        status: ProvisionFlowStatus.error,
        errorMessage: 'Không thể bật Bluetooth: $error',
      );
    }
  }

  Future<void> scanBluetoothDevices() async {
    if (!state.permissionsGranted) {
      state = state.copyWith(
        status: ProvisionFlowStatus.error,
        errorMessage: 'Hãy cấp quyền Bluetooth trước khi quét thiết bị.',
      );
      return;
    }

    if (!state.bluetoothEnabled) {
      state = state.copyWith(
        status: ProvisionFlowStatus.error,
        errorMessage: 'Hãy bật Bluetooth trước khi quét thiết bị.',
      );
      return;
    }

    state = state.copyWith(
      status: ProvisionFlowStatus.scanningBt,
      errorMessage: null,
      infoMessage: 'Đang tìm Raspberry Pi khanhpi gần bạn...',
    );

    try {
      final devices = await _bluetoothService.scanDevices();
      final selectedDevice =
          _findPreferredDevice(devices) ??
          state.selectedDevice ??
          (devices.isNotEmpty ? devices.first : null);

      if (!mounted) {
        return;
      }

      state = state.copyWith(
        status: ProvisionFlowStatus.idle,
        devices: devices,
        selectedDevice: selectedDevice,
        infoMessage: devices.isEmpty
            ? 'Không tìm thấy thiết bị Bluetooth Classic nào. Hãy đưa Pi lại gần và quét lại.'
            : selectedDevice != null && selectedDevice.matchesAlias('khanhpi')
            ? 'Đã ưu tiên thiết bị khanhpi. Bấm kết nối RFCOMM để tiếp tục.'
            : 'Đã quét xong. Chọn thiết bị rồi kết nối RFCOMM.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        status: ProvisionFlowStatus.error,
        errorMessage: 'Quét Bluetooth thất bại: $error',
      );
    }
  }

  void selectDevice(BtClassicDevice device) {
    state = state.copyWith(selectedDevice: device, errorMessage: null);
  }

  Future<void> connectSelectedDevice([BtClassicDevice? device]) async {
    final target =
        device ?? state.selectedDevice ?? _findPreferredDevice(state.devices);

    if (target == null) {
      state = state.copyWith(
        status: ProvisionFlowStatus.error,
        errorMessage: 'Chưa có thiết bị nào được chọn để kết nối.',
      );
      return;
    }

    state = state.copyWith(
      status: ProvisionFlowStatus.connectingBt,
      selectedDevice: target,
      errorMessage: null,
      infoMessage:
          'Đang kết nối RFCOMM tới ${target.displayName}. Hệ thống sẽ tự retry tối đa 2 lần.',
    );

    try {
      await _repository.connectToDevice(target);

      PiWifiStatus? wifiStatus;
      try {
        wifiStatus = await _repository.wifiStatus();
      } catch (_) {
        wifiStatus = null;
      }

      if (!mounted) {
        return;
      }

      state = state.copyWith(
        status: ProvisionFlowStatus.connectedBt,
        isBluetoothConnected: true,
        selectedDevice: target,
        wifiStatus: wifiStatus,
        errorMessage: null,
        infoMessage: 'Đã kết nối RFCOMM tới ${target.displayName}.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        status: ProvisionFlowStatus.error,
        isBluetoothConnected: false,
        errorMessage: 'Kết nối Bluetooth thất bại: $error',
      );
    }
  }

  Future<void> pingDevice() async {
    if (!state.isBluetoothConnected) {
      state = state.copyWith(
        status: ProvisionFlowStatus.error,
        errorMessage: 'Thiết bị chưa kết nối Bluetooth.',
      );
      return;
    }

    try {
      await _repository.ping();

      if (!mounted) {
        return;
      }

      state = state.copyWith(
        status: ProvisionFlowStatus.connectedBt,
        errorMessage: null,
        infoMessage: 'Pi phản hồi lệnh ping thành công.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        status: ProvisionFlowStatus.error,
        errorMessage: 'Ping thất bại: $error',
      );
    }
  }

  Future<void> scanWifiNetworks() async {
    if (!state.isBluetoothConnected) {
      state = state.copyWith(
        status: ProvisionFlowStatus.error,
        errorMessage: 'Thiết bị chưa kết nối Bluetooth.',
      );
      return;
    }

    state = state.copyWith(
      status: ProvisionFlowStatus.scanningWifi,
      errorMessage: null,
      infoMessage: 'Pi đang quét danh sách Wi-Fi xung quanh...',
    );

    try {
      final networks = await _repository.scanWifi();
      final selectedNetwork =
          _findCurrentSelectedNetwork(networks) ??
          (networks.isNotEmpty ? networks.first : null);

      if (!mounted) {
        return;
      }

      state = state.copyWith(
        status: ProvisionFlowStatus.connectedBt,
        wifiNetworks: networks,
        selectedWifiNetwork: selectedNetwork,
        infoMessage: networks.isEmpty
            ? 'Pi không tìm thấy Wi-Fi nào trong vùng phủ.'
            : 'Đã lấy danh sách Wi-Fi. Chọn SSID và nhập mật khẩu để kết nối.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        status: ProvisionFlowStatus.error,
        errorMessage: 'Quét Wi-Fi thất bại: $error',
      );
    }
  }

  void selectWifiNetwork(PiWifiNetwork network) {
    state = state.copyWith(
      selectedWifiNetwork: network,
      errorMessage: null,
      infoMessage: 'Đã chọn SSID ${network.ssid}.',
    );
  }

  void updateWifiPassword(String value) {
    state = state.copyWith(wifiPassword: value);
  }

  Future<void> connectWifi() async {
    final network = state.selectedWifiNetwork;

    if (!state.isBluetoothConnected) {
      state = state.copyWith(
        status: ProvisionFlowStatus.error,
        errorMessage: 'Thiết bị chưa kết nối Bluetooth.',
      );
      return;
    }

    if (network == null) {
      state = state.copyWith(
        status: ProvisionFlowStatus.error,
        errorMessage: 'Hãy chọn một SSID trước khi kết nối Wi-Fi.',
      );
      return;
    }

    if (network.requiresPassword && state.wifiPassword.trim().isEmpty) {
      state = state.copyWith(
        status: ProvisionFlowStatus.error,
        errorMessage: 'SSID này yêu cầu mật khẩu Wi-Fi.',
      );
      return;
    }

    state = state.copyWith(
      status: ProvisionFlowStatus.connectingWifi,
      errorMessage: null,
      infoMessage: 'Pi đang kết nối tới Wi-Fi ${network.ssid}...',
    );

    try {
      final status = await _repository.connectWifi(
        ssid: network.ssid,
        password: state.wifiPassword,
      );

      if (!mounted) {
        return;
      }

      state = state.copyWith(
        status: ProvisionFlowStatus.success,
        wifiStatus: status,
        errorMessage: null,
        infoMessage:
            'Đã cấu hình Wi-Fi thành công cho ${network.ssid}. IP: ${status.ip.isEmpty ? 'chưa có' : status.ip}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        status: ProvisionFlowStatus.error,
        errorMessage: 'Kết nối Wi-Fi thất bại: $error',
      );
    }
  }

  Future<void> refreshWifiStatus() async {
    if (!state.isBluetoothConnected) {
      return;
    }

    try {
      final status = await _repository.wifiStatus();

      if (!mounted) {
        return;
      }

      state = state.copyWith(
        status: status.isConnected
            ? ProvisionFlowStatus.success
            : ProvisionFlowStatus.connectedBt,
        wifiStatus: status,
        errorMessage: null,
        infoMessage: 'Đã cập nhật trạng thái Wi-Fi từ Raspberry Pi.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        status: ProvisionFlowStatus.error,
        errorMessage: 'Không lấy được trạng thái Wi-Fi: $error',
      );
    }
  }

  Future<void> disconnect() async {
    await _repository.disconnect();

    if (!mounted) {
      return;
    }

    state = state.copyWith(
      status: ProvisionFlowStatus.idle,
      isBluetoothConnected: false,
      wifiNetworks: const [],
      selectedWifiNetwork: null,
      wifiStatus: null,
      infoMessage: 'Đã ngắt kết nối Bluetooth với Raspberry Pi.',
      errorMessage: null,
    );
  }

  BtClassicDevice? _findPreferredDevice(List<BtClassicDevice> devices) {
    for (final device in devices) {
      if (device.matchesAlias('khanhpi')) {
        return device;
      }
    }
    return null;
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
    } catch (_) {
      return false;
    }
  }
}
