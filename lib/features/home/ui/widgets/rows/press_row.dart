// lib/features/home/ui/widgets/rows/press_row.dart
//
// Widget ปุ่มกด (momentary action) เช่น กดกริ่ง / กดเปิดประตู / ส่งสัญญาณ
// ใช้ UI โทนเดียวกับ row อื่น ๆ (พื้น #F6F7FB, มุมโค้ง)

import 'package:flutter/material.dart';

class PressRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool enabled;

  /// ถ้าต้องการกันกดรัว ให้ส่ง busy=true จาก parent (bloc)
  final bool busy;

  final String buttonText;
  final IconData icon;
  final VoidCallback? onPressed;

  const PressRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.enabled,
    this.busy = false,
    this.buttonText = 'กด',
    this.icon = Icons.notifications_active_rounded,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final canPress = enabled && !busy && onPressed != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF3AA7FF)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 34,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF3AA7FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: canPress ? onPressed : null,
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}
