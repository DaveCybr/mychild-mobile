// features/family/data/permission_repository_impl.dart
import '../../../core/services/permission_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/network/api_interceptor.dart';
import '../../../shared/repositories/permission_repository.dart';

class PermissionRepositoryImpl implements PermissionRepository {
  final PermissionService _permissionService;
  final LocalStorage _localStorage;

  PermissionRepositoryImpl({
    required PermissionService permissionService,
    required LocalStorage localStorage,
  })  : _permissionService = permissionService,
        _localStorage = localStorage;

  @override
  Future<PermissionStatusResult> checkAllPermissions() async {
    return await _permissionService.checkAllPermissions();
  }

  @override
  Future<bool> requestEssentialPermissions() async {
    try {
      final result = await _permissionService.requestAllEssentialPermissions();
      
      if (result) {
        // Check if ALL essential permissions are granted
        final statusResult = await _permissionService.checkAllPermissions();
        return statusResult.allEssentialGranted;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestEnhancedPermissions() async {
    try {
      final result = await _permissionService.requestAllEnhancedPermissions();
      
      if (result) {
        // Check if ALL enhanced permissions are granted
        final statusResult = await _permissionService.checkAllPermissions();
        return statusResult.allEnhancedGranted;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isSetupCompleted() async {
    try {
      return _localStorage.getBool(StorageKeys.permissionSetupCompleted) ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> markSetupCompleted() async {
    await _localStorage.setBool(StorageKeys.permissionSetupCompleted, true);
  }

  @override
  Future<ApiResponse<void>> syncPermissionStatus() async {
    try {
      final statusResult = await _permissionService.checkAllPermissions();
      
      // Here you could send permission status to server if needed
      // For now, just return success
      
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Failed to sync permission status: ${e.toString()}');
    }
  }
}