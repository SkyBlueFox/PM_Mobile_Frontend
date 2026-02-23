// lib/features/home/ui/pages/home_page.dart
//
// ✅ FIX: หน้าเลือก Add/Delete widget (Widget Picker) "ขาดส่ง API ไป save"
// - เดิม: เปิด sheet แล้วได้ result (List<int> included ids) แต่ไม่ส่งไปบันทึก
// - ใหม่: ส่ง event WidgetsVisibilitySaved ไปที่ DevicesBloc เพื่อให้ Bloc เรียก repo ยิง API save
//
// หมายเหตุ:
// - widget_picker_sheet.dart ยังเป็น UI ล้วน (คืนค่า ids) ไม่ผูก API
// - การยิง API/save อยู่ใน Bloc + Repository (clean architecture)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

import 'package:firebase_auth/firebase_auth.dart';

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
    // ✅ stop polling BEFORE logout (optional but recommended)
    context.read<DevicesBloc>().add(const WidgetsPollingStopped());
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  @override
  void initState() {
    super.initState();

    // ✅ ensure initial data is loaded (if needed)
    context.read<DevicesBloc>().add(const DevicesStarted());
    context.read<RoomsBloc>().add(const RoomsStarted());
  }

  @override
  void dispose() {
    context.read<DevicesBloc>().add(const WidgetsPollingStopped());
    super.dispose();
  }

  Future<void> _openActionsSheet(DevicesState st) async {
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
        await _openManageWidgetsSheet(st);
        break;
    }
  }

  Future<void> _openManageWidgetsSheet(DevicesState st) async {
    final roomId = st.selectedRoomId;
    final vm = HomeViewModel.fromState(st);

    // ✅ เปิด picker แล้วได้ "widgetIds ที่อยู่ใน Include" หลัง user กด Save
    final result = await showWidgetPickerSheet(
      context: context,
      title: 'Add/Delete widget',
      confirmText: 'Save',
      includedItems: vm.activeTiles,
      excludedItems: vm.drawerTiles,
      lockIncluded: false,
      headerTitle: 'บ้านเกม 1',
      headerSubtitle: '',
    );

    if (!mounted || result == null) return;

    // ✅ FIX: ส่งไปบันทึก include/exclude (ยิง API) ผ่าน Bloc
    // - roomId เป็น int? (null = All)
    // - includedWidgetIds คือ ids ที่ user อยากให้แสดง (include)
    context.read<DevicesBloc>().add(
          WidgetsVisibilitySaved(
            roomId: roomId,
            includedWidgetIds: result,
          ),
        );

    // ❗ไม่ต้องสั่ง refresh/polling ตรงนี้แล้วก็ได้
    // เพราะ bloc handler จะ refresh + restart polling ให้เอง
    // (ถ้าคุณไม่อยากให้ bloc ทำ ก็ย้ายกลับมาที่นี่ได้)
  }

  Future<void> _openModePicker(HomeWidgetTileVM tile) async {
    final options =
        tile.modeOptions.isEmpty ? const ['auto', 'cool', 'dry', 'fan', 'heat'] : tile.modeOptions;

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
      hintText: tile.hintText.isEmpty ? 'Enter text' : tile.hintText,
      confirmText: 'Send',
    );

    if (!mounted || text == null) return;
    context.read<DevicesBloc>().add(WidgetTextSubmitted(tile.widgetId, text));
  }

  void _startPollingIfHomeTab() {
    final bloc = context.read<DevicesBloc>();
    if (_bottomIndex == 0) {
      bloc.add(WidgetsPollingStarted(
        roomId: bloc.state.selectedRoomId,
        interval: const Duration(seconds: 5),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
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
                  p.reorderEnabled != c.reorderEnabled || p.reorderSaving != c.reorderSaving,
              builder: (context, st) {
                final enabled = st.reorderEnabled;
                return FloatingActionButton(
                  backgroundColor: blue,
                  onPressed: enabled
                      ? () => context.read<DevicesBloc>().add(const CommitReorderPressed())
                      : () => _openActionsSheet(st),
                  child: Icon(enabled ? Icons.check_rounded : Icons.more_horiz_rounded,
                      color: Colors.white),
                );
              },
            ),
      body: SafeArea(
        child: _bottomIndex == 0
            ? Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [sky, Color(0xFFDDF2FF)],
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.home_rounded, color: blue, size: 24),
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
                              icon: const Icon(Icons.logout, color: Colors.black45),
                            ),
                          ],
                        ),
                        BlocBuilder<DevicesBloc, DevicesState>(
                          buildWhen: (p, c) =>
                              p.rooms != c.rooms || p.selectedRoomId != c.selectedRoomId,
                          builder: (context, st) {
                            return TopTab(
                              rooms: st.rooms,
                              selectedRoomId: st.selectedRoomId,
                              onChanged: (roomId) {
                                context.read<DevicesBloc>().add(DevicesRoomChanged(roomId));
                                context.read<DevicesBloc>().add(WidgetsPollingStarted(roomId: roomId));
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: pageBg,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
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
                              return const Center(child: CircularProgressIndicator());
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
                              onToggle: (widgetId) =>
                                  context.read<DevicesBloc>().add(WidgetToggled(widgetId)),
                              onAdjust: (widgetId, value) => context
                                  .read<DevicesBloc>()
                                  .add(WidgetValueChanged(widgetId, value.toDouble())),
                              onOrderChanged: (newOrderWidgetIds) => context
                                  .read<DevicesBloc>()
                                  .add(WidgetsOrderChanged(newOrderWidgetIds)),
                              onOpenSensor: (tile) {
                                final sensorWidget =
                                    st.widgets.firstWhere((w) => w.widgetId == tile.widgetId);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => SensorDetailPage(sensorWidget: sensorWidget)),
                                );
                              },
                              onOpenMode: _openModePicker,
                              onOpenText: _openTextDialog,
                              onPressButton: (widgetId) =>
                                  context.read<DevicesBloc>().add(WidgetButtonPressed(widgetId)),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : MePage(
                displayName: user?.displayName ?? 'No Name',
                roleText: 'Role',
                photoUrl: user?.photoURL,
                onManageHome: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MultiBlocProvider(
                        providers: [
                          BlocProvider.value(value: context.read<DevicesBloc>()),
                          BlocProvider.value(value: context.read<RoomsBloc>()),
                        ],
                        child: const ManageHomesPage(),
                      ),
                    ),
                  );

                  if (!mounted) return;

                  context.read<RoomsBloc>().add(const RoomsRefreshRequested());
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
                          BlocProvider.value(value: context.read<DevicesBloc>()),
                          BlocProvider.value(value: context.read<RoomsBloc>()),
                        ],
                        child: const ManageDevicesPage(),
                      ),
                    ),
                  );

                  if (!mounted) return;

                  context.read<DevicesBloc>().add(const DevicesRequested());
                  context.read<RoomsBloc>().add(const RoomsRefreshRequested());
                },
                onSecurity: () {},
                onLogout: _logout,
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
              style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0B4A7A)),
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
            const Icon(Icons.cloud_off_rounded, size: 44, color: Color(0xFF3AA7FF)),
            const SizedBox(height: 10),
            const Text(
              'โหลดข้อมูลไม่สำเร็จ',
              style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0B4A7A)),
            ),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }
}