// shared/models/login_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'user_model.dart';

part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse extends Equatable {
  final bool success;
  final UserModel user;
  final String token;
  @JsonKey(name: 'token_type')
  final String tokenType;

  const LoginResponse({
    required this.success,
    required this.user,
    required this.token,
    required this.tokenType,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);

  @override
  List<Object> get props => [success, user, token, tokenType];
}

// Register response model (sama dengan login)
@JsonSerializable()
class RegisterResponse extends Equatable {
  final bool success;
  final UserModel user;
  final String token;
  @JsonKey(name: 'token_type')
  final String tokenType;

  const RegisterResponse({
    required this.success,
    required this.user,
    required this.token,
    required this.tokenType,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterResponseToJson(this);

  @override
  List<Object> get props => [success, user, token, tokenType];
}
