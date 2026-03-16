import 'package:flutter/material.dart';

import '../../../../../models/sensor_log.dart';

class SensorLogTable extends StatelessWidget {
  final List<SensorLogEntry> logs;
  final String unitFallback;
  final String title;
  final String emptyText;
  final String period;

  const SensorLogTable({
    super.key,
    required this.logs,
    this.unitFallback = '',
    this.title = 'บันทึก',
    this.emptyText = 'ยังไม่มีบันทึก',
    this.period = '',
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Container(
        width: double.infinity,
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
      width: double.infinity,
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

          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    period == 'week' ? 'วันที่' : 'เวลา',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF8AA9BF),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'ค่า',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF8AA9BF),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          ...List.generate(display.length, (index) {
            final e = display[index];
            final timeText = _fmtTime(e.timestamp);
            final valueText = _fmtValue(e.value);

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                border: index == display.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(
                          color: Color(0xFFF1F4F8),
                          width: 1,
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      timeText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0E3A5A),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      valueText,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0E3A5A),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
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
    if (period == 'week') {
      final dd = _two(dt.day);
      final mm = _two(dt.month);
      return '$dd/$mm';
    }

    final hh = _two(dt.hour);
    final mm = _two(dt.minute);
    final ss = _two(dt.second);

    if(period == 'day') {
      return '$hh:$mm';
    }
     
    return '$hh:$mm:$ss';
  }
}