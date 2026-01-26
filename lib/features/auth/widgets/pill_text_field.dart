import 'package:flutter/material.dart';

/// TextField ทรงแคปซูล + รองรับ errorText (ตัวแดง) + highlight ตอน focus
class PillTextField extends StatefulWidget {
  final String hint;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  // error ใต้ช่อง
  final String? errorText;

  // โฟกัส
  final bool autofocus;
  final bool highlightOnFocus; // ✅ เปิดให้กรอบน้ำเงินตาม focus
  final TextInputType keyboardType;

  // ถ้าต้องการบังคับให้กรอบน้ำเงินตลอด (ไม่จำเป็นในเคสนี้)
  final bool highlighted;

  const PillTextField({
    super.key,
    required this.hint,
    this.obscureText = false,
    this.onChanged,
    this.suffix,
    this.errorText,
    this.autofocus = false,
    this.highlightOnFocus = false,
    this.keyboardType = TextInputType.text,
    this.highlighted = false,
  });

  @override
  State<PillTextField> createState() => _PillTextFieldState();
}

class _PillTextFieldState extends State<PillTextField> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  static const _blue = Color(0xFF3AA7FF);
  static const _red = Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!mounted) return;
      setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.trim().isNotEmpty;
    final shouldHighlight = widget.highlighted || (widget.highlightOnFocus && _hasFocus);

    final fill = shouldHighlight ? Colors.white : const Color(0xFFF3F3F3);

    Border? border;
    if (hasError) {
      border = Border.all(color: _red, width: 2);
    } else if (shouldHighlight) {
      border = Border.all(color: _blue, width: 2);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(999),
            border: border,
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: TextField(
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            obscureText: widget.obscureText,
            decoration: InputDecoration(
              hintText: widget.hint,
              border: InputBorder.none,
              isCollapsed: true,
              suffixIcon: widget.suffix == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: widget.suffix,
                    ),
              suffixIconConstraints: const BoxConstraints(minHeight: 40, minWidth: 40),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                color: _red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
