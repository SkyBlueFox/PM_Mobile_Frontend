import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/sensor_history.dart'; // <-- ปรับ path ให้ถูก

class SensorLineChartFl extends StatelessWidget {
  final List<SensorHistoryPoint> points;
  final String unit;
  final Duration? range;

  const SensorLineChartFl({
    super.key,
    required this.points,
    required this.unit,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox(height: 240);

    final sorted = [...points]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final end = sorted.last.timestamp;

    final start = range == null ? sorted.first.timestamp : end.subtract(range!);

    final baseMs = start.millisecondsSinceEpoch;

    final spots = sorted
        .where((p) => !p.timestamp.isBefore(start) && !p.timestamp.isAfter(end)) // กันหลุดช่วง
        .map((p) {
          final xSec = (p.timestamp.millisecondsSinceEpoch - baseMs) / 1000.0;
          return FlSpot(xSec, p.value);
        })
        .toList();

    final minX = 0.0;
    final maxX = range == null
        ? ((end.millisecondsSinceEpoch - baseMs) / 1000.0)
        : range!.inSeconds.toDouble();

    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _pickTimeIntervalSec(minX, maxX),
                getTitlesWidget: (v, meta) {
                  final dt = DateTime.fromMillisecondsSinceEpoch(
                    baseMs + (v * 1000).round(),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(DateFormat('HH:mm').format(dt)),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touched) => touched.map((ts) {
                final dt = DateTime.fromMillisecondsSinceEpoch(
                  baseMs + (ts.x * 1000).round(),
                );
                return LineTooltipItem(
                  '${DateFormat('HH:mm:ss').format(dt)}\n${ts.y.toStringAsFixed(2)}$unit',
                  const TextStyle(fontWeight: FontWeight.w800),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  double _pickTimeIntervalSec(double minX, double maxX) {
    final rangeSec = maxX - minX;
    if (rangeSec <= 60 * 60) return 10 * 60;
    if (rangeSec <= 6 * 60 * 60) return 60 * 60;
    if (rangeSec <= 24 * 60 * 60) return 3 * 60 * 60;
    return 12 * 60 * 60;
  }
}