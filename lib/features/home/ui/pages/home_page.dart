// lib/features/home/ui/pages/home_page.dart
//
// ✅ FIX (ครบทั้งไฟล์):
// - ปรับพื้นหลังให้ “ไล่สีลงมาทั้งหน้า” (ไม่ใช่เฉพาะส่วนบน)
//   โดยห่อทั้งหน้า (Scaffold) ด้วย Container ที่มี LinearGradient
//   และทำให้ Scaffold โปร่งใส
// - เอาสีพื้นหลังทึบ (pageBg) ที่ทับ gradient ออกในส่วน body หลัก
//
// หมายเหตุ:
// - widget_picker_sheet.dart เป็น UI ล้วน (คืนค่า ids) ไม่ผูก API
// - การยิง API/save อยู่ใน Bloc + Repository (clean architecture)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';

import '../../../device/manage_devices_page.dart';
import '../../../room/bloc/rooms_bloc.dart';
import '../../../room/bloc/rooms_event.dart';

import '../../bloc/devices_bloc.dart';
import '../../bloc/devices_event.dart';
import '../../bloc/devices_state.dart';

import '../view_models/home_view_model.dart';
import '../widgets/components/top_tabs.dart';
import '../widgets/components/home_widget_grid.dart';
import '../widgets/bottom_sheets/home_actions_sheet.dart';
import '../widgets/bottom_sheets/widget_picker_sheet.dart';

import '../widgets/dialogs/text_command_dialog.dart';
import '../widgets/bottom_sheets/mode_picker_sheet.dart';

import 'add_device_page.dart';
import '../../../room/ui/manage_homes_page.dart';
import 'sensor_detail_page.dart';
import '../../../me/me_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ blocs are already provided in main.dart
    return const _HomeView();
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  int _bottomIndex = 0;

  static const Color blue = Color(0xFF3AA7FF);
  static const Color sky = Color(0xFFBFE6FF);
  static const Color pageBg = Color(0xFFF6F7FB);

  final user = FirebaseAuth.instance.currentUser;

  void _logout() {
    context.read<DevicesBloc>().add(const WidgetsPollingStopped());
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  @override
  void initState() {
    super.initState();

    context.read<DevicesBloc>().add(const DevicesStarted());
    context.read<RoomsBloc>().add(const RoomsStarted());
  }

  @override
  void dispose() {
    context.read<DevicesBloc>().add(const WidgetsPollingStopped());
    super.dispose();
  }

  Future<void> _openActionsSheet() async {
    final action = await showHomeActionsSheet(context);
    if (!mounted || action == null) return;

    switch (action) {
      case HomeAction.addDeviceWidget:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<DevicesBloc>(),
              child: const AddDevicePage(),
            ),
          ),
        );

        if (!mounted) return;
        final roomId = context.read<DevicesBloc>().state.selectedRoomId;

        context.read<DevicesBloc>().add(DevicesRoomChanged(roomId));
        context.read<DevicesBloc>().add(WidgetsPollingStarted(roomId: roomId));
        break;

      case HomeAction.reorderWidgets:
        final enabled = !context.read<DevicesBloc>().state.reorderEnabled;
        context.read<DevicesBloc>().add(ReorderModeChanged(enabled));
        break;

      case HomeAction.manageWidgets:
        await _openManageWidgetsSheet();
        break;
    }
  }

  Future<void> _openManageWidgetsSheet() async {
    final bloc = context.read<DevicesBloc>();
    final roomId = bloc.state.selectedRoomId;
    if (roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกห้องก่อนจัดการ widget')),
      );
      return;
    }

    // โหลด list สำหรับ picker (ใน Bloc คุณทำให้ดึง all แล้ว filter room ไว้แล้ว)
    bloc.add(WidgetSelectionLoaded(roomId: roomId));
    final loadedState = await bloc.stream.firstWhere((s) => !s.isLoading);

    if (!mounted) return;

    final vm = HomeViewModel.fromState(loadedState);

    // ✅ จำ included เดิมไว้ เพื่อคำนวณ diff ตอนกดบันทึก
    final beforeIncluded = vm.activeTiles.map((e) => e.widgetId).toSet();

    final result = await showWidgetPickerSheet(
      context: context,
      title: 'เพิ่ม/ลบ widget',
      confirmText: 'บันทึก',
      includedItems: vm.activeTiles,
      excludedItems: vm.drawerTiles,
      lockIncluded: false,
      headerTitle: 'บ้านเกม 1',
      headerSubtitle: '',

      // ✅ ข้อ A: ให้ sheet เรียก callback นี้ตอนกดบันทึก
      // sheet จะโชว์ loading + ถ้า error จะไม่ปิดเอง
      onConfirm: (afterIncludedIds) async {
        final afterIncluded = afterIncludedIds.toSet();

        final toInclude = afterIncluded.difference(beforeIncluded);
        final toExclude = beforeIncluded.difference(afterIncluded);

        // ยิงเฉพาะตัวที่เปลี่ยน
        for (final id in toInclude) {
          await bloc.widgetRepo.changeWidgetStatus(
            widgetId: id,
            widgetStatus: 'include',
          );
        }
        for (final id in toExclude) {
          await bloc.widgetRepo.changeWidgetStatus(
            widgetId: id,
            widgetStatus: 'exclude',
          );
        }
      },
      confirmErrorText: 'บันทึกไม่สำเร็จ',
    );

    // ถ้า cancel -> ไม่ต้องทำอะไร
    if (!mounted || result == null) return;

    final currentRoomId = bloc.state.selectedRoomId;
    if (currentRoomId != null) {
      bloc.add(DevicesRoomChanged(currentRoomId));
      bloc.add(WidgetsPollingStarted(roomId: currentRoomId));
    }
  }

  Future<void> _openModePicker(HomeWidgetTileVM tile) async {
    final options = tile.modeOptions.isEmpty
        ? const ['auto', 'cool', 'dry', 'fan', 'heat']
        : tile.modeOptions;

    final selected = await showModePickerSheet(
      context: context,
      title: tile.title,
      current: tile.value,
      options: options,
    );

    if (!mounted || selected == null) return;
    context.read<DevicesBloc>().add(WidgetModeChanged(tile.widgetId, selected));
  }

  Future<void> _openTextDialog(HomeWidgetTileVM tile) async {
    final text = await showTextCommandDialog(
      context: context,
      title: tile.title,
      initialText: tile.value,
      hintText: tile.hintText.isEmpty ? 'ใส่ข้อความ' : tile.hintText,
      confirmText: 'ส่ง',
    );

    if (!mounted || text == null) return;
    context.read<DevicesBloc>().add(WidgetTextSubmitted(tile.widgetId, text));
  }

  void _startPollingIfHomeTab() {
    final bloc = context.read<DevicesBloc>();
    final roomId = bloc.state.selectedRoomId;
    if (_bottomIndex == 0 && roomId != null) {
      bloc.add(WidgetsPollingStarted(
        roomId: roomId,
        interval: const Duration(seconds: 5),
      ));
    } else {
      bloc.add(const WidgetsPollingStopped());
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ไล่สีทั้งหน้า (ลงมาถึง body)
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // ปรับ stops ให้สีฟ้าลงมาลึกขึ้น
          stops: [0.0, 0.45, 1.0],
          colors: [
            sky,
            Color(0xFFDDF2FF),
            pageBg,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // สำคัญ: ไม่ให้ทับ gradient
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _bottomIndex,
          onTap: (i) {
            setState(() => _bottomIndex = i);
            if (i == 0) {
              _startPollingIfHomeTab();
            } else {
              context.read<DevicesBloc>().add(const WidgetsPollingStopped());
            }
          },
          selectedItemColor: blue,
          unselectedItemColor: Colors.blueGrey.withOpacity(0.6),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'บ้าน'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'ฉัน'),
          ],
        ),
        floatingActionButton: _bottomIndex != 0
            ? null
            : BlocBuilder<DevicesBloc, DevicesState>(
                buildWhen: (p, c) =>
                    p.reorderEnabled != c.reorderEnabled ||
                    p.reorderSaving != c.reorderSaving,
                builder: (context, st) {
                  final enabled = st.reorderEnabled;
                  return FloatingActionButton(
                    backgroundColor: blue,
                    onPressed: enabled
                        ? () => context
                            .read<DevicesBloc>()
                            .add(const CommitReorderPressed())
                        : () => _openActionsSheet(),
                    child: Icon(
                      enabled ? Icons.check_rounded : Icons.more_horiz_rounded,
                      color: Colors.white,
                    ),
                  );
                },
              ),
        body: SafeArea(
          child: _bottomIndex == 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ ส่วนหัว: ทำให้โปร่งใส/ไม่ทับ gradient ทั้งหน้า
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(0, 10, 16, 12),
                      // เอา gradient เดิมออกเพื่อให้ใช้ gradient ของทั้งหน้า
                      color: Colors.transparent,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.home_rounded,
                                    color: blue, size: 24),
                                const SizedBox(width: 10),
                                const Text(
                                  'บ้านเกม 1',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0B4A7A),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: _logout,
                                  icon: const Icon(Icons.logout,
                                      color: Colors.black45),
                                ),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: BlocBuilder<DevicesBloc, DevicesState>(
                              buildWhen: (p, c) =>
                                  p.rooms != c.rooms ||
                                  p.selectedRoomId != c.selectedRoomId,
                              builder: (context, st) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: TopTab(
                                    rooms: st.rooms,
                                    selectedRoomId: st.selectedRoomId,
                                    onChanged: (roomId) {
                                      context
                                          .read<DevicesBloc>()
                                          .add(DevicesRoomChanged(roomId!));
                                      context.read<DevicesBloc>().add(
                                          WidgetsPollingStarted(
                                              roomId: roomId));
                                                                        },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Container(
                        width: double.infinity,
                        // ✅ เดิมสีทึบ pageBg จะทับ gradient -> ทำให้โปร่งใส
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: BlocBuilder<DevicesBloc, DevicesState>(
                            buildWhen: (p, c) =>
                                p.widgets != c.widgets ||
                                p.isLoading != c.isLoading ||
                                p.error != c.error ||
                                p.selectedRoomId != c.selectedRoomId ||
                                p.reorderEnabled != c.reorderEnabled ||
                                p.reorderSaving != c.reorderSaving,
                            builder: (context, st) {
                              if (st.isLoading && st.widgets.isEmpty) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (st.error != null && st.widgets.isEmpty) {
                                return _ErrorState(message: st.error!);
                              }

                              final vm = HomeViewModel.fromState(st);
                              if (vm.tiles.isEmpty) {
                                return const _EmptyState(
                                  title: 'ไม่มี widget ในห้องนี้',
                                  subtitle: 'กดปุ่มสีน้ำเงินเพื่อเพิ่ม widget',
                                );
                              }

                              return HomeWidgetGrid(
                                tiles: vm.tiles,
                                reorderEnabled: st.reorderEnabled,
                                onToggle: (widgetId) => context
                                    .read<DevicesBloc>()
                                    .add(WidgetToggled(widgetId)),
                                onAdjust: (widgetId, value) => context
                                    .read<DevicesBloc>()
                                    .add(WidgetValueChanged(
                                        widgetId, value.toDouble())),
                                onOrderChanged: (newOrderWidgetIds) => context
                                    .read<DevicesBloc>()
                                    .add(WidgetsOrderChanged(
                                        newOrderWidgetIds)),
                                onOpenSensor: (tile) {
                                  final sensorWidget = st.widgets.firstWhere(
                                      (w) => w.widgetId == tile.widgetId);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SensorDetailPage(
                                          sensorWidget: sensorWidget),
                                    ),
                                  );
                                },
                                onOpenMode: _openModePicker,
                                onOpenText: _openTextDialog,
                                onPressButton: (widgetId) => context
                                    .read<DevicesBloc>()
                                    .add(WidgetButtonPressed(widgetId)),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : MePage(
                  displayName: user?.displayName ?? 'ไม่มีชื่อ',
                  roleText: 'Role',
                  photoUrl: user?.photoURL,
                  onManageHome: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MultiBlocProvider(
                          providers: [
                            BlocProvider.value(
                                value: context.read<DevicesBloc>()),
                            BlocProvider.value(
                                value: context.read<RoomsBloc>()),
                          ],
                          child: const ManageHomesPage(),
                        ),
                      ),
                    );

                    if (!mounted) return;

                    context
                        .read<RoomsBloc>()
                        .add(const RoomsRefreshRequested());
                    context.read<DevicesBloc>().add(const DevicesStarted());
                  },
                  onManageDevices: () async {
                    context.read<DevicesBloc>().add(const DevicesRequested());
                    context.read<RoomsBloc>().add(const RoomsStarted());

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MultiBlocProvider(
                          providers: [
                            BlocProvider.value(
                                value: context.read<DevicesBloc>()),
                            BlocProvider.value(
                                value: context.read<RoomsBloc>()),
                          ],
                          child: const ManageDevicesPage(),
                        ),
                      ),
                    );

                    if (!mounted) return;

                    context.read<DevicesBloc>().add(const DevicesRequested());
                    context
                        .read<RoomsBloc>()
                        .add(const RoomsRefreshRequested());
                  },
                  onSecurity: () {},
                  onLogout: _logout,
                ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.widgets_outlined, size: 44, color: Color(0xFF3AA7FF)),
            SizedBox(height: 10),
            Text(
              'ไม่มี widget ในห้องนี้',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w900, color: Color(0xFF0B4A7A)),
            ),
            SizedBox(height: 6),
            Text(
              'กดปุ่มสีน้ำเงินเพื่อเพิ่ม widget',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 44, color: Color(0xFF3AA7FF)),
            const SizedBox(height: 10),
            const Text(
              'โหลดข้อมูลไม่สำเร็จ',
              style: TextStyle(
                  fontWeight: FontWeight.w900, color: Color(0xFF0B4A7A)),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}