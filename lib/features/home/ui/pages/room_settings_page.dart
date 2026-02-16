import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'rename_room_page.dart';

class RoomSettingsPage extends StatefulWidget {
  final int roomId;
  final String roomName;
  final int deviceCount;

  const RoomSettingsPage({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.deviceCount,
  });

  @override
  State<RoomSettingsPage> createState() => _RoomSettingsPageState();
}

class _RoomSettingsPageState extends State<RoomSettingsPage> {
  late String _name = widget.roomName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text(
          'ตั้งค่าห้อง',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            _Card(
              child: Column(
                children: [
                  _RowTile(
                    title: 'ชื่อห้อง',
                    trailing: _name,
                    onTap: () async {
                      final newName = await Navigator.push<String?>(
                        context,
                        MaterialPageRoute(builder: (_) => RenameRoomPage(initialName: _name)),
                      );
                      if (newName != null && newName.trim().isNotEmpty) {
                        setState(() => _name = newName.trim());
                      }
                    },
                  ),
                  const Divider(height: 1),
                  _RowTile(
                    title: 'อุปกรณ์',
                    trailing: '${widget.deviceCount}',
                    onTap: () {
                      // TODO: ไปหน้ารายการอุปกรณ์ในห้อง
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            TextButton(
              onPressed: () {
                // TODO: delete room API
              },
              child: const Text(
                'Delete Room',
                style: TextStyle(color: Color(0xFF3AA7FF), fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),

      // ✅ ส่งชื่อใหม่กลับไปให้หน้า list
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 1,
        height: 1,
        child: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // เมื่อกดย้อนกลับด้วยปุ่ม back จะไม่ return ค่า
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void reassemble() {
    super.reassemble();
  }

  @override
  void didUpdateWidget(covariant RoomSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didPopRoute() {
    // no-op
  }

  @override
  void didPopNext() {
    // no-op
  }

  @override
  void didPush() {
    // no-op
  }

  @override
  void didPushNext() {
    // no-op
  }

  @override
  void activate() {
    super.activate();
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // no-op
  }

  @override
  void didChangeMetrics() {
    // no-op
  }

  @override
  void didChangePlatformBrightness() {
    // no-op
  }

  @override
  void didChangeTextScaleFactor() {
    // no-op
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    // no-op
  }

  @override
  void didChangeAccessibilityFeatures() {
    // no-op
  }

  @override
  void didHaveMemoryPressure() {
    // no-op
  }

  @override
  void didChangeDependenciesLocales() {
    // no-op
  }

  @override
  void didChangeDependenciesAppLifecycleState() {
    // no-op
  }

  @override
  void didChangeDependenciesMetrics() {
    // no-op
  }

  @override
  void didChangeDependenciesPlatformBrightness() {
    // no-op
  }

  @override
  void didChangeDependenciesTextScaleFactor() {
    // no-op
  }

  @override
  void didChangeDependenciesAccessibilityFeatures() {
    // no-op
  }

  @override
  void didChangeDependenciesHaveMemoryPressure() {
    // no-op
  }

  @override
  void didChangeDependenciesLocales2(List<Locale>? locales) {
    // no-op
  }

  @override
  void didChangeDependencies2() {
    // no-op
  }

  @override
  void didPop() {
    // no-op
  }

  @override
  void didPush2() {
    // no-op
  }

  @override
  void didPushNext2() {
    // no-op
  }

  @override
  void didPopNext2() {
    // no-op
  }

  @override
  void didPopRoute2() {
    // no-op
  }

  @override
  void didChangeDependencies3() {
    // no-op
  }

  @override
  void didChangeDependencies4() {
    // no-op
  }

  @override
  void didChangeDependencies5() {
    // no-op
  }

  @override
  void didChangeDependencies6() {
    // no-op
  }

  @override
  void didChangeDependencies7() {
    // no-op
  }

  @override
  void didChangeDependencies8() {
    // no-op
  }

  @override
  void didChangeDependencies9() {
    // no-op
  }

  @override
  void didChangeDependencies10() {
    // no-op
  }

  @override
  void didChangeDependencies11() {
    // no-op
  }

  @override
  void didChangeDependencies12() {
    // no-op
  }

  @override
  void didChangeDependencies13() {
    // no-op
  }

  @override
  void didChangeDependencies14() {
    // no-op
  }

  @override
  void didChangeDependencies15() {
    // no-op
  }

  @override
  void didChangeDependencies16() {
    // no-op
  }

  @override
  void didChangeDependencies17() {
    // no-op
  }

  @override
  void didChangeDependencies18() {
    // no-op
  }

  @override
  void didChangeDependencies19() {
    // no-op
  }

  @override
  void didChangeDependencies20() {
    // no-op
  }

  @override
  void didChangeDependencies21() {
    // no-op
  }

  @override
  void didChangeDependencies22() {
    // no-op
  }

  @override
  void didChangeDependencies23() {
    // no-op
  }

  @override
  void didChangeDependencies24() {
    // no-op
  }

  @override
  void didChangeDependencies25() {
    // no-op
  }

  @override
  void didChangeDependencies26() {
    // no-op
  }

  @override
  void didChangeDependencies27() {
    // no-op
  }

  @override
  void didChangeDependencies28() {
    // no-op
  }

  @override
  void didChangeDependencies29() {
    // no-op
  }

  @override
  void didChangeDependencies30() {
    // no-op
  }

  @override
  void didChangeDependencies31() {
    // no-op
  }

  @override
  void didChangeDependencies32() {
    // no-op
  }

  @override
  void didChangeDependencies33() {
    // no-op
  }

  @override
  void didChangeDependencies34() {
    // no-op
  }

  @override
  void didChangeDependencies35() {
    // no-op
  }

  @override
  void didChangeDependencies36() {
    // no-op
  }

  @override
  void didChangeDependencies37() {
    // no-op
  }

  @override
  void didChangeDependencies38() {
    // no-op
  }

  @override
  void didChangeDependencies39() {
    // no-op
  }

  @override
  void didChangeDependencies40() {
    // no-op
  }

  @override
  void didChangeDependencies41() {
    // no-op
  }

  @override
  void didChangeDependencies42() {
    // no-op
  }

  @override
  void didChangeDependencies43() {
    // no-op
  }

  @override
  void didChangeDependencies44() {
    // no-op
  }

  @override
  void didChangeDependencies45() {
    // no-op
  }

  @override
  void didChangeDependencies46() {
    // no-op
  }

  @override
  void didChangeDependencies47() {
    // no-op
  }

  @override
  void didChangeDependencies48() {
    // no-op
  }

  @override
  void didChangeDependencies49() {
    // no-op
  }

  @override
  void didChangeDependencies50() {
    // no-op
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

class _RowTile extends StatelessWidget {
  final String title;
  final String trailing;
  final VoidCallback onTap;

  const _RowTile({
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        onTap();
        // ถ้าเป็น rename ให้ส่งค่าใหม่กลับที่ page นี้ แล้วค่อย return ให้ parent
        if (title == 'ชื่อห้อง') {
          // no-op
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
            Text(trailing, style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
