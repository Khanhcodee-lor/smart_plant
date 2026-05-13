import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/bluetooth/data/services/pi_ble_provisioning_client.dart';
import 'package:app_iot/src/features/bluetooth/domain/models/pi_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProvisioningScreen extends StatefulWidget {
  const ProvisioningScreen({super.key});

  @override
  State<ProvisioningScreen> createState() => _ProvisioningScreenState();
}

class _ProvisioningScreenState extends State<ProvisioningScreen> {
  final PiBleProvisioningClient _client = PiBleProvisioningClient();

  List<PiWifiNetwork> _wifiList = [];
  PiWifiNetwork? _selectedWifi;
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _client.addListener(_onClientStateChanged);
  }

  @override
  void dispose() {
    _client.removeListener(_onClientStateChanged);
    _client.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onClientStateChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _requestPermissionsAndScan() async {
    final granted = await _client.requestPermissions();
    if (!mounted) {
      return;
    }

    if (granted) {
      await _client.scanDevices();
      return;
    }

    _showSnackBar(
      'Cần cấp quyền Bluetooth và vị trí để tiếp tục.',
      backgroundColor: AppColors.warning,
    );
  }

  Future<void> _scanWifi() async {
    try {
      final networks = await _client.scanWifi(limit: 8);
      if (!mounted) {
        return;
      }

      setState(() => _wifiList = networks);
      _showSnackBar(
        'Đã tìm thấy ${_wifiList.length} mạng Wi-Fi.',
        backgroundColor: AppColors.accent,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Lỗi quét Wi-Fi: $e', backgroundColor: AppColors.error);
    }
  }

  Future<void> _connectWifi() async {
    final ssid = _ssidController.text.trim();
    final password = _passwordController.text.trim();

    if (ssid.isEmpty) {
      _showSnackBar(
        'Vui lòng nhập hoặc chọn tên Wi-Fi.',
        backgroundColor: AppColors.warning,
      );
      return;
    }

    try {
      final response = await _client.sendCommand(
        'connect_wifi',
        payload: {'ssid': ssid, 'password': password},
      );
      if (!mounted) {
        return;
      }

      if (response.ok) {
        final ip = response.status?.ip ?? 'Chưa có IP';
        _showSnackBar(
          'Kết nối Wi-Fi thành công. IP: $ip',
          backgroundColor: AppColors.success,
        );
      } else {
        _showSnackBar(
          'Pi báo lỗi: ${response.error}',
          backgroundColor: AppColors.error,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Lỗi kết nối Wi-Fi: $e', backgroundColor: AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Cấu hình Pi qua BLE',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
          ),
        ),
        leadingWidth: 64.w,
        leading: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black,
                size: 20.sp,
              ),
            ),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3FFFB), Color(0xFFF6FBF8), Color(0xFFFFFCF6)],
            stops: [0.0, 0.62, 1.0],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20.w,
            topPadding + kToolbarHeight + 8.h,
            20.w,
            28.h,
          ),
          children: [
            _buildStatusCard(),
            SizedBox(height: 20.h),
            if (_shouldShowScanSection) ...[
              _buildDeviceSection(),
              SizedBox(height: 20.h),
            ],
            if (_shouldShowProvisioningSection) ...[
              _buildWifiSection(),
              SizedBox(height: 20.h),
            ],
          ],
        ),
      ),
    );
  }

  bool get _shouldShowScanSection =>
      _client.state == PiBleState.idle ||
      _client.state == PiBleState.scanning ||
      _client.state == PiBleState.connecting ||
      _client.state == PiBleState.error;

  bool get _shouldShowProvisioningSection =>
      _client.state == PiBleState.subscribed ||
      _client.state == PiBleState.sending ||
      _client.state == PiBleState.success;

  Widget _buildStatusCard() {
    final presentation = _statusPresentation();
    final showProgress =
        _client.state == PiBleState.scanning ||
        _client.state == PiBleState.connecting ||
        _client.state == PiBleState.sending;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: _cardDecoration(
        backgroundColor: presentation.backgroundColor,
        borderColor: presentation.borderColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: presentation.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Icon(
                  presentation.icon,
                  color: presentation.color,
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trạng thái hiện tại',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      presentation.title,
                      style: TextStyle(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMain,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      presentation.subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _StatusBadge(
                color: presentation.color,
                label: presentation.badgeLabel,
              ),
              if (_client.connectedDevice != null)
                const _StatusBadge(
                  color: AppColors.success,
                  label: 'Đã ghép nối',
                ),
            ],
          ),
          if (showProgress) ...[
            SizedBox(height: 16.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(999.r),
              child: LinearProgressIndicator(
                minHeight: 7.h,
                valueColor: AlwaysStoppedAnimation<Color>(presentation.color),
                backgroundColor: presentation.color.withOpacity(0.12),
              ),
            ),
          ],
          if (_client.errorMessage != null) ...[
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.error.withOpacity(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 18.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      _client.errorMessage!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.45,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceSection() {
    final isScanning = _client.state == PiBleState.scanning;

    return _SectionCard(
      title: 'Thiết bị BLE',
      subtitle:
          'Quét các Raspberry Pi đang phát dịch vụ BLE và chọn thiết bị muốn cấu hình.',
      trailing: _buildActionButton(
        onPressed: isScanning ? null : _requestPermissionsAndScan,
        icon: Icons.bluetooth_searching_rounded,
        label: isScanning ? 'Đang quét...' : 'Quét thiết bị',
        isBusy: isScanning,
        isPrimary: true,
      ),
      child: Column(
        children: [
          SizedBox(height: 14.h),
          _buildStatRow(
            icon: Icons.devices_rounded,
            label: 'Thiết bị tìm thấy',
            value: '${_client.scanResults.length}',
          ),
          SizedBox(height: 14.h),
          if (_client.scanResults.isEmpty)
            _buildEmptyState(
              icon: Icons.bluetooth_disabled_rounded,
              title: isScanning ? 'Đang quét thiết bị' : 'Chưa có thiết bị BLE',
              description: isScanning
                  ? 'Giữ Raspberry Pi ở gần điện thoại và chờ danh sách cập nhật.'
                  : 'Bấm quét thiết bị để tìm Raspberry Pi hỗ trợ cấu hình qua BLE.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _client.scanResults.length,
              separatorBuilder: (context, index) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final result = _client.scanResults[index];
                final name = result.device.advName.isNotEmpty
                    ? result.device.advName
                    : (result.device.platformName.isNotEmpty
                          ? result.device.platformName
                          : result.device.remoteId.str);

                return Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46.w,
                        height: 46.w,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(
                          Icons.memory_rounded,
                          color: AppColors.accent,
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              result.device.remoteId.str,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10.w),
                      FilledButton.tonal(
                        onPressed: _client.state == PiBleState.connecting
                            ? null
                            : () => _client.connect(result.device),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent.withOpacity(0.12),
                          foregroundColor: AppColors.accent,
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 10.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(
                          'Kết nối',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWifiSection() {
    final isSending = _client.state == PiBleState.sending;

    return Column(
      children: [
        _SectionCard(
          title: 'Thiết bị đã kết nối',
          subtitle:
              'Raspberry Pi hiện sẵn sàng nhận cấu hình Wi-Fi từ điện thoại.',
          trailing: IconButton(
            onPressed: _client.disconnect,
            tooltip: 'Ngắt kết nối',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.error.withOpacity(0.10),
              foregroundColor: AppColors.error,
            ),
            icon: Icon(Icons.power_settings_new_rounded, size: 20.sp),
          ),
          child: Column(
            children: [
              SizedBox(height: 14.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FFFC),
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Icon(
                        Icons.developer_board_rounded,
                        color: AppColors.success,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mã thiết bị',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _client.connectedDevice?.remoteId.str ??
                                'Không xác định',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        _SectionCard(
          title: 'Mạng Wi-Fi',
          subtitle:
              'Quét các mạng khả dụng gần Raspberry Pi rồi chạm để điền nhanh SSID.',
          trailing: _buildActionButton(
            onPressed: isSending ? null : _scanWifi,
            icon: Icons.wifi_find_rounded,
            label: isSending ? 'Đang gửi...' : 'Quét mạng',
            isBusy: false,
            isPrimary: false,
          ),
          child: Column(
            children: [
              SizedBox(height: 14.h),
              _buildStatRow(
                icon: Icons.wifi_rounded,
                label: 'Mạng đã quét',
                value: '${_wifiList.length}',
              ),
              SizedBox(height: 14.h),
              if (_wifiList.isEmpty)
                _buildEmptyState(
                  icon: Icons.portable_wifi_off_rounded,
                  title: 'Chưa có danh sách Wi-Fi',
                  description:
                      'Bấm quét mạng để lấy các Wi-Fi mà Raspberry Pi đang nhìn thấy.',
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _wifiList.length,
                  separatorBuilder: (context, index) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final wifi = _wifiList[index];
                    final isSelected = _selectedWifi?.ssid == wifi.ssid;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18.r),
                        onTap: () {
                          setState(() {
                            _selectedWifi = wifi;
                            _ssidController.text = wifi.ssid;
                          });
                        },
                        child: Ink(
                          padding: EdgeInsets.all(14.r),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent.withOpacity(0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18.r),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent.withOpacity(0.28)
                                  : AppColors.border.withOpacity(0.70),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44.w,
                                height: 44.w,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.accent.withOpacity(0.14)
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                child: Icon(
                                  _wifiSignalIcon(wifi.signal),
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                                  size: 20.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      wifi.ssid,
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
                                      'Tín hiệu ${wifi.signal}% • ${wifi.security}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.accent,
                                  size: 20.sp,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        _SectionCard(
          title: 'Gửi cấu hình cho Pi',
          subtitle:
              'Nhập thủ công hoặc chọn một mạng ở trên, sau đó gửi cấu hình sang thiết bị.',
          child: Column(
            children: [
              SizedBox(height: 14.h),
              _buildInputField(
                controller: _ssidController,
                label: 'Tên Wi-Fi (SSID)',
                icon: Icons.wifi_rounded,
              ),
              SizedBox(height: 14.h),
              _buildInputField(
                controller: _passwordController,
                label: 'Mật khẩu Wi-Fi',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              _buildActionButton(
                onPressed: isSending ? null : _connectWifi,
                icon: Icons.cloud_done_rounded,
                label: isSending
                    ? 'Đang gửi cấu hình...'
                    : 'Kết nối và đồng bộ',
                isBusy: isSending,
                isPrimary: true,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    bool isBusy = false,
    bool fullWidth = false,
  }) {
    final indicatorColor = isPrimary ? Colors.white : AppColors.accent;
    final iconWidget = isBusy
        ? SizedBox(
            width: 18.w,
            height: 18.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: indicatorColor,
            ),
          )
        : Icon(icon, size: isPrimary ? 20.sp : 18.sp);

    final labelWidget = Text(
      label,
      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
    );

    final child = SizedBox(
      height: 50.h,
      width: fullWidth ? double.infinity : null,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: AppColors.disabled,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconWidget,
                  SizedBox(width: 10.w),
                  Flexible(child: labelWidget),
                ],
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent.withOpacity(0.30)),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconWidget,
                  SizedBox(width: 8.w),
                  Flexible(child: labelWidget),
                ],
              ),
            ),
    );

    if (fullWidth) {
      return child;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 130.w),
      child: child,
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FCFB),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withOpacity(0.60)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: AppColors.textSecondary),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 22.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFEFD),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border.withOpacity(0.65)),
      ),
      child: Column(
        children: [
          Container(
            width: 54.w,
            height: 54.w,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Icon(icon, color: AppColors.disabledText, size: 28.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(
        fontSize: 14.sp,
        color: AppColors.textMain,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, size: 20.sp, color: AppColors.textSecondary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.backgroundGreen,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({Color? backgroundColor, Color? borderColor}) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white.withOpacity(0.96),
      borderRadius: BorderRadius.circular(24.r),
      border: Border.all(
        color: borderColor ?? AppColors.card.withOpacity(0.88),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow.withOpacity(0.06),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  _StatusPresentation _statusPresentation() {
    switch (_client.state) {
      case PiBleState.success:
      case PiBleState.subscribed:
        return const _StatusPresentation(
          title: 'Đã kết nối',
          subtitle:
              'Raspberry Pi đã sẵn sàng. Bạn có thể quét Wi-Fi và gửi cấu hình.',
          badgeLabel: 'Sẵn sàng',
          icon: Icons.bluetooth_connected_rounded,
          color: AppColors.success,
          backgroundColor: Colors.white,
          borderColor: Color(0x332ECC71),
        );
      case PiBleState.scanning:
        return const _StatusPresentation(
          title: 'Đang quét thiết bị',
          subtitle: 'Ứng dụng đang tìm Raspberry Pi hỗ trợ BLE gần bạn.',
          badgeLabel: 'Đang quét',
          icon: Icons.bluetooth_searching_rounded,
          color: AppColors.info,
          backgroundColor: Colors.white,
          borderColor: Color(0x332980B9),
        );
      case PiBleState.connecting:
        return const _StatusPresentation(
          title: 'Đang kết nối',
          subtitle:
              'Giữ điện thoại và Raspberry Pi ở gần nhau trong lúc bắt tay BLE.',
          badgeLabel: 'Đang ghép nối',
          icon: Icons.settings_ethernet_rounded,
          color: AppColors.info,
          backgroundColor: Colors.white,
          borderColor: Color(0x332980B9),
        );
      case PiBleState.sending:
        return const _StatusPresentation(
          title: 'Đang đồng bộ',
          subtitle: 'Cấu hình Wi-Fi đang được gửi sang Raspberry Pi.',
          badgeLabel: 'Đang gửi',
          icon: Icons.sync_rounded,
          color: AppColors.accent,
          backgroundColor: Colors.white,
          borderColor: Color(0x3348C9B0),
        );
      case PiBleState.error:
        return const _StatusPresentation(
          title: 'Có lỗi kết nối',
          subtitle:
              'Kiểm tra Bluetooth, quyền truy cập và thử quét lại thiết bị.',
          badgeLabel: 'Cần kiểm tra',
          icon: Icons.error_outline_rounded,
          color: AppColors.error,
          backgroundColor: Colors.white,
          borderColor: Color(0x33E74C3C),
        );
      case PiBleState.idle:
        return const _StatusPresentation(
          title: 'Chưa kết nối',
          subtitle:
              'Bắt đầu bằng cách quét Raspberry Pi đang phát BLE ở gần bạn.',
          badgeLabel: 'Chờ thao tác',
          icon: Icons.bluetooth_disabled_rounded,
          color: AppColors.disabledText,
          backgroundColor: Colors.white,
          borderColor: Color(0x3395A5A6),
        );
    }
  }

  IconData _wifiSignalIcon(int signal) {
    if (signal < 30) {
      return Icons.network_wifi_1_bar_rounded;
    }
    if (signal < 60) {
      return Icons.network_wifi_2_bar_rounded;
    }
    if (signal < 80) {
      return Icons.network_wifi_3_bar_rounded;
    }
    return Icons.wifi_rounded;
  }

  void _showSnackBar(String message, {required Color backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.card.withOpacity(0.88)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.06),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMain,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[SizedBox(width: 12.w), trailing!],
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String title;
  final String subtitle;
  final String badgeLabel;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
}
