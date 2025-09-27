// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FamilyModel _$FamilyModelFromJson(Map<String, dynamic> json) => FamilyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      familyCode: json['family_code'] as String,
      createdBy: json['created_by'] as String,
      isActive: json['is_active'] as bool,
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      membersCount: (json['members_count'] as num).toInt(),
      parentsCount: (json['parents_count'] as num).toInt(),
      childrenCount: (json['children_count'] as num).toInt(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$FamilyModelToJson(FamilyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'family_code': instance.familyCode,
      'created_by': instance.createdBy,
      'is_active': instance.isActive,
      'members': instance.members,
      'members_count': instance.membersCount,
      'parents_count': instance.parentsCount,
      'children_count': instance.childrenCount,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
