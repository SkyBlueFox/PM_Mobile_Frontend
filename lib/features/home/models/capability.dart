enum CapabilityType { toggle, adjust, sensor, mode, unknown }

CapabilityType capabilityTypeFromString(String value) {
  switch (value.trim().toLowerCase()) {
    case 'toggle':
      return CapabilityType.toggle;
    case 'adjust':
      return CapabilityType.adjust;
    case 'sensor':
      return CapabilityType.sensor;
    case 'mode':
      return CapabilityType.mode;
    default:
      return CapabilityType.unknown;
  }
}

class Capability {
  final int id;
  final CapabilityType type;

  const Capability({
    required this.id,
    required this.type,
  });

  factory Capability.fromJson(Map<String, dynamic> json) {
    return Capability(
      id: json['capability_id'] as int,
      type: capabilityTypeFromString(json['capability_type'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'capability_id': id,
        'capability_type': type.name,
      };
}

class CapabilitiesResponse {
  final List<Capability> data;

  const CapabilitiesResponse({required this.data});

  factory CapabilitiesResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List).cast<Map<String, dynamic>>();
    return CapabilitiesResponse(data: list.map(Capability.fromJson).toList());
  }
}
