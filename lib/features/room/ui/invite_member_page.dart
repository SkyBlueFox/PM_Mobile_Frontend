import 'package:flutter/material.dart';

class InviteMemberPage extends StatefulWidget {
  const InviteMemberPage({super.key});

  @override
  State<InviteMemberPage> createState() => _InviteMemberPageState();
}

class _InviteMemberPageState extends State<InviteMemberPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          'เพิ่มสมาชิก',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ชื่อ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  border: InputBorder.none,
                  hintText: 'กรอกชื่อสมาชิก',
                ),
                style: const TextStyle(fontWeight: FontWeight.w400),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'อีเมล',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  border: InputBorder.none,
                  hintText: 'กรอกอีเมล',
                ),
                style: const TextStyle(fontWeight: FontWeight.w400),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: ส่งคำเชิญ
                  Navigator.pop(context, {
                    'name': _nameController.text.trim(),
                    'email': _emailController.text.trim(),
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7BAAF7),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ตกลง',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
