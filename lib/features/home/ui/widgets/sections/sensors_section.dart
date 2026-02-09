import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../home_view_model.dart';

class SensorsSection extends StatelessWidget {
  /// Sensors จาก API (ไม่มี fallback)
  final List<HomeSensorVM> sensors;

  const SensorsSection({
    super.key,
    required this.sensors,
  });

  @override
  Widget build(BuildContext context) {
    if (sensors.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // แสดงเป็น 2 คอลัมน์แบบดีไซน์ ถ้ามี 1 ตัวจะเต็มแถว
        LayoutBuilder(
          builder: (context, c) {
            final width = c.maxWidth;
            final cardWidth = (sensors.length == 1) ? width : (width - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: sensors.map((s) {
                final unitPart = s.unit.isEmpty ? '' : ' ${s.unit}';
                return SizedBox(
                  width: cardWidth,
                  child: _MiniValueCard(
                    label: s.label,
                    valueText: '${s.valueText}$unitPart',
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 12),

        // กราฟเป็น UI แสดงผล (placeholder) — ไม่อ้างข้อมูลเกินจริง
        SizedBox(
          height: 140,
          width: double.infinity,
          child: CustomPaint(painter: _LineChartPainter()),
        ),
      ],
    );
  }
}

class _MiniValueCard extends StatelessWidget {
  final String label;
  final String valueText;

  const _MiniValueCard({
    required this.label,
    required this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            valueText,
            style: const TextStyle(
              color: Color(0xFF3AA7FF),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      axisPaint,
    );

    final linePaint = Paint()
      ..color = const Color(0xFF3AA7FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final path = Path();
    const points = 40;

    for (int i = 0; i < points; i++) {
      final t = i / (points - 1);
      final x = t * size.width;
      final y = size.height *
          (0.60 - 0.18 * math.sin(t * math.pi * 2) - 0.10 * math.sin(t * math.pi * 4));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
