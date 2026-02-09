import 'package:flutter/material.dart';

import '../../home_view_model.dart';

class DevicesSection extends StatelessWidget {
  /// Toggles จาก API (ไม่มี fallback)
  final List<HomeToggleVM> toggles;

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
            label: toggles[i].label,
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Switch(
            value: isOn,
            onChanged: (_) => onToggle(),
          ),
        ],
      ),
    );
  }
}
