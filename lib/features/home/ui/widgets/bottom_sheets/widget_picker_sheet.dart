// lib/features/home/ui/widgets/bottom_sheets/widget_picker_sheet.dart
//
// Manage widgets (Include/Exclude) — ตาม UI
//
// ✅ จุดสำคัญ (เวอร์ชันนี้):
// - ยังรองรับแบบเดิม: กด Save แล้ว pop ออกพร้อม List<int> (widgetIds ที่อยู่ใน Include)
// - เพิ่ม option ใหม่: onConfirm(ids) เพื่อให้ “caller ส่ง API save” ได้จากใน sheet เลย (ถ้าต้องการ)
//   - ถ้าไม่ส่ง onConfirm => ทำงานเหมือนเดิม 100%
//   - ถ้าส่ง onConfirm => ตอนกด Save จะ:
//       1) set loading
//       2) await onConfirm(ids)
//       3) pop(ids) ถ้าสำเร็จ
//       4) ถ้า error => แสดง SnackBar และไม่ pop
//
// UI Spec:
// - ไม่มี checkbox
// - ปุ่มขวาบนเป็น Save
// - Include ด้านบน / Exclude ด้านล่าง (แยก Sensors/Devices/Adjust/Mode/Text/Button)
// - แตะการ์ดใน Include = ย้ายลง Exclude (ถ้า lockIncluded=false)
// - แตะการ์ดใน Exclude = ย้ายขึ้น Include

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

  /// ✅ OPTIONAL: ถ้าส่งมา จะให้ sheet เรียก callback นี้ก่อนปิด (เหมาะสำหรับยิง API save)
  /// - สำเร็จ: pop(ids)
  /// - ล้มเหลว: แสดง error แล้วไม่ปิด
  Future<void> Function(List<int> includedWidgetIds)? onConfirm,

  /// ✅ OPTIONAL: ข้อความ error ใน SnackBar ถ้า onConfirm throw
  String confirmErrorText = 'บันทึกไม่สำเร็จ',
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
            onConfirm: onConfirm,
            confirmErrorText: confirmErrorText,
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

  final Future<void> Function(List<int> includedWidgetIds)? onConfirm;
  final String confirmErrorText;

  const _WidgetPickerSheet({
    required this.scrollController,
    required this.title,
    required this.confirmText,
    required this.includedItems,
    required this.excludedItems,
    required this.lockIncluded,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.onConfirm,
    required this.confirmErrorText,
  });

  @override
  State<_WidgetPickerSheet> createState() => _WidgetPickerSheetState();
}

class _WidgetPickerSheetState extends State<_WidgetPickerSheet> {
  late final Map<int, HomeWidgetTileVM> _byId;
  late final Set<int> _included;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    // รวมทั้งหมด + ป้องกันซ้ำ (อิง widgetId) แบบ deterministic:
    // - ถ้ามีซ้ำ: ให้ "included" ชนะ (เพื่อคงสถานะที่ UI เห็นอยู่จริง)
    final map = <int, HomeWidgetTileVM>{};
    for (final t in widget.excludedItems) {
      map[t.widgetId] = t;
    }
    for (final t in widget.includedItems) {
      map[t.widgetId] = t;
    }
    _byId = Map<int, HomeWidgetTileVM>.unmodifiable(map);

    // Set ของ widgetId ที่อยู่ใน include ณ ตอนเริ่มต้น
    _included = widget.includedItems.map((e) => e.widgetId).toSet();
  }

  void _include(int id) => setState(() => _included.add(id));
  void _exclude(int id) => setState(() => _included.remove(id));

  Future<void> _handleSave() async {
    if (_saving) return;

    final ids = _included.toList(growable: false);

    // ✅ ถ้าไม่ได้ส่ง callback มา: behavior เดิม (pop ids ทันที)
    if (widget.onConfirm == null) {
      Navigator.pop(context, ids);
      return;
    }

    // ✅ ถ้ามี onConfirm: ทำ loading + await save
    setState(() => _saving = true);
    try {
      await widget.onConfirm!(ids);
      if (!mounted) return;
      Navigator.pop(context, ids);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.confirmErrorText}: $e')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _byId.values.toList(growable: false);

    // ทำให้เสถียร: sort ด้วย kind -> title -> widgetId
    int kindOrder(HomeTileKind k) {
      switch (k) {
        case HomeTileKind.toggle:
          return 0;
        case HomeTileKind.sensor:
          return 1;
        case HomeTileKind.adjust:
          return 2;
        case HomeTileKind.mode:
          return 3;
        case HomeTileKind.text:
          return 4;
        case HomeTileKind.button:
          return 5;
      }
    }

    int cmpTile(HomeWidgetTileVM a, HomeWidgetTileVM b) {
      final ko = kindOrder(a.kind).compareTo(kindOrder(b.kind));
      if (ko != 0) return ko;
      final t = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      if (t != 0) return t;
      return a.widgetId.compareTo(b.widgetId);
    }

    final included = all
        .where((e) => _included.contains(e.widgetId))
        .toList(growable: false)
      ..sort(cmpTile);

    final excluded = all
        .where((e) => !_included.contains(e.widgetId))
        .toList(growable: false)
      ..sort(cmpTile);

    List<HomeWidgetTileVM> onlyKind(List<HomeWidgetTileVM> list, HomeTileKind k) =>
        list.where((t) => t.kind == k).toList(growable: false);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF5FF),
              Color(0xFFF7FBFF),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: IgnorePointer(
          // กัน user กดอย่างอื่นระหว่าง save
          ignoring: _saving,
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
                                color: Color(0xFF5E87A3),
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
                      onPressed: _saving ? null : () => Navigator.pop(context, null),
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3AA7FF),
                        ),
                      ),
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
                      onPressed: _handleSave,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(widget.confirmText, style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ===== Include =====
                Text(
                  'Include (${included.length})',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0E3A5A)),
                ),
                const SizedBox(height: 10),

                _Group(
                  title: 'Devices',
                  items: onlyKind(included, HomeTileKind.toggle),
                  onTap: (t) {
                    if (widget.lockIncluded) return;
                    _exclude(t.widgetId);
                  },
                ),
                const SizedBox(height: 12),
                _Group(
                  title: 'Sensors',
                  items: onlyKind(included, HomeTileKind.sensor),
                  onTap: (t) {
                    if (widget.lockIncluded) return;
                    _exclude(t.widgetId);
                  },
                ),
                const SizedBox(height: 12),
                _Group(
                  title: 'Adjust',
                  items: onlyKind(included, HomeTileKind.adjust),
                  onTap: (t) {
                    if (widget.lockIncluded) return;
                    _exclude(t.widgetId);
                  },
                ),
                const SizedBox(height: 12),
                _Group(
                  title: 'Mode',
                  items: onlyKind(included, HomeTileKind.mode),
                  onTap: (t) {
                    if (widget.lockIncluded) return;
                    _exclude(t.widgetId);
                  },
                ),
                const SizedBox(height: 12),
                _Group(
                  title: 'Text',
                  items: onlyKind(included, HomeTileKind.text),
                  onTap: (t) {
                    if (widget.lockIncluded) return;
                    _exclude(t.widgetId);
                  },
                ),
                const SizedBox(height: 12),
                _Group(
                  title: 'Button',
                  items: onlyKind(included, HomeTileKind.button),
                  onTap: (t) {
                    if (widget.lockIncluded) return;
                    _exclude(t.widgetId);
                  },
                ),

                const SizedBox(height: 18),

                // ===== Exclude =====
                const Text(
                  'Exclude',
                  style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0E3A5A)),
                ),
                const SizedBox(height: 10),

                _Group(
                  title: 'Sensors',
                  items: onlyKind(excluded, HomeTileKind.sensor),
                  onTap: (t) => _include(t.widgetId),
                ),
                const SizedBox(height: 12),
                _Group(
                  title: 'Devices',
                  items: onlyKind(excluded, HomeTileKind.toggle),
                  onTap: (t) => _include(t.widgetId),
                ),
                const SizedBox(height: 12),
                _Group(
                  title: 'Adjust',
                  items: onlyKind(excluded, HomeTileKind.adjust),
                  onTap: (t) => _include(t.widgetId),
                ),
                const SizedBox(height: 12),
                _Group(
                  title: 'Mode',
                  items: onlyKind(excluded, HomeTileKind.mode),
                  onTap: (t) => _include(t.widgetId),
                ),
                const SizedBox(height: 12),
                _Group(
                  title: 'Text',
                  items: onlyKind(excluded, HomeTileKind.text),
                  onTap: (t) => _include(t.widgetId),
                ),
                const SizedBox(height: 12),
                _Group(
                  title: 'Button',
                  items: onlyKind(excluded, HomeTileKind.button),
                  onTap: (t) => _include(t.widgetId),
                ),

                if (excluded.isEmpty) ...[
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text('ไม่มี widget ที่สามารถเพิ่มได้', style: TextStyle(color: Color(0xFF5E87A3))),
                    ),
                  ),
                ],
              ],
            ),
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
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF5E87A3)),
        ),
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
        border: Border.all(color: const Color(0x1100A3FF)),
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0E3A5A),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.drag_indicator_rounded, color: Color(0x553AA7FF), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            tile.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF5E87A3),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),

          // body (preview) — รองรับทุก kind (ไม่ throw)
          _previewBody(tile),
        ],
      ),
    );
  }

  static Widget _previewBody(HomeWidgetTileVM t) {
    final text = _valueText(t);
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF3AA7FF)),
    );
  }

  static String _valueText(HomeWidgetTileVM t) {
    switch (t.kind) {
      case HomeTileKind.toggle:
        return t.isOn ? 'ON' : 'OFF';

      case HomeTileKind.sensor:
      case HomeTileKind.adjust:
        return t.unit.isEmpty ? '${t.value}' : '${t.value}${t.unit}';

      case HomeTileKind.mode: {
        final v = t.value.trim();
        return v.isEmpty ? 'MODE' : v.toUpperCase();
      }

      case HomeTileKind.text: {
        final v = t.value.trim();
        if (v.isEmpty) return 'TEXT';
        return v;
      }

      case HomeTileKind.button:
        return (t.buttonLabel.trim().isEmpty) ? 'PRESS' : t.buttonLabel.trim().toUpperCase();
    }
  }
}