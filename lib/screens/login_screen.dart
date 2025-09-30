import 'package:couple_guard_child/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> login() async {
    setState(() => isLoading = true);
    try {
      final response = await http
          .post(
            Uri.parse('http://192.168.137.1:8000/api/auth/login'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": emailController.text.trim(),
              "password": passwordController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint("Status code: ${response.statusCode}");
      debugPrint("Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          String token = data['data']['token'];
          debugPrint("Login sukses, token: $token");

          if (mounted) {
            setState(() => isLoading = false);
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          debugPrint("Login gagal: ${data['message']}");
          _showError("Login gagal: ${data['message']}");
        }
      } else {
        debugPrint("Server error: ${response.statusCode}");
        _showError("Error server: ${response.statusCode}");
      }
    } catch (e, stack) {
      debugPrint("Exception login: $e");
      debugPrint("Stacktrace: $stack");
      _showError("Terjadi error: $e");
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: login, child: const Text("Login")),
          ],
        ),
      ),
    );
  }
}
