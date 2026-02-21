// lib/features/home/ui/widgets/cards/widget_card.dart

import 'package:flutter/material.dart';

import '../../view_models/home_view_model.dart';

/// Card ต่อ widget 1 ตัว
/// - sensor: half + tap เข้า detail
/// - toggle: half
/// - adjust: full + แสดงตัวเลข + slider + (color bar ตาม tile.showColorBar)
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

  static const Color blue = Color(0xFF3AA7FF);

  @override
  Widget build(BuildContext context) {
    final isSensor = tile.kind == HomeTileKind.sensor;
    final isToggle = tile.kind == HomeTileKind.toggle;
    final isAdjust = tile.kind == HomeTileKind.adjust;

    return InkWell(
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
        const Icon(Icons.sensors_rounded, size: 18, color: blue),
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
              color: blue,
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
        const Text('Power', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
        const Spacer(),
        Switch(
          value: tile.isOn,
          onChanged: (_) => onToggle(),
        ),
      ],
    );
  }

  Widget _adjustBody() {
    // ✅ ใช้จาก VM (ไม่เดาจากชื่อ)
    final isColor = tile.showColorBar;

    final min = tile.min.toDouble();
    final max = tile.max.toDouble();

    final valueText = tile.unit.isEmpty ? '${tile.displayValue}' : '${tile.displayValue}${tile.unit}';

    final raw = double.tryParse(tile.displayValue) ?? min;
    final sliderValue = raw.clamp(min, max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Adjust', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
            const Spacer(),
            Text(
              valueText,
              style: const TextStyle(fontWeight: FontWeight.w900, color: blue),
            ),
          ],
        ),
        const SizedBox(height: 10),

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
          min: min,
          max: max,
          onChanged: (v) => onAdjust(v.round()),
        ),
      ],
    );
  }

  Widget _unknownBody() {
    return const Text(
      'Unsupported widget',
      style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w600),
    );
  }
}