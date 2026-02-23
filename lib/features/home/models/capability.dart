// lib/features/home/models/capability.dart
//
// ✅ FIX: ให้ UI เรียก dw.capability.name / dw.capability.unit ได้
// - โปรเจกต์คุณเก็บ config ไว้ใน meta อยู่แล้ว -> ทำ getter alias
// - fromJson รองรับ key หลายแบบ + เติม name/unit เข้า meta ถ้ามาแบบ top-level

enum CapabilityType {
  toggle,
  adjust,
  sensor,
  mode,
  text,
  button,
  unknown,
}

CapabilityType capabilityTypeFromString(String? value) {
  final v = (value ?? '').trim().toLowerCase();

  switch (v) {
    case 'toggle':
      return CapabilityType.toggle;
    case 'adjust':
      return CapabilityType.adjust;
    case 'sensor':
      return CapabilityType.sensor;
    case 'mode':
      return CapabilityType.mode;

    case 'text':
    case 'input':
    case 'message':
      return CapabilityType.text;

    case 'button':
    case 'momentary':
    case 'press':
    case 'trigger':
      return CapabilityType.button;

    default:
      return CapabilityType.unknown;
  }
}

class Capability {
  final int id;
  final CapabilityType type;

  /// optional: รายการตัวเลือก เช่น mode: ["auto","cool","dry","fan","heat"]
  final List<String> options;

  /// optional: เผื่อ backend ส่ง config อื่น ๆ (min/max/step/unit/name ฯลฯ)
  final Map<String, dynamic> meta;

  const Capability({
    required this.id,
    required this.type,
    this.options = const [],
    this.meta = const {},
  });

  // ---------------------------------------------------------------------------
  // ✅ UI-friendly getters
  // ---------------------------------------------------------------------------

  /// ชื่อ capability ที่ใช้แสดงผลใน UI
  /// รองรับ key: meta.name / meta.capability_name / meta.title
  String get name {
    final v = meta['name'] ?? meta['capability_name'] ?? meta['title'];
    return (v ?? '').toString();
  }

  /// หน่วยของค่า เช่น °C, %, ppm
  /// รองรับ key: meta.unit / meta.capability_unit
  String get unit {
    final v = meta['unit'] ?? meta['capability_unit'];
    return (v ?? '').toString();
  }

  factory Capability.fromJson(Map<String, dynamic> json) {
    // id รองรับทั้ง capability_id และ id
    final rawId = json['capability_id'] ?? json['id'] ?? 0;

    final rawOptions = json['options'] ?? json['capability_options'];
    final optionsList = (rawOptions is List) ? rawOptions : const [];

    final rawMeta = json['meta'] ?? json['capability_meta'];
    final metaMap = (rawMeta is Map)
        ? rawMeta.cast<String, dynamic>()
        : const <String, dynamic>{};

    // ✅ เติม name/unit เข้า meta ถ้า backend ส่งมาแบบ top-level
    final mergedMeta = Map<String, dynamic>.from(metaMap);

    final topName = json['name'] ?? json['capability_name'];
    if (topName != null && mergedMeta['name'] == null && mergedMeta['capability_name'] == null) {
      mergedMeta['name'] = topName.toString();
    }

    final topUnit = json['unit'] ?? json['capability_unit'];
    if (topUnit != null && mergedMeta['unit'] == null && mergedMeta['capability_unit'] == null) {
      mergedMeta['unit'] = topUnit.toString();
    }

    return Capability(
      id: (rawId as num).toInt(),
      type: capabilityTypeFromString((json['capability_type'] ?? json['type'])?.toString()),
      options: optionsList.map((e) => e.toString()).toList(),
      meta: mergedMeta,
    );
  }

  Map<String, dynamic> toJson() => {
        'capability_id': id,
        'capability_type': type.name,
        'options': options,
        'meta': meta,
      };
}

class CapabilitiesResponse {
  final List<Capability> data;

  const CapabilitiesResponse({required this.data});

  factory CapabilitiesResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final list = (raw is List ? raw : const [])
        .whereType<Map>()
        .map((m) => Capability.fromJson(m.cast<String, dynamic>()))
        .toList();

    return CapabilitiesResponse(data: list);
  }
}