import 'package:flutter/material.dart';

class AdjustRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final bool enabled;
  final ValueChanged<int>? onChanged;

  const AdjustRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(min, max).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        Slider(
          value: v,
          min: min.toDouble(),
          max: max.toDouble(),
          onChanged: enabled ? (value) => onChanged!(value.toInt()) : null,
        ),
      ],
    );
  }
}
