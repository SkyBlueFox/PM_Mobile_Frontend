// lib/features/home/ui/pages/home_page.dart
//
// ✅ UPDATE (ทั้งไฟล์):
// - ทำพื้นหลัง “เหมือน MePage” = ฟ้าด้านบนไล่เฉดลงขาว (เฉพาะช่วงหัว) ไม่ไล่ทั้งหน้า
// - เอาปุ่ม logout ขวาบนออก (ยังคงฟังก์ชัน _logout ไว้ใช้จากหน้า "ฉัน")
// - ปรับปุ่มลอยให้เป็นวงกลม + ไอคอน 3 จุดแนวตั้ง (more_vert) ตาม UI ตัวอย่าง
//   (โหมด reorder ยังใช้เครื่องหมายถูกเหมือนเดิม)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pm_mobile_frontend/features/user/bloc/user_bloc.dart';
import 'package:pm_mobile_frontend/features/user/bloc/user_event.dart';
import 'package:pm_mobile_frontend/models/user.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';

import '../../../device/manage_devices_page.dart';
import '../../../room/bloc/rooms_bloc.dart';
import '../../../room/bloc/rooms_event.dart';

import '../../../user/ui/manage_home_page.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';

import '../view_models/home_view_model.dart';
import '../widgets/components/top_tabs.dart';
import '../widgets/components/home_widget_grid.dart';
import '../widgets/bottom_sheets/home_actions_sheet.dart';
import '../widgets/bottom_sheets/widget_picker_sheet.dart';

import '../widgets/dialogs/text_command_dialog.dart';
import '../widgets/bottom_sheets/mode_picker_sheet.dart';

import 'add_device_page.dart';
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
  static const Color topBlue = Color(0xFFBFE6FF);

  void _logout() {
    context.read<HomeBloc>().add(const WidgetsPollingStopped());
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    context.read<UserBloc>().add(FetchUserByEmail(user!.email!));
    context.read<HomeBloc>().add(const HomeStarted());
    context.read<RoomsBloc>().add(const RoomsStarted());
  }

  @override
  void dispose() {
    context.read<HomeBloc>().add(const WidgetsPollingStopped());
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
              value: context.read<HomeBloc>(),
              child: const AddDevicePage(),
            ),
          ),
        );

        if (!mounted) return;
        final roomId = context.read<HomeBloc>().state.selectedRoomId;

        context.read<HomeBloc>().add(TabRoomChanged(roomId));
        context.read<HomeBloc>().add(WidgetsPollingStarted(roomId: roomId));
        break;

      case HomeAction.reorderWidgets:
        final enabled = !context.read<HomeBloc>().state.reorderEnabled;
        context.read<HomeBloc>().add(ReorderModeChanged(enabled));
        break;

      case HomeAction.manageWidgets:
        await _openManageWidgetsSheet();
        break;
    }
  }

  Future<void> _openManageWidgetsSheet() async {
    final bloc = context.read<HomeBloc>();
    final roomId = bloc.state.selectedRoomId;

    bloc.add(WidgetSelectionLoaded(roomId: roomId));
    final loadedState = await bloc.stream.firstWhere((s) => !s.isLoading);

    final pickerState =
        loadedState.copyWith(widgets: loadedState.selectionWidgets);

    final vm = HomeViewModel.fromState(pickerState);
    final beforeIncluded = vm.activeTiles.map((e) => e.widgetId).toSet();

    final result = await showWidgetPickerSheet(
      context: context,
      title: 'เพิ่ม/ลบ widget',
      confirmText: 'บันทึก',
      includedItems: vm.activeTiles,
      excludedItems: vm.drawerTiles,
      lockIncluded: false,
      headerTitle: 'บ้านของฉัน',
      headerSubtitle: '',
      onConfirm: (afterIncludedIds) async {
        final afterIncluded = afterIncludedIds.toSet();

        final toInclude = afterIncluded.difference(beforeIncluded);
        final toExclude = beforeIncluded.difference(afterIncluded);

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

    if (!mounted || result == null) return;

    final currentRoomId = bloc.state.selectedRoomId;
    bloc.add(TabRoomChanged(currentRoomId));
    bloc.add(WidgetsPollingStarted(roomId: currentRoomId));
  }

  Future<void> _openModePicker(HomeWidgetTileVM tile) async {
    final options = tile.modeOptions.isEmpty
        ? const ['auto', 'off']
        : tile.modeOptions;

    final selected = await showModePickerSheet(
      context: context,
      title: tile.title,
      current: tile.value,
      options: options,
    );

    if (!mounted || selected == null) return;
    context.read<HomeBloc>().add(WidgetModeChanged(tile.widgetId, selected));
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
    context.read<HomeBloc>().add(WidgetTextSubmitted(tile.widgetId, text));
  }

  void _startPollingIfHomeTab() {
    final bloc = context.read<HomeBloc>();
    final roomId = bloc.state.selectedRoomId;
    if (_bottomIndex == 0) {
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
    final userState = context.select((UserBloc b) => b.state);
    final isAdmin = userState.user?.role == Role.admin;
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) {
          setState(() => _bottomIndex = i);
          if (i == 0) {
            _startPollingIfHomeTab();
          } else {
            context.read<HomeBloc>().add(const WidgetsPollingStopped());
          }
        },
        selectedItemColor: blue,
        unselectedItemColor: Colors.blueGrey.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'บ้าน'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded), label: 'ฉัน'),
        ],
      ),
      floatingActionButton: _bottomIndex != 0 || !isAdmin
          ? null
          : BlocBuilder<HomeBloc, HomeState>(
              buildWhen: (p, c) =>
                  p.reorderEnabled != c.reorderEnabled ||
                  p.reorderSaving != c.reorderSaving,
              builder: (context, st) {
                final enabled = st.reorderEnabled;
                return FloatingActionButton(
                  backgroundColor: blue,
                  shape: const CircleBorder(),
                  onPressed: enabled
                      ? () => context
                          .read<HomeBloc>()
                          .add(const CommitReorderPressed())
                      : () => _openActionsSheet(),
                  child: Icon(
                    enabled
                        ? Icons.check_rounded
                        : Icons.more_vert_rounded,
                    color: Colors.white,
                  ),
                );
              },
            ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  topBlue,
                  Color(0xF5F5F5F5),
                ],
                stops: [0.0, 0.35],
              ),
            ),
          ),

          SafeArea(
            child: _bottomIndex == 0
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header (no logout button)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(0, 10, 16, 12),
                        color: Colors.transparent,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Row(
                                children: const [
                                  Icon(Icons.home_rounded,
                                      color: blue, size: 24),
                                  SizedBox(width: 10),
                                  Text(
                                    'บ้านของฉัน',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0B4A7A),
                                    ),
                                  ),
                                  Spacer(),
                                  // ✅ เอาปุ่ม logout ขวาบนออกแล้ว
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: BlocBuilder<HomeBloc, HomeState>(
                                buildWhen: (p, c) =>
                                    p.rooms != c.rooms ||
                                    p.selectedRoomId != c.selectedRoomId,
                                builder: (context, st) {
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
                                    child: TopTab(
                                      rooms: st.rooms,
                                      selectedRoomId: st.selectedRoomId,
                                      onChanged: (roomId) {
                                        context
                                            .read<HomeBloc>()
                                            .add(TabRoomChanged(roomId!));
                                        context.read<HomeBloc>().add(
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
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(18),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                            child: BlocBuilder<HomeBloc, HomeState>(
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
                                      .read<HomeBloc>()
                                      .add(WidgetToggled(widgetId)),
                                  onAdjust: (widgetId, value) => context
                                      .read<HomeBloc>()
                                      .add(WidgetValueChanged(
                                          widgetId, value.toDouble())),
                                  onOrderChanged: (newOrderWidgetIds) => context
                                      .read<HomeBloc>()
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
                                      .read<HomeBloc>()
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
                    onManageHome: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(
                                  value: context.read<HomeBloc>()),
                              BlocProvider.value(
                                  value: context.read<RoomsBloc>()),
                            ],
                            child: const ManageHomePage(),
                          ),
                        ),
                      );

                      if (!mounted) return;

                      context
                          .read<RoomsBloc>()
                          .add(const RoomsRefreshRequested());
                      context.read<HomeBloc>().add(const HomeStarted());
                    },
                    onManageDevices: () async {
                      context.read<HomeBloc>().add(const DevicesRequested(connected: true));
                      context.read<RoomsBloc>().add(const RoomsStarted());

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(
                                  value: context.read<HomeBloc>()),
                              BlocProvider.value(
                                  value: context.read<RoomsBloc>()),
                            ],
                            child: const ManageDevicesPage(),
                          ),
                        ),
                      );

                      if (!mounted) return;

                      context.read<HomeBloc>().add(const DevicesRequested(connected: true));
                      context
                          .read<RoomsBloc>()
                          .add(const RoomsRefreshRequested());
                    },
                    onSecurity: () {},
                    onLogout: _logout,
                  ),
          ),
        ],
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