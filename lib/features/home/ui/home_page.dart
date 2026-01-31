import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_mobile_frontend/features/home/models/device.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../bloc/devices_bloc.dart';
import '../bloc/devices_event.dart';
import '../bloc/devices_state.dart';
import 'widgets/device_card.dart';
import 'widgets/room_section.dart';
import 'widgets/top_tabs.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DevicesBloc()..add(const DevicesStarted()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
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

                  IconButton(
                    tooltip: 'Logout',
                    icon: const Icon(Icons.logout_rounded, color: Colors.black45),
                    onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              BlocBuilder<DevicesBloc, DevicesState>(
                buildWhen: (p, c) => p.selectedTab != c.selectedTab,
                builder: (context, st) {
                  return TopTab(
                    selected: st.selectedTab,
                    onChanged: (tab) => context.read<DevicesBloc>().add(DevicesTabChanged(tab)),
                  );
                },
              ),

              const SizedBox(height: 14),

              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CB2FF), Color(0xFFBFE5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: const [
                    Expanded(
                      child: Text(
                        '23°C\nจตุจักร, กรุงเทพฯ',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Icon(Icons.weekend_rounded, color: Colors.white, size: 58),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              BlocBuilder<DevicesBloc, DevicesState>(
                buildWhen: (p, c) =>
                    p.selectedRoom != c.selectedRoom ||
                    p.selectedTab != c.selectedTab ||
                    p.devices != c.devices,
                builder: (context, st) {
                  return RoomSection(
                    selectedRoom: st.selectedRoom,
                    deviceCount: st.deviceCount,
                    onRoomChanged: (r) => context.read<DevicesBloc>().add(DevicesRoomChanged(r)),
                  );
                },
              ),

              const SizedBox(height: 12),

              Expanded(
                child: BlocBuilder<DevicesBloc, DevicesState>(
                  builder: (context, st) {
                    if (st.isLoading) return const Center(child: CircularProgressIndicator());
                    if (st.error != null) return Center(child: Text(st.error!));

                    final devices = st.visibleDevices;
                    if (devices.isEmpty) return const Center(child: Text('ไม่มีอุปกรณ์ไฟในห้องนี้'));

                    return GridView.builder(
                      itemCount: devices.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.0,
                      ),
                      itemBuilder: (context, i) {
                        final d = devices[i];
                        return DeviceCard(
                          device: d,
                          onToggle: d is Toggleable
                              ? () => context.read<DevicesBloc>().add(DeviceToggled(d.id))
                              : null,
                          onValueChanged: (d is Quantifiable)
                              ? (v) => context.read<DevicesBloc>().add(DeviceValueChanged(d.id, v))
                              : null,
                        );

                      },
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
