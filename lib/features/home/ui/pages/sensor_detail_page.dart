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
    // ❗️หลีกเลี่ยงตั้งชื่อตัวแปรว่า `widget` เพราะชนกับคำที่ Flutter ใช้บ่อย
    final dw = sensorWidget;
    final device = dw.device;

    // ✅ ป้องกัน crash ถ้า name เป็นค่าว่าง/ไม่มี
    final title = (device.name).trim().isEmpty ? 'Sensor' : device.name;

    // ✅ ถ้ามี capability name ในโมเดลของคุณให้ใช้จริง (ตัวอย่าง)
    // final subtitle = dw.capability?.name ?? 'sensor';
    final subtitle = 'sensor';

    // ✅ กัน null/ชนิดแปลก
    final valueText = (dw.value == null) ? '-' : dw.value.toString();

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
            Text(
              valueText,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),

            // TODO: คุณสามารถเอา history/log มา plot กราฟได้
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
            const SizedBox(height: 10),

            Text(
              'Widget value: ${dw.value ?? '-'}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
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