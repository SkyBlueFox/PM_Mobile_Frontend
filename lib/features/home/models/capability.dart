// lib/features/home/models/capability.dart

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

  /// optional: เผื่อ backend ส่ง config อื่น ๆ (min/max/step/unit ฯลฯ)
  final Map<String, dynamic> meta;

  const Capability({
    required this.id,
    required this.type,
    this.options = const [],
    this.meta = const {},
  });

  factory Capability.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] ?? json['capability_options'];
    final optionsList = (rawOptions is List) ? rawOptions : const [];

    final rawMeta = json['meta'] ?? json['capability_meta'];
    final metaMap = (rawMeta is Map<String, dynamic>) ? rawMeta : const <String, dynamic>{};

    return Capability(
      id: (json['capability_id'] as num).toInt(),
      type: capabilityTypeFromString(json['capability_type']?.toString()),
      options: optionsList.map((e) => e.toString()).toList(),
      meta: metaMap,
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
        .whereType<Map<String, dynamic>>()
        .map(Capability.fromJson)
        .toList();

    return CapabilitiesResponse(data: list);
  }
}