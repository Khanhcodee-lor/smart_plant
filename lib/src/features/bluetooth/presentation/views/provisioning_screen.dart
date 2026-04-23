import 'package:flutter/material.dart';
import 'package:app_iot/src/features/bluetooth/domain/models/pi_response.dart';
import 'package:app_iot/src/features/bluetooth/data/services/pi_ble_provisioning_client.dart';

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
    setState(() {});
  }

  Future<void> _requestPermissionsAndScan() async {
    final granted = await _client.requestPermissions();
    if (!mounted) return;
    if (granted) {
      await _client.scanDevices();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cần cấp quyền BLE và Vị trí để tiếp tục.'),
        ),
      );
    }
  }

  Future<void> _scanWifi() async {
    try {
      final networks = await _client.scanWifi(limit: 8);
      if (!mounted) return;
      setState(() => _wifiList = networks);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tìm thấy ${_wifiList.length} mạng Wi-Fi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi quét Wi-Fi: $e')));
    }
  }

  Future<void> _connectWifi() async {
    final ssid = _ssidController.text.trim();
    final password = _passwordController.text.trim();

    if (ssid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập hoặc chọn SSID')),
      );
      return;
    }

    try {
      final response = await _client.sendCommand(
        'connect_wifi',
        payload: {'ssid': ssid, 'password': password},
      );
      if (!mounted) return;
      if (response.ok) {
        final ip = response.status?.ip ?? 'Chưa có IP';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kết nối Wi-Fi thành công! IP: $ip'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pi báo lỗi: ${response.error}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối Wi-Fi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Premium light background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: const Text(
          'Cấu hình Pi qua BLE',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusHeader(),
              const SizedBox(height: 24),
              if (_client.state == PiBleState.idle ||
                  _client.state == PiBleState.scanning ||
                  _client.state == PiBleState.connecting ||
                  _client.state == PiBleState.error)
                _buildScanSection(),
              if (_client.state == PiBleState.subscribed ||
                  _client.state == PiBleState.sending ||
                  _client.state == PiBleState.success)
                _buildProvisioningSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.bluetooth_disabled;
    String statusText = 'CHƯA KẾT NỐI';

    switch (_client.state) {
      case PiBleState.success:
      case PiBleState.subscribed:
        statusColor = Colors.green;
        statusIcon = Icons.bluetooth_connected;
        statusText = 'ĐÃ KẾT NỐI';
        break;
      case PiBleState.scanning:
      case PiBleState.connecting:
      case PiBleState.sending:
        statusColor = Colors.blue;
        statusIcon = Icons.bluetooth_searching;
        statusText = 'ĐANG XỬ LÝ...';
        break;
      case PiBleState.error:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        statusText = 'LỖI';
        break;
      default:
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.15),
                child: Icon(statusIcon, color: statusColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trạng thái của kết nối',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_client.errorMessage != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _client.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _client.state == PiBleState.scanning
              ? null
              : _requestPermissionsAndScan,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _client.state == PiBleState.scanning
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'QUÉT TÌM RASPBERRY PI',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
        const SizedBox(height: 24),
        if (_client.scanResults.isNotEmpty) ...[
          Text(
            'THIẾT BỊ TÌM THẤY',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _client.scanResults.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final r = _client.scanResults[index];
              final name = r.device.advName.isNotEmpty
                  ? r.device.advName
                  : (r.device.platformName.isNotEmpty
                        ? r.device.platformName
                        : r.device.remoteId.str);
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.bluetooth, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    r.device.remoteId.str,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: _client.state == PiBleState.connecting
                        ? null
                        : () => _client.connect(r.device),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Kết nối'),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildProvisioningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Device info card
        Container(
          padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.green.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.developer_board, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đang truy cập thiết bị',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      _client.connectedDevice?.remoteId.str ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _client.disconnect,
                icon: const Icon(Icons.power_settings_new),
                color: Colors.redAccent,
                tooltip: 'Ngắt kết nối',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Wi-Fi Scan Section
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: ElevatedButton.icon(
                  onPressed: _client.state == PiBleState.sending
                      ? null
                      : _scanWifi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.wifi_find, size: 22),
                  label: const Text(
                    'TÌM MẠNG WI-FI',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              if (_wifiList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  child: Text(
                    'Chưa có danh sách mạng Wi-Fi.\nHãy bấm nút tìm kiếm bên trên.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              if (_wifiList.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _wifiList.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final w = _wifiList[index];
                      // Select icon based on signal strength
                      IconData wifiIcon = Icons.wifi;
                      if (w.signal < 30)
                        wifiIcon = Icons.network_wifi_1_bar;
                      else if (w.signal < 60)
                        wifiIcon = Icons.network_wifi_2_bar;
                      else if (w.signal < 80)
                        wifiIcon = Icons.network_wifi_3_bar;

                      final isSelected = _selectedWifi?.ssid == w.ssid;

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        selected: isSelected,
                        selectedTileColor: Colors.teal.shade50,
                        leading: Icon(
                          wifiIcon,
                          color: isSelected ? Colors.teal : Colors.grey[400],
                        ),
                        title: Text(
                          w.ssid,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Tín hiệu: ${w.signal}% • Bảo mật: ${w.security}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.teal,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedWifi = w;
                            _ssidController.text = w.ssid;
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Connect Wi-Fi Form
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.settings_input_antenna,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Gửi cấu hình cho Pi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _ssidController,
                decoration: InputDecoration(
                  labelText: 'Tên Wi-Fi (SSID)',
                  prefixIcon: const Icon(Icons.wifi),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu Wi-Fi',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _client.state == PiBleState.sending
                    ? null
                    : _connectWifi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _client.state == PiBleState.sending
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'KẾT NỐI VÀ ĐỒNG BỘ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
