import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  final String baseUrl;

  AuthApi({required this.baseUrl});

  Future<String> loginWithFirebase(String firebaseIdToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/firebase'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $firebaseIdToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Backend auth failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body);

    return data['token'];
  }
}