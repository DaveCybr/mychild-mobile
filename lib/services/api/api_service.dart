import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // set your API base URL here
  static const String baseUrl = 'http://192.168.1.100:8000/api';

  static Map<String, String> headers([String? token]) {
    final h = {'Accept': 'application/json'};
    if (token != null) h['Authorization'] = 'Bearer \$token';
    return h;
  }

  static Future<http.Response> post(String path, Map body, [String? token]) {
    return http.post(
      Uri.parse('\$baseUrl\$path'),
      headers: headers(token),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> get(String path, [String? token]) {
    return http.get(Uri.parse('\$baseUrl\$path'), headers: headers(token));
  }
}
