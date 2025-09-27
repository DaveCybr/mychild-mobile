// injection_container.dart - Updated with missing dependencies
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/api_client.dart';
import '../core/network/api_interceptor.dart';
import '../core/services/background_service.dart';
import '../core/services/device_service.dart';
import '../core/services/location_service.dart';
import '../core/services/permission_service.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/secure_storage.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../shared/repositories/auth_repository.dart';
import '../features/family/data/family_repository_impl.dart';
import '../features/family/data/permission_repository_impl.dart';
import '../shared/repositories/family_repository.dart';
import '../shared/repositories/permission_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  const flutterSecureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => flutterSecureStorage);
  
  // Storage
  sl.registerLazySingleton<SecureStorage>(
    () => SecureStorageImpl(sl()),
  );
  sl.registerLazySingleton<LocalStorage>(
    () => LocalStorageImpl(sl()),
  );
  
  // Network
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => ApiInterceptor(sl<SecureStorage>()));
  
  // Configure Dio
  sl<Dio>().interceptors.add(sl<ApiInterceptor>());
  sl<Dio>().options.connectTimeout = const Duration(seconds: 30);
  sl<Dio>().options.receiveTimeout = const Duration(seconds: 30);
  sl<Dio>().options.sendTimeout = const Duration(seconds: 30);
  
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(sl()),
  );
  
  // Services
  sl.registerLazySingleton<PermissionService>(
    () => PermissionServiceImpl(sl()),
  );
  sl.registerLazySingleton<LocationService>(
    () => LocationServiceImpl(sl(), sl()),
  );
  sl.registerLazySingleton<BackgroundService>(
    () => BackgroundServiceImpl(),
  );
  sl.registerLazySingleton<DeviceService>(
    () => DeviceServiceImpl(sl()),
  );
  
  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      apiClient: sl(),
      secureStorage: sl(),
      localStorage: sl(),
    ),
  );
  sl.registerLazySingleton<FamilyRepository>(
    () => FamilyRepositoryImpl(
      apiClient: sl(),
      localStorage: sl(),
    ),
  );
  sl.registerLazySingleton<PermissionRepository>(
    () => PermissionRepositoryImpl(
      permissionService: sl(),
      localStorage: sl(),
    ),
  );
}