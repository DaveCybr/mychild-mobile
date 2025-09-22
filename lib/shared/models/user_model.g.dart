// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      emailVerifiedAt: json['email_verified_at'] as String?,
      role: json['role'] as String,
      familyId: json['family_id'] as String?,
      deviceId: json['device_id'] as String?,
      avatar: json['avatar'] as String?,
      isActive: json['is_active'] as bool,
      lastSeenAt: json['last_seen_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'email_verified_at': instance.emailVerifiedAt,
      'role': instance.role,
      'family_id': instance.familyId,
      'device_id': instance.deviceId,
      'avatar': instance.avatar,
      'is_active': instance.isActive,
      'last_seen_at': instance.lastSeenAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
