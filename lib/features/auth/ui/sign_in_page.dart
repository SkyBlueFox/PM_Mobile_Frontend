import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/sign_in_bloc.dart';
import '../bloc/sign_in_event.dart';
import '../bloc/sign_in_state.dart';

import '../data/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

import 'widgets/auth_background.dart';
import 'widgets/pill_text_field.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  static const Color _blue = Color(0xFF3AA7FF);
  static const Color _red = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => SignInBloc(
        authRepository: ctx.read<AuthRepository>(), // ✅ ใช้ repo จาก main.dart
        authBloc: ctx.read<AuthBloc>(),             // ✅ ส่งให้ bloc เพื่อ dispatch AuthLoggedIn
      ),
      child: const _SignInView(),
    );
  }
}

class _SignInView extends StatelessWidget {
  const _SignInView();

  @override
  Widget build(BuildContext context) {
    // ✅ ไม่ต้อง navigate ไป Home แล้ว เพราะ AuthGate จะสลับให้เอง
    return BlocListener<SignInBloc, SignInState>(
      listenWhen: (p, c) => p.didSucceed != c.didSucceed,
      listener: (context, st) {
        if (st.didSucceed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signed in')),
          );
        }
      },
      child: Scaffold(
        body: AuthBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  const Text(
                    'Name',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: SignInPage._blue,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Let’s Sign in",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: SignInPage._blue,
                    ),
                  ),

                  const SizedBox(height: 34),

                  // Username
                  BlocBuilder<SignInBloc, SignInState>(
                    buildWhen: (p, c) =>
                        p.usernameTouched != c.usernameTouched ||
                        p.attemptedSubmit != c.attemptedSubmit ||
                        p.usernameError != c.usernameError,
                    builder: (context, st) {
                      final showErr = st.usernameTouched || st.attemptedSubmit;
                      return PillTextField(
                        hint: 'Your Email or Username',
                        autofocus: true,
                        highlightOnFocus: true,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) => context.read<SignInBloc>().add(SignInEmailChanged(v)),
                        errorText: showErr ? st.usernameError : null,
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // Password
                  BlocBuilder<SignInBloc, SignInState>(
                    buildWhen: (p, c) =>
                        p.obscurePassword != c.obscurePassword ||
                        p.passwordTouched != c.passwordTouched ||
                        p.attemptedSubmit != c.attemptedSubmit ||
                        p.passwordError != c.passwordError,
                    builder: (context, st) {
                      final showErr = st.passwordTouched || st.attemptedSubmit;
                      return PillTextField(
                        hint: 'Your Password',
                        obscureText: st.obscurePassword,
                        highlightOnFocus: true,
                        onChanged: (v) => context.read<SignInBloc>().add(SignInPasswordChanged(v)),
                        errorText: showErr ? st.passwordError : null,
                        suffix: IconButton(
                          onPressed: () => context.read<SignInBloc>().add(const SignInTogglePassword()),
                          icon: Icon(
                            st.obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: const Color(0xFF6B6B6B),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: SignInPage._blue, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Sign in button + form error
                  BlocBuilder<SignInBloc, SignInState>(
                    buildWhen: (p, c) =>
                        p.isSubmitting != c.isSubmitting || p.formError != c.formError,
                    builder: (context, st) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 56,
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SignInPage._blue,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                elevation: 10,
                                shadowColor: const Color(0x33000000),
                              ),
                              onPressed: st.isSubmitting
                                  ? null
                                  : () => context.read<SignInBloc>().add(const SignInSubmitted()),
                              child: st.isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Sign in',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                          if (st.formError != null && st.formError!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 14),
                              child: Text(
                                st.formError!,
                                style: const TextStyle(
                                  color: SignInPage._red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 18),
                  // divider "or"
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Color(0xFFBDBDBD), thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: TextStyle(color: Color(0xFF7A7A7A))),
                      ),
                      Expanded(child: Divider(color: Color(0xFFBDBDBD), thickness: 1)),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Google button
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () => context.read<SignInBloc>().add(const SignInGooglePressed()),
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 28), // placeholder icon
                      label: const Text(
                        'Continue with Google',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
