// lib/features/home/ui/widgets/widget_picker_sheet.dart

import 'package:flutter/material.dart';

import '../../view_models/home_view_model.dart';

/// ลิ้นชักเลือก widget ด้วย checkbox
/// ใช้ได้ทั้ง “Add” (เลือกจาก drawerTiles) และ “Remove” (เลือกจาก tiles)
Future<List<int>?> showWidgetPickerSheet({
  required BuildContext context,
  required String title,
  required String confirmText,
  required List<HomeWidgetTileVM> items,
  required bool isDeleteMode,
}) {
  return showModalBottomSheet<List<int>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return _WidgetPickerSheet(
        title: title,
        confirmText: confirmText,
        items: items,
        isDeleteMode: isDeleteMode,
      );
    },
  );
}

class _WidgetPickerSheet extends StatefulWidget {
  final String title;
  final String confirmText;
  final List<HomeWidgetTileVM> items;
  final bool isDeleteMode;

  const _WidgetPickerSheet({
    required this.title,
    required this.confirmText,
    required this.items,
    required this.isDeleteMode,
  });

  @override
  State<_WidgetPickerSheet> createState() => _WidgetPickerSheetState();
}

class _WidgetPickerSheetState extends State<_WidgetPickerSheet> {
  final Set<int> _selected = <int>{};

  @override
  Widget build(BuildContext context) {
    final items = widget.items;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 6,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: items.isEmpty
                      ? null
                      : () {
                          setState(() {
                            if (_selected.length == items.length) {
                              _selected.clear();
                            } else {
                              _selected
                                ..clear()
                                ..addAll(items.map((e) => e.widgetId));
                            }
                          });
                        },
                  child: Text(_selected.length == items.length ? 'Unselect all' : 'Select all'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  widget.isDeleteMode ? 'No widgets to remove.' : 'No widgets available.',
                  style: const TextStyle(color: Colors.black54),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final it = items[i];
                    final checked = _selected.contains(it.widgetId);

                    return CheckboxListTile(
                      value: checked,
                      onChanged: (_) => setState(() {
                        if (checked) {
                          _selected.remove(it.widgetId);
                        } else {
                          _selected.add(it.widgetId);
                        }
                      }),
                      title: Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(_subtitleFor(it)),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: widget.isDeleteMode
                    ? ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      )
                    : null,
                onPressed: _selected.isEmpty ? null : () => Navigator.pop(context, _selected.toList()),
                child: Text(widget.confirmText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitleFor(HomeWidgetTileVM it) {
    // HomeTileKind มีแค่ sensor/toggle/adjust (ไม่มี unknown)
    switch (it.kind) {
      case HomeTileKind.sensor:
        return 'Sensor • Tap to view chart';
      case HomeTileKind.toggle:
        return 'Device • Toggle';
      case HomeTileKind.adjust:
        return 'Adjust • Slider';
      }
  }
}
