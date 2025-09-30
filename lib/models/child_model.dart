// models/child_model.dart
class ChildModel {
  final String childId;
  final String familyCode;
  final String deviceId;
  final int parentId;
  final bool isActive;
  final DateTime? createdAt;

  ChildModel({
    required this.childId,
    required this.familyCode,
    required this.deviceId,
    required this.parentId,
    this.isActive = true,
    this.createdAt,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      childId: json['child_id'],
      familyCode: json['family_code'],
      deviceId: json['device_id'],
      parentId: json['parent_id'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'child_id': childId,
      'family_code': familyCode,
      'device_id': deviceId,
      'parent_id': parentId,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
