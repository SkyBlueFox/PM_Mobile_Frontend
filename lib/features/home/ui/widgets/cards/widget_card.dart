// lib/features/home/ui/widgets/cards/widget_card.dart
//
// ✅ UI FIX (ไม่กระทบ logic/Bloc):
// 1) ทำ layout ให้เหมือนภาพตัวอย่าง
//    - ซ้าย: ชื่ออุปกรณ์ (title) ด้านบน + ชื่อ cap (subtitle) ด้านล่าง
//    - ขวา: แสดงค่าของ sensor ให้ “ใหญ่และชัด” + หน่วยตัวเล็ก
// 2) ทำให้ card “fit” ในความสูงคงที่ที่ถูกกำหนดจาก HomeWidgetGrid
//    - ทุก kind ใช้ layout แบบ compact (Row-based)
//    - ลดโอกาส overflow เมื่อบังคับ height เท่ากันหมด
//
// หมายเหตุ:
// - full/half เป็นเรื่องความกว้าง (จัดโดย HomeWidgetGrid)
// - ไฟล์นี้โฟกัสเฉพาะหน้าตา/การจัดวางภายในการ์ดเท่านั้น

import 'package:flutter/material.dart';

import '../../view_models/home_view_model.dart';

class WidgetCard extends StatelessWidget {
  final HomeWidgetTileVM tile;
  final bool showDragHint;

  // actions
  final VoidCallback onToggle;
  final ValueChanged<int> onAdjust; // int (จำนวนเต็ม)
  final VoidCallback onOpenSensor;

  // new kinds
  final VoidCallback onOpenMode;
  final VoidCallback onOpenText;
  final VoidCallback onPressButton;

  const WidgetCard({
    super.key,
    required this.tile,
    required this.showDragHint,
    required this.onToggle,
    required this.onAdjust,
    required this.onOpenSensor,
    required this.onOpenMode,
    required this.onOpenText,
    required this.onPressButton,
  });

  static const Color blue = Color(0xFF3AA7FF);

  @override
  Widget build(BuildContext context) {
    final isSensor = tile.kind == HomeTileKind.sensor;
    final isToggle = tile.kind == HomeTileKind.toggle;
    final isAdjust = tile.kind == HomeTileKind.adjust;
    final isMode = tile.kind == HomeTileKind.mode;
    final isText = tile.kind == HomeTileKind.text;
    final isButton = tile.kind == HomeTileKind.button;

    // tap behavior: sensor/mode/text เปิดรายละเอียด
    final VoidCallback? tap =
        isSensor ? onOpenSensor : (isMode ? onOpenMode : (isText ? onOpenText : null));

    return InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
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
        child: Row(
          children: [
            // ===== Left: title/subtitle (ตาม requirement) =====
            Expanded(
              child: _TitleBlock(
                title: tile.title,
                subtitle: tile.subtitle,
              ),
            ),
            const SizedBox(width: 10),

            // ===== Right: compact body (fit ในความสูงเท่ากัน) =====
            if (isSensor) _sensorRight(),
            if (isToggle) _toggleRight(),
            if (isAdjust) _adjustRight(),
            if (isMode) _modeRight(),
            if (isText) _textRight(),
            if (isButton) _buttonRight(),
            if (!isSensor && !isToggle && !isAdjust && !isMode && !isText && !isButton)
              _unknownRight(),

            if (showDragHint)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.drag_indicator_rounded, color: Colors.black26),
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------------
  // Right side widgets (compact)
  // ------------------------------

  /// ✅ Sensor: แสดงตัวเลขใหญ่ชัด + หน่วยเล็ก (ตามภาพ)
  Widget _sensorRight() {
    final v = tile.displayValue.trim();
    final u = tile.unit.trim();

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 78),
      child: Align(
        alignment: Alignment.centerRight,
        child: RichText(
          textAlign: TextAlign.right,
          text: TextSpan(
            style: const TextStyle(color: blue),
            children: [
              TextSpan(
                text: v.isEmpty ? '-' : v,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              if (u.isNotEmpty)
                TextSpan(
                  text: ' $u',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Toggle: ใช้ Switch แบบ compact
  Widget _toggleRight() {
    return Switch(
      value: tile.isOn,
      onChanged: (_) => onToggle(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  /// Adjust: compact slider + ค่า (เพื่อไม่ให้ล้นความสูง)
  Widget _adjustRight() {
    final min = tile.min.toDouble();
    final max = tile.max.toDouble();

    final raw = double.tryParse(tile.displayValue) ?? min;
    final sliderValue = raw.clamp(min, max);

    final valueText = tile.unit.isEmpty ? tile.displayValue : '${tile.displayValue}${tile.unit}';

    // ความกว้างควบคุมให้พอดีทั้ง full/half
    return SizedBox(
      width: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            valueText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, color: blue),
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: sliderValue,
              min: min,
              max: max,
              onChanged: (v) => onAdjust(v.round()),
            ),
          ),
        ],
      ),
    );
  }

  /// Mode: แสดงค่า + chevron (tap เข้า sheet)
  Widget _modeRight() {
    final current = tile.displayValue.trim();
    final label = current.isEmpty ? '-' : current.toUpperCase();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, color: blue),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right_rounded, color: Colors.black26),
      ],
    );
  }

  /// Text: preview สั้น ๆ (tap เข้า dialog/sheet)
  Widget _textRight() {
    final preview = tile.displayValue.trim();
    final shown = preview.isEmpty ? '-' : preview;

    return SizedBox(
      width: 120,
      child: Text(
        shown,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFF0B4A7A),
        ),
      ),
    );
  }

  /// Button: ปุ่ม compact
  Widget _buttonRight() {
    return ElevatedButton(
      onPressed: onPressButton,
      style: ElevatedButton.styleFrom(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        tile.buttonLabel.isEmpty ? 'Press' : tile.buttonLabel,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _unknownRight() {
    return const Text(
      '-',
      style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w700),
    );
  }
}

/// ซ้าย: ชื่ออุปกรณ์ด้านบน + cap ด้านล่าง (ตาม requirement)
class _TitleBlock extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TitleBlock({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final t = title.trim().isEmpty ? '-' : title.trim();
    final s = subtitle.trim().isEmpty ? 'cap' : subtitle.trim();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          s,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black45,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}