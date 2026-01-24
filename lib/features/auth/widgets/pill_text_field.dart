// lib/features/auth/widgets/pill_text_field.dart
import 'package:flutter/material.dart';

/// TextField ทรงแคปซูล + เงา + border ตอน highlight
class PillTextField extends StatelessWidget {
  final String hint;
  final bool highlighted;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  const PillTextField({
    super.key,
    required this.hint,
    this.highlighted = false,
    this.obscureText = false,
    this.onChanged,
    this.suffix,
  });

  static const _blue = Color(0xFF3AA7FF);

  @override
  Widget build(BuildContext context) {
    final fill = highlighted ? Colors.white : const Color(0xFFF3F3F3);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: highlighted ? Border.all(color: _blue, width: 2) : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          isCollapsed: true,
          suffixIcon: suffix == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: suffix,
                ),
          suffixIconConstraints: const BoxConstraints(minHeight: 40, minWidth: 40),
        ),
      ),
    );
  }
}
