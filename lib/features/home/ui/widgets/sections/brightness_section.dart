import 'package:flutter/material.dart';

class BrightnessSection extends StatelessWidget {
  final int value;
  final ValueChanged<double> onChanged;

  const BrightnessSection({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 100).toDouble();

    return Row(
      children: [
        const Icon(Icons.brightness_low_rounded, color: Colors.black38),
        Expanded(
          child: Slider(
            value: v,
            min: 0,
            max: 100,
            onChanged: onChanged,
          ),
        ),
        const Icon(Icons.brightness_high_rounded, color: Colors.black38),
      ],
    );
  }
}
