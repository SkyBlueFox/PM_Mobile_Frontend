import 'package:flutter/material.dart';
import '../../models/device.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onToggle;
  final ValueChanged<double>? onValueChanged;

  const DeviceCard({
    super.key,
    required this.device,
    this.onToggle,
    this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isToggleable = device is Toggleable;
    final isQuantifiable = device is Quantifiable;

    final bool isOn = isToggleable ? (device as Toggleable).isOn : false;
    final iconColor = isOn ? const Color(0xFF3AA7FF) : const Color(0xFFB0BEC5);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // ---------- LEFT: icon + text ----------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // top row: icon + switch (ย้าย switch ขึ้นบน)
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, size: 30, color: iconColor),
                    const Spacer(),
                    if (isToggleable)
                      Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: isOn,
                          onChanged: onToggle == null ? null : (_) => onToggle!(),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  roomLabel(device.room),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w600),
                ),

                const Spacer(), // ✅ ดันข้อความขึ้นให้สมดุล
              ],
            ),
          ),

          // ---------- RIGHT: vertical quantity ----------
          if (isQuantifiable && onValueChanged != null) ...[
            const SizedBox(width: 8),
            _VerticalValueBar(
              device: device as Quantifiable,
              enabled: isOn, // ปิดแล้ว disable
              onChanged: onValueChanged!,
            ),
          ],
        ],
      ),
    );
  }
}

class _VerticalValueBar extends StatelessWidget {
  final Quantifiable device;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _VerticalValueBar({
    required this.device,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final v = device.value.clamp(device.minValue, device.maxValue).toDouble();

    return SizedBox(
      width: 34,
      child: Column(
        children: [
          Text(
            '${v.toStringAsFixed(0)}${device.unit}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),

          // Slider แนวตั้ง (ใช้หมุน)
          Expanded(
            child: RotatedBox(
              quarterTurns: -1,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 6),
                ),
                child: Slider(
                  value: v,
                  min: device.minValue,
                  max: device.maxValue,
                  onChanged: enabled ? onChanged : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
