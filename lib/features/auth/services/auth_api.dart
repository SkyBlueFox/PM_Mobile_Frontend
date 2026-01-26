import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApiException implements Exception {
  final int? statusCode;
  final String message;
  AuthApiException(this.message, {this.statusCode});

  @override
  String toString() => 'AuthApiException($statusCode): $message';
}

class AuthApi {
  final String baseUrl;
  final http.Client _client;

  AuthApi({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<String> signIn({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/signin');

    final res = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      // พยายามดึง message จาก backend ถ้ามี
      try {
        final decoded = jsonDecode(res.body);
        final msg = (decoded is Map && decoded['message'] is String)
            ? decoded['message'] as String
            : 'Sign in failed';
        throw AuthApiException(msg, statusCode: res.statusCode);
      } catch (_) {
        throw AuthApiException('Sign in failed', statusCode: res.statusCode);
      }
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw AuthApiException('Invalid response format', statusCode: res.statusCode);
    }

    final token = decoded['token'];
    if (token is! String || token.isEmpty) {
      throw AuthApiException('Token not found in response', statusCode: res.statusCode);
    }

    return token;
  }
}
