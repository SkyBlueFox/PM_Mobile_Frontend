import 'package:flutter/material.dart';
import '../../models/device.dart';

class RoomSection extends StatelessWidget {
  final RoomType selectedRoom;
  final int deviceCount;
  final ValueChanged<RoomType> onRoomChanged;

  const RoomSection({
    super.key,
    required this.selectedRoom,
    required this.deviceCount,
    required this.onRoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownButtonHideUnderline(
          child: DropdownButton<RoomType>(
            value: selectedRoom,
            items: const [
              DropdownMenuItem(value: RoomType.bedroom, child: Text('ห้องนอน')),
              DropdownMenuItem(value: RoomType.living, child: Text('ห้องนั่งเล่น')),
              DropdownMenuItem(value: RoomType.all, child: Text('ทั้งหมด')),
            ],
            onChanged: (v) {
              if (v != null) onRoomChanged(v);
            },
          ),
        ),
        const Spacer(),
        Text(
          '$deviceCount อุปกรณ์',
          style: const TextStyle(color: Colors.black38, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
