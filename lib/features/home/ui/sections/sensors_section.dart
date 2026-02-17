// lib/features/home/ui/sections/sensors_section.dart

import 'package:flutter/material.dart';

import '../view_models/home_view_model.dart';

class SensorsSection extends StatelessWidget {
  /// Sensors จาก API (ไม่มี fallback)
  /// ใช้ VM เดียวกับหน้า home (HomeWidgetTileVM) แล้วคัดเฉพาะ kind=sensor ตอนส่งเข้ามา
  final List<HomeWidgetTileVM> sensors;

  /// (optional) ถ้าต้องการกดเข้า detail
  final void Function(int widgetId)? onOpenSensor;

  const SensorsSection({
    super.key,
    required this.sensors,
    this.onOpenSensor,
  });

  @override
  Widget build(BuildContext context) {
    // กันพลาด: เอาเฉพาะ sensor จริง
    final items = sensors.where((t) => t.kind == HomeTileKind.sensor).toList(growable: false);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // แสดงเป็น 2 คอลัมน์แบบดีไซน์ ถ้ามี 1 ตัวจะเต็มแถว
        LayoutBuilder(
          builder: (context, c) {
            final width = c.maxWidth;
            final cardWidth = (items.length == 1) ? width : (width - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: items.map((s) {
                final valueText = s.unit.isEmpty ? '${s.value}' : '${s.value}${s.unit}';

                return SizedBox(
                  width: cardWidth,
                  child: _MiniValueCard(
                    label: s.title,
                    valueText: valueText,
                    onTap: onOpenSensor == null ? null : () => onOpenSensor!(s.widgetId),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _MiniValueCard extends StatelessWidget {
  final String label;
  final String valueText;
  final VoidCallback? onTap;

  const _MiniValueCard({
    required this.label,
    required this.valueText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
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

    if (onTap == null) return child;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: child,
    );
  }
}
