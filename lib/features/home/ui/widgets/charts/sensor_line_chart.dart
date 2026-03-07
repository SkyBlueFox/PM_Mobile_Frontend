import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/sensor_log.dart';

class SensorLineChartFl extends StatelessWidget {
  final List<SensorLogEntry> points;
  final String unit;
  final String period; // hour | day | week

  const SensorLineChartFl({
    super.key,
    required this.points,
    required this.unit,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(
          child: Text('ยังไม่มีข้อมูล'),
        ),
      );
    }

    final sorted = [...points]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final baseMs = sorted.first.timestamp.millisecondsSinceEpoch;

    final spots = sorted.map((p) {
      final xSec = (p.timestamp.millisecondsSinceEpoch - baseMs) / 1000.0;
      return FlSpot(xSec, p.value);
    }).toList();

    if (spots.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(
          child: Text('ยังไม่มีข้อมูลในช่วงนี้'),
        ),
      );
    }

    var minX = 0.0;
    var maxX = spots.last.x;

    if ((maxX - minX).abs() < 0.000001) {
      maxX = minX + 60;
    }

    final ys = spots.map((e) => e.y).toList();

    double minY = ys.reduce((a, b) => a < b ? a : b);
    double maxY = ys.reduce((a, b) => a > b ? a : b);

    if ((maxY - minY).abs() < 0.0001) {
      minY -= 1;
      maxY += 1;
    }

    final span = maxY - minY;
    final padding = span * 0.12;

    final chartMinY = minY - padding;
    final chartMaxY = maxY + padding;
    final chartSpanY = chartMaxY - chartMinY;

    // ✅ 5 levels = 4 gaps
    final yInterval = chartSpanY / 4;

    return Padding(
      padding: const EdgeInsets.only(top: 12, right: 12),
      child: SizedBox(
        height: 240,
        child: LineChart(
          LineChartData(
            minX: minX,
            maxX: maxX,
            minY: chartMinY,
            maxY: chartMaxY,
            clipData: const FlClipData.all(),
            gridData: FlGridData(
            show: true,
            horizontalInterval: yInterval,
            verticalInterval: _intervalX(maxX),
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0x22000000),
              strokeWidth: 1,
              dashArray: [6, 4],
            ),
            getDrawingVerticalLine: (_) => const FlLine(
              color: Color(0x22000000),
              strokeWidth: 1,
              dashArray: [6, 4],
            ),
          ),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                left: BorderSide(color: Color(0xFF777777), width: 1),
                bottom: BorderSide(color: Color(0xFF777777), width: 1),
                top: BorderSide(color: Color(0x22000000), width: 1),
                right: BorderSide(color: Color(0x22000000), width: 1),
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      _formatY(value, yInterval),
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: _intervalX(maxX),
                  getTitlesWidget: (v, meta) {
                    final dt = DateTime.fromMillisecondsSinceEpoch(
                      baseMs + (v * 1000).round(),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _formatBottom(dt),
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touched) {
                  return touched.map((ts) {
                    final dt = DateTime.fromMillisecondsSinceEpoch(
                      baseMs + (ts.x * 1000).round(),
                    );
                    return LineTooltipItem(
                      '${_formatTooltipTime(dt)}\n${ts.y.toStringAsFixed(2)}$unit',
                      const TextStyle(fontWeight: FontWeight.w800),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: spots.length > 1,
                barWidth: 2,
                isStrokeCapRound: true,
                color: const Color(0xFF00BCD4),
                dotData: FlDotData(
                  show: spots.length == 1,
                ),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _intervalX(double maxX) {
    switch (period) {
      case 'hour':
        return 10 * 60; // 10 นาที
      case 'day':
        return 3 * 60 * 60; // 3 ชั่วโมง
      case 'week':
        return 24 * 60 * 60; // 1 วัน
      default:
        if (maxX <= 3600) return 10 * 60;
        if (maxX <= 24 * 3600) return 3 * 60 * 60;
        return 24 * 60 * 60;
    }
  }

  String _formatBottom(DateTime dt) {
    switch (period) {
      case 'hour':
        return DateFormat('HH:mm').format(dt);
      case 'day':
        return DateFormat('HH น.').format(dt);
      case 'week':
        return DateFormat('dd/MM').format(dt);
      default:
        return DateFormat('HH:mm').format(dt);
    }
  }

  String _formatTooltipTime(DateTime dt) {
    switch (period) {
      case 'hour':
        return DateFormat('HH:mm:ss').format(dt);
      case 'day':
        return DateFormat('dd/MM HH:mm').format(dt);
      case 'week':
        return DateFormat('dd/MM HH:mm').format(dt);
      default:
        return DateFormat('HH:mm:ss').format(dt);
    }
  }

  String _formatY(double v, double interval) {
    if (interval >= 5) return v.toStringAsFixed(0);
    if (interval >= 1) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }
}