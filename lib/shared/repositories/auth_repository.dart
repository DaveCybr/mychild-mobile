// shared/repositories/auth_repository.dart
import '../models/user_model.dart';
import '../../core/network/api_interceptor.dart';

abstract class AuthRepository {
  Future<ApiResponse<UserModel>> login({
    required String email,
    required String password,
  });
  
  Future<ApiResponse<UserModel>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  });
  
  Future<ApiResponse<void>> logout();
  
  Future<ApiResponse<UserModel>> getCurrentUser();
  
  Future<ApiResponse<UserModel>> updateProfile({
    required Map<String, dynamic> profileData,
  });
  
  Future<bool> isLoggedIn();
  Future<UserModel?> getCachedUser();
  Future<void> clearUserData();
}