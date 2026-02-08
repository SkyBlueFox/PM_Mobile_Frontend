import 'package:flutter/material.dart';

class DevicesSection extends StatelessWidget {
  final String label1;
  final bool isOn1;
  final VoidCallback? onToggle1;

  final String label2;
  final bool isOn2;
  final VoidCallback? onToggle2;

  const DevicesSection({
    super.key,
    required this.label1,
    required this.isOn1,
    required this.onToggle1,
    required this.label2,
    required this.isOn2,
    required this.onToggle2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ToggleTile(label: label1, isOn: isOn1, onToggle: onToggle1),
        const SizedBox(height: 10),
        _ToggleTile(label: label2, isOn: isOn2, onToggle: onToggle2),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final bool isOn;
  final VoidCallback? onToggle;

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
            onChanged: onToggle == null ? null : (_) => onToggle!(),
          ),
        ],
      ),
    );
  }
}
