import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/devices_event.dart';
import '../../models/device.dart';
import '../../bloc/devices_bloc.dart';
import '../../bloc/devices_state.dart';
import '../../models/room.dart';

class AddDevicePage extends StatefulWidget {
  const AddDevicePage({super.key});

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  final _nicknameCtrl = TextEditingController(text: 'Light_Bulb_01');
  final _passwordCtrl = TextEditingController();
  Room? _selectedRoom;
  Device? _selectedDevice;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  List<Device> _uniqueDevices(List<Device> devices) {
    final map = <String, Device>{};
    for (final d in devices) {
      map[d.id] = d;
    }
    final list = map.values.toList();
    list.sort((a, b) => a.name.compareTo(b.name)); // adjust field name if different
    return list;
  }

  Future<void> _pickDevice() async {
    final devicesBloc = context.read<DevicesBloc>();
    // context.read<DevicesBloc>().add(const DevicesRequested(connectedOnly: true));
    final picked = await showModalBottomSheet<Device>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return BlocProvider.value(
          value: devicesBloc,
          child: SafeArea(
            child: BlocBuilder<DevicesBloc, DevicesState>(
              buildWhen: (p, c) =>
                  p.widgets != c.widgets || p.isLoading != c.isLoading || p.error != c.error,
              builder: (context, st) {
                if (st.isLoading && st.widgets.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (st.error != null && st.widgets.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(st.error!)),
                  );
                }

                final devices = _uniqueDevices(st.devices!);

                if (devices.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No devices available')),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final d = devices[i];
                    final isSelected = d.id == _selectedDevice?.id;

                    return ListTile(
                      title: Text(
                        d.name, // change if your field differs
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded, color: Color(0xFF3AA7FF))
                          : null,
                      onTap: () => Navigator.pop(context, d),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (picked != null) {
      setState(() => _selectedDevice = picked);
    }
  }


  Future<void> _pickRoom() async {
    final devicesBloc = context.read<DevicesBloc>();
    final picked = await showModalBottomSheet<Room>(
      context: context,
      showDragHandle: true,
      builder: (_) {return BlocProvider.value(
      value: devicesBloc, // ✅ ensures provider exists inside the sheet
      child: SafeArea(
        child: BlocBuilder<DevicesBloc, DevicesState>(
          builder: (context, st) {
              if (st.isLoading && st.rooms.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (st.error != null && st.rooms.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(st.error!)),
                );
              }

              final rooms = st.rooms;

              if (rooms.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No rooms available')),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                itemCount: rooms.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final room = rooms[i];
                  final isSelected = room.id == _selectedRoom?.id;

                  return ListTile(
                    title: Text(
                      room.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded, color: Color(0xFF3AA7FF))
                        : null,
                    onTap: () => Navigator.pop(context, room),
                  );
                },
              );
            },
          ),
        ),
        );
      },
    );

    if (!mounted) return;
    if (picked != null) {
      setState(() => _selectedRoom = picked);
    }
  }

  void _register() async {
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกอุปกรณ์')),
      );
      return;
    }

    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกห้อง')),
      );
      return;
    }

    try {
      final repo = context.read<DevicesBloc>().deviceRepo;

      await repo.pairDevice(
        deviceId: _selectedDevice!.id,
        deviceKey: _passwordCtrl.text,
      );

      if (!mounted) return;
      Navigator.pop(context, true); // success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('จับคู่อุปกรณ์ไม่สำเร็จ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF3AA7FF);

    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มอุปกรณ์'), centerTitle: true),
      body: SafeArea(
        child: BlocBuilder<DevicesBloc, DevicesState>(
          buildWhen: (p, c) =>
              p.isLoading != c.isLoading ||
              p.error != c.error ||
              p.rooms != c.rooms,
          builder: (context, st) {
            // If user opens this before home finished loading
            if (st.isLoading && st.rooms.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (st.error != null && st.rooms.isEmpty) {
              return Center(child: Text(st.error!, style: const TextStyle(color: Colors.red)));
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              children: [
                _RowCard(
                  title: 'อุปกรณ์',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedDevice?.name ?? '*เลือกอุปกรณ์', // adjust field
                        style: TextStyle(
                          color: _selectedDevice == null ? Colors.blueGrey : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded, color: Colors.black38),
                    ],
                  ),
                  onTap: _pickDevice,
                ),
                const SizedBox(height: 14),

                _RowCard(
                  title: 'ห้อง',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedRoom?.name ?? '*เลือกห้อง',
                        style: TextStyle(
                          color: _selectedRoom == null ? Colors.blueGrey : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded, color: Colors.black38),
                    ],
                  ),
                  onTap: _pickRoom,
                ),
                const SizedBox(height: 14),

                const Text('รหัสผ่าน',
                    style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),

                _InputCard(
                  child: TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'รหัสผ่าน...',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _register,
                    child: const Text('ลงทะเบียน', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// UI helpers
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

class _RowCard extends StatelessWidget {
  final String title;
  final Widget trailing;
  final VoidCallback onTap;

  const _RowCard({
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7FB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            trailing,
          ],
        ),
      ),
    );
  }
}
