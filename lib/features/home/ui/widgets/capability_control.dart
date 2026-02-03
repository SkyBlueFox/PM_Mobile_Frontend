import 'package:flutter/material.dart';

import '../../models/device_widget.dart';
import 'slider.dart';
import 'toggle.dart';

class CapabilityControl extends StatelessWidget {
  final DeviceWidget widgetData;
  final bool enabled;

  final ValueChanged<int>? onToggle; // widgetId
  final void Function(int widgetId, double value)? onValue; // widgetId, value

  const CapabilityControl({
    required this.widgetData,
    required this.enabled,
    required this.onToggle,
    required this.onValue,
  });

  @override
  Widget build(BuildContext context) {
    switch (widgetData.capability.id) {
      case 1: // toggle
        return ToggleRow(
          label: 'Power',
          isOn: widgetData.value >= 1,
          enabled: true, // always allow toggling
          onChanged: onToggle == null ? null : () => onToggle!(widgetData.widgetId),
        );

      case 2: // adjust (example: temperature / volume)
        return SliderRow(
          label: 'Adjust',
          value: widgetData.value,
          min: 0,
          max: 100,
          enabled: enabled,
          onChanged: onValue == null ? null : (v) => onValue!(widgetData.widgetId, v),
        );

      // Add more capability IDs here:
      // case 3: brightness
      // case 4: color
      // case 5: mode
      default:
        // fallback: show something minimal so you can see it's there
        return Text(
          'capability_id=${widgetData.capability.id} value=${widgetData.value.toStringAsFixed(0)}',
          style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w600),
        );
    }
  }
}
