class PiWifiNetwork {
  const PiWifiNetwork({
    required this.ssid,
    required this.signal,
    required this.security,
  });

  final String ssid;
  final int signal;
  final String security;

  bool get requiresPassword {
    final normalized = security.trim().toLowerCase();
    return normalized.isNotEmpty &&
        normalized != 'open' &&
        normalized != 'none';
  }

  factory PiWifiNetwork.fromJson(Map<String, dynamic> json) {
    return PiWifiNetwork(
      ssid: json['ssid']?.toString() ?? '',
      signal: _toInt(json['signal']),
      security: json['security']?.toString() ?? '',
    );
  }
}

class PiWifiStatus {
  const PiWifiStatus({
    required this.interfaceName,
    required this.state,
    required this.connection,
    required this.ip,
  });

  final String interfaceName;
  final String state;
  final String connection;
  final String ip;

  bool get isConnected => state.trim().toLowerCase() == 'connected';

  factory PiWifiStatus.fromJson(Map<String, dynamic> json) {
    return PiWifiStatus(
      interfaceName: json['interface']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      connection: json['connection']?.toString() ?? '',
      ip: json['ip']?.toString() ?? '',
    );
  }
}

class PiResponse {
  const PiResponse({
    required this.ok,
    required this.action,
    required this.networks,
    required this.raw,
    this.error,
    this.status,
    this.ssid,
  });

  final bool ok;
  final String action;
  final String? error;
  final String? ssid;
  final PiWifiStatus? status;
  final List<PiWifiNetwork> networks;
  final Map<String, dynamic> raw;

  factory PiResponse.fromJson(Map<String, dynamic> json) {
    final networksJson = json['networks'];
    final statusJson = json['status'];

    return PiResponse(
      ok: json['ok'] == true,
      action: json['action']?.toString() ?? '',
      error: json['error']?.toString(),
      ssid: json['ssid']?.toString(),
      status: statusJson is Map<String, dynamic>
          ? PiWifiStatus.fromJson(statusJson)
          : statusJson is Map
          ? PiWifiStatus.fromJson(Map<String, dynamic>.from(statusJson))
          : null,
      networks: networksJson is List
          ? networksJson
                .whereType<Map>()
                .map(
                  (item) =>
                      PiWifiNetwork.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : const [],
      raw: Map<String, dynamic>.from(json),
    );
  }
}

int _toInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
