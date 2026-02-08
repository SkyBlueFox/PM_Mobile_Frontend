import 'dart:math' as math;
import 'package:flutter/material.dart';

class SensorsSection extends StatelessWidget {
  final String aLabel;
  final String aValue;
  final String aUnit;

  final String bLabel;
  final String bValue;
  final String bUnit;

  const SensorsSection({
    super.key,
    required this.aLabel,
    required this.aValue,
    required this.aUnit,
    required this.bLabel,
    required this.bValue,
    required this.bUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _MiniValueCard(label: aLabel, value: aValue, unit: aUnit)),
            const SizedBox(width: 12),
            Expanded(child: _MiniValueCard(label: bLabel, value: bValue, unit: bUnit)),
          ],
        ),
        const SizedBox(height: 12),
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
  final String value;
  final String unit;

  const _MiniValueCard({
    required this.label,
    required this.value,
    required this.unit,
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
            '$value $unit',
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
