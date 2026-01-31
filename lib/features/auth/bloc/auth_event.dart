sealed class AuthEvent {
  const AuthEvent();
}

/// เริ่มแอพแล้วเช็คว่าเคยมี token เก็บไว้ไหม
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// login สำเร็จ (รับ token ของระบบเรา)
class AuthLoggedIn extends AuthEvent {
  final String token;
  const AuthLoggedIn(this.token);
}

/// กด logout
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
