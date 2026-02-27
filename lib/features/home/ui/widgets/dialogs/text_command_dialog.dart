// lib/features/home/ui/widgets/dialogs/text_command_dialog.dart

import 'package:flutter/material.dart';

Future<String?> showTextCommandDialog({
  required BuildContext context,
  required String title,
  String initialText = '',
  String hintText = 'ใส่ข้อความ',
  String confirmText = 'ส่ง',
}) {
  final controller = TextEditingController(text: initialText);

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
}