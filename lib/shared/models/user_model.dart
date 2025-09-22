
// shared/models/user_model.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  @JsonKey(name: 'email_verified_at')
  final String? emailVerifiedAt;
  final String role;
  @JsonKey(name: 'family_id')
  final String? familyId;
  @JsonKey(name: 'device_id')
  final String? deviceId;
  final String? avatar;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'last_seen_at')
  final String? lastSeenAt;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    required this.role,
    this.familyId,
    this.deviceId,
    this.avatar,
    required this.isActive,
    this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  bool get isParent => role == 'parent';
  bool get isChild => role == 'child';
  bool get hasFamily => familyId != null && familyId!.isNotEmpty;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? emailVerifiedAt,
    String? role,
    String? familyId,
    String? deviceId,
    String? avatar,
    bool? isActive,
    String? lastSeenAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      role: role ?? this.role,
      familyId: familyId ?? this.familyId,
      deviceId: deviceId ?? this.deviceId,
      avatar: avatar ?? this.avatar,
      isActive: isActive ?? this.isActive,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    emailVerifiedAt,
    role,
    familyId,
    deviceId,
    avatar,
    isActive,
    lastSeenAt,
    createdAt,
    updatedAt,
  ];
}
