import 'package:flutter/material.dart';

import '../view_models/home_view_model.dart';

class DevicesSection extends StatelessWidget {
  /// Toggles จาก API (ไม่มี fallback)
  /// ใช้ VM เดียวกับหน้า home (HomeWidgetTileVM) แล้วคัดเฉพาะ kind=toggle ตอนส่งเข้ามา
  final List<HomeWidgetTileVM> toggles;

  /// ส่ง widgetId กลับไปให้ parent ยิง event
  final void Function(int widgetId) onToggle;

  const DevicesSection({
    super.key,
    required this.toggles,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (toggles.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (int i = 0; i < toggles.length; i++) ...[
          _ToggleTile(
            label: toggles[i].title,
            isOn: toggles[i].isOn,
            onToggle: () => onToggle(toggles[i].widgetId),
          ),
          if (i != toggles.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final bool isOn;
  final VoidCallback onToggle;

  const _ToggleTile({
    required this.label,
    required this.isOn,
    required this.onToggle,
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
          Switch(
            value: isOn,
            onChanged: (_) => onToggle(),
          ),
        ],
      ),
    );
  }
}
