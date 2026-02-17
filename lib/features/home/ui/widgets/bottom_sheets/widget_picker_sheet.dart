// lib/features/home/ui/widgets/bottom_sheets/widget_picker_sheet.dart
//
// Manage widgets (Add/Delete) — ตาม UI
// - ไม่มี checkbox
// - ปุ่มขวาบนเป็น Save
// - Include ด้านบน / Exclude ด้านล่าง (แยก Sensors/Devices/Adjust)
// - แตะการ์ดใน Include = ย้ายลง Exclude
// - แตะการ์ดใน Exclude = ย้ายขึ้น Include
// - return: List<int> widgetIds ที่ “อยู่ใน Include” หลัง Save

import 'package:flutter/material.dart';

import '../../view_models/home_view_model.dart';

Future<List<int>?> showWidgetPickerSheet({
  required BuildContext context,
  required String title,
  String confirmText = 'Save',
  required List<HomeWidgetTileVM> includedItems,
  required List<HomeWidgetTileVM> excludedItems,

  /// ถ้า true: กันไม่ให้เอาออกจาก include (แตะแล้วไม่ย้ายลง)
  bool lockIncluded = false,

  /// หัวแบบในรูป (optional)
  String headerTitle = '',
  String headerSubtitle = '',
}) {
  return showModalBottomSheet<List<int>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    showDragHandle: true,
    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.70,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _WidgetPickerSheet(
            scrollController: scrollController,
            title: title,
            confirmText: confirmText,
            includedItems: includedItems,
            excludedItems: excludedItems,
            lockIncluded: lockIncluded,
            headerTitle: headerTitle,
            headerSubtitle: headerSubtitle,
          );
        },
      );
    },
  );
}

class _WidgetPickerSheet extends StatefulWidget {
  final ScrollController scrollController;

  final String title;
  final String confirmText;
  final List<HomeWidgetTileVM> includedItems;
  final List<HomeWidgetTileVM> excludedItems;
  final bool lockIncluded;

  final String headerTitle;
  final String headerSubtitle;

  const _WidgetPickerSheet({
    required this.scrollController,
    required this.title,
    required this.confirmText,
    required this.includedItems,
    required this.excludedItems,
    required this.lockIncluded,
    required this.headerTitle,
    required this.headerSubtitle,
  });

  @override
  State<_WidgetPickerSheet> createState() => _WidgetPickerSheetState();
}

class _WidgetPickerSheetState extends State<_WidgetPickerSheet> {
  late final Set<int> _included = widget.includedItems.map((e) => e.widgetId).toSet();

  void _include(int id) => setState(() => _included.add(id));
  void _exclude(int id) => setState(() => _included.remove(id));

  @override
  Widget build(BuildContext context) {
    // รวมทั้งหมดเพื่อให้ย้ายไปมาได้
    final all = <HomeWidgetTileVM>[
      ...widget.includedItems,
      ...widget.excludedItems,
    ];

    // ป้องกันซ้ำ (อิง widgetId)
    final byId = <int, HomeWidgetTileVM>{};
    for (final t in all) {
      byId[t.widgetId] = t;
    }
    final uniq = byId.values.toList(growable: false);

    final included = uniq.where((e) => _included.contains(e.widgetId)).toList(growable: false);
    final excluded = uniq.where((e) => !_included.contains(e.widgetId)).toList(growable: false);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: Container(
        color: const Color(0xFFF6F7FB),
        child: SingleChildScrollView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Header (optional) =====
              if (widget.headerTitle.trim().isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.home_rounded, color: Color(0xFF3AA7FF), size: 24),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.headerTitle,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        if (widget.headerSubtitle.trim().isNotEmpty)
                          Text(
                            widget.headerSubtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black45,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ===== Top bar: title + Cancel + Save =====
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('ยกเลิก'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3AA7FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context, _included.toList()),
                    child: Text(widget.confirmText, style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ===== Include =====
              Text(
                'Include (${included.length})',
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              const SizedBox(height: 10),

              _Group(
                title: 'Devices',
                items: included.where((t) => t.kind == HomeTileKind.toggle).toList(growable: false),
                onTap: (t) {
                  if (widget.lockIncluded) return;
                  _exclude(t.widgetId);
                },
              ),
              const SizedBox(height: 12),
              _Group(
                title: 'Sensors',
                items: included.where((t) => t.kind == HomeTileKind.sensor).toList(growable: false),
                onTap: (t) {
                  if (widget.lockIncluded) return;
                  _exclude(t.widgetId);
                },
              ),
              const SizedBox(height: 12),
              _Group(
                title: 'Adjust',
                items: included.where((t) => t.kind == HomeTileKind.adjust).toList(growable: false),
                onTap: (t) {
                  if (widget.lockIncluded) return;
                  _exclude(t.widgetId);
                },
              ),

              const SizedBox(height: 18),

              // ===== Exclude =====
              const Text(
                'Exclude',
                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              const SizedBox(height: 10),

              _Group(
                title: 'Sensors',
                items: excluded.where((t) => t.kind == HomeTileKind.sensor).toList(growable: false),
                onTap: (t) => _include(t.widgetId),
              ),
              const SizedBox(height: 12),
              _Group(
                title: 'Devices',
                items: excluded.where((t) => t.kind == HomeTileKind.toggle).toList(growable: false),
                onTap: (t) => _include(t.widgetId),
              ),
              const SizedBox(height: 12),
              _Group(
                title: 'Adjust',
                items: excluded.where((t) => t.kind == HomeTileKind.adjust).toList(growable: false),
                onTap: (t) => _include(t.widgetId),
              ),

              if (excluded.isEmpty) ...[
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text('No widgets available.', style: TextStyle(color: Colors.black54)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<HomeWidgetTileVM> items;
  final ValueChanged<HomeWidgetTileVM> onTap;

  const _Group({
    required this.title,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black54)),
        const SizedBox(height: 10),
        _TileGrid(items: items, onTap: onTap),
      ],
    );
  }
}

class _TileGrid extends StatelessWidget {
  final List<HomeWidgetTileVM> items;
  final ValueChanged<HomeWidgetTileVM> onTap;

  const _TileGrid({
    required this.items,
    required this.onTap,
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
              child: InkWell(
                onTap: () => onTap(t),
                borderRadius: BorderRadius.circular(16),
                child: _WidgetPreviewCard(tile: t),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _WidgetPreviewCard extends StatelessWidget {
  final HomeWidgetTileVM tile;

  const _WidgetPreviewCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // header
          Row(
            children: [
              Expanded(
                child: Text(
                  tile.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.drag_indicator_rounded, color: Colors.black26, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            tile.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black45,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),

          // body (preview)
          if (tile.kind == HomeTileKind.sensor) _sensorBody(tile),
          if (tile.kind == HomeTileKind.toggle) _toggleBody(tile),
          if (tile.kind == HomeTileKind.adjust) _adjustBody(tile),
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
