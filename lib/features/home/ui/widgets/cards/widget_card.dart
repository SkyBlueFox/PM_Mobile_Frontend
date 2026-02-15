// lib/features/home/ui/widgets/widget_card.dart

import 'package:flutter/material.dart';

import '../../view_models/home_view_model.dart';

/// Card ต่อ widget 1 ตัว
/// - sensor: half + tap เข้า detail
/// - toggle: half
/// - adjust: full + แสดงตัวเลข + slider + (color bar ถ้าชื่อมีคำว่า color)
class WidgetCard extends StatelessWidget {
  final HomeWidgetTileVM tile;
  final bool showDragHint;

  final VoidCallback onToggle;
  final ValueChanged<int> onAdjust; // ส่ง int (จำนวนเต็ม)
  final VoidCallback onOpenSensor;

  const WidgetCard({
    super.key,
    required this.tile,
    required this.showDragHint,
    required this.onToggle,
    required this.onAdjust,
    required this.onOpenSensor,
  });

  @override
  Widget build(BuildContext context) {
    final isSensor = tile.kind == HomeTileKind.sensor;
    final isToggle = tile.kind == HomeTileKind.toggle;
    final isAdjust = tile.kind == HomeTileKind.adjust;

    return InkWell(
      // sensor ต้องกดเข้า detail
      onTap: isSensor ? onOpenSensor : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Header =====
            Row(
              children: [
                Expanded(
                  child: Text(
                    tile.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
                if (showDragHint)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.drag_indicator_rounded, color: Colors.black26),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // ===== Body by type =====
            if (isSensor) _sensorBody(),
            if (isToggle) _toggleBody(),
            if (isAdjust) _adjustBody(),
            if (!isSensor && !isToggle && !isAdjust) _unknownBody(),
          ],
        ),
      ),
    );
  }

  Widget _sensorBody() {
    return Row(
      children: [
        const Icon(Icons.sensors_rounded, size: 18, color: Color(0xFF3AA7FF)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${tile.displayValue}${tile.unit}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF3AA7FF),
            ),
          ),
        ),
        const Spacer(),
        const Icon(Icons.chevron_right_rounded, color: Colors.black26),
      ],
    );
  }

  Widget _toggleBody() {
    return Row(
      children: [
        Text('Power', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
        const Spacer(),
        Switch(
          value: tile.isOn,
          onChanged: (_) => onToggle(),
        ),
      ],
    );
  }

  Widget _adjustBody() {
    final name = tile.title.toLowerCase();
    final isColor = name.contains('color');

    // ค่าที่โชว์เป็นจำนวนเต็ม
    final valueText = tile.unit.isEmpty ? '${tile.displayValue}' : '${tile.displayValue}${tile.unit}';

    // Slider ต้องเป็น double และ clamp ได้ -> แปลง String เป็น double ก่อน
    final sliderValue = (double.tryParse(tile.displayValue) ?? 0.0)
        .clamp(0.0, 100.0)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Adjust', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
            const Spacer(),
            Text(
              valueText,
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3AA7FF)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // color bar (แสดง “ข้อมูล” ของ adjust ตาม requirement)
        if (isColor) ...[
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF00A3FF),
                  Color(0xFF00E5FF),
                  Color(0xFFFFD600),
                  Color(0xFFFF6D00),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        Slider(
          value: sliderValue,
          min: 0.0,
          max: 100.0,
          onChanged: (v) => onAdjust(v.round()),
        ),
      ],
    );
  }

  Widget _unknownBody() {
    return Text(
      'Unsupported widget',
      style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w600),
    );
  }
}
