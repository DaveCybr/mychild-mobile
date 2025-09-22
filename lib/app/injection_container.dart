// injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Core
import '../core/network/api_client.dart';
import '../core/services/background_service.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/secure_storage.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../shared/repositories/auth_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // Initialize FlutterSecureStorage dengan proper configuration
  const flutterSecureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => flutterSecureStorage);
  
  // Storage
  sl.registerLazySingleton<SecureStorage>(
    () => SecureStorageImpl(sl<FlutterSecureStorage>()),
  );
  sl.registerLazySingleton<LocalStorage>(
    () => LocalStorageImpl(sl()),
  );
  
  // Network
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(sl()),
  );
  
  // Services
  sl.registerLazySingleton<BackgroundService>(
    () => BackgroundServiceImpl(),
  );
  
  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      apiClient: sl(),
      secureStorage: sl(),
      localStorage: sl(),
    ),
  );
}