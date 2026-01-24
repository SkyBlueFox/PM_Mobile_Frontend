import 'package:equatable/equatable.dart';

/// State ของหน้า Sign in
class SignInState extends Equatable {
  final String emailOrUsername;
  final String password;
  final bool obscurePassword;
  final bool isValid;

  const SignInState({
    this.emailOrUsername = '',
    this.password = '',
    this.obscurePassword = true,
    this.isValid = false,
  });

  SignInState copyWith({
    String? emailOrUsername,
    String? password,
    bool? obscurePassword,
    bool? isValid,
  }) {
    return SignInState(
      emailOrUsername: emailOrUsername ?? this.emailOrUsername,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  List<Object?> get props => [emailOrUsername, password, obscurePassword, isValid];
}
