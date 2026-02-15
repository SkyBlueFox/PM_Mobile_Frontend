import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRoom() async {
    // final picked = await Navigator.push<Room>(
    //   context,
    //   MaterialPageRoute(builder: (_) => const SelectRoomPage()),
    // );
    // if (!mounted) return;
    // if (picked != null) setState(() => _selectedRoom = picked);
  }

  void _register() {
    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกห้อง')),
      );
      return;
    }

    // TODO: call your backend register device endpoint here.
    // For now: pop or go next page.
    Navigator.pop(context);
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
                _InputCard(
                  child: TextField(
                    controller: _nicknameCtrl,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Nickname',
                    ),
                  ),
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
