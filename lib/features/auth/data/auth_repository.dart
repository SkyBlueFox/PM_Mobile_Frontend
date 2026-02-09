import 'auth_api.dart';
import 'token_storage.dart';

/// Repository-level exception ที่ยัง "พก statusCode" ต่อให้ Bloc map ข้อความได้ถูกต้อง
class AuthFailure implements Exception {
  final String message;
  final int? statusCode;

  const AuthFailure(this.message, {this.statusCode});

  @override
  String toString() => 'AuthFailure($statusCode): $message';
}

class AuthRepository {
  final AuthApi _api;
  final TokenStorage _storage;

  AuthRepository({
    required AuthApi api,
    required TokenStorage storage,
  })  : _api = api,
        _storage = storage;

  /// สำเร็จจะ return token และเซฟลง secure storage
  /// - ไม่ catch กว้าง ๆ เพื่อไม่ทำลายประเภท error (SocketException/TimeoutException)
  /// - ถ้าเป็น 401/403 จะส่ง statusCode ขึ้นไปให้ Bloc แสดง "Invalid username or password."
  Future<String> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final data = await _api.signIn(username.trim(), password);

      final token = data['token'];
      if (token is! String || token.isEmpty) {
        // server ตอบมาไม่ครบ (ผู้ใช้ไม่ต้องรู้รายละเอียด)
        throw const AuthFailure('Invalid server response.', statusCode: 500);
      }

      await _storage.saveAccessToken(token);
      return token;
    } on AuthApiException catch (e) {
      // ✅ สำคัญ: เก็บ statusCode ไว้ ไม่ทิ้ง
      // Bloc จะใช้ statusCode=401/403 map เป็น Invalid username or password.
      throw AuthFailure('Sign-in failed.', statusCode: e.statusCode);
    }
  }

  Future<String> signInWithGoogle() async {
    throw UnimplementedError('signInWithGoogle not implemented yet');
  }

  Future<String?> getSavedToken() => _storage.readAccessToken();

  Future<void> signOut() => _storage.clearAccessToken();
}
