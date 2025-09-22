// injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Core
import '../core/network/api_client.dart';
import '../core/services/background_service.dart';
// import '../core/storage/secure_storage.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/secure_storage.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../shared/repositories/auth_repository.dart';
// import '../core/services/permission_service.dart';
// import '../core/services/location_service.dart';
// import '../core/services/device_service.dart';
// import 'core/storage/secure_storage.dart';

// Repositories
// import '../shared/repositories/auth_repository.dart';
// import '../shared/repositories/family_repository.dart';
// import '../shared/repositories/permission_repository.dart';

// Repository Implementations
// import '../features/auth/data/auth_repository_impl.dart';
// import '../features/family/data/family_repository_impl.dart';
// import '../features/permissions/data/permission_repository_impl.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  // final flutterSecureStorage = FlutterSecureStorage(
  //   aOptions: AndroidOptions(
  //     encryptedSharedPreferences: true,
  //   ),
  //   iOptions: IOSOptions(
  //     accessibility: KeychainItemAccessibility.first_unlock_this_device,
  //   ),
  // );
  
  sl.registerLazySingleton(() => sharedPreferences);
  // sl.registerLazySingleton(() => flutterSecureStorage);
  
  // Storage
  sl.registerLazySingleton<SecureStorage>(
    () => SecureStorageImpl(sl()),
  );
  sl.registerLazySingleton<LocalStorage>(
    () => LocalStorageImpl(sl()),
  );
  
  // Network
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(sl()),
  );
  
  // // Services
  // sl.registerLazySingleton<PermissionService>(
  //   () => PermissionServiceImpl(),
  // );
  // sl.registerLazySingleton<LocationService>(
  //   () => LocationServiceImpl(),
  // );
  sl.registerLazySingleton<BackgroundService>(
    () => BackgroundServiceImpl(),
  );
  // sl.registerLazySingleton<DeviceService>(
  //   () => DeviceServiceImpl(),
  // );
  
  // // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      apiClient: sl(),
      secureStorage: sl(),
      localStorage: sl(),
    ),
  );
  // sl.registerLazySingleton<FamilyRepository>(
  //   () => FamilyRepositoryImpl(
  //     apiClient: sl(),
  //     localStorage: sl(),
  //   ),
  // );
  // sl.registerLazySingleton<PermissionRepository>(
  //   () => PermissionRepositoryImpl(
  //     permissionService: sl(),
  //     localStorage: sl(),
  //   ),
  // );
}