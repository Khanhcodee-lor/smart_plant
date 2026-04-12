class BtClassicDevice {
  const BtClassicDevice({
    required this.address,
    required this.name,
    this.isBonded = false,
  });

  final String address;
  final String? name;
  final bool isBonded;

  String get displayName {
    final value = name?.trim();
    if (value == null || value.isEmpty) {
      return 'Thiết bị chưa đặt tên';
    }
    return value;
  }

  String get normalizedName => (name ?? '').trim().toLowerCase();

  bool matchesAlias(String alias) =>
      normalizedName == alias.trim().toLowerCase();

  factory BtClassicDevice.fromPluginMap(
    Map<dynamic, dynamic> map, {
    bool isBonded = false,
  }) {
    return BtClassicDevice(
      address: (map['address'] ?? '').toString(),
      name: map['name']?.toString(),
      isBonded: isBonded,
    );
  }
}
