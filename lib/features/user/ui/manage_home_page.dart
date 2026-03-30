import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_mobile_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:pm_mobile_frontend/features/auth/bloc/auth_event.dart';

import 'manage_user_page.dart';
import 'invite_member_page.dart';

import '../../home/bloc/home_bloc.dart';
import '../bloc/user_bloc.dart';
import '../bloc/user_event.dart';
import '../bloc/user_state.dart';
import '../../room/bloc/rooms_bloc.dart';
import '../../room/bloc/rooms_state.dart';
import '../../room/ui/manage_rooms_page.dart';
import '../../../models/user.dart';

class ManageHomePage extends StatefulWidget {
  const ManageHomePage({super.key});

  @override
  State<ManageHomePage> createState() => _ManageHomePageState();
}

class _ManageHomePageState extends State<ManageHomePage> {
  String _familyName = 'เก็ต A';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if(user == null) {
      context.read<AuthBloc>().add(const AuthLogoutRequested());
      Navigator.pop(context);
      return;
    }
    context.read<UserBloc>().add(FetchUsers());
    context.read<UserBloc>().add(FetchUserByEmail(user.email!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          'จัดการบ้าน',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          if (state.status == UserStatus.failure && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WhiteCard(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "ชื่อครอบครัว",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Text(
                            "ครอบครัวของฉัน",
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                    BlocBuilder<RoomsBloc, RoomsState>(
                      builder: (context, state) {
                        final roomCount = state.rooms.length;
                        return _buildSettingRow(
                          label: 'จัดการห้อง',
                          value: '$roomCount ห้อง',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MultiBlocProvider(
                                  providers: [
                                    BlocProvider.value(
                                      value: context.read<RoomsBloc>(),
                                    ),
                                    BlocProvider.value(
                                      value: context.read<HomeBloc>(),
                                    ),
                                  ],
                                  child: const ManageRoomsPage(),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'สมาชิกครอบครัว',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              _WhiteCard(
                child: BlocBuilder<UserBloc, UserState>(
                  builder: (context, state) {
                    if (state.status == UserStatus.loading &&
                        state.users.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (state.users.isEmpty) {
                      return Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'ยังไม่มีสมาชิก',
                              style: TextStyle(
                                color: Colors.black45,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          _buildAddMemberButton(),
                        ],
                      );
                    }

                    final Role? myRole = state.user?.role;
                    return Column(
                      children: [
                        ...state.users.map(
                          (user) => _buildMemberRow(
                            name: user.name,
                            email: user.email,
                            myRole: myRole!,
                          ),
                        ),
                        _buildAddMemberButton(),
                      ],
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

  Widget _buildSettingRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.black45,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberRow({
    required String name,
    required String email,
    required Role myRole,
  }) {
    return InkWell(
      onTap: () async {
        //user from Bloc State
        if (myRole == Role.admin) {
          final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ManageUserPage(
              userName: name,
              userEmail: email,
              myRole: myRole,
              ),
          ),
        );

        if (result == true && mounted) {
          context.read<UserBloc>().add(FetchUsers());
        }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (myRole == Role.admin) 
              const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMemberButton() {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push<Map<String, String>>(
          context,
          MaterialPageRoute(
            builder: (_) => const InviteMemberPage(),
          ),
        );

        if (result != null) {
          debugPrint('Invite: ${result['name']} <${result['email']}>');
          context.read<UserBloc>().add(CreateUser(name: result['name']!, email: result['email']!));
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: const Text(
          'เพิ่มสมาชิก',
          style: TextStyle(
            color: Color(0xFF3AA7FF),
            fontWeight: FontWeight.w600,
          ),
        ),
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
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}