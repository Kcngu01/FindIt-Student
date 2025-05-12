import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class AuthService {

  // Request password reset
  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse(ApiConfig.forgotPasswordEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
    );

    if (response.statusCode != 200) {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Failed to send password reset email');
    }
  }

  // Reset password with token
  Future<void> resetPassword(String id, String hash, String email,String password) async {
    final response = await http.post(
      Uri.parse(ApiConfig.resetPasswordEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'id': id,
        'hash': hash,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? 'Failed to reset password');
    }
  }
}