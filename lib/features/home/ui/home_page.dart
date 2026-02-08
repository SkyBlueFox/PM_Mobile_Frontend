import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';

import '../bloc/devices_bloc.dart';
import '../bloc/devices_event.dart';
import '../bloc/devices_state.dart';
import '../data/device_repository.dart';
import '../data/mqtt/mqtt_service.dart';

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
    return BlocProvider(
      create: (_) {
        final mqtt = MqttService(
          broker: 'YOUR_BROKER_HOST', // TODO: ใส่ host จริงทีหลัง
          port: 1883,
          clientId: 'pm-mobile-${DateTime.now().millisecondsSinceEpoch}',
        );

        final repo = DevicesRepository(mqtt: mqtt);
        return DevicesBloc(repo: repo)..add(const DevicesStarted());
      },
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
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

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _order.removeAt(oldIndex);
      _order.insert(newIndex, item);
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

              // Header (ไม่มีการ์ดโซฟาแล้ว)
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

              BlocBuilder<DevicesBloc, DevicesState>(
                buildWhen: (p, c) =>
                    p.selectedRoomId != c.selectedRoomId ||
                    p.rooms != c.rooms ||
                    p.devices != c.devices ||
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
                  builder: (context, st) {
                    final vm = HomeViewModel.fromState(st);

                    // ไม่บล็อก UI (ทำดีไซน์ก่อน)
                    return Column(
                      children: [
                        if (vm.isLoading || vm.error != null)
                          _Banner(
                            isLoading: vm.isLoading,
                            error: vm.error,
                          ),
                        Expanded(
                          child: ReorderableListView.builder(
                            padding: const EdgeInsets.only(bottom: 18),
                            buildDefaultDragHandles: false,
                            itemCount: _order.length,
                            onReorder: _onReorder,
                            itemBuilder: (context, i) {
                              final section = _order[i];

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

  Widget _buildSection(HomeSection section, HomeViewModel vm) {
    switch (section) {
      case HomeSection.sensors:
        final s1 = vm.sensors[0];
        final s2 = vm.sensors[1];
        return SensorsSection(
          aLabel: s1.label,
          aValue: s1.valueText,
          aUnit: s1.unit,
          bLabel: s2.label,
          bValue: s2.valueText,
          bUnit: s2.unit,
        );

      case HomeSection.devices:
        final t1 = vm.toggles[0];
        final t2 = vm.toggles[1];
        return DevicesSection(
          label1: t1.label,
          isOn1: t1.isOn,
          onToggle1: t1.widgetId == null
              ? null
              : () => context.read<DevicesBloc>().add(WidgetToggled(t1.widgetId!)),
          label2: t2.label,
          isOn2: t2.isOn,
          onToggle2: t2.widgetId == null
              ? null
              : () => context.read<DevicesBloc>().add(WidgetToggled(t2.widgetId!)),
        );

      case HomeSection.color:
        return ColorSection(
          value: _colorValue,
          onChanged: (v) {
            setState(() => _colorValue = v);
            final id = vm.colorAdjust.widgetId;
            if (id != null) {
              context.read<DevicesBloc>().add(WidgetValueChanged(id, v));
            }
          },
        );

      case HomeSection.brightness:
        return BrightnessSection(
          value: _brightnessValue,
          onChanged: (v) {
            setState(() => _brightnessValue = v);
            final id = vm.brightnessAdjust.widgetId;
            if (id != null) {
              context.read<DevicesBloc>().add(WidgetValueChanged(id, v));
            }
          },
        );

      case HomeSection.extra:
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
        ? 'กำลังโหลดข้อมูล (โหมดทำดีไซน์)'
        : 'เชื่อมต่อไม่สำเร็จ (โหมดทำดีไซน์)';

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
