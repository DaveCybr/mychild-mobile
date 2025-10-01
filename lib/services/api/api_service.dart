// services/api/api_service.dart - ENHANCED DEBUGGING
import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import 'dart:developer' as developer;
import 'dart:convert';
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
        responseType: ResponseType.json,
        // Don't throw on bad status codes so we can log them
        validateStatus: (status) {
          return status! < 500; // Only throw on server errors
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          developer.log('========== REQUEST ==========', name: _tag);
          developer.log(
            'URL: ${options.method} ${options.baseUrl}${options.path}',
            name: _tag,
          );
          developer.log('Headers: ${options.headers}', name: _tag);
          developer.log('Data Type: ${options.data.runtimeType}', name: _tag);
          developer.log('Request Data: ${options.data}', name: _tag);

          // Pretty print JSON if possible
          if (options.data is Map) {
            final prettyJson = const JsonEncoder.withIndent(
              '  ',
            ).convert(options.data);
            developer.log('Request JSON:\n$prettyJson', name: _tag);
          }

          final token = await LocalStorageService.getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            developer.log(
              'Token added: Bearer ${token.substring(0, 10)}...',
              name: _tag,
            );
          }

          developer.log('=============================', name: _tag);
          handler.next(options);
        },
        onResponse: (response, handler) {
          developer.log('========== RESPONSE ==========', name: _tag);
          developer.log('Status Code: ${response.statusCode}', name: _tag);
          developer.log(
            'Status Message: ${response.statusMessage}',
            name: _tag,
          );

          // Check if it's an error status
          if (response.statusCode == 422) {
            developer.log(
              '⚠️ VALIDATION ERROR (422) ⚠️',
              name: _tag,
              level: 900,
            );
            developer.log('Response Headers: ${response.headers}', name: _tag);
            developer.log(
              'Response Data Type: ${response.data.runtimeType}',
              name: _tag,
            );
            developer.log('Raw Response Data: ${response.data}', name: _tag);

            // Pretty print if JSON
            if (response.data is Map) {
              final prettyJson = const JsonEncoder.withIndent(
                '  ',
              ).convert(response.data);
              developer.log(
                'Response JSON:\n$prettyJson',
                name: _tag,
                level: 900,
              );

              // Parse Laravel validation errors
              if (response.data['errors'] != null) {
                developer.log(
                  'Laravel Validation Errors:',
                  name: _tag,
                  level: 900,
                );
                final errors = response.data['errors'] as Map;
                errors.forEach((field, messages) {
                  developer.log('  $field: $messages', name: _tag, level: 900);
                });
              }

              if (response.data['message'] != null) {
                developer.log(
                  'Error Message: ${response.data['message']}',
                  name: _tag,
                  level: 900,
                );
              }
            }

            // Throw DioException for 422
            throw DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: 'Validation failed',
            );
          } else if (response.statusCode! >= 200 &&
              response.statusCode! < 300) {
            developer.log('✅ Success Response', name: _tag);
            if (response.data is Map) {
              final prettyJson = const JsonEncoder.withIndent(
                '  ',
              ).convert(response.data);
              developer.log('Response JSON:\n$prettyJson', name: _tag);
            }
          }

          developer.log('==============================', name: _tag);
          handler.next(response);
        },
        onError: (error, handler) {
          developer.log('========== ERROR ==========', name: _tag, level: 1000);
          developer.log('Error Type: ${error.type}', name: _tag, level: 1000);
          developer.log(
            'Error Message: ${error.message}',
            name: _tag,
            level: 1000,
          );

          if (error.response != null) {
            developer.log(
              'Response Status: ${error.response?.statusCode}',
              name: _tag,
              level: 1000,
            );
            developer.log(
              'Response Data: ${error.response?.data}',
              name: _tag,
              level: 1000,
            );

            // Pretty print error response if JSON
            if (error.response?.data is Map) {
              final prettyJson = const JsonEncoder.withIndent(
                '  ',
              ).convert(error.response?.data);
              developer.log(
                'Error Response JSON:\n$prettyJson',
                name: _tag,
                level: 1000,
              );
            }
          }

          developer.log('===========================', name: _tag, level: 1000);
          handler.next(error);
        },
      ),
    );

    _initialized = true;
    developer.log(
      '🚀 ApiService initialized with baseUrl: ${ApiEndpoints.baseUrl}',
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
