import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/device_repository.dart';
import '../home/models/device.dart';

class DeviceSetupPage extends StatefulWidget {
  final Device device;

  const DeviceSetupPage({
    super.key,
    required this.device,
  });

  @override
  State<DeviceSetupPage> createState() => _DeviceSetupPageState();
}

class _DeviceSetupPageState extends State<DeviceSetupPage> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.device.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) return;

    try {
      final repo = context.read<DeviceRepository>();
      await repo.updateDeviceName(
        deviceId: widget.device.id,
        deviceName: newName,
      );

      if (!mounted) return;
      Navigator.pop(context, newName); // return new name
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _confirmUnpair() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unpair Device'),
        content: const Text('ต้องการยกเลิกการเชื่อมต่ออุปกรณ์นี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ยกเลิกการเชื่อมต่อ'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (ok != true) return;

    try {
      final repo = context.read<DeviceRepository>();
      await repo.unpairDevice(widget.device.id);

      if (!mounted) return;
      Navigator.pop(context, 'unpair');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unpair failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF3AA7FF);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าอุปกรณ์'),
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
                controller: _nameCtrl,
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
            ),

            const SizedBox(height: 30),

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

            const SizedBox(height: 16),

            // 🔴 UNPAIR BUTTON
            SizedBox(
              height: 54,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _confirmUnpair,
                child: const Text(
                  'ยกเลิกการเชื่อมต่ออุปกรณ์',
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