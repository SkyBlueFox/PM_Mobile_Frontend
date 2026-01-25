import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/sign_in_bloc.dart';
import 'bloc/sign_in_event.dart';
import 'bloc/sign_in_state.dart';

import 'widgets/auth_background.dart';
import 'widgets/google_button.dart';
import 'widgets/pill_text_field.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  static const Color _blue = Color(0xFF3AA7FF);

  @override
  Widget build(BuildContext context) {
    // 1) ครอบหน้าไว้ด้วย BlocProvider
    return BlocProvider(
      create: (_) => SignInBloc(),
      child: const _SignInView(),
    );
  }
}

class _SignInView extends StatelessWidget {
  const _SignInView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 2) พื้นหลัง
      body: AuthBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
            child: Column(
              children: [
                const SizedBox(height: 40),

                // 3) Title
                const Text(
                  'Name',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: SignInPage._blue,
                    height: 1.0,
                  ),
                ),

                // 4) Subtitle
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

                // 5) Email/Username input
                PillTextField(
                  hint: 'Your Email or Username',
                  highlighted: true,
                  onChanged: (v) => context.read<SignInBloc>().add(SignInEmailChanged(v)),
                ),

                const SizedBox(height: 14),

                // 6) Password input + toggle
                BlocBuilder<SignInBloc, SignInState>(
                  buildWhen: (p, c) =>
                      p.obscurePassword != c.obscurePassword || p.password != c.password,
                  builder: (context, st) {
                    return PillTextField(
                      hint: 'Your Password',
                      obscureText: st.obscurePassword,
                      onChanged: (v) => context.read<SignInBloc>().add(SignInPasswordChanged(v)),
                      suffix: IconButton(
                        onPressed: () => context.read<SignInBloc>().add(const SignInTogglePassword()),
                        icon: Icon(
                          st.obscurePassword ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: const Color(0xFF6B6B6B),
                        ),
                      ),
                    );
                  },
                ),

                // 7) Forgot password
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: SignInPage._blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 8) Sign in button (เปิดเมื่อ valid)
                BlocBuilder<SignInBloc, SignInState>(
                  buildWhen: (p, c) => p.isValid != c.isValid,
                  builder: (context, st) {
                    return SizedBox(
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
                        onPressed: st.isValid
                            ? () {
                                // mock action
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sign in (mock)')),
                                );
                              }
                            : null,
                        child: const Text(
                          'Sign in',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 22),

                // 9) Divider "or"
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

                const SizedBox(height: 18),

                // 10) Google button
                GoogleButton(
                  onPressed: () {
                    // mock action
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Google (mock)')),
                    );
                  },
                ),

                const Spacer(),

                // 11) ข้อความด้านล่าง
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    "Don’t have an account?  Sign up",
                    style: TextStyle(color: Color(0xFF6C6C6C)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
