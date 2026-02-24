import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home/bloc/devices_bloc.dart';
import '../../home/bloc/devices_event.dart';
import '../../../data/room_repository.dart';
import '../../home/models/device.dart';

import '../bloc/rooms_bloc.dart';
import '../bloc/rooms_event.dart';
import '../bloc/rooms_state.dart';

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

  bool _didPop = false;

  bool _devicesLoading = false;
  String? _devicesError;
  List<Device> _devices = const [];

  // track if we already loaded devices once successfully
  bool _devicesLoaded = false;

  @override
  void initState() {
    super.initState();
    // ✅ load devices immediately (no click needed)
    _loadDevicesInRoom();
  }

  Future<void> _openRename() async {
    final newName = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<RoomsBloc>(),
          child: RenameRoomPage(
            initialName: _name,
            roomId: widget.roomId,
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (newName != null && newName.trim().isNotEmpty) {
      setState(() => _name = newName.trim());
    }
  }

  Future<void> _loadDevicesInRoom() async {
    setState(() {
      _devicesLoading = true;
      _devicesError = null;
    });

    try {
      final repo = context.read<RoomRepository>();
      final list = await repo.fetchDevicesInRoom(widget.roomId);

      if (!mounted) return;
      setState(() {
        _devices = list;
        _devicesLoading = false;
        _devicesLoaded = true; // success even if empty
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _devicesLoading = false;
        _devicesError = e.toString();
        _devicesLoaded = false; // allow retry
      });
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Room'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบห้องนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (ok != true) return;

    context.read<RoomsBloc>().add(RoomDeleteRequested(widget.roomId));

    // keep Home tabs in sync (DevicesBloc uses rooms list)
    context.read<DevicesBloc>().add(const DevicesStarted());
    context.read<RoomsBloc>().add(const RoomsRefreshRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoomsBloc, RoomsState>(
      listenWhen: (p, c) =>
          p.status != c.status || p.error != c.error || p.rooms != c.rooms,
      listener: (context, st) {
        if (!mounted) return;

        // error
        if (st.status == RoomsStatus.failure &&
            st.error != null &&
            st.error!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(st.error!)),
          );
          return;
        }

        // ✅ success delete: room no longer exists in list
        final exists = st.rooms.any((r) => r.id == widget.roomId);
        if (!_didPop && !exists && st.status == RoomsStatus.ready) {
          _didPop = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop(true);
          });
        }
      },
      child: Scaffold(
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
                      onTap: _openRename,
                      trailingIcon: Icons.chevron_right_rounded,
                    ),
                    const Divider(height: 1),

                    // ✅ always show devices section (no click)
                    _RowTile(
                      title: 'อุปกรณ์',
                      trailing: _devicesLoaded
                          ? '${_devices.length}'
                          : '${widget.deviceCount}',
                      onTap: null, // disabled
                      trailingIcon: null, // hide arrow
                    ),
                    const Divider(height: 1),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: _DevicesSection(
                        loading: _devicesLoading,
                        error: _devicesError,
                        devices: _devices,
                        onRetry: _loadDevicesInRoom,
                        onRefresh: _loadDevicesInRoom,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              BlocBuilder<RoomsBloc, RoomsState>(
                buildWhen: (p, c) => p.status != c.status,
                builder: (context, st) {
                  final deleting = st.status == RoomsStatus.deleting;

                  return TextButton(
                    onPressed: deleting ? null : _confirmDelete,
                    child: deleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Delete Room',
                            style: TextStyle(
                              color: Color(0xFF3AA7FF),
                              fontWeight: FontWeight.w800,
                            ),
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

class _DevicesSection extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<Device> devices;
  final Future<void> Function() onRetry;
  final Future<void> Function() onRefresh;

  const _DevicesSection({
    required this.loading,
    required this.error,
    required this.devices,
    required this.onRetry,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Column(
        children: [
          Text(
            'โหลดรายการอุปกรณ์ไม่สำเร็จ\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: onRetry, child: const Text('ลองใหม่')),
        ],
      );
    }

    // EMPTY STATE (no fixed height anymore)
    if (devices.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 18),
            Center(
              child: Text(
                'ไม่มีอุปกรณ์ในห้องนี้',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            SizedBox(height: 18),
          ],
        ),
      );
    }

    // NORMAL LIST (no blank space below)
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: devices.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final d = devices[i];
          return ListTile(
            dense: true,
            leading: const Icon(
              Icons.devices_other_rounded,
              color: Color(0xFF3AA7FF),
            ),
            title: Text(
              d.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              d.type,
              style: const TextStyle(color: Colors.black45),
            ),
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _RowTile extends StatelessWidget {
  final String title;
  final String trailing;
  final VoidCallback? onTap; // ✅ nullable to allow disabling
  final IconData? trailingIcon;

  const _RowTile({
    required this.title,
    required this.trailing,
    required this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              trailing,
              style: const TextStyle(
                color: Colors.black45,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            if (trailingIcon != null)
              Icon(trailingIcon!, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}