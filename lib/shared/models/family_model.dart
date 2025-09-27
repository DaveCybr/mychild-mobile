
// shared/models/family_model.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'user_model.dart';

part 'family_model.g.dart';

@JsonSerializable()
class FamilyModel extends Equatable {
  final String id;
  final String name;
  @JsonKey(name: 'family_code')
  final String familyCode;
  @JsonKey(name: 'created_by')
  final String createdBy;
  @JsonKey(name: 'is_active')
  final bool isActive;
  final List<UserModel>? members;
  @JsonKey(name: 'members_count')
  final int membersCount;
  @JsonKey(name: 'parents_count')
  final int parentsCount;
  @JsonKey(name: 'children_count')
  final int childrenCount;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const FamilyModel({
    required this.id,
    required this.name,
    required this.familyCode,
    required this.createdBy,
    required this.isActive,
    this.members,
    required this.membersCount,
    required this.parentsCount,
    required this.childrenCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyModel.fromJson(Map<String, dynamic> json) => _$FamilyModelFromJson(json);
  Map<String, dynamic> toJson() => _$FamilyModelToJson(this);

  List<UserModel> get parents => members?.where((user) => user.isParent).toList() ?? [];
  List<UserModel> get children => members?.where((user) => user.isChild).toList() ?? [];

  FamilyModel copyWith({
    String? id,
    String? name,
    String? familyCode,
    String? createdBy,
    bool? isActive,
    List<UserModel>? members,
    int? membersCount,
    int? parentsCount,
    int? childrenCount,
    String? createdAt,
    String? updatedAt,
  }) {
    return FamilyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      familyCode: familyCode ?? this.familyCode,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      members: members ?? this.members,
      membersCount: membersCount ?? this.membersCount,
      parentsCount: parentsCount ?? this.parentsCount,
      childrenCount: childrenCount ?? this.childrenCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    familyCode,
    createdBy,
    isActive,
    members,
    membersCount,
    parentsCount,
    childrenCount,
    createdAt,
    updatedAt,
  ];
}