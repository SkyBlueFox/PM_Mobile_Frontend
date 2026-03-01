import 'package:flutter/material.dart';

class EditUserNamePage extends StatefulWidget {
  final String initialName;

  const EditUserNamePage({super.key, required this.initialName});

  @override
  State<EditUserNamePage> createState() => _EditUserNamePageState();
}

class _EditUserNamePageState extends State<EditUserNamePage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB), // พื้นหลังสีเทาอ่อนตามรูป
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          'เปลี่ยนชื่อสมาชิก',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
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
              'ชื่อสมาชิก',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            //ช่องกรอกข้อมูล
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  border: InputBorder.none,
                  hintText: 'กรอกชื่อสมาชิก',
                ),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 32),
            //ปุ่มตกลง
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // ส่งชื่อใหม่กลับไปที่หน้าก่อนหน้า
                  Navigator.pop(context, _controller.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7BAAF7), // สีฟ้าตามรูป
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
