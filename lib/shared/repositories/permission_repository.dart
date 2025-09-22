// shared/repositories/permission_repository.dart
import '../../core/services/permission_service.dart';
import '../../core/network/api_interceptor.dart';

abstract class PermissionRepository {
  Future<PermissionStatusResult> checkAllPermissions();
  Future<bool> requestEssentialPermissions();
  Future<bool> requestEnhancedPermissions();
  Future<bool> isSetupCompleted();
  Future<void> markSetupCompleted();
  Future<ApiResponse<void>> syncPermissionStatus();
}