import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/devices_bloc.dart';
import '../../bloc/devices_event.dart';
import '../../models/device_widget.dart';
import 'rows/info_row.dart';
import 'rows/adjust_row.dart';
import 'rows/toggle_row.dart';

class CapabilityControl extends StatefulWidget {
  final DeviceWidget widgetData;
  final bool enabled;

  const CapabilityControl({
    super.key,
    required this.widgetData,
    required this.enabled,
  });

  @override
  State<CapabilityControl> createState() => _CapabilityControlState();
}

class _CapabilityControlState extends State<CapabilityControl> {
  DeviceWidget get widgetData => widget.widgetData;
  bool get enabled => widget.enabled;

  @override
  Widget build(BuildContext context) {
    switch (widgetData.capability.id) {
      case 1: // toggle
        return ToggleRow(
          label: 'Power',
          isOn: widgetData.value >= 1,
          enabled: true, // always allow toggling
          onChanged: () {
            context.read<DevicesBloc>().add(WidgetToggled(widgetData.widgetId));
          },
        );

      case 2: // adjust
        return AdjustRow(
          label: 'Adjust',
          value: widgetData.value,
          min: 0,
          max: 100,
          enabled: enabled,
          onChanged: !enabled
              ? null
              : (v) {
                  context
                      .read<DevicesBloc>()
                      .add(WidgetValueChanged(widgetData.widgetId, v.toDouble()));
                },
        );

      case 3: // info (read-only)
        return InfoRow(
          label: 'Info',
          valueText: widgetData.value.toString(),
          enabled: enabled,
        );

      default:
        return Text(
          'capability_id=${widgetData.capability.id} value=${widgetData.value.toStringAsFixed(0)}',
          style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w600),
        );
    }
  }
}
