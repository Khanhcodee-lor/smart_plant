import 'dart:convert';

abstract class PiRequest {
  const PiRequest();

  String get action;

  Map<String, dynamic> toJson();

  String toLine() => '${jsonEncode(toJson())}\n';

  factory PiRequest.ping() = PingPiRequest;
  factory PiRequest.scanWifi() = ScanWifiPiRequest;
  factory PiRequest.wifiStatus() = WifiStatusPiRequest;
  factory PiRequest.connectWifi({
    required String ssid,
    required String password,
  }) = ConnectWifiPiRequest;
}

class PingPiRequest extends PiRequest {
  const PingPiRequest();

  @override
  String get action => 'ping';

  @override
  Map<String, dynamic> toJson() => {'action': action};
}

class ScanWifiPiRequest extends PiRequest {
  const ScanWifiPiRequest();

  @override
  String get action => 'scan_wifi';

  @override
  Map<String, dynamic> toJson() => {'action': action};
}

class WifiStatusPiRequest extends PiRequest {
  const WifiStatusPiRequest();

  @override
  String get action => 'wifi_status';

  @override
  Map<String, dynamic> toJson() => {'action': action};
}

class ConnectWifiPiRequest extends PiRequest {
  const ConnectWifiPiRequest({required this.ssid, required this.password});

  final String ssid;
  final String password;

  @override
  String get action => 'connect_wifi';

  @override
  Map<String, dynamic> toJson() => {
    'action': action,
    'ssid': ssid,
    'password': password,
  };
}
