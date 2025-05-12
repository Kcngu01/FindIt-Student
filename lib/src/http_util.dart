import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/login_service.dart';

class HttpUtil {
  static Future<http.Response> makeAuthenticatedRequest(
    String url,
    String? token,
    {String method = 'GET', Map<String, dynamic>? body}
  ) async {
    final effectiveToken = token ?? await LoginService().token;
    if (effectiveToken == null) {
      throw Exception('No authentication token available');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $effectiveToken',
    };

    switch (method.toUpperCase()) {
      case 'POST':
        return await http.post(
          Uri.parse(url),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          Uri.parse(url),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(
          Uri.parse(url),
          headers: headers,
        );
      case 'GET':
      default:
        return await http.get(
          Uri.parse(url),
          headers: headers,
        );
    }
  }
}