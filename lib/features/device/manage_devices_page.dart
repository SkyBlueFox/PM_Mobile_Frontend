import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_mobile_frontend/features/user/bloc/user_bloc.dart';
import 'package:pm_mobile_frontend/features/user/bloc/user_event.dart';
import 'package:pm_mobile_frontend/models/user.dart';

import '../../models/device.dart';
import '../home/bloc/home_bloc.dart';
import '../home/bloc/home_event.dart';
import '../home/bloc/home_state.dart';

import '../home/ui/pages/add_device_page.dart';
import 'device_setup_page.dart';

class ManageDevicesPage extends StatefulWidget {
  /// Optional: if you want to filter only devices in a room
  final int? roomId;
  final String? roomName;

  const ManageDevicesPage({
    super.key,
    this.roomId,
    this.roomName,
  });

  @override
  State<ManageDevicesPage> createState() => _ManageDevicesPageState();
}

class _ManageDevicesPageState extends State<ManageDevicesPage> {
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    context.read<UserBloc>().add(FetchUserByEmail(user!.email!));
    context.read<HomeBloc>().add(const DevicesRequested(connected: true));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.roomId == null
        ? 'จัดการอุปกรณ์'
        : 'อุปกรณ์ใน ${widget.roomName ?? 'ห้อง'}';

    final userState = context.select((UserBloc b) => b.state);
    final isAdmin = userState.user?.role == Role.admin;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: Text(
          title,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            onPressed: () {
              context.read<HomeBloc>().add(const DevicesRequested(connected: true));
            },
            icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        buildWhen: (p, c) =>
            p.isLoading != c.isLoading ||
            p.error != c.error ||
            p.devices != c.devices,
        builder: (context, st) {
  final all = st.devices ?? const <Device>[];
  final devices = all;

  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    child: Column(
      children: [
        if (st.isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: CircularProgressIndicator(),
          ),

        if (!st.isLoading && st.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _ErrorCard(
              message: st.error!,
              onRetry: () => context.read<HomeBloc>().add(
                    const DevicesRequested(connected: true),
                  ),
            ),
          ),

        if (!st.isLoading && st.error == null && devices.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
              'ยังไม่มีอุปกรณ์',
              style: TextStyle(color: Colors.black54),
            ),
          ),

        if (!st.isLoading && st.error == null && devices.isNotEmpty)
          Expanded(
            child: _WhiteCard(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: devices.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final d = devices[i];

                  return InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(value: context.read<HomeBloc>()),
                            ],
                            child: DeviceSetupPage(device: d),
                          ),
                        ),
                      );

                      if (!mounted) return;
                      context.read<HomeBloc>().add(
                            const DevicesRequested(connected: true),
                          );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.devices_other_rounded,
                            color: Color(0xFF3AA7FF),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  d.type,
                                  style: const TextStyle(
                                    color: Colors.black45,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        if (isAdmin) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<HomeBloc>()),
                      ],
                      child: const AddDevicePage(),
                    ),
                  ),
                );
              },
              child: const Text(
                'เพิ่มอุปกรณ์',
                style: TextStyle(
                  color: Color(0xFF3AA7FF),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: child,
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        children: [
          Text(
            'โหลดรายการอุปกรณ์ไม่สำเร็จ\n$message',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: onRetry, child: const Text('ลองใหม่')),
        ],
      ),
    );
  }
}