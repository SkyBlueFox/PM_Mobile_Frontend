// lib/features/home/ui/pages/home_page.dart
//
// Home page (after login)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';

import '../../bloc/devices_bloc.dart';
import '../../bloc/devices_event.dart';
import '../../bloc/devices_state.dart';
import '../../data/device_repository.dart';
import '../../data/room_repository.dart';
import '../../data/widget_repository.dart';

import '../view_models/home_view_model.dart';

import '../widgets/components/top_tabs.dart';
import '../widgets/components/home_widget_grid.dart';

import '../widgets/bottom_sheets/home_actions_sheet.dart';
import '../widgets/bottom_sheets/widget_picker_sheet.dart';

import 'me_page.dart';
import 'manage_homes_page.dart';
import 'sensor_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (_) => WidgetRepository(baseUrl: dotenv.get('BACKEND_API_URL')),
        ),
        RepositoryProvider(
          create: (_) => RoomRepository(baseUrl: dotenv.get('BACKEND_API_URL')),
        ),
        RepositoryProvider(
          create: (_) => DeviceRepository(baseUrl: dotenv.get('BACKEND_API_URL')),
        ),
      ],
      child: BlocProvider(
        create: (context) => DevicesBloc(
          widgetRepo: context.read<WidgetRepository>(),
          roomRepo: context.read<RoomRepository>(),
          deviceRepo: context.read<DeviceRepository>(),
        )..add(const DevicesStarted()),
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
  int _bottomIndex = 0;

  void _logout() {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  @override
  void initState() {
    super.initState();
    context.read<DevicesBloc>().add(const WidgetsPollingStarted());
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
      case HomeAction.addWidgets:
        await _openWidgetPickerSheet(st, isDeleteMode: false);
        break;

      case HomeAction.editWidgets:
        final enabled = !context.read<DevicesBloc>().state.reorderEnabled;
        context.read<DevicesBloc>().add(ReorderModeChanged(enabled));
        break;

      case HomeAction.deleteWidgets:
        await _openWidgetPickerSheet(st, isDeleteMode: true);
        break;
    }
  }

  Future<void> _openWidgetPickerSheet(
    DevicesState st, {
    required bool isDeleteMode,
  }) async {
    final vm = HomeViewModel.fromState(st);

    // ✅ ลิ้นชักแบบ Include/Exclude (return: includedIds)
    final includedIds = await showWidgetPickerSheet(
      context: context,
      title: isDeleteMode ? 'Remove widgets' : 'Add widgets',
      confirmText: isDeleteMode ? 'Remove' : 'Done',
      includedItems: vm.activeTiles,
      excludedItems: vm.drawerTiles,
      isDeleteMode: isDeleteMode,
    );

    if (!mounted || includedIds == null) return;

    // TODO: connect API:
    // - ตั้งค่า active/inactive ตาม includedIds (final state)
    // - แล้ว refresh ห้องเดิม
    // context.read<DevicesBloc>().add(DevicesRoomChanged(st.selectedRoomId));
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
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'ฉัน'),
        ],
      ),

      // ✅ ซ่อน FAB ตอนอยู่หน้า “ฉัน”
      floatingActionButton: _bottomIndex == 0
          ? BlocBuilder<DevicesBloc, DevicesState>(
              buildWhen: (p, c) =>
                  p.reorderEnabled != c.reorderEnabled ||
                  p.reorderSaving != c.reorderSaving,
              builder: (context, st) {
                final enabled = st.reorderEnabled;

                return FloatingActionButton(
                  backgroundColor: const Color(0xFF3AA7FF),
                  onPressed: enabled
                      ? () => context.read<DevicesBloc>().add(const CommitReorderPressed())
                      : () => _openActionsSheet(st),
                  child: Icon(enabled ? Icons.check_rounded : Icons.more_horiz_rounded),
                );
              },
            )
          : null,

      body: SafeArea(
        child: _bottomIndex == 0
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Header
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

                    // Room tabs
                    BlocBuilder<DevicesBloc, DevicesState>(
                      buildWhen: (p, c) =>
                          p.rooms != c.rooms || p.selectedRoomId != c.selectedRoomId,
                      builder: (context, st) {
                        return TopTab(
                          rooms: st.rooms,
                          selectedRoomId: st.selectedRoomId,
                          onChanged: (roomId) =>{
                              context.read<DevicesBloc>().add(DevicesRoomChanged(roomId)),
                              context.read<DevicesBloc>().add(
                                WidgetsPollingStarted(roomId: roomId),
                              )
                              },
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    // Main content
                    Expanded(
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

                          // Empty state
                          if (vm.tiles.isEmpty) {
                            return const _EmptyState(
                              title: 'No widgets in this room',
                              subtitle: 'Tap the blue button to add widgets.',
                            );
                          }

                          return HomeWidgetGrid(
                            tiles: vm.tiles,
                            reorderEnabled: st.reorderEnabled,

                            onToggle: (widgetId) =>
                                context.read<DevicesBloc>().add(WidgetToggled(widgetId)),

                            onAdjust: (widgetId, value) {
                              context.read<DevicesBloc>().add(
                                    WidgetValueChanged(widgetId, value.toDouble()),
                                  );
                            },

                            onOrderChanged: (newOrderWidgetIds) {
                              context
                                  .read<DevicesBloc>()
                                  .add(WidgetsOrderChanged(newOrderWidgetIds));
                            },

                            onOpenSensor: (HomeWidgetTileVM value) {
                               final sensorWidget = st.widgets.firstWhere((w) => w.widgetId == value.widgetId);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SensorDetailPage(sensorWidget: sensorWidget),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            : MePage(
                displayName: 'FirstName LastName',
                roleText: 'Role',
                onManageHome: () {
                  final devicesBloc = context.read<DevicesBloc>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: devicesBloc,
                        child: const ManageHomesPage(),
                      ),
                    ),
                  );
                },

                onManageDevices: () {
                  // TODO
                },
                onSecurity: () {
                  // TODO
                },
                onLogout: _logout,
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.widgets_outlined, size: 44, color: Colors.black38),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: Colors.black38),
            const SizedBox(height: 10),
            const Text('Unable to load data', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
