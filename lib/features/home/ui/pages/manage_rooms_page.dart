import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/devices_bloc.dart';
import '../../bloc/devices_state.dart';

import 'room_settings_page.dart';

class ManageRoomsPage extends StatefulWidget {
  const ManageRoomsPage({super.key});

  @override
  State<ManageRoomsPage> createState() => _ManageRoomsPageState();
}

class _ManageRoomsPageState extends State<ManageRoomsPage> {
  final Map<int, String> _nameOverrides = {};
  final List<_LocalRoom> _localAddedRooms = [];

  int _roomId(dynamic r) {
    try {
      return (r.id as int);
    } catch (_) {
      return r.hashCode;
    }
  }

  String _roomName(dynamic r) {
    final id = _roomId(r);
    final override = _nameOverrides[id];
    if (override != null && override.trim().isNotEmpty) return override;

    try {
      return (r.name as String);
    } catch (_) {
      return 'ห้อง';
    }
  }

  int _deviceCountForRoom(DevicesState st, int roomId) {
    var count = 0;
    for (final w in st.widgets) {
      final dynamic dev = (w as dynamic).device;
      var ok = false;

      try {
        if (dev.roomId == roomId) ok = true;
      } catch (_) {}
      try {
        if (dev.room?.id == roomId) ok = true;
      } catch (_) {}
      try {
        if (dev.room_id == roomId) ok = true;
      } catch (_) {}

      if (ok) count++;
    }
    return count;
  }

  Future<void> _addRoomDialog() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Room'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'ชื่อห้อง',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty) return;

    setState(() {
      _localAddedRooms.add(_LocalRoom(id: -DateTime.now().millisecondsSinceEpoch, name: name));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text(
          'จัดการห้อง',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
        ),
      ),
      body: BlocBuilder<DevicesBloc, DevicesState>(
        builder: (context, st) {
          final apiRooms = st.rooms.cast<dynamic>();
          final rooms = <dynamic>[
            ...apiRooms,
            ..._localAddedRooms, // local-only เพิ่มเพื่อให้ UI ทำงานตาม flow
          ];

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                if (rooms.isNotEmpty)
                  _WhiteCard(
                    child: Column(
                      children: [
                        for (int i = 0; i < rooms.length; i++) ...[
                          InkWell(
                            onTap: () async {
                              final r = rooms[i];
                              final id = r is _LocalRoom ? r.id : _roomId(r);

                              final count = r is _LocalRoom ? 0 : _deviceCountForRoom(st, id);
                              final currentName = r is _LocalRoom ? r.name : _roomName(r);

                              final newName = await Navigator.push<String?>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RoomSettingsPage(
                                    roomId: id,
                                    roomName: currentName,
                                    deviceCount: count,
                                  ),
                                ),
                              );

                              if (newName != null && newName.trim().isNotEmpty) {
                                setState(() => _nameOverrides[id] = newName.trim());
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      rooms[i] is _LocalRoom ? (rooms[i] as _LocalRoom).name : _roomName(rooms[i]),
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Text(
                                    rooms[i] is _LocalRoom
                                        ? ''
                                        : '${_deviceCountForRoom(st, _roomId(rooms[i]))} อุปกรณ์',
                                    style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.black38),
                                ],
                              ),
                            ),
                          ),
                          if (i != rooms.length - 1) const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
                if (rooms.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text('ยังไม่มีห้อง', style: TextStyle(color: Colors.black54)),
                  ),
                const SizedBox(height: 14),

                // Add Room button (ตาม UI)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _addRoomDialog,
                    child: const Text(
                      'Add Room',
                      style: TextStyle(color: Color(0xFF3AA7FF), fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: child,
    );
  }
}

class _LocalRoom {
  final int id;
  final String name;
  _LocalRoom({required this.id, required this.name});
}
