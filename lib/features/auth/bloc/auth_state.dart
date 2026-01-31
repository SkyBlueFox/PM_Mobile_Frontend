sealed class AuthState {
  const AuthState();
}

/// สถานะเริ่มต้น/กำลังเช็ค token (ใช้แสดง loading)
class AuthUnknown extends AuthState {
  const AuthUnknown();
}

/// login แล้ว
class AuthAuthenticated extends AuthState {
  final String token;
  const AuthAuthenticated(this.token);
}

/// ยังไม่ login หรือ logout แล้ว
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}
