import 'package:flutter/material.dart';
import '../../../models/room.dart';

class TopTab extends StatefulWidget {
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
  State<TopTab> createState() => _TopTabState();
}

class _TopTabState extends State<TopTab> {
  int? _selectedRoomId;

  @override
  void initState() {
    super.initState();
    _selectedRoomId = widget.selectedRoomId;
  }

  @override
  void didUpdateWidget(covariant TopTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sync with Bloc updates
    if (oldWidget.selectedRoomId != widget.selectedRoomId) {
      _selectedRoomId = widget.selectedRoomId;
    }
  }

  void _handleTap(int? roomId) {
    if (_selectedRoomId == roomId) return;

    setState(() => _selectedRoomId = roomId);
    widget.onChanged(roomId);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ...widget.rooms.map(
            (r) => Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 18, 0),
              child: _TabItem(
                label: r.name,
                isSelected: _selectedRoomId == r.id,
                onTap: () => _handleTap(r.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        style: TextStyle(
          fontSize: 16,
          fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
          color: widget.isSelected ? Colors.black87 : Colors.black38,
        ),
        child: Text(widget.label),
      ),
    );
  }
}
