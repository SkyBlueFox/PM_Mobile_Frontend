// lib/features/home/ui/widgets/bottom_sheets/home_actions_sheet.dart
//
// ปรับรายการให้เป็น:
// - Add device/widget
// - Reorder widget
// - Add/Delete widget

import 'package:flutter/material.dart';

enum HomeAction {
  addDeviceWidget,
  reorderWidgets,
  manageWidgets,
}

Future<HomeAction?> showHomeActionsSheet(BuildContext context) {
  return showModalBottomSheet<HomeAction>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionTile(
                icon: Icons.add_circle_outline_rounded,
                title: 'จับคู่อุปกรณ์',
                onTap: () => Navigator.pop(context, HomeAction.addDeviceWidget),
              ),
              _ActionTile(
                icon: Icons.reorder_rounded,
                title: 'จัดเรียง widget',
                onTap: () => Navigator.pop(context, HomeAction.reorderWidgets),
              ),
              _ActionTile(
                icon: Icons.widgets_outlined,
                title: 'เพิ่ม/ลบ widget',
                onTap: () => Navigator.pop(context, HomeAction.manageWidgets),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      onTap: onTap,
    );
  }
}
