import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home/bloc/devices_bloc.dart';
import '../../home/bloc/devices_event.dart';
import '../bloc/rooms_bloc.dart';
import '../bloc/rooms_event.dart';
import '../bloc/rooms_state.dart';

class RenameRoomPage extends StatefulWidget {
  final int roomId;
  final String initialName;

  const RenameRoomPage({
    super.key,
    required this.roomId,
    required this.initialName,
  });

  @override
  State<RenameRoomPage> createState() => _RenameRoomPageState();
}

class _RenameRoomPageState extends State<RenameRoomPage> {
  late final TextEditingController _controller;

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

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return;

    context.read<RoomsBloc>().add(
          RoomRenameRequested(roomId: widget.roomId, roomName: trimmed),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoomsBloc, RoomsState>(
      listenWhen: (p, c) => p.status != c.status || p.error != c.error,
      listener: (context, st) {
        if (st.status == RoomsStatus.failure) {
          final msg = st.error ?? 'Rename failed';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          return;
        }

        if (st.status == RoomsStatus.success) {
          final trimmed = _controller.text.trim();

          // ✅ keep Home tabs in sync (DevicesBloc uses rooms list)
          context.read<DevicesBloc>().add(const DevicesStarted());
          context.read<RoomsBloc>().add(const RoomsRefreshRequested());
          // ✅ return new name so caller updates immediately
          Navigator.pop(context, trimmed);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Colors.black87),
          title: const Text(
            'เปลี่ยนชื่อห้อง',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ชื่อห้อง',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
              ),
              const Spacer(),
              BlocBuilder<RoomsBloc, RoomsState>(
                buildWhen: (p, c) => p.status != c.status,
                builder: (context, st) {
                  final saving = st.status == RoomsStatus.saving;

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3AA7FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: saving ? null : _submit,
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('ตกลง', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}