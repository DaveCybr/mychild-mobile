// shared/repositories/family_repository.dart
import '../models/family_model.dart';
import '../models/user_model.dart';
import '../../core/network/api_interceptor.dart';

abstract class FamilyRepository {
  Future<ApiResponse<FamilyModel>> createFamily({
    required String name,
  });
  
  Future<ApiResponse<FamilyModel>> joinFamily({
    required String familyCode,
  });
  
  Future<ApiResponse<FamilyModel>> getFamilyInfo();
  
  Future<ApiResponse<List<UserModel>>> getFamilyMembers();
  
  Future<ApiResponse<void>> leaveFamily();
  
  Future<bool> hasFamilyConnection();
  Future<FamilyModel?> getCachedFamily();
  Future<void> clearFamilyData();
}