// lib/features/home/ui/widgets/charts/sensor_line_chart.dart
//
// ✅ กราฟเส้นแบบไม่พึ่ง package ภายนอก + ปรับตาม requirement
// - รองรับจำกัดจำนวนจุด (maxPoints) เพื่อให้กราฟสวยขึ้นเมื่อช่วงยาว
// - แสดงเวลาเป็นไทย/24 ชม. (HH:mm หรือ HH:mm:ss) แทน AM/PM
// - tooltip: "เวลา • ค่า" (มี unit ได้)
// - มี empty state เป็นไทยได้
//
// หมายเหตุ:
// - widget นี้เป็น UI ล้วน (ไม่ผูก repo/bloc)

import 'package:flutter/material.dart';

import '../../../models/sensor_history.dart';

enum TimeLabelMode {
  hm24, // HH:mm
  hms24, // HH:mm:ss
}

class SensorLineChart extends StatefulWidget {
  final List<SensorHistoryPoint> points;

  /// ค่าที่แสดงด้านบน เช่น "24.5°C"
  final String headerValueText;

  /// label ใต้ค่า เช่น "ค่าปัจจุบัน"
  final String headerSubtitle;

  /// จำกัดจำนวนจุด (ทำให้กราฟไม่แน่นเมื่อช่วงยาว)
  final int maxPoints;

  /// รูปแบบเวลาใต้กราฟ/tooltip
  final TimeLabelMode timeLabelMode;

  /// unit สำหรับ tooltip (ถ้าอยากแสดงค่า+หน่วย)
  final String tooltipUnit;

  /// ข้อความตอนยังไม่มีข้อมูล
  final String emptyText;

  const SensorLineChart({
    super.key,
    required this.points,
    required this.headerValueText,
    required this.headerSubtitle,
    this.maxPoints = 160,
    this.timeLabelMode = TimeLabelMode.hm24,
    this.tooltipUnit = '',
    this.emptyText = 'ยังไม่มีข้อมูล',
  });

  @override
  State<SensorLineChart> createState() => _SensorLineChartState();
}

class _SensorLineChartState extends State<SensorLineChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    // ✅ downsample ให้กราฟสวย + ไม่หนัก
    final pts = _downsampleSorted(widget.points, widget.maxPoints);

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
          Text(
            widget.headerSubtitle,
            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF5E87A3)),
          ),
          const SizedBox(height: 6),
          Text(
            widget.headerValueText.trim().isEmpty ? '-' : widget.headerValueText,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF3AA7FF)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            width: double.infinity,
            child: pts.isEmpty
                ? Center(
                    child: Text(
                      widget.emptyText,
                      style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w700),
                    ),
                  )
                : GestureDetector(
                    onTapDown: (d) {
                      if (pts.isEmpty) return;
                      final box = context.findRenderObject() as RenderBox?;
                      if (box == null) return;

                      final local = box.globalToLocal(d.globalPosition);
                      final idx = _nearestIndexByX(local.dx, pts, box.size.width);
                      setState(() => _selectedIndex = idx);
                    },
                    child: CustomPaint(
                      painter: _LineChartPainter(
                        points: pts,
                        selectedIndex: _selectedIndex,
                      ),
                    ),
                  ),
          ),
          if (pts.isNotEmpty) ...[
            const SizedBox(height: 10),
            _axisHintRow(pts, _selectedIndex),
          ],
        ],
      ),
    );
  }

  List<SensorHistoryPoint> _downsampleSorted(List<SensorHistoryPoint> input, int maxPoints) {
    if (input.isEmpty) return const [];

    // ensure sorted ascending by time
    final pts = List<SensorHistoryPoint>.from(input)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (maxPoints <= 1 || pts.length <= maxPoints) return pts;

    // เลือกทุก step เพื่อให้เหลือ ~maxPoints
    final step = (pts.length / maxPoints).ceil();
    final out = <SensorHistoryPoint>[];
    for (int i = 0; i < pts.length; i += step) {
      out.add(pts[i]);
    }
    // ให้มีจุดสุดท้ายเสมอ เพื่อสเกลแกนถูก
    if (out.isNotEmpty && out.last.timestamp != pts.last.timestamp) {
      out.add(pts.last);
    }
    return out;
  }

  int _nearestIndexByX(double x, List<SensorHistoryPoint> pts, double width) {
    if (pts.length == 1) return 0;

    final minT = pts.first.timestamp.millisecondsSinceEpoch.toDouble();
    final maxT = pts.last.timestamp.millisecondsSinceEpoch.toDouble();
    final span = (maxT - minT).abs() < 1 ? 1.0 : (maxT - minT);

    double bestDist = double.infinity;
    int bestIdx = 0;

    for (int i = 0; i < pts.length; i++) {
      final t = pts[i].timestamp.millisecondsSinceEpoch.toDouble();
      final nx = (t - minT) / span;
      final px = nx * width;
      final dist = (px - x).abs();
      if (dist < bestDist) {
        bestDist = dist;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  Widget _axisHintRow(List<SensorHistoryPoint> pts, int? selected) {
    final left = _fmtTime(pts.first.timestamp);
    final right = _fmtTime(pts.last.timestamp);

    String? mid;
    if (selected != null && selected >= 0 && selected < pts.length) {
      final p = pts[selected];
      final v = p.value.toString();
      final u = widget.tooltipUnit.trim();
      final vu = u.isEmpty ? v : '$v$u';
      mid = '${_fmtTime(p.timestamp)} • $vu';
    }

    return Row(
      children: [
        Text(left, style: const TextStyle(color: Color(0xFF8AA9BF), fontWeight: FontWeight.w700)),
        const Spacer(),
        if (mid != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F6FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              mid,
              style: const TextStyle(color: Color(0xFF3AA7FF), fontWeight: FontWeight.w900),
            ),
          ),
        const Spacer(),
        Text(right, style: const TextStyle(color: Color(0xFF8AA9BF), fontWeight: FontWeight.w700)),
      ],
    );
  }

  String _two(int n) => n < 10 ? '0$n' : '$n';

  String _fmtTime(DateTime dt) {
    // ✅ เน้นไทย: แสดงแบบ 24 ชั่วโมง
    final hh = _two(dt.hour);
    final mm = _two(dt.minute);
    final ss = _two(dt.second);

    switch (widget.timeLabelMode) {
      case TimeLabelMode.hm24:
        return '$hh:$mm';
      case TimeLabelMode.hms24:
        return '$hh:$mm:$ss';
    }
  }
}

class _LineChartPainter extends CustomPainter {
  final List<SensorHistoryPoint> points;
  final int? selectedIndex;

  _LineChartPainter({
    required this.points,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // พื้นหลัง + กรอบนุ่ม ๆ
    final rect = Offset.zero & size;

    final bg = Paint()..color = const Color(0xFFF7FBFF);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)), bg);

    if (points.isEmpty) return;
    if (points.length == 1) {
      _drawSinglePoint(canvas, size);
      return;
    }

    // คำนวณช่วง x/y
    final minT = points.first.timestamp.millisecondsSinceEpoch.toDouble();
    final maxT = points.last.timestamp.millisecondsSinceEpoch.toDouble();
    final tSpan = (maxT - minT).abs() < 1 ? 1.0 : (maxT - minT);

    double minY = points.first.value;
    double maxY = points.first.value;
    for (final p in points) {
      if (p.value < minY) minY = p.value;
      if (p.value > maxY) maxY = p.value;
    }

    // กันกรณีค่าเท่ากันหมด
    final ySpan = (maxY - minY).abs() < 0.000001 ? 1.0 : (maxY - minY);

    // paddings
    const pad = 14.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    Offset mapPoint(SensorHistoryPoint p) {
      final t = p.timestamp.millisecondsSinceEpoch.toDouble();
      final nx = (t - minT) / tSpan;
      final ny = (p.value - minY) / ySpan;

      final x = pad + nx * w;
      final y = pad + (1 - ny) * h;
      return Offset(x, y);
    }

    // grid (เบา ๆ)
    final paintGrid = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..color = const Color(0x11000000);

    for (int i = 1; i <= 3; i++) {
      final y = pad + (h * (i / 4.0));
      canvas.drawLine(Offset(pad, y), Offset(pad + w, y), paintGrid);
    }

    // เส้นกราฟ
    final line = Paint()
      ..color = const Color(0xFF3AA7FF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final o = mapPoint(points[i]);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }

    // เติม area ใต้กราฟแบบจาง ๆ
    final fill = Paint()
      ..color = const Color(0x223AA7FF)
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path)
      ..lineTo(pad + w, pad + h)
      ..lineTo(pad, pad + h)
      ..close();

    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, line);

    // วาดจุดเลือก (selected)
    final idx = selectedIndex;
    if (idx != null && idx >= 0 && idx < points.length) {
      final o = mapPoint(points[idx]);

      final dotOuter = Paint()..color = const Color(0xFF3AA7FF);
      final dotInner = Paint()..color = Colors.white;

      canvas.drawCircle(o, 6.0, dotOuter);
      canvas.drawCircle(o, 3.0, dotInner);
    }
  }

  void _drawSinglePoint(Canvas canvas, Size size) {
    final dotOuter = Paint()..color = const Color(0xFF3AA7FF);
    final dotInner = Paint()..color = Colors.white;

    final o = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(o, 7.0, dotOuter);
    canvas.drawCircle(o, 3.5, dotInner);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.selectedIndex != selectedIndex;
  }
}