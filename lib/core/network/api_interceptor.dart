
// core/network/api_interceptor.dart
import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../constants/storage_keys.dart';

class ApiInterceptor extends Interceptor {
  final SecureStorage _secureStorage;

  ApiInterceptor(this._secureStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Add auth token if available
    final token = await _secureStorage.getString(StorageKeys.userToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Add common headers
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    // Log request in debug mode
    _logRequest(options);

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Log response in debug mode
    _logResponse(response);
    
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle token expiration
    if (err.response?.statusCode == 401) {
      await _handleTokenExpiration();
    }

    // Log error
    _logError(err);

    // Transform error to custom exception
    final customError = _transformError(err);
    super.onError(customError, handler);
  }

  Future<void> _handleTokenExpiration() async {
    // Clear stored tokens
    await _secureStorage.delete(StorageKeys.userToken);
    await _secureStorage.delete(StorageKeys.refreshToken);
    
    // Could trigger navigation to login here
    // This would require a reference to the router or a callback
  }

  DioException _transformError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return DioException(
          requestOptions: error.requestOptions,
          error: NetworkException('Connection timeout. Please check your internet connection.'),
          type: error.type,
        );
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        String message = 'Something went wrong';
        
        if (statusCode != null) {
          switch (statusCode) {
            case 400:
              message = 'Bad request. Please check your input.';
              break;
            case 401:
              message = 'Unauthorized. Please login again.';
              break;
            case 403:
              message = 'Access forbidden.';
              break;
            case 404:
              message = 'Resource not found.';
              break;
            case 422:
              message = _extractValidationMessage(error.response?.data);
              break;
            case 500:
              message = 'Server error. Please try again later.';
              break;
            default:
              message = 'Network error occurred.';
          }
        }
        
        return DioException(
          requestOptions: error.requestOptions,
          error: NetworkException(message),
          response: error.response,
          type: error.type,
        );
      
      case DioExceptionType.cancel:
        return DioException(
          requestOptions: error.requestOptions,
          error: NetworkException('Request was cancelled.'),
          type: error.type,
        );
      
      case DioExceptionType.unknown:
        return DioException(
          requestOptions: error.requestOptions,
          error: NetworkException('Network error. Please check your connection.'),
          type: error.type,
        );
      
      default:
        return error;
    }
  }

  String _extractValidationMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('message')) {
        return data['message'] as String;
      }
      if (data.containsKey('errors')) {
        final errors = data['errors'] as Map<String, dynamic>;
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first as String;
        }
      }
    }
    return 'Validation error occurred.';
  }

  void _logRequest(RequestOptions options) {
    print('📤 REQUEST: ${options.method} ${options.path}');
    print('Headers: ${options.headers}');
    if (options.data != null) {
      print('Data: ${options.data}');
    }
  }

  void _logResponse(Response response) {
    print('📥 RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
    print('Data: ${response.data}');
  }

  void _logError(DioException error) {
    print('❌ ERROR: ${error.requestOptions.method} ${error.requestOptions.path}');
    print('Message: ${error.message}');
    if (error.response != null) {
      print('Status: ${error.response?.statusCode}');
      print('Data: ${error.response?.data}');
    }
  }
}

// core/network/network_exceptions.dart
class NetworkException implements Exception {
  final String message;
  
  const NetworkException(this.message);
  
  @override
  String toString() => message;
}

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? errors;
  
  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });
  
  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] ?? true,
      message: json['message'],
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      errors: json['errors'],
    );
  }
  
  factory ApiResponse.success(T data, [String? message]) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
    );
  }
  
  factory ApiResponse.error(String message, [Map<String, dynamic>? errors]) {
    return ApiResponse<T>(
      success: false,
      message: message,
      errors: errors,
    );
  }
}