import 'package:flutter/material.dart';
import '../../models/room.dart';

class TopTab extends StatelessWidget {
  final List<Room> rooms;

  /// null = All
  final int? selectedRoomId;

  /// pass null for All
  final ValueChanged<int?> onChanged;

  const TopTab({
    super.key,
    required this.rooms,
    required this.selectedRoomId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabItem(
            label: 'ทั้งหมด',
            isSelected: selectedRoomId == null,
            onTap: () => onChanged(null),
          ),

          ...rooms.map((r) => Padding(
                padding: const EdgeInsets.only(left: 18),
                child: _TabItem(
                  label: r.name,
                  isSelected: selectedRoomId == r.id,
                  onTap: () => onChanged(r.id),
                ),
              )),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.black87 : Colors.black38,
        ),
      ),
    );
  }
}
