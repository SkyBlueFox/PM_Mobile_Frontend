import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home/bloc/devices_bloc.dart';
import '../../home/bloc/devices_event.dart';
import '../../home/bloc/devices_state.dart';

import '../bloc/rooms_bloc.dart';
import '../bloc/rooms_event.dart';
import '../bloc/rooms_state.dart';

import 'room_settings_page.dart';

class ManageRoomsPage extends StatefulWidget {
  const ManageRoomsPage({super.key});

  @override
  State<ManageRoomsPage> createState() => _ManageRoomsPageState();
}

class _ManageRoomsPageState extends State<ManageRoomsPage> {
  final Map<int, String> _nameOverrides = {};

  @override
  void initState() {
    super.initState();

    // devices for counting
    context.read<DevicesBloc>().add(const DevicesRequested());

    // rooms list (if not already loaded)
    context.read<RoomsBloc>().add(const RoomsStarted());
  }

  String _roomName(dynamic r) {
    final id = (r as dynamic).id as int;
    final override = _nameOverrides[id];
    if (override != null && override.trim().isNotEmpty) return override;

    return (r as dynamic).name as String? ?? 'ห้อง';
  }

  int _deviceCountForRoom(DevicesState st, int roomId) {
    final devices = st.devices ?? const [];
    return devices.where((d) => d.roomId == roomId).length;
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (name == null || name.trim().isEmpty) return;

    context.read<RoomsBloc>().add(RoomCreateRequested(name.trim()));
  }

  @override
  Widget build(BuildContext context) {
    // listen rooms errors
    return BlocListener<RoomsBloc, RoomsState>(
      listenWhen: (p, c) => p.error != c.error && c.error != null,
      listener: (context, st) {
        if (st.error != null && st.error!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(st.error!)),
          );
        }
      },
      child: Scaffold(
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
        body: BlocBuilder<RoomsBloc, RoomsState>(
          buildWhen: (p, c) => p.rooms != c.rooms || p.status != c.status || p.error != c.error,
          builder: (context, roomsState) {
            final rooms = roomsState.rooms; // typed Room model
            final savingRoom = roomsState.status == RoomsStatus.saving;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  if (rooms.isNotEmpty)
                    _WhiteCard(
                      child: BlocBuilder<DevicesBloc, DevicesState>(
                        // rebuild list rows when devices change (counts)
                        buildWhen: (p, c) => p.devices != c.devices,
                        builder: (context, devicesState) {
                          return Column(
                            children: [
                              for (int i = 0; i < rooms.length; i++) ...[
                                InkWell(
                                  onTap: () async {
                                    final r = rooms[i];
                                    final id = r.id;

                                    final count = _deviceCountForRoom(devicesState, id);
                                    final currentName = _nameOverrides[id] ?? r.name;

                                    // ✅ provide BOTH blocs to next route
                                    final result = await Navigator.push<dynamic>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MultiBlocProvider(
                                          providers: [
                                            BlocProvider.value(value: context.read<RoomsBloc>()),
                                            BlocProvider.value(value: context.read<DevicesBloc>()),
                                          ],
                                          child: RoomSettingsPage(
                                            roomId: id,
                                            roomName: currentName,
                                            deviceCount: count,
                                          ),
                                        ),
                                      ),
                                    );

                                    if (!mounted) return;

                                    // if rename page returns new name (String)
                                    if (result is String && result.trim().isNotEmpty) {
                                      setState(() => _nameOverrides[id] = result.trim());
                                    }

                                    // if delete returns true, refresh devices + rooms
                                    if (result == true) {
                                      context.read<RoomsBloc>().add(const RoomsRefreshRequested());
                                      context.read<DevicesBloc>().add(const DevicesRequested());
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _nameOverrides[rooms[i].id] ?? rooms[i].name,
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        // Text(
                                        //   '${_deviceCountForRoom(devicesState, rooms[i].id)} อุปกรณ์',
                                        //   style: const TextStyle(
                                        //     color: Colors.black45,
                                        //     fontWeight: FontWeight.w700,
                                        //   ),
                                        // ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.chevron_right_rounded, color: Colors.black38),
                                      ],
                                    ),
                                  ),
                                ),
                                if (i != rooms.length - 1) const Divider(height: 1),
                              ],
                            ],
                          );
                        },
                      ),
                    ),

                  if (rooms.isEmpty && roomsState.status == RoomsStatus.loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: CircularProgressIndicator(),
                    ),

                  if (rooms.isEmpty && roomsState.status != RoomsStatus.loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text('ยังไม่มีห้อง', style: TextStyle(color: Colors.black54)),
                    ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: savingRoom ? null : _addRoomDialog,
                      child: Text(
                        savingRoom ? 'กำลังสร้าง...' : 'Add Room',
                        style: const TextStyle(
                          color: Color(0xFF3AA7FF),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: child,
    );
  }
}