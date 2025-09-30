import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class AuthService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _token;
  bool _isLoading = false;

  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    developer.log('sedang login');
    try {
      final res = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/auth/login'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      developer.log(res.body);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data['success'] == true) {
          _token = data['data']['token'];
          await _storage.write(key: 'token', value: _token);
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      developer.log("Login error: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_token != null) {
      await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/logout'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
    }
    _token = null;
    await _storage.delete(key: 'token');
    notifyListeners();
  }

  Future<void> loadFromStorage() async {
    _token = await _storage.read(key: 'token');
    notifyListeners();
  }
}
