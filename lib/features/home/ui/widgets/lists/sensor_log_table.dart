// lib/features/home/ui/widgets/lists/sensor_log_table.dart
//
// ตาราง log ของ sensor
// จุดสำคัญ:
// - ใช้ DataTable (ไม่ต้องพึ่ง package)
// - format เวลาให้อ่านง่าย
// - รองรับ empty state

import 'package:flutter/material.dart';

import '../../../models/sensor_log.dart';

class SensorLogTable extends StatelessWidget {
  final List<SensorLogEntry> logs;

  const SensorLogTable({
    super.key,
    required this.logs,
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
        child: const Center(
          child: Text(
            'No logs',
            style: TextStyle(color: Color(0xFF5E87A3), fontWeight: FontWeight.w800),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF8AA9BF),
          ),
          dataTextStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0E3A5A),
          ),
          columns: const [
            DataColumn(label: Text('DATE')),
            DataColumn(label: Text('VALUE')),
          ],
          rows: logs.map((e) {
            final dateText = _fmtDateTime(e.timestamp);
            final valueText = e.unit.trim().isEmpty ? e.value : '${e.value}${e.unit}';

            return DataRow(
              cells: [
                DataCell(Text(dateText)),
                DataCell(Text(valueText)),
              ],
            );
          }).toList(growable: false),
        ),
      ),
    );
  }

  /// format แบบอ่านง่ายให้คล้าย mock: "5:00 PM"
  static String _fmtDateTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';

    final day = dt.day.toString().padLeft(2, '0');
    final mon = dt.month.toString().padLeft(2, '0');
    final yr = dt.year.toString();

    return '$day/$mon/$yr  $h:$m $ap';
  }
}