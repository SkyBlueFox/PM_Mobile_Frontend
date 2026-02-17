import 'package:flutter/material.dart';
import '../../models/device_widget.dart';

class SensorDetailPage extends StatelessWidget {
  final DeviceWidget sensorWidget;

  const SensorDetailPage({
    super.key,
    required this.sensorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final widget = sensorWidget;
    final device = sensorWidget.device;
    final title = device.name; // ปรับ field ตาม Device ของคุณ
    final subtitle = 'cap';     // หรือ sensorWidget.capability.name ถ้ามี

    // ค่าปัจจุบันของ sensor (เช่น heartbeat/sensor value)
    final valueText = sensorWidget.value.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 10),
            Text(valueText, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),

            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
                ],
              ),
              alignment: Alignment.center,
              child: const Text('Chart (TODO)', style: TextStyle(color: Colors.black45)),
            ),
            Text('Widget value: ${widget.value}', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            const Text('Log', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),

            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: const Center(
                child: Text('Log table (TODO)', style: TextStyle(color: Colors.black45)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
