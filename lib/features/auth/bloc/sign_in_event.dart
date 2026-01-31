import 'package:equatable/equatable.dart';

/// Events ของหน้า Sign in
sealed class SignInEvent extends Equatable {
  const SignInEvent();
  @override
  List<Object?> get props => [];
}

/// เปลี่ยนค่า Email/Username
class SignInEmailChanged extends SignInEvent {
  final String value;
  const SignInEmailChanged(this.value);
  @override
  List<Object?> get props => [value];
}

/// เปลี่ยนค่า Password
class SignInPasswordChanged extends SignInEvent {
  final String value;
  const SignInPasswordChanged(this.value);
  @override
  List<Object?> get props => [value];
}

/// กดปุ่มโชว์/ซ่อนรหัสผ่าน
class SignInTogglePassword extends SignInEvent {
  const SignInTogglePassword();
}

class SignInSubmitted extends SignInEvent {
  const SignInSubmitted();
}

class SignInGooglePressed extends SignInEvent {
  const SignInGooglePressed();
}
