import 'package:flutter/material.dart';

class ColorSection extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const ColorSection({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 100).toDouble();

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        trackShape: const GradientSliderTrackShape(
          gradient: LinearGradient(
            colors: [Color(0xFF4CB2FF), Color(0xFFFFB74D)],
          ),
        ),
        activeTrackColor: Colors.transparent,
        inactiveTrackColor: Colors.transparent,
      ),
      child: Slider(
        value: v,
        min: 0,
        max: 100,
        onChanged: onChanged,
      ),
    );
  }
}

class GradientSliderTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  final LinearGradient gradient;

  const GradientSliderTrackShape({required this.gradient});

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final paint = Paint()..shader = gradient.createShader(trackRect);
    final rrect = RRect.fromRectAndRadius(trackRect, const Radius.circular(999));
    context.canvas.drawRRect(rrect, paint);
  }
}
