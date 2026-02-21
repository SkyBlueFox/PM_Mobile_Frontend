// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import '../../bloc/devices_bloc.dart';
// import '../../bloc/devices_event.dart';
// import '../../models/device_widget.dart';
// import 'rows/info_row.dart';
// import 'rows/adjust_row.dart';
// import 'rows/toggle_row.dart';
// import 'rows/press_row.dart';

// class CapabilityControl extends StatefulWidget {
//   final DeviceWidget widgetData;
//   final bool enabled;

//   const CapabilityControl({
//     super.key,
//     required this.widgetData,
//     required this.enabled,
//   });

//   @override
//   State<CapabilityControl> createState() => _CapabilityControlState();
// }

// class _CapabilityControlState extends State<CapabilityControl> {
//   DeviceWidget get widgetData => widget.widgetData;
//   bool get enabled => widget.enabled;

//   bool _pressBusy = false;

//   String _pressLabel(DeviceWidget w) {
//     // ถ้ามีชื่อ capability/device ที่สื่อว่าเป็นกริ่ง ให้ใช้คำที่เข้าใจง่าย
//     final name = (w.device.name).toLowerCase();
//     if (name.contains('bell') || name.contains('ring') || name.contains('กริ่ง')) {
//       return 'Doorbell';
//     }
//     return 'Press';
//   }

//   String _pressSubtitle(DeviceWidget w) {
//     final name = (w.device.name).toLowerCase();
//     if (name.contains('bell') || name.contains('ring') || name.contains('กริ่ง')) {
//       return 'กดเพื่อกริ่ง';
//     }
//     return 'กดเพื่อสั่งงาน';
//   }

//   String _pressButtonText(DeviceWidget w) {
//     final name = (w.device.name).toLowerCase();
//     if (name.contains('bell') || name.contains('ring') || name.contains('กริ่ง')) {
//       return 'Ring';
//     }
//     return 'กด';
//   }

//   IconData _pressIcon(DeviceWidget w) {
//     final name = (w.device.name).toLowerCase();
//     if (name.contains('bell') || name.contains('ring') || name.contains('กริ่ง')) {
//       return Icons.notifications_active_rounded;
//     }
//     return Icons.touch_app_rounded;
//   }

//   Future<void> _sendPress(DeviceWidget w) async {
//     if (!enabled || _pressBusy) return;

//     setState(() => _pressBusy = true);

//     // ใช้ WidgetValueChanged เพื่อส่งคำสั่งแบบ momentary
//     // (กด = 1 แล้วปล่อยกลับเป็น 0)
//     context.read<DevicesBloc>().add(WidgetValueChanged(w.widgetId, 1.0));

//     await Future.delayed(const Duration(milliseconds: 200));
//     if (!mounted) return;

//     context.read<DevicesBloc>().add(WidgetValueChanged(w.widgetId, 0.0));

//     if (mounted) {
//       setState(() => _pressBusy = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final doubleValue = double.tryParse(widgetData.value);
//     final int intValue = doubleValue?.round() ?? 0;

//     switch (widgetData.capability.id) {
//       case 1: // toggle
//         return ToggleRow(
//           label: 'Power',
//           isOn: intValue >= 1,
//           enabled: true, // always allow toggling
//           onChanged: () {
//             context.read<DevicesBloc>().add(WidgetToggled(widgetData.widgetId));
//           },
//         );

//       case 2: // adjust
//         return AdjustRow(
//           label: 'Adjust',
//           value: intValue,
//           min: 0,
//           max: 100,
//           enabled: enabled,
//           onChanged: !enabled
//               ? null
//               : (v) {
//                   context
//                       .read<DevicesBloc>()
//                       .add(WidgetValueChanged(widgetData.widgetId, v.toDouble()));
//                 },
//         );

//       case 3: // info (read-only)
//         return InfoRow(
//           label: 'Info',
//           valueText: widgetData.value.toString(),
//           enabled: enabled,
//         );

//       case 4: // press (button) เช่น กดกริ่ง
//         return PressRow(
//           label: _pressLabel(widgetData),
//           subtitle: _pressSubtitle(widgetData),
//           enabled: enabled,
//           busy: _pressBusy,
//           buttonText: _pressButtonText(widgetData),
//           icon: _pressIcon(widgetData),
//           onPressed: enabled ? () => _sendPress(widgetData) : null,
//         );

//       default:
//         return Text(
//           'capability_id=${widgetData.capability.id} value=${widgetData.value}',
//           style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w600),
//         );
//     }
//   }
// }
