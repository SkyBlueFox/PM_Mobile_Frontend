import 'package:flutter/material.dart';
import '../../models/device_widget.dart';
import 'capability_control.dart';

class WidgetCard extends StatefulWidget {
  final DeviceWidget widgetData;

  /// Provided by parent (computed from state.widgets)
  final bool isOn;

  final ValueChanged<int>? onToggle;
  final void Function(int widgetId, double value)? onValue;

  const WidgetCard({
    super.key,
    required this.widgetData,
    required this.isOn,
    this.onToggle,
    this.onValue,
  });

  @override
  State<WidgetCard> createState() => _WidgetCardState();
}

class _WidgetCardState extends State<WidgetCard> {
  @override
  Widget build(BuildContext context) {
    final device = widget.widgetData.device;

    final bool enabled = widget.isOn || widget.widgetData.capability.id == 1; // id 1 = toggle

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
          Row(
            children: [
              Icon(
                _iconForType(device.type),
                size: 30,
                color: widget.isOn ? const Color(0xFF3AA7FF) : const Color(0xFFB0BEC5),
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
          CapabilityControl(
            widgetData: widget.widgetData,
            enabled: enabled,
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