// lib/features/auth/widgets/auth_background.dart
import 'package:flutter/material.dart';

/// Background แบบใน mock (ขาว + เงาฟุ้งรอบ ๆ)
class AuthBackground extends StatelessWidget {
  final Widget child;
  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.7),
          radius: 1.2,
          colors: [Colors.white, Color(0xFFF1F1F1)],
        ),
      ),
      child: Stack(
        children: [
          // vignette ทำให้ขอบมืดนิด ๆ
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.95,
                    colors: const [Colors.transparent, Color(0x22000000)],
                    stops: const [0.70, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
