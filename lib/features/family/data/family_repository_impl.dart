// features/family/data/family_repository_impl.dart
import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_interceptor.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../shared/models/family_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/repositories/family_repository.dart';

class FamilyRepositoryImpl implements FamilyRepository {
  final ApiClient _apiClient;
  final LocalStorage _localStorage;

  FamilyRepositoryImpl({
    required ApiClient apiClient,
    required LocalStorage localStorage,
  })  : _apiClient = apiClient,
        _localStorage = localStorage;

  @override
  Future<ApiResponse<FamilyModel>> createFamily({
    required String name,
  }) async {
    try {
      final response = await _apiClient.createFamily({
        'name': name,
      });

      if (response.success && response.data != null) {
        await _saveFamilyData(response.data!);
      }

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to create family: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<FamilyModel>> joinFamily({
    required String familyCode,
  }) async {
    try {
      final response = await _apiClient.joinFamily({
        'family_code': familyCode,
      });

      if (response.success && response.data != null) {
        await _saveFamilyData(response.data!);
      }

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to join family: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<FamilyModel>> getFamilyInfo() async {
    try {
      final response = await _apiClient.getFamilyInfo();
      
      if (response.success && response.data != null) {
        await _saveFamilyData(response.data!);
      }

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get family info: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<List<UserModel>>> getFamilyMembers() async {
    try {
      return await _apiClient.getFamilyMembers();
    } catch (e) {
      return ApiResponse.error('Failed to get family members: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<void>> leaveFamily() async {
    try {
      await _apiClient.leaveFamily();
      await clearFamilyData();
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Failed to leave family: ${e.toString()}');
    }
  }

  @override
  Future<bool> hasFamilyConnection() async {
    try {
      final familyId = _localStorage.getString(StorageKeys.familyId);
      return familyId != null && familyId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<FamilyModel?> getCachedFamily() async {
    try {
      final familyDataString = _localStorage.getString(StorageKeys.familyData);
      if (familyDataString != null && familyDataString.isNotEmpty) {
        final familyJson = jsonDecode(familyDataString);
        return FamilyModel.fromJson(familyJson);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearFamilyData() async {
    await _localStorage.remove(StorageKeys.familyId);
    await _localStorage.remove(StorageKeys.familyData);
    await _localStorage.remove(StorageKeys.familyCode);
  }

  Future<void> _saveFamilyData(FamilyModel family) async {
    await _localStorage.setString(StorageKeys.familyId, family.id);
    await _localStorage.setString(StorageKeys.familyCode, family.familyCode);
    await _localStorage.setString(
      StorageKeys.familyData,
      jsonEncode(family.toJson()),
    );
  }
}