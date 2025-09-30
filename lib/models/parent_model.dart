class ParentModel {
  final int id;
  final String email;
  final String familyCode;

  ParentModel({
    required this.id,
    required this.email,
    required this.familyCode,
  });

  factory ParentModel.fromJson(Map<String, dynamic> j) => ParentModel(
    id: j['id'],
    email: j['email'],
    familyCode: j['family_code'] ?? '',
  );
}
