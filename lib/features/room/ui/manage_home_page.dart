import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import หน้าที่เพิ่งสร้าง
import 'edit_family_name_page.dart'; 
import '../../user/ui/manage_user_page.dart';
import 'invite_member_page.dart';

import '../../home/bloc/devices_bloc.dart';
import '../bloc/rooms_bloc.dart';
import '../bloc/rooms_state.dart';
import 'manage_rooms_page.dart';

class ManageHomePage extends StatefulWidget {
  const ManageHomePage({super.key});

  @override
  State<ManageHomePage> createState() => _ManageHomePageState();
}

class _ManageHomePageState extends State<ManageHomePage> {
  // สร้างตัวแปรไว้เก็บชื่อบ้าน (ในอนาคตควรดึงมาจาก Bloc หรือ Initial Data)
  String _familyName = 'เก็ต A';

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
          'ตั้งค่าครอบครัว',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600, // ปรับให้หนาตาม UI
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ส่วนที่ 1: ข้อมูลทั่วไป ---
            _WhiteCard(
              child: Column(
                children: [
                  _buildSettingRow(
                    label: 'ชื่อครอบครัว',
                    value: _familyName, // ใช้ตัวแปรที่ประกาศไว้
                    onTap: () async {
                      // กดแล้วไปหน้าที่เพิ่งสร้าง
                      final newName = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditFamilyNamePage(initialName: _familyName),
                        ),
                      );

                      // ถ้ามีการส่งชื่อกลับมา และชื่อไม่ว่าง ให้ทำการอัปเดตหน้าจอ
                      if (newName != null && newName.isNotEmpty) {
                        setState(() {
                          _familyName = newName;
                        });
                        // TODO: ส่ง Event ไปยัง Bloc เพื่อบันทึกชื่อใหม่ลงฐานข้อมูล/API
                      }
                    },
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
                                  BlocProvider.value(value: context.read<RoomsBloc>()),
                                  BlocProvider.value(value: context.read<DevicesBloc>()),
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

            // --- ส่วนที่ 2: สมาชิกครอบครัว ---
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
              child: Column(
                children: [
                  _buildMemberRow(name: 'ฐาพล', role: 'Home Owner', email: 'taphon@example.com'),
                  _buildMemberRow(name: 'ธรรมสรณ์', role: 'Member', email: 'thumb@example.com'),
                  _buildMemberRow(name: 'อธิพงศ์', role: 'Member', email: 'athipong@example.com'),
                  
                  // ปุ่มเพิ่มสมาชิก
                  InkWell(
                    onTap: () async {
                      final result = await Navigator.push<Map<String,String>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InviteMemberPage(),
                        ),
                      );
                      if (result != null) {
                        // TODO: use data (name/email) to send invite or update state
                        debugPrint('Invite: \\${result['name']} <\\${result['email']}>');
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
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- ส่วนที่ 3: ปุ่มลบบ้าน ---
            _WhiteCard(
              child: InkWell(
                onTap: () => _showDeleteConfirmDialog(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Text(
                    'ลบบ้าน',
                    style: TextStyle(
                      color: Color(0xFFCF2F2F),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget Helpers เหมือนเดิม ---
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
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
            Text(
              value,
              style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w400),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberRow({required String name, required String role, required String email}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ManageUserPage(
              userName: name,
              userEmail: email,
              userRole: role,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.grey[300], radius: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
            Text(
              role,
              style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w400),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบบ้าน'),
        content: const Text('คุณต้องการลบบ้านนี้ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
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