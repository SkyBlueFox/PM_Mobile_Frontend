import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';

import '../bloc/devices_bloc.dart';
import '../bloc/devices_event.dart';
import '../bloc/devices_state.dart';
import '../data/room_repository.dart';
import '../data/widget_repository.dart';

import 'home_sections.dart';
import 'home_view_model.dart';

import 'widgets/top_tabs.dart';
import 'widgets/section_card.dart';
import 'widgets/sections/sensors_section.dart';
import 'widgets/sections/devices_section.dart';
import 'widgets/sections/color_section.dart';
import 'widgets/sections/brightness_section.dart';
import 'widgets/sections/extra_section.dart';

/// HomePage: หน้าหลักหลังล็อกอิน
/// หลักการสำคัญ:
/// 1) แสดงข้อมูล "ตามจริง" จาก API เท่านั้น (ไม่มี fallback widget ปลอม)
/// 2) ถ้าในห้องนั้น "ไม่มี widget จริง" ให้แสดงข้อความอธิบาย (ไม่ปล่อยหน้าว่าง)
/// 3) รองรับการลากสลับตำแหน่งเฉพาะ section ที่แสดงอยู่จริง (visible)
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // แยก Repository ออกมาเพื่อให้ Bloc ใช้งาน (SRP: UI ไม่รับผิดชอบเรื่อง data access)
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (_) => WidgetRepository(baseUrl: 'http://10.0.2.2:3000'),
        ),
        RepositoryProvider(
          create: (_) => RoomRepository(baseUrl: 'http://10.0.2.2:3000'),
        ),
      ],
      child: BlocProvider(
        // สร้าง Bloc ครั้งเดียวในหน้า Home
        create: (context) => DevicesBloc(
          widgetRepo: context.read<WidgetRepository>(),
          roomRepo: context.read<RoomRepository>(),
        )..add(DevicesStarted()),
        child: const _HomeView(),
      ),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  /// เก็บ “ลำดับ section” (ผู้ใช้ลากสลับได้)
  /// NOTE: บาง section อาจถูกซ่อนถ้าไม่มีข้อมูลจริง
  final List<HomeSection> _order = <HomeSection>[
    HomeSection.sensors,
    HomeSection.devices,
    HomeSection.color,
    HomeSection.brightness,
    HomeSection.extra,
  ];

  // ค่า UI ของสไลเดอร์ (ยังทำงานได้เฉพาะเมื่อมี widgetId จริง)
  int _colorValue = 50;
  int _brightnessValue = 60;

  // ค่า UI ของ extra (ตอนนี้ hasExtra=false จึงปกติไม่ถูกแสดง)
  bool _modeOn = true;

  int _bottomIndex = 0;

  /// Reorder แบบถูกต้องเมื่อ “บาง section ถูกซ่อน”
  /// - UI แสดงเฉพาะ visibleSections
  /// - เราต้องอัปเดตลำดับใน _order โดย “แทนที่เฉพาะสมาชิกที่มองเห็น”
  void _onReorderVisible(List<HomeSection> visible, int oldIndex, int newIndex) {
    // ทำงานกับ copy เพื่อความปลอดภัย (ไม่แก้ list จากภายนอก)
    final reordered = List<HomeSection>.from(visible);

    // กติกาของ ReorderableListView: ถ้าขยับลง ต้องลด index เป้าหมายลง 1
    if (newIndex > oldIndex) newIndex -= 1;

    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    // อัปเดตเฉพาะ section ที่มองเห็นใน _order
    final visibleSet = reordered.toSet();
    var qi = 0;

    setState(() {
      for (var i = 0; i < _order.length; i++) {
        if (visibleSet.contains(_order[i])) {
          _order[i] = reordered[qi++];
        }
      }
    });
  }

  void _logout() {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) => setState(() => _bottomIndex = i),
        selectedItemColor: const Color(0xFF3AA7FF),
        unselectedItemColor: Colors.black38,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'บ้าน'),
          BottomNavigationBarItem(icon: Icon(Icons.star_rounded), label: 'ตั้ง'),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ===== Header =====
              Row(
                children: [
                  const Icon(Icons.home_rounded, color: Color(0xFF3AA7FF), size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'บ้านเกม 1',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.black45),
                    onSelected: (v) {
                      if (v == 'logout') _logout();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'logout', child: Text('Logout')),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ===== Room Tabs =====
              BlocBuilder<DevicesBloc, DevicesState>(
                buildWhen: (p, c) =>
                    p.selectedRoomId != c.selectedRoomId ||
                    p.rooms != c.rooms ||
                    p.deviceRoomId != c.deviceRoomId,
                builder: (context, st) {
                  return TopTab(
                    rooms: st.rooms,
                    selectedRoomId: st.selectedRoomId,
                    onChanged: (roomId) => context
                        .read<DevicesBloc>()
                        .add(DevicesRoomChanged(roomId)),
                  );
                },
              ),

              const SizedBox(height: 14),

              // ===== Main Content =====
              Expanded(
                child: BlocBuilder<DevicesBloc, DevicesState>(
                  // ลด rebuild ที่ไม่จำเป็น: สนใจเฉพาะ widget/room/loading/error
                  buildWhen: (p, c) =>
                      p.widgets != c.widgets ||
                      p.selectedRoomId != c.selectedRoomId ||
                      p.deviceRoomId != c.deviceRoomId ||
                      p.isLoading != c.isLoading ||
                      p.error != c.error,
                  builder: (context, st) {
                    // แปลง state -> view model ที่ UI ต้องใช้ (KISS: UI ไม่ parse เอง)
                    final vm = HomeViewModel.fromState(st);

                    // ✅ กรอง section ที่ "มีข้อมูลจริง" เท่านั้น (No fallback)
                    final visibleSections = _order.where((s) => s.hasData(vm)).toList();

                    // ถ้าไม่มีข้อมูลจริงเลย:
                    // - แสดง Banner (ถ้ามี loading/error)
                    // - แสดงข้อความอธิบายให้ user เข้าใจ
                    if (visibleSections.isEmpty) {
                      return Column(
                        children: [
                          if (vm.isLoading || vm.error != null)
                            _Banner(isLoading: vm.isLoading, error: vm.error),
                          const Expanded(child: _EmptyRoomMessage()),
                        ],
                      );
                    }

                    // ถ้ามีข้อมูล -> แสดงเฉพาะ section ที่มีจริง + ลากสลับตำแหน่งได้
                    return Column(
                      children: [
                        if (vm.isLoading || vm.error != null)
                          _Banner(isLoading: vm.isLoading, error: vm.error),

                        Expanded(
                          child: ReorderableListView.builder(
                            padding: const EdgeInsets.only(bottom: 18),
                            buildDefaultDragHandles: false,
                            itemCount: visibleSections.length,
                            onReorder: (oldIndex, newIndex) =>
                                _onReorderVisible(visibleSections, oldIndex, newIndex),
                            itemBuilder: (context, i) {
                              final section = visibleSections[i];

                              return Padding(
                                key: ValueKey('section_${section.name}'),
                                padding: const EdgeInsets.only(bottom: 14),
                                child: SectionCard(
                                  title: section.title,
                                  actionText: section.actionText,
                                  dragHandle: ReorderableDragStartListener(
                                    index: i,
                                    child: const Icon(
                                      Icons.drag_indicator_rounded,
                                      color: Colors.black26,
                                    ),
                                  ),
                                  child: _buildSection(section, vm),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// สร้าง UI ของแต่ละ section (Single responsibility: แค่เลือก widget ตาม type)
  Widget _buildSection(HomeSection section, HomeViewModel vm) {
    switch (section) {
      case HomeSection.sensors:
        // SensorsSection รองรับ 1..N (แสดงเท่าที่มี)
        return SensorsSection(sensors: vm.sensors);

      case HomeSection.devices:
        // DevicesSection รองรับ 1..N (แสดงเท่าที่มี)
        return DevicesSection(
          toggles: vm.toggles,
          onToggle: (widgetId) => context.read<DevicesBloc>().add(WidgetToggled(widgetId)),
        );

      case HomeSection.color:
        // section นี้ถูกกรองแล้วว่า “มี widgetId จริง”
        final id = vm.colorAdjust.widgetId!;
        return ColorSection(
          value: _colorValue,
          onChanged: (v) {
            setState(() => _colorValue = v.toInt());
            context.read<DevicesBloc>().add(WidgetValueChanged(id, v.toInt()));
          },
        );

      case HomeSection.brightness:
        // section นี้ถูกกรองแล้วว่า “มี widgetId จริง”
        final id = vm.brightnessAdjust.widgetId!;
        return BrightnessSection(
          value: _brightnessValue,
          onChanged: (v) {
            setState(() => _brightnessValue = v.toInt());
            context.read<DevicesBloc>().add(WidgetValueChanged(id, v.toInt()));
          },
        );

      case HomeSection.extra:
        // ปัจจุบัน vm.hasExtra=false => จะไม่เข้ามา (กันการโชว์ UI ที่ไม่ผูกกับข้อมูลจริง)
        return ExtraSection(
          modeOn: _modeOn,
          onModeChanged: (v) => setState(() => _modeOn = v),
          onMinus: () {},
          onPlus: () {},
        );
    }
  }
}

/// Banner สำหรับบอกสถานะโหลด/ผิดพลาด (ไม่ใช่ fallback ข้อมูล)
class _Banner extends StatelessWidget {
  final bool isLoading;
  final String? error;

  const _Banner({
    required this.isLoading,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final text = isLoading ? 'กำลังโหลดข้อมูล' : 'เชื่อมต่อไม่สำเร็จ';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isLoading ? Icons.hourglass_bottom_rounded : Icons.cloud_off_rounded,
            color: Colors.black45,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error == null ? text : '$text — $error',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

/// ข้อความสำหรับกรณี “ห้องนี้ไม่มี widget จริงจาก API”
/// NOTE: แสดงเพื่อให้ user เข้าใจ ไม่ใช่การสร้าง widget ปลอม
class _EmptyRoomMessage extends StatelessWidget {
  const _EmptyRoomMessage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.widgets_outlined, size: 44, color: Colors.black38),
            SizedBox(height: 10),
            Text(
              'No widgets available for this room.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Please select another room or add devices/widgets.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
