class NotificationModel {
  final int? id;
  final String deviceId;
  final String appName;
  final String title;
  final String content;
  final DateTime timestamp;

  NotificationModel({
    this.id,
    required this.deviceId,
    required this.appName,
    required this.title,
    required this.content,
    required this.timestamp,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      deviceId: json['device_id'],
      appName: json['app_name'],
      title: json['title'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'app_name': appName,
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
