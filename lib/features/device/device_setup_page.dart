import 'package:flutter/material.dart';

import '../home/models/device.dart';
import '../home/models/room.dart';

class DeviceSetupPage extends StatefulWidget {
  final Device device;
  final Room room;

  const DeviceSetupPage({
    super.key,
    required this.device,
    required this.room,
  });

  @override
  State<DeviceSetupPage> createState() => _DeviceSetupPageState();
}

class _DeviceSetupPageState extends State<DeviceSetupPage> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();

    // ✅ วิธีที่ 2: ใช้ชื่อ device เป็นค่าเริ่มต้น (แทน nickname)
    _nameCtrl = TextEditingController(text: widget.device.name);
    // ถ้าฟิลด์ของคุณชื่อ deviceName ให้เปลี่ยนเป็น:
    // _nameCtrl = TextEditingController(text: widget.device.deviceName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    // mock: ยังไม่บันทึกจริง (ส่งค่าที่ผู้ใช้แก้กลับไปได้)
    Navigator.pop(context, _nameCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF3AA7FF);

    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มอุปกรณ์'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          children: [
            const Text(
              'ชื่ออุปกรณ์',
              style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _InputCard(
              child: TextField(
                controller: _nameCtrl, // ✅ ต้องเป็น controller
                textAlign: TextAlign.center,
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'รายละเอียด',
              style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            _InfoCard(
              left: 'Device’s Name',
              right: widget.device.name,
              // ถ้าฟิลด์ชื่อ deviceName ให้ใช้ widget.device.deviceName
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _save,
                child: const Text(
                  'เสร็จสิ้น',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---- Small UI helpers ----

class _InputCard extends StatelessWidget {
  final Widget child;
  const _InputCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String left;
  final String right;

  const _InfoCard({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(left, style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(
            right,
            style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
