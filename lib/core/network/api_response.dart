// core/network/api_response.dart - PERBAIKAN
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'api_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> extends Equatable {
  final bool success;
  final String? message;
  final T? data;
  final String? token; // TAMBAHKAN ini untuk handle token dari login
  @JsonKey(name: 'token_type')
  final String? tokenType;
  final Map<String, dynamic>? errors;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.token,
    this.tokenType,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null
          ? fromJsonT(json['data'])
          :
            // FALLBACK: Jika 'data' null, coba ambil dari 'user' untuk login response
            json['user'] != null
          ? fromJsonT(json['user'])
          : null,
      token: json['token'],
      tokenType: json['token_type'],
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);

  factory ApiResponse.success(T data, [String? message]) {
    return ApiResponse<T>(success: true, data: data, message: message);
  }

  factory ApiResponse.error(String message, [Map<String, dynamic>? errors]) {
    return ApiResponse<T>(success: false, message: message, errors: errors);
  }

  @override
  List<Object?> get props => [success, message, data, token, tokenType, errors];

  @override
  String toString() {
    return 'ApiResponse(success: $success, data: $data, message: $message, token: ${token?.substring(0, 10)}...)';
  }
}
