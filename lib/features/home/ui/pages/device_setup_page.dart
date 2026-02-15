import 'package:flutter/material.dart';

import '../../models/room.dart';

class DeviceSetupPage extends StatefulWidget {
  final String nickname;
  final String deviceName;
  final Room room;

  const DeviceSetupPage({
    super.key,
    required this.nickname,
    required this.deviceName,
    required this.room,
  });

  @override
  State<DeviceSetupPage> createState() => _DeviceSetupPageState();
}

class _DeviceSetupPageState extends State<DeviceSetupPage> {
  late final TextEditingController _nicknameCtrl;

  // mock widget list in screenshot: toggle + sensor/info tile
  bool _ledOn = true;

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController(text: widget.nickname);
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    // TODO: call repo/bloc save config
    Navigator.pop(context);
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
            const Text('Nickname', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _InputCard(
              child: TextField(
                controller: _nicknameCtrl,
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
            const SizedBox(height: 14),

            const Text('รายละเอียด', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            _InfoCard(
              left: 'Device’s Name',
              right: widget.deviceName,
            ),
            const SizedBox(height: 10),

            const Text('Widget', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            _WidgetRow(
              title: 'LED 1',
              subtitle: 'cap',
              trailing: Switch(
                value: _ledOn,
                onChanged: (v) => setState(() => _ledOn = v),
              ),
            ),
            const Divider(height: 1),

            _WidgetRow(
              title: 'Sensor A',
              subtitle: 'cap',
              trailing: const SizedBox.shrink(),
              centerAlign: true,
            ),
            const SizedBox(height: 18),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _save,
                child: const Text('เสร็จสิ้น', style: TextStyle(fontWeight: FontWeight.w800)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
          Text(right, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _WidgetRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final bool centerAlign;

  const _WidgetRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.centerAlign = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F7FB),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: centerAlign
                ? Column(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w600)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w600)),
                    ],
                  ),
          ),
          trailing,
        ],
      ),
    );
  }
}
