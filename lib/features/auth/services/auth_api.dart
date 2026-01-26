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

  AuthApi({
    required this.baseUrl,
  });

  Future<Map<String, dynamic>> signIn(
  String username,
  String password,
) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data; // e.g. { "token": "..." }
    } else {
      throw Exception(
        'Failed to login. Status Code: ${response.statusCode}',
      );
    }
  } catch (e) {
    print('Error posting login: $e'); // Debug
    rethrow;
  }
}
}