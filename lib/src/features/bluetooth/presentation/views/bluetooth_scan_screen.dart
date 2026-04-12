import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/views/base_view.dart';
import 'package:app_iot/src/features/bluetooth/domain/models/bt_classic_device.dart';
import 'package:app_iot/src/features/bluetooth/domain/models/pi_response.dart';
import 'package:app_iot/src/features/bluetooth/presentation/controllers/pi_provision_controller.dart';
import 'package:app_iot/src/features/bluetooth/presentation/controllers/pi_provision_state.dart';
import 'package:app_iot/src/features/bluetooth/presentation/widgets/radar_scan_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothScanScreen extends BaseView {
  const BluetoothScanScreen({super.key});

  @override
  Color? backgroundColor(BuildContext context) => Colors.white;

  @override
  bool extendBodyBehindAppBar() => true;

  @override
  EdgeInsetsGeometry padding(BuildContext context) => EdgeInsets.zero;

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textMain,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Cài đặt Wi-Fi cho thiết bị',
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
        ),
      ),
    );
  }

  @override
  Decoration? bodyDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        transform: const GradientRotation(0.24),
        stops: const [0.0, 0.72],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.accentSecond.withOpacity(0.10),
          AppColors.backgroundGreen.withOpacity(0.88),
        ],
      ),
    );
  }

  @override
  Widget buildBody(BuildContext context, WidgetRef ref) {
    return const _BluetoothProvisionBody();
  }
}

class _BluetoothProvisionBody extends ConsumerStatefulWidget {
  const _BluetoothProvisionBody();

  @override
  ConsumerState<_BluetoothProvisionBody> createState() =>
      _BluetoothProvisionBodyState();
}

class _BluetoothProvisionBodyState
    extends ConsumerState<_BluetoothProvisionBody>
    with WidgetsBindingObserver {
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future<void>.microtask(
      () => ref.read(piProvisionControllerProvider.notifier).initialize(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(piProvisionControllerProvider.notifier).syncSystemState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(piProvisionControllerProvider);
    final controller = ref.read(piProvisionControllerProvider.notifier);

    return RefreshIndicator(
      onRefresh: controller.syncSystemState,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 108.h, 16.w, 32.h),
        children: [
          _buildMessageBanner(state),
          SizedBox(height: 14.h),
          if (!state.isSupported) _buildUnsupportedCard(),
          if (state.isSupported) ...[
            _buildPermissionCard(state, controller),
            SizedBox(height: 14.h),
            _buildBluetoothPowerCard(state, controller),
            SizedBox(height: 14.h),
            _buildDeviceCard(state, controller),
            if (state.isBluetoothConnected) ...[
              SizedBox(height: 14.h),
              _buildPiActionsCard(state, controller),
              SizedBox(height: 14.h),
              _buildWifiNetworksCard(state, controller),
              SizedBox(height: 14.h),
              _buildWifiFormCard(state, controller),
              SizedBox(height: 14.h),
              _buildWifiStatusCard(state, controller),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBanner(PiProvisionState state) {
    final hasError =
        state.errorMessage != null && state.errorMessage!.trim().isNotEmpty;
    final message = hasError ? state.errorMessage! : state.infoMessage;

    if (message == null || message.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final color = hasError ? AppColors.error : AppColors.info;
    final background = hasError
        ? AppColors.error.withOpacity(0.10)
        : AppColors.info.withOpacity(0.10);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: color,
            size: 20.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.45,
                color: hasError ? AppColors.textMain : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'Thiết bị không hỗ trợ',
            Icons.phone_iphone_rounded,
          ),
          SizedBox(height: 12.h),
          Text(
            'Màn hình này dùng Bluetooth Classic RFCOMM nên chỉ hỗ trợ Android. Trên iOS, vui lòng hiển thị thông báo không hỗ trợ và cấu hình bằng điện thoại Android thật.',
            style: TextStyle(
              fontSize: 14.sp,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(
    PiProvisionState state,
    PiProvisionController controller,
  ) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            step: '1',
            title: 'Quyền truy cập',
            subtitle:
                'BLUETOOTH_SCAN, BLUETOOTH_CONNECT và ACCESS_FINE_LOCATION',
          ),
          SizedBox(height: 14.h),
          _buildStatusRow(
            label: 'Trạng thái',
            value: state.permissionsGranted
                ? 'Đã cấp đủ quyền'
                : state.permissionsPermanentlyDenied
                ? 'Bị chặn vĩnh viễn'
                : 'Chưa cấp đủ quyền',
            color: state.permissionsGranted
                ? AppColors.success
                : state.permissionsPermanentlyDenied
                ? AppColors.error
                : AppColors.warning,
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              FilledButton.icon(
                onPressed: state.isBusy ? null : controller.requestPermissions,
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Xin quyền'),
              ),
              if (state.permissionsPermanentlyDenied)
                OutlinedButton.icon(
                  onPressed: openAppSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Mở Settings'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothPowerCard(
    PiProvisionState state,
    PiProvisionController controller,
  ) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            step: '2',
            title: 'Bật Bluetooth',
            subtitle: 'Bật Bluetooth hệ thống trước khi quét Raspberry Pi',
          ),
          SizedBox(height: 14.h),
          _buildStatusRow(
            label: 'Bluetooth',
            value: state.bluetoothEnabled ? 'Đang bật' : 'Đang tắt',
            color: state.bluetoothEnabled
                ? AppColors.success
                : AppColors.warning,
          ),
          SizedBox(height: 16.h),
          FilledButton.icon(
            onPressed: state.permissionsGranted && !state.isBusy
                ? controller.enableBluetooth
                : null,
            icon: const Icon(Icons.bluetooth_searching_rounded),
            label: const Text('Bật Bluetooth'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(
    PiProvisionState state,
    PiProvisionController controller,
  ) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            step: '3-4',
            title: 'Tìm và kết nối Raspberry Pi',
            subtitle:
                'Ưu tiên thiết bị alias khanhpi và kết nối RFCOMM channel 4',
          ),
          SizedBox(height: 16.h),
          if (state.status == ProvisionFlowStatus.scanningBt) ...[
            const Center(child: RadarScanIndicator()),
            SizedBox(height: 14.h),
            Center(
              child: Text(
                'Đang quét Bluetooth Classic...',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            SizedBox(height: 18.h),
          ],
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              FilledButton.icon(
                onPressed:
                    state.permissionsGranted &&
                        state.bluetoothEnabled &&
                        !state.isBusy
                    ? controller.scanBluetoothDevices
                    : null,
                icon: const Icon(Icons.radar_outlined),
                label: const Text('Quét thiết bị'),
              ),
              OutlinedButton.icon(
                onPressed: state.selectedDevice != null && !state.isBusy
                    ? () => controller.connectSelectedDevice()
                    : null,
                icon: const Icon(Icons.bluetooth_connected_rounded),
                label: const Text('Kết nối RFCOMM'),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          if (state.devices.isEmpty &&
              state.status != ProvisionFlowStatus.scanningBt)
            Text(
              'Chưa có thiết bị nào. Sau khi bật Bluetooth, bấm "Quét thiết bị" để tìm Pi.',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
            ),
          if (state.devices.isNotEmpty)
            Column(
              children: state.devices
                  .map(
                    (device) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: _buildDeviceTile(state, controller, device),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(
    PiProvisionState state,
    PiProvisionController controller,
    BtClassicDevice device,
  ) {
    final selected = state.selectedDevice?.address == device.address;
    final preferred = device.matchesAlias('khanhpi');

    return InkWell(
      onTap: state.isBusy ? null : () => controller.selectDevice(device),
      borderRadius: BorderRadius.circular(16.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withOpacity(0.10)
              : const Color(0xFFF8FBFC),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? AppColors.accent : const Color(0xFFE8EEF1),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent.withOpacity(0.16)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                preferred ? Icons.memory_rounded : Icons.bluetooth_rounded,
                color: preferred ? AppColors.primary : AppColors.textMain,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          device.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      if (preferred)
                        _buildMiniBadge('Ưu tiên', AppColors.success),
                      if (device.isBonded) ...[
                        SizedBox(width: 6.w),
                        _buildMiniBadge('Paired', AppColors.info),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    device.address,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.accent : AppColors.disabledText,
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPiActionsCard(
    PiProvisionState state,
    PiProvisionController controller,
  ) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            step: '5-6',
            title: 'Làm việc với Pi',
            subtitle: 'Ping, quét Wi-Fi và kiểm tra trạng thái mạng hiện tại',
          ),
          SizedBox(height: 14.h),
          _buildStatusRow(
            label: 'RFCOMM',
            value: state.isBluetoothConnected
                ? 'Đã kết nối tới ${state.selectedDevice?.displayName ?? 'Pi'}'
                : 'Chưa kết nối',
            color: state.isBluetoothConnected
                ? AppColors.success
                : AppColors.warning,
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              FilledButton.icon(
                onPressed: state.isBusy ? null : controller.pingDevice,
                icon: const Icon(Icons.wifi_tethering_rounded),
                label: const Text('Ping'),
              ),
              OutlinedButton.icon(
                onPressed: state.isBusy ? null : controller.scanWifiNetworks,
                icon: const Icon(Icons.wifi_find_rounded),
                label: const Text('Scan Wi-Fi'),
              ),
              OutlinedButton.icon(
                onPressed: state.isBusy ? null : controller.refreshWifiStatus,
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Wi-Fi status'),
              ),
              TextButton.icon(
                onPressed: state.isBusy ? null : controller.disconnect,
                icon: const Icon(Icons.link_off_rounded),
                label: const Text('Ngắt kết nối'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWifiNetworksCard(
    PiProvisionState state,
    PiProvisionController controller,
  ) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            step: '6-7',
            title: 'Danh sách Wi-Fi',
            subtitle: 'Chọn SSID cần cấp cho Raspberry Pi',
          ),
          SizedBox(height: 14.h),
          if (state.wifiNetworks.isEmpty)
            Text(
              'Chưa có danh sách Wi-Fi. Bấm "Scan Wi-Fi" để Pi quét các mạng khả dụng.',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
            ),
          if (state.wifiNetworks.isNotEmpty)
            Column(
              children: state.wifiNetworks
                  .map(
                    (network) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: _buildWifiTile(state, controller, network),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  Widget _buildWifiTile(
    PiProvisionState state,
    PiProvisionController controller,
    PiWifiNetwork network,
  ) {
    final selected = state.selectedWifiNetwork?.ssid == network.ssid;

    return InkWell(
      onTap: state.isBusy ? null : () => controller.selectWifiNetwork(network),
      borderRadius: BorderRadius.circular(16.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.08)
              : const Color(0xFFF8FBFC),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE8EEF1),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _signalIcon(network.signal),
              color: AppColors.textMain,
              size: 22.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    network.ssid,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Signal ${network.signal}%  •  ${network.security}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              network.requiresPassword
                  ? Icons.lock_outline_rounded
                  : Icons.lock_open_rounded,
              color: AppColors.textSecondary,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiFormCard(
    PiProvisionState state,
    PiProvisionController controller,
  ) {
    final network = state.selectedWifiNetwork;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            step: '7',
            title: 'Kết nối Wi-Fi',
            subtitle: 'Nhập mật khẩu và gửi lệnh connect_wifi cho Raspberry Pi',
          ),
          SizedBox(height: 14.h),
          _buildStatusRow(
            label: 'SSID đã chọn',
            value: network?.ssid ?? 'Chưa chọn',
            color: network != null ? AppColors.success : AppColors.warning,
          ),
          SizedBox(height: 16.h),
          TextField(
            enabled: network != null && !state.isBusy,
            obscureText: _obscurePassword,
            onChanged: controller.updateWifiPassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu Wi-Fi',
              hintText: network == null
                  ? 'Chọn SSID trước'
                  : network.requiresPassword
                  ? 'Nhập mật khẩu'
                  : 'Mạng mở, có thể để trống',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          FilledButton.icon(
            onPressed: network != null && !state.isBusy
                ? controller.connectWifi
                : null,
            icon: const Icon(Icons.router_rounded),
            label: const Text('Connect Wi-Fi'),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiStatusCard(
    PiProvisionState state,
    PiProvisionController controller,
  ) {
    final status = state.wifiStatus;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            step: '8',
            title: 'Trạng thái mạng',
            subtitle: 'Hiển thị interface, state, connection và IP từ Pi',
          ),
          SizedBox(height: 14.h),
          if (status == null)
            Text(
              'Chưa có trạng thái Wi-Fi. Sau khi kết nối Bluetooth hoặc kết nối Wi-Fi thành công, bấm "Wi-Fi status" để làm mới.',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
            ),
          if (status != null) ...[
            _buildStatusRow(
              label: 'Interface',
              value: status.interfaceName.isEmpty
                  ? 'wlan0?'
                  : status.interfaceName,
              color: AppColors.info,
            ),
            SizedBox(height: 10.h),
            _buildStatusRow(
              label: 'State',
              value: status.state,
              color: status.isConnected ? AppColors.success : AppColors.warning,
            ),
            SizedBox(height: 10.h),
            _buildStatusRow(
              label: 'Connection',
              value: status.connection.isEmpty ? 'Chưa có' : status.connection,
              color: AppColors.textMain,
            ),
            SizedBox(height: 10.h),
            _buildStatusRow(
              label: 'IP',
              value: status.ip.isEmpty ? 'Chưa có IP' : status.ip,
              color: status.ip.isEmpty ? AppColors.warning : AppColors.success,
            ),
            SizedBox(height: 16.h),
            OutlinedButton.icon(
              onPressed: state.isBusy ? null : controller.refreshWifiStatus,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Làm mới trạng thái'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMain, size: 22.sp),
        SizedBox(width: 10.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
      ],
    );
  }

  Widget _buildStepHeader({
    required String step,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34.w,
          height: 34.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.16),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            step,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFC),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE8EEF1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  IconData _signalIcon(int signal) {
    if (signal >= 75) {
      return Icons.wifi_rounded;
    }
    if (signal >= 45) {
      return Icons.network_wifi_3_bar_rounded;
    }
    if (signal >= 20) {
      return Icons.network_wifi_2_bar_rounded;
    }
    return Icons.network_wifi_1_bar_rounded;
  }
}
