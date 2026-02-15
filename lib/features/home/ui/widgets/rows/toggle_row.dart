import 'package:flutter/material.dart';

class ToggleRow extends StatelessWidget {
  final String label;
  final bool isOn;
  final bool enabled;
  final VoidCallback? onChanged;

  const ToggleRow({
    super.key,
    required this.label,
    required this.isOn,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const Spacer(),
        Switch(
          value: isOn,
          onChanged: (!enabled || onChanged == null) ? null : (_) => onChanged!(),
        ),
      ],
    );
  }
}
