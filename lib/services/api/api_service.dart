import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import 'dart:developer' as developer;
import '../../core/constants/app_endpoints.dart';
import '../local/local_storage_service.dart';

class ApiService extends getx.GetxService {
  static const String _tag = 'ApiService';
  late Dio _dio;
  bool _initialized = false;

  ApiService() {
    // Initialize Dio immediately in constructor
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        responseType: ResponseType.json, // Explicitly set to JSON
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          developer.log(
            'Request: ${options.method} ${options.baseUrl}${options.path}',
            name: _tag,
          );
          developer.log('Request data: ${options.data}', name: _tag);

          final token = await LocalStorageService.getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            developer.log('Token added to request', name: _tag);
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          developer.log(
            'Response: ${response.statusCode} from ${response.requestOptions.path}',
            name: _tag,
          );
          developer.log(
            'Response data type: ${response.data.runtimeType}',
            name: _tag,
          );
          developer.log('Response headers: ${response.headers}', name: _tag);
          developer.log('Response data: ${response.data}', name: _tag);
          handler.next(response);
        },
        onError: (error, handler) {
          developer.log(
            'API Error: ${error.message}',
            name: _tag,
            error: error,
            level: 1000,
          );
          developer.log('Error type: ${error.type}', name: _tag, level: 1000);
          developer.log(
            'Error response: ${error.response?.data}',
            name: _tag,
            level: 1000,
          );
          developer.log(
            'Status code: ${error.response?.statusCode}',
            name: _tag,
            level: 1000,
          );

          print('API Error: ${error.message}');
          handler.next(error);
        },
      ),
    );

    _initialized = true;
    developer.log(
      'ApiService initialized with baseUrl: ${ApiEndpoints.baseUrl}',
      name: _tag,
    );
  }

  Future<ApiService> init() async {
    developer.log('ApiService init() called', name: _tag);
    return this;
  }

  Dio get dio => _dio;

  // Generic request methods
  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    try {
      developer.log('GET request to: $path with params: $params', name: _tag);
      final response = await _dio.get(path, queryParameters: params);
      return response;
    } catch (e, stackTrace) {
      developer.log(
        'GET request failed',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      developer.log('POST request to: $path', name: _tag);
      developer.log('POST data: $data', name: _tag);
      final response = await _dio.post(path, data: data);
      return response;
    } catch (e, stackTrace) {
      developer.log(
        'POST request failed',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      developer.log('PUT request to: $path', name: _tag);
      developer.log('PUT data: $data', name: _tag);
      final response = await _dio.put(path, data: data);
      return response;
    } catch (e, stackTrace) {
      developer.log(
        'PUT request failed',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }
}
