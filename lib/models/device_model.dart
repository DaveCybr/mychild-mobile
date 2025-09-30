class DeviceModel {
  final int? id;
  final int parentId;
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final bool isOnline;
  final DateTime? lastSeen;

  DeviceModel({
    this.id,
    required this.parentId,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    this.isOnline = false,
    this.lastSeen,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'],
      parentId: json['parent_id'],
      deviceId: json['device_id'],
      deviceName: json['device_name'],
      deviceType: json['device_type'],
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parent_id': parentId,
      'device_id': deviceId,
      'device_name': deviceName,
      'device_type': deviceType,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
    };
  }
}
