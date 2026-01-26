import 'package:equatable/equatable.dart';

class SignInState extends Equatable {
  final String username; // email/username
  final String password;

  final bool obscurePassword;

  // ใช้คุมการโชว์ error (แดง)
  final bool usernameTouched;
  final bool passwordTouched;
  final bool attemptedSubmit;

  final bool isSubmitting;
  final bool didSucceed;

  // error แยกตามช่อง + error รวมจาก API
  final String? usernameError;
  final String? passwordError;
  final String? formError;

  const SignInState({
    this.username = '',
    this.password = '',
    this.obscurePassword = true,
    this.usernameTouched = false,
    this.passwordTouched = false,
    this.attemptedSubmit = false,
    this.isSubmitting = false,
    this.didSucceed = false,
    this.usernameError,
    this.passwordError,
    this.formError,
  });

  SignInState copyWith({
    String? username,
    String? password,
    bool? obscurePassword,
    bool? usernameTouched,
    bool? passwordTouched,
    bool? attemptedSubmit,
    bool? isSubmitting,
    bool? didSucceed,
    String? usernameError,
    String? passwordError,
    String? formError,
  }) {
    return SignInState(
      username: username ?? this.username,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      usernameTouched: usernameTouched ?? this.usernameTouched,
      passwordTouched: passwordTouched ?? this.passwordTouched,
      attemptedSubmit: attemptedSubmit ?? this.attemptedSubmit,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      didSucceed: didSucceed ?? this.didSucceed,
      usernameError: usernameError,
      passwordError: passwordError,
      formError: formError,
    );
  }

  @override
  List<Object?> get props => [
        username,
        password,
        obscurePassword,
        usernameTouched,
        passwordTouched,
        attemptedSubmit,
        isSubmitting,
        didSucceed,
        usernameError,
        passwordError,
        formError,
      ];
}
