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
import '../../data/room_repository.dart';
import '../../data/widget_repository.dart';

import '../view_models/home_view_model.dart';

import '../widgets/components/top_tabs.dart';
import '../widgets/components/home_widget_grid.dart';

import '../widgets/bottom_sheets/home_actions_sheet.dart';
import '../widgets/bottom_sheets/widget_picker_sheet.dart';

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
      ],
      child: BlocProvider(
        create: (context) => DevicesBloc(
          widgetRepo: context.read<WidgetRepository>(),
          roomRepo: context.read<RoomRepository>(),
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
  bool _reorderEnabled = false;
  int _bottomIndex = 0;

  void _logout() {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  Future<void> _openActionsSheet(DevicesState st) async {
    final action = await showHomeActionsSheet(context);
    if (!mounted || action == null) return;

    switch (action) {
      case HomeAction.addWidgets:
        await _openWidgetPickerSheet(st, isDeleteMode: false);
        break;

      case HomeAction.editWidgets:
        setState(() => _reorderEnabled = !_reorderEnabled);
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

    final result = await showWidgetPickerSheet(
      context: context,
      title: isDeleteMode ? 'Remove widgets' : 'Add widgets',
      confirmText: isDeleteMode ? 'Remove' : 'Add',

      // ✅ กัน null (ตอนนี้ vm.activeTiles/vm.drawerTiles ยังเป็น null ในไฟล์ที่คุณส่งมา)
      items: vm.tiles,

      isDeleteMode: isDeleteMode,
    );

    if (!mounted || result == null) return;

    // TODO: connect API add/remove แล้ว refresh
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
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Me'),
        ],
      ),
      floatingActionButton: BlocBuilder<DevicesBloc, DevicesState>(
        builder: (context, st) {
          return FloatingActionButton(
            backgroundColor: const Color(0xFF3AA7FF),
            onPressed: _reorderEnabled
          ? () => context.read<DevicesBloc>().add(const CommitReorderPressed()) //TODO: implement reorder commit
          : () => _openActionsSheet(st),
      child: Icon(_reorderEnabled ? Icons.check_rounded : Icons.more_horiz_rounded),
          );
        },
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
                      p.selectedRoomId != c.selectedRoomId,
                  builder: (context, st) {
                    if (st.isLoading && st.widgets.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (st.error != null && st.widgets.isEmpty) {
                      return _ErrorState(message: st.error!);
                    }

                    final widgets = st.visibleWidgets;
                    final vm = HomeViewModel.fromState(st);

                    if (widgets.isEmpty) {
                      return const _EmptyState(
                        title: 'No widgets in this room',
                        subtitle: 'Tap the blue button to add widgets.',
                      );
                    }

                    return HomeWidgetGrid(
  tiles: vm.tiles,
  reorderEnabled: _reorderEnabled,

  onToggle: (widgetId) =>
      context.read<DevicesBloc>().add(WidgetToggled(widgetId)),

  onAdjust: (widgetId, value) {
  context.read<DevicesBloc>().add(
        WidgetValueChanged(widgetId, value.toDouble()),
      );
},


  onOrderChanged: (newOrderWidgetIds) {
    // TODO: call API change order
  }, onOpenSensor: (HomeWidgetTileVM value) {  },
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
