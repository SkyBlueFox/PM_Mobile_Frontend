// lib/features/home/ui/pages/sensor_detail_page.dart

import 'package:flutter/material.dart';

class SensorDetailPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String valueText;

  const SensorDetailPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    // ตอนนี้ทำเป็น UI placeholder ให้เหมือนในรูป (กราฟ/ตาราง log ใส่ทีหลังได้)
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

            // fake chart card
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
