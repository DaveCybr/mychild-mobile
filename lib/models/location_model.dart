// models/location_model.dart
class LocationModel {
  final int? id;
  final String deviceId;
  final double latitude;
  final double longitude;
  final int? batteryLevel;
  final DateTime timestamp;

  LocationModel({
    this.id,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    this.batteryLevel,
    required this.timestamp,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      deviceId: json['device_id'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      batteryLevel: json['battery_level'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'latitude': latitude,
      'longitude': longitude,
      'battery_level': batteryLevel,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
