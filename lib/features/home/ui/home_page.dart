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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => WidgetRepository(baseUrl: 'http://10.0.2.2:3000')),
        RepositoryProvider(create: (_) => RoomRepository(baseUrl: 'http://10.0.2.2:3000')),
      ],
      child: BlocProvider(
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
  final List<HomeSection> _order = <HomeSection>[
    HomeSection.sensors,
    HomeSection.devices,
    HomeSection.color,
    HomeSection.brightness,
    HomeSection.extra,
  ];

  double _colorValue = 50;
  double _brightnessValue = 60;
  bool _modeOn = true;
  int _bottomIndex = 0;

  /// Reorder แบบถูกต้องเมื่อ “บาง section ถูกซ่อน”
  /// - UI แสดงเฉพาะ visibleSections
  /// - แต่เราต้องอัปเดตลำดับใน _order โดย “แทนที่เฉพาะสมาชิกที่มองเห็น”
  void _onReorderVisible(List<HomeSection> visible, int oldIndex, int newIndex) {
    final reordered = List<HomeSection>.from(visible);

    if (newIndex > oldIndex) newIndex -= 1;
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

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

              Row(
                children: [
                  const Icon(Icons.home_rounded, color: Color(0xFF3AA7FF), size: 28),
                  const SizedBox(width: 10),
                  const Text('บ้านเกม 1', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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

              BlocBuilder<DevicesBloc, DevicesState>(
                buildWhen: (p, c) =>
                    p.selectedRoomId != c.selectedRoomId ||
                    p.rooms != c.rooms ||
                    p.deviceRoomId != c.deviceRoomId,
                builder: (context, st) {
                  return TopTab(
                    rooms: st.rooms,
                    selectedRoomId: st.selectedRoomId,
                    onChanged: (roomId) =>
                        context.read<DevicesBloc>().add(DevicesRoomChanged(roomId)),
                  );
                },
              ),

              const SizedBox(height: 14),

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
                    final vm = HomeViewModel.fromState(st);

                    // ✅ กรอง section ที่มีข้อมูลจริงเท่านั้น
                    final visibleSections = _order.where((s) => s.hasData(vm)).toList();

                    // ถ้าไม่มีข้อมูลจริงเลย => ไม่ render อะไร (ไม่มีการ์ดว่าง/ข้อความ fallback)
                    if (visibleSections.isEmpty) {
                      // จะยังมี header+tabs อยู่ตามปกติ (ตามที่คุณต้องการ)
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: [
                        // Banner ใช้เพื่อบอกสถานะโหลด/ผิดพลาด (ไม่ใช่ fallback ข้อมูล)
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
                                    child: const Icon(Icons.drag_indicator_rounded, color: Colors.black26),
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

  Widget _buildSection(HomeSection section, HomeViewModel vm) {
    switch (section) {
      case HomeSection.sensors:
        // แสดงเท่าที่มี (1..N)
        return SensorsSection(sensors: vm.sensors);

      case HomeSection.devices:
        // แสดงเท่าที่มี (1..N)
        return DevicesSection(
          toggles: vm.toggles,
          onToggle: (widgetId) =>
              context.read<DevicesBloc>().add(WidgetToggled(widgetId)),
        );

      case HomeSection.color:
        // section นี้ถูกกรองแล้วว่า “มี widgetId จริง”
        final id = vm.colorAdjust.widgetId!;
        return ColorSection(
          value: _colorValue,
          onChanged: (v) {
            setState(() => _colorValue = v);
            context.read<DevicesBloc>().add(WidgetValueChanged(id, v));
          },
        );

      case HomeSection.brightness:
        final id = vm.brightnessAdjust.widgetId!;
        return BrightnessSection(
          value: _brightnessValue,
          onChanged: (v) {
            setState(() => _brightnessValue = v);
            context.read<DevicesBloc>().add(WidgetValueChanged(id, v));
          },
        );

      case HomeSection.extra:
        // ปัจจุบัน hasExtra=false => ไม่ควรถูกเรียก
        return ExtraSection(
          modeOn: _modeOn,
          onModeChanged: (v) => setState(() => _modeOn = v),
          onMinus: () {},
          onPlus: () {},
        );
    }
  }
}

class _Banner extends StatelessWidget {
  final bool isLoading;
  final String? error;

  const _Banner({
    required this.isLoading,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final text = isLoading
        ? 'กำลังโหลดข้อมูล'
        : 'เชื่อมต่อไม่สำเร็จ';

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
