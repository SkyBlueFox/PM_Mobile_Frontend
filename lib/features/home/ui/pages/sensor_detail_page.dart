// lib/features/home/ui/pages/sensor_detail_page.dart
//
// ✅ Refactor + UI ปรับตาม requirement (ไทย / กราฟสวย / log 2 คอลัมน์ / refresh ชัด)
// - แยกกราฟไปใช้ SensorLineChart (ไฟล์ widgets/charts/sensor_line_chart.dart)
// - แยก log ไปใช้ SensorLogTable (ไฟล์ widgets/lists/sensor_log_table.dart)
// - default ช่วงเวลา: 1 ชั่วโมง (กำหนดใน SensorDetailState.initial())
// - ช่วงเวลาแสดงผลขึ้นบรรทัดใหม่ + ตัดไม่ล้นจอ
// - ปุ่มรีเฟรชมีเอฟเฟกต์ (สลับไอคอนกับ spinner) + ยังมี pull-to-refresh (RefreshIndicator)
//
// หมายเหตุ:
// - Bloc นี้ไม่พึ่ง polling ของ Home เพื่อกัน state ชนกัน
// - Repo ดึงจาก DevicesBloc ที่ provide ไว้แล้วใน main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/devices_bloc.dart';
import '../../models/device_widget.dart';

import '../../bloc/sensor_detail_bloc.dart';
import '../../bloc/sensor_detail_event.dart';
import '../../bloc/sensor_detail_state.dart';

import '../widgets/charts/sensor_line_chart.dart';
import '../widgets/lists/sensor_log_table.dart';

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
      deviceId: dw.device.id, // String
      unit: dw.capability.unit, // ได้จาก Capability getter
    ));

    // ✅ polling เพื่อ refresh history/log/heartbeat
    _bloc.add(const SensorDetailPollingStarted(interval: Duration(seconds: 5)));
  }

  @override
  void dispose() {
    _bloc.add(const SensorDetailPollingStopped());
    _bloc.close();
    super.dispose();
  }

  Future<void> _refreshWithIndicator() async {
    _bloc.add(const SensorDetailRefreshRequested());
    // หน่วงนิดเพื่อให้ผู้ใช้เห็นเอฟเฟกต์ชัด (กันกระพริบเร็วเกิน)
    await Future.delayed(const Duration(milliseconds: 450));
  }

  @override
  Widget build(BuildContext context) {
    final dw = widget.sensorWidget;
    final deviceName = dw.device.name.trim().isEmpty ? 'เซนเซอร์' : dw.device.name.trim();
    final capName = dw.capability.name.trim().isEmpty ? 'ข้อมูลเซนเซอร์' : dw.capability.name.trim();

    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<SensorDetailBloc, SensorDetailState>(
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
          return Scaffold(
            backgroundColor: const Color(0xFFF6F7FB),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(deviceName, style: const TextStyle(fontWeight: FontWeight.w800)),
              actions: [
                // ✅ เอฟเฟกต์รีเฟรช: กดแล้วเห็น spinner ชัด
                IconButton(
                  tooltip: 'รีเฟรช',
                  onPressed: st.isRefreshing ? null : () => _bloc.add(const SensorDetailRefreshRequested()),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: st.isRefreshing
                        ? const SizedBox(
                            key: ValueKey('spin'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(key: ValueKey('icon'), Icons.refresh_rounded),
                  ),
                ),
              ],
            ),
            body: st.isLoading && st.history.isEmpty && st.logs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshWithIndicator,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                      children: [
                        if (st.error != null) ...[
                          _ErrorBanner(message: st.error!),
                          const SizedBox(height: 10),
                        ],

                        // ===== สรุปค่า + สถานะออนไลน์ =====
                        _Card(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // LEFT: ชื่อ + ค่า + ช่วงเวลา (ขึ้นบรรทัดใหม่)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      capName,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          st.currentValue.trim().isEmpty ? '-' : st.currentValue,
                                          style: const TextStyle(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Text(
                                            st.unit.trim().isEmpty ? '' : st.unit,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // ✅ ช่วงเวลาแสดงผล: ขึ้นบรรทัดใหม่ + ไม่ล้นจอ
                                    const Text(
                                      'ช่วงเวลาที่แสดงผล',
                                      style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_fmtShortThai(st.from)} - ${_fmtShortThai(st.to)}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),

                              // RIGHT: สถานะ + เวลา heartbeat ล่าสุด
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _OnlinePill(isOnline: st.isOnline),
                                  const SizedBox(height: 8),
                                  Text(
                                    st.lastHeartbeatAt == null
                                        ? 'อัปเดตล่าสุด: -'
                                        : 'อัปเดตล่าสุด: ${_fmtTimeThai(st.lastHeartbeatAt!)}',
                                    style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ===== กราฟ =====
                        SensorLineChart(
                          points: st.history,
                          headerValueText: _valueWithUnit(st.currentValue, st.unit),
                          headerSubtitle: 'ค่าปัจจุบัน',
                          // ✅ ให้กราฟสวยขึ้นตอนช่วงยาว (จำกัดจำนวนจุด)
                          maxPoints: 160,
                          // ✅ format เวลาเป็นไทย/24 ชม.
                          timeLabelMode: TimeLabelMode.hm24,
                          // tooltip แสดง "เวลา • ค่า"
                          tooltipUnit: st.unit,
                          emptyText: 'ยังไม่มีข้อมูลกราฟ',
                        ),

                        const SizedBox(height: 10),

                        // ===== ปุ่มเลือกช่วงเวลา (เพิ่ม 1 ชั่วโมง) =====
                        _RangeRow(
                          from: st.from,
                          to: st.to,
                          onPick1h: () {
                            final now = DateTime.now();
                            _bloc.add(SensorRangeChanged(from: now.subtract(const Duration(hours: 1)), to: now));
                          },
                          onPick24h: () {
                            final now = DateTime.now();
                            _bloc.add(SensorRangeChanged(from: now.subtract(const Duration(hours: 24)), to: now));
                          },
                          onPick7d: () {
                            final now = DateTime.now();
                            _bloc.add(SensorRangeChanged(from: now.subtract(const Duration(days: 7)), to: now));
                          },
                        ),

                        const SizedBox(height: 12),

                        // ===== Log (2 คอลัมน์: เวลา | ค่า) =====
                        SensorLogTable(
                          logs: st.logs,
                          unitFallback: st.unit,
                          title: 'บันทึก (${st.logs.length})',
                          emptyText: 'ยังไม่มีบันทึก',
                          // ให้เวลาในตารางสั้นลง
                          timeMode: LogTimeMode.hms24,
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}

// ===============================
// UI Helpers (เดิม) + ปรับข้อความไทย
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
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
            ),
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
    final text = isOnline ? 'ออนไลน์' : 'ออฟไลน์';
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
  final VoidCallback onPick1h;
  final VoidCallback onPick24h;
  final VoidCallback onPick7d;

  const _RangeRow({
    required this.from,
    required this.to,
    required this.onPick1h,
    required this.onPick24h,
    required this.onPick7d,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ แสดงช่วงเวลาแยกบรรทัด เพื่อไม่ให้ล้น (ตาม requirement)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ChipButton(label: '1 ชม.', onTap: onPick1h),
            const SizedBox(width: 8),
            _ChipButton(label: '24 ชม.', onTap: onPick24h),
            const SizedBox(width: 8),
            _ChipButton(label: '7 วัน', onTap: onPick7d),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'ช่วงเวลา: ${_fmtShortThai(from)} - ${_fmtShortThai(to)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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

String _valueWithUnit(String value, String unit) {
  final v = value.trim();
  final u = unit.trim();
  if (v.isEmpty) return '-';
  if (u.isEmpty) return v;
  return '$v$u';
}

String _two(int n) => n < 10 ? '0$n' : '$n';

String _fmtTimeThai(DateTime dt) => '${_two(dt.hour)}:${_two(dt.minute)}:${_two(dt.second)}';

String _fmtShortThai(DateTime dt) => '${_two(dt.day)}/${_two(dt.month)}/${dt.year} ${_two(dt.hour)}:${_two(dt.minute)}';