// lib/features/auth/widgets/google_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// ปุ่ม Google แบบ pill (ไม่ใช้ asset)
class GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const GoogleButton({super.key, this.onPressed});

  static const _border = Color(0xFFDADADA);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _border, width: 1.4),
          shape: const StadiumBorder(),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(_googleG, width: 22, height: 22),
            const SizedBox(width: 10),
            const Text(
              'Google',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
            ),
          ],
        ),
      ),
    );
  }

  static const String _googleG = '''
<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M23.04 12.261c0-.815-.073-1.597-.209-2.347H12v4.444h6.189a5.29 5.29 0 0 1-2.295 3.472v2.88h3.708c2.169-1.998 3.438-4.944 3.438-8.449Z" fill="#4285F4"/>
  <path d="M12 24c3.24 0 5.956-1.075 7.942-2.91l-3.708-2.88c-1.03.69-2.348 1.098-4.234 1.098-3.127 0-5.778-2.112-6.723-4.95H1.444v3.0A12 12 0 0 0 12 24Z" fill="#34A853"/>
  <path d="M5.277 14.358A7.2 7.2 0 0 1 4.9 12c0-.818.142-1.612.377-2.358v-3H1.444A12 12 0 0 0 0 12c0 1.936.464 3.766 1.444 5.358l3.833-3Z" fill="#FBBC05"/>
  <path d="M12 4.692c1.763 0 3.343.606 4.587 1.794l3.439-3.438C17.952 1.126 15.238 0 12 0A12 12 0 0 0 1.444 6.642l3.833 3C6.222 6.804 8.873 4.692 12 4.692Z" fill="#EA4335"/>
</svg>
''';
}
