import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home/bloc/home_bloc.dart';
import '../home/bloc/home_event.dart';
import '../room/bloc/rooms_bloc.dart';
import '../room/bloc/rooms_event.dart';
import '../device/manage_devices_page.dart';

class MePage extends StatelessWidget {
  final String displayName;
  final String roleText;
  final String? photoUrl;

  final VoidCallback onManageHome;
  final VoidCallback? onManageDevices;
  final VoidCallback onSecurity; // kept for compatibility (not shown)
  final VoidCallback onLogout;

  const MePage({
    super.key,
    required this.displayName,
    required this.roleText,
    required this.photoUrl,
    required this.onManageHome,
    this.onManageDevices,
    required this.onSecurity,
    required this.onLogout,
  });

  void _goManageDevices(BuildContext context) {
    context.read<HomeBloc>().add(const DevicesRequested());
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

  @override
  Widget build(BuildContext context) {
    final highResPhoto =
        photoUrl != null && photoUrl!.isNotEmpty ? "${photoUrl!}?sz=200" : null;

    // จำกัดความกว้างการ์ด/แถวให้ไม่เต็มจอเหมือนตัวอย่างด้านขวา
    const double contentMaxWidth = 380;

    const Color topBlue = Color(0xFFCBEAFF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [
                  topBlue,
                  Color(0xF5F5F5F5),
                ],
                stops: const [0.0, 0.35],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                    child: Column(
                      children: [
                        const SizedBox(height: 18),

                        // Avatar
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
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

                        // Name pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
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

                        // Role
                        Text(
                          roleText,
                          style: const TextStyle(
                            color: Color(0xFF3AA7FF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Menu card (ไม่มี Divider และลบ "บัญชีและความปลอดภัย")
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
                              const SizedBox(height: 2),
                              _MenuRow(
                                title: 'จัดการอุปกรณ์',
                                onTap: onManageDevices ??
                                    () => _goManageDevices(context),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Logout
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
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
              ),
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