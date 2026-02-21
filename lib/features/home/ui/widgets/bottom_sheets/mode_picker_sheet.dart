// lib/features/home/ui/widgets/bottom_sheets/mode_picker_sheet.dart

import 'package:flutter/material.dart';

Future<String?> showModePickerSheet({
  required BuildContext context,
  required String title,
  required String current,
  required List<String> options,
}) {
  final cur = current.trim().toLowerCase();

  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ...options.map((m) {
                final v = m.trim();
                final isSelected = v.toLowerCase() == cur;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: isSelected ? const Color(0xFF3AA7FF) : Colors.black26,
                  ),
                  title: Text(
                    v.toUpperCase(),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      color: isSelected ? const Color(0xFF3AA7FF) : Colors.black87,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, v),
                );
              }),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
    },
  );
}