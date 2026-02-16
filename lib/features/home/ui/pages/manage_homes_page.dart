import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_mobile_frontend/features/home/bloc/devices_bloc.dart';

import 'manage_rooms_page.dart';

class ManageHomesPage extends StatelessWidget {
  const ManageHomesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text(
          'จัดการบ้าน',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            _Card(
              child: InkWell(
                onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<DevicesBloc>(),
        child: const ManageRoomsPage(),
      ),
    ),
  );
},

                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('บ้านเกม 1', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.black38),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  // TODO: join home
                },
                child: const Text('Join a home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: child,
    );
  }
}
