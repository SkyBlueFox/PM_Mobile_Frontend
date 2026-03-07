// lib/features/home/ui/widgets/lists/sensor_log_table.dart

import 'package:flutter/material.dart';

import '../../../models/sensor_log.dart';

enum LogTimeMode {
  hm24, // HH:mm
  hms24, // HH:mm:ss
}

class SensorLogTable extends StatelessWidget {
  final List<SensorLogEntry> logs;

  /// unit จาก capability
  final String unitFallback;

  final String title;
  final String emptyText;

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
            style: const TextStyle(
              color: Color(0xFF5E87A3),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    final display =
        logs.length > 50 ? logs.take(50).toList(growable: false) : logs;

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
              final valueText = _fmtValue(e.value);

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

  String _fmtValue(double v) {
    final unit = unitFallback.trim();
    final valueStr = v.toStringAsFixed(2);

    return unit.isEmpty ? valueStr : '$valueStr$unit';
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