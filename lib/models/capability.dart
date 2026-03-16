// lib/features/home/models/capability.dart
//
// ✅ FIX: ให้ UI เรียก dw.capability.name / dw.capability.unit ได้
// - โปรเจกต์คุณเก็บ config ไว้ใน meta อยู่แล้ว -> ทำ getter alias
// - fromJson รองรับ key หลายแบบ + เติม name/unit เข้า meta ถ้ามาแบบ top-level

enum CapabilityType {
  toggle,
  adjust,
  level,
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
    case 'level':
      return CapabilityType.level;
    case 'sensor':
      return CapabilityType.sensor;
    case 'mode':
      return CapabilityType.mode;
    case 'input':
    case 'text':
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
  final String controlType;

  /// optional: รายการตัวเลือก เช่น mode: ["auto","cool","dry","fan","heat"]
  final List<String> options;

  /// optional: เผื่อ backend ส่ง config อื่น ๆ (min/max/step/unit/name ฯลฯ)
  final Map<String, dynamic> meta;

  const Capability({
    required this.id,
    required this.type,
    required this.controlType,
    this.options = const [],
    this.meta = const {},
  });

  String get name {
    final v = meta['name'] ?? meta['capability_name'] ?? meta['title'];
    return (v ?? '').toString();
  }

  String get unit {
    final v = meta['unit'] ?? meta['capability_unit'];
    return (v ?? '').toString();
  }

  factory Capability.fromJson(Map<String, dynamic> json) {
    final rawId = json['capability_id'] ?? json['id'] ?? 0;
    final rawControlType = json['control_type'];

    final rawOptions = json['options'] ?? json['capability_options'];
    final optionsList = (rawOptions is List) ? rawOptions : const [];

    final rawMeta = json['meta'] ?? json['capability_meta'];
    final metaMap = (rawMeta is Map)
        ? rawMeta.cast<String, dynamic>()
        : const <String, dynamic>{};

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
      controlType: rawControlType,
      options: optionsList.map((e) => e.toString()).toList(),
      meta: mergedMeta,
    );
  }

  Map<String, dynamic> toJson() => {
        'capability_id': id,
        'capability_type': type.name,
        'control_type' : controlType,
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