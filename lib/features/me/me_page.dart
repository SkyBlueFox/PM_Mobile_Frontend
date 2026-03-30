import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_mobile_frontend/features/user/bloc/user_bloc.dart';
import 'package:pm_mobile_frontend/features/user/bloc/user_event.dart';
import 'package:pm_mobile_frontend/features/user/bloc/user_state.dart';

import '../home/bloc/home_bloc.dart';
import '../home/bloc/home_event.dart';
import '../room/bloc/rooms_bloc.dart';
import '../room/bloc/rooms_event.dart';
import '../device/manage_devices_page.dart';
import '../../models/user.dart';

class MePage extends StatefulWidget {
  final VoidCallback onManageHome;
  final VoidCallback? onManageDevices;
  final VoidCallback onSecurity;
  final VoidCallback onLogout;

  const MePage({
    super.key,
    required this.onManageHome,
    this.onManageDevices,
    required this.onSecurity,
    required this.onLogout,
  });

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  User? firebaseUser;

  @override
  void initState() {
    super.initState();
    firebaseUser = FirebaseAuth.instance.currentUser;

    final email = firebaseUser?.email;
    if (email != null) {
      context.read<UserBloc>().add(FetchUserByEmail(email));
    }
  }

  void _goManageDevices(BuildContext context) {
    context.read<HomeBloc>().add(const DevicesRequested(connected: true));
    context.read<RoomsBloc>().add(const RoomsStarted());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<HomeBloc>()),
            BlocProvider.value(value: context.read<RoomsBloc>()),
          ],
          child: const ManageDevicesPage(),
        ),
      ),
    );
  }

  String _roleLabel(Role? role) {
    switch (role) {
      case Role.admin:
        return 'Admin';
      case Role.user:
        return 'User';
      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    const double contentMaxWidth = 380;
    const Color topBlue = Color(0xFFCBEAFF);

    final highResPhoto = firebaseUser?.photoURL != null &&
            firebaseUser!.photoURL!.isNotEmpty
        ? "${firebaseUser!.photoURL!}?sz=200"
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
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
            child: BlocBuilder<UserBloc, UserState>(
              builder: (context, state) {
                final appUser = state.user;
                final displayName = appUser?.name ??
                    firebaseUser?.displayName ??
                    firebaseUser?.email ??
                    'Unknown User';
                final email = appUser?.email ?? firebaseUser?.email ?? '-';
                final roleText = _roleLabel(appUser?.role);

                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: contentMaxWidth),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                        child: Column(
                          children: [
                            const SizedBox(height: 18),
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: highResPhoto != null
                                    ? Image.network(
                                        highResPhoto,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _fallbackAvatar(),
                                      )
                                    : _fallbackAvatar(),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
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
                              email,
                              style: const TextStyle(
                                color: Color(0xFF3AA7FF),
                                fontWeight: FontWeight.w700,
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
                            const SizedBox(height: 12),
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
                                    onTap: widget.onManageHome,
                                  ),
                                  const SizedBox(height: 2),
                                  _MenuRow(
                                    title: 'จัดการอุปกรณ์',
                                    onTap: widget.onManageDevices ??
                                        () => _goManageDevices(context),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: widget.onLogout,
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: const Color(0xFFE0E0E0),
      child: const Icon(
        Icons.person,
        size: 40,
        color: Colors.white,
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
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}