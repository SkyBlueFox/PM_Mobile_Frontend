import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home/bloc/devices_bloc.dart';
import '../home/bloc/devices_event.dart';
import '../room/bloc/rooms_bloc.dart';
import '../room/bloc/rooms_event.dart';

// ✅ change path to where you put it
import '../device/manage_devices_page.dart';

class MePage extends StatelessWidget {
  final String displayName;
  final String roleText;

  final VoidCallback onManageHome;
  // ✅ you can keep this, but we’ll provide a default navigation if you want
  final VoidCallback? onManageDevices;
  final VoidCallback onSecurity;
  final VoidCallback onLogout;

  const MePage({
    super.key,
    required this.displayName,
    required this.roleText,
    required this.onManageHome,
    this.onManageDevices, // ✅ optional now
    required this.onSecurity,
    required this.onLogout,
  });

  void _goManageDevices(BuildContext context) {
    // load latest rooms+devices for mapping device -> room
    context.read<DevicesBloc>().add(const DevicesRequested());
    context.read<RoomsBloc>().add(const RoomsStarted());

    Navigator.push(
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFCBEAFF),
            Color(0xFFF6F7FB),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            children: [
              const SizedBox(height: 18),

              // Avatar
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
              ),
              const SizedBox(height: 14),

              // Name pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3AA7FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              Text(
                roleText,
                style: const TextStyle(
                  color: Color(0xFF3AA7FF),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),

              // Menu card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _MenuRow(
                      title: 'จัดการบ้าน',
                      onTap: onManageHome,
                    ),
                    const Divider(height: 1),
                    _MenuRow(
                      title: 'จัดการอุปกรณ์',
                      onTap: onManageDevices ?? () => _goManageDevices(context),
                    ),
                    const Divider(height: 1),
                    _MenuRow(
                      title: 'บัญชีและความปลอดภัย',
                      onTap: onSecurity,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Logout
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
                  onPressed: onLogout,
                  child: const Text(
                    'ออกจากระบบ',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _MenuRow({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}