import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_mobile_frontend/features/home/ui/widgets/top_tabs.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../bloc/devices_bloc.dart';
import '../bloc/devices_event.dart';
import '../bloc/devices_state.dart';
import '../data/device_repository.dart';
import '../data/mqtt/mqtt_service.dart';
import '../models/device_widget.dart';
import 'widgets/widget_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final mqtt = MqttService(
          broker: 'YOUR_BROKER_HOST', //TODO: replace with your MQTT broker host
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

              // Container(
              //   height: 120,
              //   width: double.infinity,
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(18),
              //     gradient: const LinearGradient(
              //       colors: [Color(0xFF4CB2FF), Color(0xFFBFE5FF)],
              //       begin: Alignment.topLeft,
              //       end: Alignment.bottomRight,
              //     ),
              //   ),
              //   padding: const EdgeInsets.all(18),
              //   child: const Row(
              //     children: [
              //       Expanded(
              //         child: Text(
              //           '23°C\nจตุจักร, กรุงเทพฯ',
              //           style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
              //         ),
              //       ),
              //       Icon(Icons.weekend_rounded, color: Colors.white, size: 58),
              //     ],
              //   ),
              // ),

              const SizedBox(height: 12),

              Expanded(
                child: BlocBuilder<DevicesBloc, DevicesState>(
                  builder: (context, st) {
                    if (st.isLoading) return const Center(child: CircularProgressIndicator());
                    if (st.error != null) return Center(child: Text(st.error!));

                    final widgets = st.visibleWidgets;
                    if (widgets.isEmpty) return const Center(child: Text('ไม่มีอุปกรณ์ในห้องนี้'));

                    return GridView.builder(
                      itemCount: widgets.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.0,
                      ),
                      itemBuilder: (context, i) {
                      final w = widgets[i];

                      // Find the toggle widget for the same device (capability.id == 1 is toggle)
                      final DeviceWidget? toggle = st.widgets.cast<DeviceWidget?>().firstWhere(
                            (x) => x != null && x.device.id == w.device.id && x.capability.id == 1,
                            orElse: () => null,
                          );

                      final bool isOn = toggle == null ? true : toggle.value >= 1;

                      return WidgetCard(
                        key: ValueKey(w.widgetId),
                        widgetData: w,
                        isOn: isOn,
                        onToggle: (widgetId) =>
                            context.read<DevicesBloc>().add(WidgetToggled(widgetId)),
                        onValue: (widgetId, v) =>
                            context.read<DevicesBloc>().add(WidgetValueChanged(widgetId, v)),
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
