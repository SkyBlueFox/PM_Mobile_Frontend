// lib/features/home/ui/widgets/widget_picker_sheet.dart

import 'package:flutter/material.dart';

import '../../view_models/home_view_model.dart';

/// ลิ้นชักปรับ widget:
/// - แสดง Include (ด้านบน) / Exclude (ด้านล่าง)
/// - checkbox อยู่ “มุมขวาบน” ของการ์ด
/// - กดการ์ด/กด checkbox = ย้ายระหว่าง Include/Exclude
/// - return: รายการ widgetId ที่ “อยู่ฝั่ง Include” หลังปรับเสร็จ
Future<List<int>?> showWidgetPickerSheet({
  required BuildContext context,
  required String title,
  required String confirmText,
  required List<HomeWidgetTileVM> includedItems,
  required List<HomeWidgetTileVM> excludedItems,
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
        includedItems: includedItems,
        excludedItems: excludedItems,
        isDeleteMode: isDeleteMode,
      );
    },
  );
}

class _WidgetPickerSheet extends StatefulWidget {
  final String title;
  final String confirmText;
  final List<HomeWidgetTileVM> includedItems;
  final List<HomeWidgetTileVM> excludedItems;
  final bool isDeleteMode;

  const _WidgetPickerSheet({
    required this.title,
    required this.confirmText,
    required this.includedItems,
    required this.excludedItems,
    required this.isDeleteMode,
  });

  @override
  State<_WidgetPickerSheet> createState() => _WidgetPickerSheetState();
}

class _WidgetPickerSheetState extends State<_WidgetPickerSheet> {
  late final List<HomeWidgetTileVM> _allItems;
  late final Set<int> _includedIds;

  @override
  void initState() {
    super.initState();

    // รวมรายการทั้งหมด (รักษาลำดับ: included ก่อน แล้วตามด้วย excluded)
    final seen = <int>{};
    final all = <HomeWidgetTileVM>[];

    for (final it in widget.includedItems) {
      if (seen.add(it.widgetId)) all.add(it);
    }
    for (final it in widget.excludedItems) {
      if (seen.add(it.widgetId)) all.add(it);
    }

    _allItems = all;
    _includedIds = widget.includedItems.map((e) => e.widgetId).toSet();
  }

  void _toggleInclude(int widgetId) {
    setState(() {
      if (_includedIds.contains(widgetId)) {
        _includedIds.remove(widgetId);
      } else {
        _includedIds.add(widgetId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final included = _allItems.where((t) => _includedIds.contains(t.widgetId)).toList(growable: false);
    final excluded = _allItems.where((t) => !_includedIds.contains(t.widgetId)).toList(growable: false);

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
            // Header: title + cancel + done
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('ยกเลิก'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: widget.isDeleteMode
                      ? ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white)
                      : null,
                  onPressed: () => Navigator.pop(context, _includedIds.toList()),
                  child: Text(widget.confirmText),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Flexible(
              child: ListView(
                children: [
                  _SectionHeader(title: 'Include', count: included.length),
                  const SizedBox(height: 8),
                  if (included.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('No widgets included.', style: TextStyle(color: Colors.black54)),
                    )
                  else
                    _GroupedTiles(
                      items: included,
                      isChecked: (id) => _includedIds.contains(id),
                      onToggle: _toggleInclude,
                    ),

                  const SizedBox(height: 16),
                  _SectionHeader(title: 'Exclude', count: excluded.length),
                  const SizedBox(height: 8),
                  if (excluded.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('No widgets excluded.', style: TextStyle(color: Colors.black54)),
                    )
                  else
                    _GroupedTiles(
                      items: excluded,
                      isChecked: (id) => _includedIds.contains(id),
                      onToggle: _toggleInclude,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(width: 6),
        Text('($count)', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _GroupedTiles extends StatelessWidget {
  final List<HomeWidgetTileVM> items;
  final bool Function(int widgetId) isChecked;
  final void Function(int widgetId) onToggle;

  const _GroupedTiles({
    required this.items,
    required this.isChecked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final sensors = items.where((t) => t.kind == HomeTileKind.sensor).toList(growable: false);
    final devices = items.where((t) => t.kind == HomeTileKind.toggle).toList(growable: false);
    final adjusts = items.where((t) => t.kind == HomeTileKind.adjust).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sensors.isNotEmpty) ...[
          const Text('Sensors', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black54)),
          const SizedBox(height: 8),
          _TileWrapGrid(items: sensors, isChecked: isChecked, onToggle: onToggle),
          const SizedBox(height: 12),
        ],
        if (devices.isNotEmpty) ...[
          const Text('Devices', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black54)),
          const SizedBox(height: 8),
          _TileWrapGrid(items: devices, isChecked: isChecked, onToggle: onToggle),
          const SizedBox(height: 12),
        ],
        if (adjusts.isNotEmpty) ...[
          const Text('Adjust', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black54)),
          const SizedBox(height: 8),
          _TileWrapGrid(items: adjusts, isChecked: isChecked, onToggle: onToggle),
        ],
      ],
    );
  }
}

class _TileWrapGrid extends StatelessWidget {
  final List<HomeWidgetTileVM> items;
  final bool Function(int widgetId) isChecked;
  final void Function(int widgetId) onToggle;

  const _TileWrapGrid({
    required this.items,
    required this.isChecked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final full = c.maxWidth;
        final half = (c.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((t) {
            final w = t.span == HomeTileSpan.full ? full : half;
            return SizedBox(
              width: w,
              child: _PickCard(
                tile: t,
                checked: isChecked(t.widgetId),
                onToggle: () => onToggle(t.widgetId),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _PickCard extends StatelessWidget {
  final HomeWidgetTileVM tile;
  final bool checked;
  final VoidCallback onToggle;

  const _PickCard({
    required this.tile,
    required this.checked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final valueText = _valueText(tile);

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tile.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      valueText,
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3AA7FF)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tile.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          // ✅ checkbox มุมขวาบน
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(999),
              child: Icon(
                checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: checked ? const Color(0xFF3AA7FF) : Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _valueText(HomeWidgetTileVM t) {
    switch (t.kind) {
      case HomeTileKind.toggle:
        return t.isOn ? 'ON' : 'OFF';
      case HomeTileKind.sensor:
      case HomeTileKind.adjust:
        return t.unit.isEmpty ? '${t.value}' : '${t.value}${t.unit}';
    }
  }
}
