// lib/features/home/ui/pages/sensor_detail_page.dart
//
// ✅ เวอร์ชัน “ทำงานสมบูรณ์” (กราฟ + log + heartbeat online/offline)
// - ใช้ SensorDetailBloc โหลด: history + logs + heartbeat
// - เริ่ม polling ตอนเข้า และหยุดตอนออก
// - แสดง:
//   1) ค่า current + unit
//   2) Heartbeat online/offline + last heartbeat time
//   3) กราฟ (Mini line chart) จาก history
//   4) Logs (newest first)
//
// ข้อกำหนด:
// - หน้า detail ไม่พึ่ง polling ของ Home (กันข้อมูลกระพริบ/ชน state)
// - Repo ถูกดึงจาก DevicesBloc ที่ถูก provide อยู่แล้วในต้นไม้ widget

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/devices_bloc.dart';
import '../../models/device_widget.dart';
import '../../models/sensor_history.dart';
import '../../models/sensor_log.dart';

import '../../bloc/sensor_detail_bloc.dart';
import '../../bloc/sensor_detail_event.dart';
import '../../bloc/sensor_detail_state.dart';

class SensorDetailPage extends StatefulWidget {
  final DeviceWidget sensorWidget;

  const SensorDetailPage({
    super.key,
    required this.sensorWidget,
  });

  @override
  State<SensorDetailPage> createState() => _SensorDetailPageState();
}

class _SensorDetailPageState extends State<SensorDetailPage> {
  late final SensorDetailBloc _bloc;

  @override
  void initState() {
    super.initState();

    // ✅ ดึง repo จาก DevicesBloc (มีอยู่แล้วใน main.dart)
    final devicesBloc = context.read<DevicesBloc>();

    _bloc = SensorDetailBloc(
      widgetRepo: devicesBloc.widgetRepo,
      deviceRepo: devicesBloc.deviceRepo,
      onlineThreshold: const Duration(seconds: 20),
    );

    final dw = widget.sensorWidget;

    // ✅ เริ่มโหลดข้อมูล
    _bloc.add(SensorDetailStarted(
      widgetId: dw.widgetId,
      deviceId: dw.device.id, // ต้องเป็น String ใน Device model
      unit: dw.capability.unit, // ✅ ได้จาก Capability getter ที่คุณเพิ่มแล้ว
    ));

    // ✅ polling เพื่อ refresh history/log/heartbeat
    _bloc.add(const SensorDetailPollingStarted(interval: Duration(seconds: 5)));
  }

  @override
  void dispose() {
    // ✅ หยุด polling + ปิด bloc
    _bloc.add(const SensorDetailPollingStopped());
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dw = widget.sensorWidget;
    final title = dw.device.name.trim().isEmpty ? 'Sensor' : dw.device.name;

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              tooltip: 'รีเฟรช',
              onPressed: () => _bloc.add(const SensorDetailRefreshRequested()),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: BlocBuilder<SensorDetailBloc, SensorDetailState>(
          // ลด rebuild ที่ไม่จำเป็น
          buildWhen: (p, c) =>
              p.isLoading != c.isLoading ||
              p.isRefreshing != c.isRefreshing ||
              p.error != c.error ||
              p.currentValue != c.currentValue ||
              p.unit != c.unit ||
              p.isOnline != c.isOnline ||
              p.lastHeartbeatAt != c.lastHeartbeatAt ||
              p.history != c.history ||
              p.logs != c.logs ||
              p.from != c.from ||
              p.to != c.to,
          builder: (context, st) {
            if (st.isLoading && st.history.isEmpty && st.logs.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // ใช้ชื่อ capability ถ้ามี (คุณเพิ่ม getter name แล้ว)
            final capName = dw.capability.name.trim().isEmpty ? 'sensor' : dw.capability.name;

            return RefreshIndicator(
              onRefresh: () async {
                _bloc.add(const SensorDetailRefreshRequested());
                // หน่วงนิดเพื่อให้ indicator มีโอกาสแสดง (กัน flicker)
                await Future.delayed(const Duration(milliseconds: 350));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                children: [
                  if (st.error != null) ...[
                    _ErrorBanner(message: st.error!),
                    const SizedBox(height: 10),
                  ],

                  // ===== Summary card (ค่า + heartbeat) =====
                  _Card(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT: title/value/unit/range
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                capName,
                                style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    st.currentValue.trim().isEmpty ? '-' : st.currentValue,
                                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(width: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      st.unit.trim().isEmpty ? '' : st.unit,
                                      style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'ช่วงเวลา: ${_fmtShort(st.from)} - ${_fmtShort(st.to)}',
                                style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),

                        // RIGHT: online pill + last heartbeat + refreshing indicator
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _OnlinePill(isOnline: st.isOnline),
                            const SizedBox(height: 8),
                            Text(
                              st.lastHeartbeatAt == null ? 'last: -' : 'last: ${_fmtTime(st.lastHeartbeatAt!)}',
                              style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w700),
                            ),
                            if (st.isRefreshing) ...[
                              const SizedBox(height: 8),
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===== Chart =====
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Graph', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 220,
                          width: double.infinity,
                          child: st.history.isEmpty
                              ? const Center(child: Text('No history', style: TextStyle(color: Colors.black45)))
                              : _MiniLineChart(points: st.history),
                        ),
                        const SizedBox(height: 10),
                        _RangeRow(
                          from: st.from,
                          to: st.to,
                          onPick24h: () {
                            final now = DateTime.now();
                            _bloc.add(SensorRangeChanged(from: now.subtract(const Duration(hours: 24)), to: now));
                          },
                          onPick7d: () {
                            final now = DateTime.now();
                            _bloc.add(SensorRangeChanged(from: now.subtract(const Duration(days: 7)), to: now));
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===== Logs =====
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Log (${st.logs.length})', style: const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        if (st.logs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: Text('No logs', style: TextStyle(color: Colors.black45))),
                          )
                        else
                          Column(
                            children: st.logs.take(50).map((SensorLogEntry e) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _LogRow(
                                  timestamp: e.timestamp,
                                  title: e.title,
                                  detail: e.detail,
                                  value: e.value,
                                  unit: st.unit,
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ===============================
// UI Helpers
// ===============================

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x22FF0000)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _OnlinePill extends StatelessWidget {
  final bool isOnline;
  const _OnlinePill({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final text = isOnline ? 'ONLINE' : 'OFFLINE';
    final bg = isOnline ? const Color(0xFFE8FFF2) : const Color(0xFFFFF1F1);
    final fg = isOnline ? const Color(0xFF1C9B5E) : const Color(0xFFD64545);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

class _RangeRow extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final VoidCallback onPick24h;
  final VoidCallback onPick7d;

  const _RangeRow({
    required this.from,
    required this.to,
    required this.onPick24h,
    required this.onPick7d,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ChipButton(label: '24h', onTap: onPick24h),
        const SizedBox(width: 8),
        _ChipButton(label: '7d', onTap: onPick7d),
        const Spacer(),
        Text(
          '${_fmtShort(from)} - ${_fmtShort(to)}',
          style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ChipButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F6FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x1100A3FF)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3AA7FF)),
        ),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final DateTime timestamp;
  final String title;
  final String detail;
  final String? value;
  final String unit;

  const _LogRow({
    required this.timestamp,
    required this.title,
    required this.detail,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final v = (value == null || value!.trim().isEmpty) ? '' : value!;
    final vu = (v.isEmpty || unit.trim().isEmpty) ? v : '$v$unit';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(
            _fmtTime(timestamp),
            style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              if (detail.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(detail, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
        if (vu.trim().isNotEmpty)
          Text(vu, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3AA7FF))),
      ],
    );
  }
}

// ===============================
// Mini chart (simple & stable)
// ===============================
class _MiniLineChart extends StatelessWidget {
  final List<SensorHistoryPoint> points;
  const _MiniLineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniLineChartPainter(points),
    );
  }
}

class _MiniLineChartPainter extends CustomPainter {
  final List<SensorHistoryPoint> points;
  _MiniLineChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // extract numeric values
    final values = <double>[];
    for (final p in points) {
      final raw = p.value;
      final v = (raw is num) ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0.0;
      values.add(v);
    }

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);

    final paintLine = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF3AA7FF);

    final paintGrid = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..color = const Color(0x11000000);

    // grid
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    // line path
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = (values.length == 1) ? 0.0 : (size.width * i / (values.length - 1));
      final yNorm = (values[i] - minV) / range;
      final y = size.height * (1.0 - yNorm);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant _MiniLineChartPainter oldDelegate) {
    // repaint เมื่อจำนวนจุด/ค่าต่างกัน (พอสำหรับกราฟเล็ก)
    if (oldDelegate.points.length != points.length) return true;
    if (points.isEmpty) return false;
    // เช็คจุดท้ายสุดพอ (ลด cost)
    final a = oldDelegate.points.last;
    final b = points.last;
    return a.timestamp != b.timestamp || a.value != b.value;
  }
}

// ===============================
// Format helpers (no intl dependency)
// ===============================
String _two(int n) => n < 10 ? '0$n' : '$n';

String _fmtTime(DateTime dt) => '${_two(dt.hour)}:${_two(dt.minute)}:${_two(dt.second)}';

String _fmtShort(DateTime dt) => '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';