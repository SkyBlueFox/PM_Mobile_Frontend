import 'package:flutter/material.dart';
import '../../models/device_widget.dart';
import 'capability_control.dart';

class WidgetCard extends StatelessWidget {
  /// One card = one widget (capability)
  final DeviceWidget widgetData;

  final ValueChanged<int>? onToggle; // widgetId
  final void Function(int widgetId, double value)? onValue; // widgetId, value

  const WidgetCard({
    super.key,
    required this.widgetData,
    this.onToggle,
    this.onValue,
  });

  @override
  Widget build(BuildContext context) {
    final device = widgetData.device;

    // Determine device on/off from its toggle widget (if any), so we can gray out icon
    // Find toggle for the same device as widgetData.device
    final toggleWidget = device.widgets
        .where((w) => w.status == 'include')
        .cast<DeviceWidget?>()
        .firstWhere(
          (w) => w != null && w!.capability.type.name == 'toggle',
          orElse: () => null,
        );

    final bool isOn = toggleWidget == null ? true : toggleWidget.value >= 1;

    // Enable rule:
    // - if device is on -> enabled
    // - if device is off -> only enable toggle widget
    final bool enabled = isOn || widgetData.capability.type.name == 'toggle';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: icon + device name
          Row(
            children: [
              Icon(
                _iconForType(device.type),
                size: 30,
                color: isOn ? const Color(0xFF3AA7FF) : const Color(0xFFB0BEC5),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Exactly ONE control
          CapabilityControl(
            widgetData: widgetData,
            enabled: enabled,
            onToggle: onToggle,
            onValue: onValue,
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'light':
        return Icons.lightbulb_outline_rounded;
      case 'speaker':
        return Icons.speaker_outlined;
      case 'air conditioner':
        return Icons.ac_unit;
      default:
        return Icons.devices_other;
    }
  }
}
