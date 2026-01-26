import 'package:equatable/equatable.dart';

/// State ของหน้า Sign in
class SignInState extends Equatable {
  final String username;
  final String password;
  final bool obscurePassword;
  final bool isValid;

  final bool isSubmitting;
  final String? errorMessage;
  final bool didSucceed;

  const SignInState({
    this.username = '',
    this.password = '',
    this.obscurePassword = true,
    this.isValid = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.didSucceed = false,
  });

  SignInState copyWith({
    String? username,
    String? password,
    bool? obscurePassword,
    bool? isValid,
    bool? isSubmitting,
    String? errorMessage,
    bool? didSucceed,
  }) {
    return SignInState(
      username: username ?? this.username,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isValid: isValid ?? this.isValid,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      didSucceed: didSucceed ?? this.didSucceed,
    );
  }

  @override
  List<Object?> get props =>
      [username, password, obscurePassword, isValid, isSubmitting, errorMessage];
}
