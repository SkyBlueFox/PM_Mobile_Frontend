// lib/features/home/ui/widgets/bottom_sheets/home_actions_sheet.dart
//
// Bottom sheet สำหรับ FAB: 3 actions
// - Add widgets
// - Edit widgets (reorder mode)
// - Remove widgets (move to drawer)

import 'package:flutter/material.dart';

enum HomeAction {
  addWidgets,
  editWidgets,
  deleteWidgets,
}

Future<HomeAction?> showHomeActionsSheet(BuildContext context) {
  return showModalBottomSheet<HomeAction>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add devices/widgets'),
              onTap: () => Navigator.pop(context, HomeAction.addWidgets),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit widgets (reorder)'),
              onTap: () => Navigator.pop(context, HomeAction.editWidgets),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove widgets (move to drawer)'),
              onTap: () => Navigator.pop(context, HomeAction.deleteWidgets),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}
