// features/auth/data/auth_repository_impl.dart
import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_interceptor.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final SecureStorage _secureStorage;
  final LocalStorage _localStorage;

  AuthRepositoryImpl({
    required ApiClient apiClient,
    required SecureStorage secureStorage,
    required LocalStorage localStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage,
        _localStorage = localStorage;

  @override
  Future<ApiResponse<UserModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.login({
        'email': email,
        'password': password,
      });

      if (response.success && response.data != null) {
        // Save tokens
        if (response.data!.token != null) {
          await _secureStorage.setString(StorageKeys.userToken, response.data!.token!);
        }
        
        // Save user data
        await _localStorage.setString(
          StorageKeys.userData,
          jsonEncode(response.data!.toJson()),
        );
        await _localStorage.setString(StorageKeys.userId, response.data!.id);

        // Save family ID if exists
        if (response.data!.familyId != null) {
          await _localStorage.setString(StorageKeys.familyId, response.data!.familyId!);
        }
      }

      return response;
    } catch (e) {
      return ApiResponse.error('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<UserModel>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _apiClient.register({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });

      if (response.success && response.data != null) {
        // Save tokens
        if (response.data!.token != null) {
          await _secureStorage.setString(StorageKeys.userToken, response.data!.token!);
        }
        
        // Save user data
        await _localStorage.setString(
          StorageKeys.userData,
          jsonEncode(response.data!.toJson()),
        );
        await _localStorage.setString(StorageKeys.userId, response.data!.id);
      }

      return response;
    } catch (e) {
      return ApiResponse.error('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<void>> logout() async {
    try {
      await _apiClient.logout();
      await clearUserData();
      return ApiResponse.success(null);
    } catch (e) {
      // Even if API fails, clear local data
      await clearUserData();
      return ApiResponse.success(null);
    }
  }

  @override
  Future<ApiResponse<UserModel>> getCurrentUser() async {
    try {
      final response = await _apiClient.getCurrentUser();
      
      if (response.success && response.data != null) {
        // Update cached user data
        await _localStorage.setString(
          StorageKeys.userData,
          jsonEncode(response.data!.toJson()),
        );
      }

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get user data: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<UserModel>> updateProfile({
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final response = await _apiClient.updateProfile(profileData);
      
      if (response.success && response.data != null) {
        // Update cached user data
        await _localStorage.setString(
          StorageKeys.userData,
          jsonEncode(response.data!.toJson()),
        );
      }

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final token = await _secureStorage.getString(StorageKeys.userToken);
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final userDataString = _localStorage.getString(StorageKeys.userData);
      if (userDataString != null && userDataString.isNotEmpty) {
        final userJson = jsonDecode(userDataString);
        return UserModel.fromJson(userJson);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearUserData() async {
    await _secureStorage.delete(StorageKeys.userToken);
    await _secureStorage.delete(StorageKeys.refreshToken);
    await _localStorage.remove(StorageKeys.userData);
    await _localStorage.remove(StorageKeys.userId);
    await _localStorage.remove(StorageKeys.familyId);
    await _localStorage.remove(StorageKeys.familyData);
  }
}

// Extension for UserModel to include token
extension UserModelAuth on UserModel {
  String? get token => null; // This should be handled separately in auth response
}