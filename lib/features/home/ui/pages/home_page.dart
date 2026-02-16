// lib/features/home/ui/pages/home_page.dart

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

import 'add_device_page.dart';

// ✅ เพิ่ม
import 'manage_homes_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => WidgetRepository(baseUrl: dotenv.get('BACKEND_API_URL'))),
        RepositoryProvider(create: (_) => RoomRepository(baseUrl: dotenv.get('BACKEND_API_URL'))),
        RepositoryProvider(create: (_) => DeviceRepository(baseUrl: dotenv.get('BACKEND_API_URL'))),
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
    final vm = HomeViewModel.fromState(st);

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

    // TODO: ต่อ API/Bloc เพื่อ set active/inactive + refresh
    // context.read<DevicesBloc>().add(WidgetsVisibilitySaved(includedWidgetIds: result));
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF3AA7FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) => setState(() => _bottomIndex = i),
        selectedItemColor: blue,
        unselectedItemColor: Colors.black38,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Me'),
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
                  child: Icon(enabled ? Icons.check_rounded : Icons.more_horiz_rounded),
                );
              },
            ),

      body: IndexedStack(
        index: _bottomIndex,
        children: [
          _HomeTab(onLogout: _logout),
          _MeTab(
            onLogout: _logout,

            // ✅ แก้: กด “จัดการบ้าน” ให้ไปหน้า ManageHomePage
            onManageHome: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<DevicesBloc>(),
                    child: const ManageHomesPage(),
                  ),
                ),
              );
            },

            onManageDevices: () {
              // TODO: ต่อไปค่อยทำหน้า “จัดการอุปกรณ์”
            },
            onSecurity: () {
              // TODO: ต่อไปค่อยทำหน้า “บัญชีและความปลอดภัย”
            },
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final VoidCallback onLogout;
  const _HomeTab({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF3AA7FF);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.home_rounded, color: blue, size: 28),
                const SizedBox(width: 10),
                const Text('บ้านเกม 1', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.black45),
                  onSelected: (v) {
                    if (v == 'logout') onLogout();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'logout', child: Text('Logout')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            BlocBuilder<DevicesBloc, DevicesState>(
              buildWhen: (p, c) => p.rooms != c.rooms || p.selectedRoomId != c.selectedRoomId,
              builder: (context, st) {
                return TopTab(
                  rooms: st.rooms,
                  selectedRoomId: st.selectedRoomId,
                  onChanged: (roomId) => context.read<DevicesBloc>().add(DevicesRoomChanged(roomId)),
                );
              },
            ),
            const SizedBox(height: 14),
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

                  if (vm.tiles.isEmpty) {
                    return const _EmptyState(
                      title: 'No widgets in this room',
                      subtitle: 'Tap the blue button to add widgets.',
                    );
                  }

                  return HomeWidgetGrid(
                    tiles: vm.tiles,
                    reorderEnabled: st.reorderEnabled,
                    onToggle: (widgetId) => context.read<DevicesBloc>().add(WidgetToggled(widgetId)),
                    onAdjust: (widgetId, value) {
                      context.read<DevicesBloc>().add(
                            WidgetValueChanged(widgetId, value.toDouble()),
                          );
                    },
                    onOrderChanged: (newOrderWidgetIds) {
                      context.read<DevicesBloc>().add(WidgetsOrderChanged(newOrderWidgetIds));
                    },
                    onOpenSensor: (tile) {
                      // TODO: push sensor detail
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeTab extends StatelessWidget {
  final VoidCallback onManageHome;
  final VoidCallback onManageDevices;
  final VoidCallback onSecurity;
  final VoidCallback onLogout;

  const _MeTab({
    required this.onManageHome,
    required this.onManageDevices,
    required this.onSecurity,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF3AA7FF);

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFCFEAFF), Color(0xFFF6F7FB)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
          children: [
            const SizedBox(height: 18),
            const Center(child: CircleAvatar(radius: 44, backgroundColor: Color(0xFFD9D9D9))),
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(999)),
                child: const Text(
                  'FirstName LastName',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text('Role', style: TextStyle(color: blue, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  _MeTile(title: 'จัดการบ้าน', onTap: onManageHome),
                  const Divider(height: 1),
                  _MeTile(title: 'จัดการอุปกรณ์', onTap: onManageDevices),
                  const Divider(height: 1),
                  _MeTile(title: 'บัญชีและความปลอดภัย', onTap: onSecurity),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onLogout,
                child: const Text('ออกจากระบบ', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _MeTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black45),
      onTap: onTap,
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
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
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
