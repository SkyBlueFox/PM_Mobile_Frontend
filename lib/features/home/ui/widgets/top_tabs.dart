import 'package:flutter/material.dart';
import '../../models/device.dart';

class TopTab extends StatelessWidget {
  final RoomType selected;
  final ValueChanged<RoomType> onChanged;

  const TopTab({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      RoomType.all,
      RoomType.bedroom,
      RoomType.living,
    ];

    return Row(
      children: items.map((t) {
        final isSelected = t == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 18),
          child: GestureDetector(
            onTap: () => onChanged(t),
            child: Text(
              roomLabel(t),
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.black87 : Colors.black38,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
