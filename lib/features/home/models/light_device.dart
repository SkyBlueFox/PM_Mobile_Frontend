import 'device.dart';

class LightDevice extends Device with Toggleable {
  @override
  final bool isOn;

  const LightDevice({
    required super.id,
    required super.name,
    required super.room,
    this.isOn = false,
  });

  LightDevice copyWith({
    bool? isOn,
  }) {
    return LightDevice(
      id: id,
      name: name,
      room: room,
      isOn: isOn ?? this.isOn,
    );
  }
}
