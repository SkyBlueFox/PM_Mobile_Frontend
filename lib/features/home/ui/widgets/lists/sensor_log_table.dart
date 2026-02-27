// lib/features/home/ui/widgets/lists/sensor_log_table.dart
//
// ✅ ตาราง log ของ sensor (ปรับตาม requirement)
// - แสดง 2 คอลัมน์เท่านั้น: "เวลา" | "ค่า"
// - ไม่แสดง title/detail/message
// - เวลาให้สั้น (HH:mm:ss หรือ HH:mm)
// - รองรับ empty state เป็นไทย
//
// หมายเหตุ:
// - ไม่บังคับ scroll แนวนอน เพราะมีแค่ 2 คอลัมน์

import 'package:flutter/material.dart';

import '../../../models/sensor_log.dart';

enum LogTimeMode {
  hm24, // HH:mm
  hms24, // HH:mm:ss
}

class SensorLogTable extends StatelessWidget {
  final List<SensorLogEntry> logs;

  /// ถ้า log ไม่มี unit ให้ใช้ unitFallback แทน (จาก capability)
  final String unitFallback;

  /// หัวข้อการ์ด (เช่น "บันทึก (10)")
  final String title;

  /// ข้อความตอนไม่มี log
  final String emptyText;

  /// รูปแบบเวลาในตาราง
  final LogTimeMode timeMode;

  const SensorLogTable({
    super.key,
    required this.logs,
    this.unitFallback = '',
    this.title = 'บันทึก',
    this.emptyText = 'ยังไม่มีบันทึก',
    this.timeMode = LogTimeMode.hms24,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
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
        child: Center(
          child: Text(
            emptyText,
            style: const TextStyle(color: Color(0xFF5E87A3), fontWeight: FontWeight.w800),
          ),
        ),
      );
    }

    // จำกัดจำนวนแถวเพื่อความลื่น (เผื่อ logs ใหญ่)
    final display = logs.length > 50 ? logs.take(50).toList(growable: false) : logs;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          DataTable(
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF8AA9BF),
            ),
            dataTextStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0E3A5A),
            ),
            columns: const [
              DataColumn(label: Text('เวลา')),
              DataColumn(label: Text('ค่า')),
            ],
            rows: display.map((e) {
              final timeText = _fmtTime(e.timestamp);
              final valueText = _fmtValue(e);

              return DataRow(
                cells: [
                  DataCell(Text(timeText)),
                  DataCell(Text(valueText)),
                ],
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }

  String _fmtValue(SensorLogEntry e) {
    final rawV = (e.value ?? '').trim();
    if (rawV.isEmpty) return '-';

    final u1 = e.unit.trim();
    final u2 = unitFallback.trim();
    final u = u1.isNotEmpty ? u1 : u2;
    return u.isEmpty ? rawV : '$rawV$u';
  }

  String _two(int n) => n < 10 ? '0$n' : '$n';

  String _fmtTime(DateTime dt) {
    final hh = _two(dt.hour);
    final mm = _two(dt.minute);
    final ss = _two(dt.second);

    switch (timeMode) {
      case LogTimeMode.hm24:
        return '$hh:$mm';
      case LogTimeMode.hms24:
        return '$hh:$mm:$ss';
    }
  }
}