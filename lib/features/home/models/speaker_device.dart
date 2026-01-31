import 'device.dart';

class SpeakerDevice extends Device with Toggleable, Quantifiable {
  @override
  final bool isOn;

  /// ระดับเสียงปัจจุบัน
  @override
  final double value;

  /// ระดับเสียงต่ำสุด
  @override
  final double minValue;

  /// ระดับเสียงสูงสุด
  @override
  final double maxValue;

  /// หน่วย (เช่น %)
  @override
  final String unit;

  const SpeakerDevice({
    required super.id,
    required super.name,
    required super.room,
    this.isOn = false,
    this.value = 30,
    this.minValue = 0,
    this.maxValue = 100,
    this.unit = '%',
  });

  SpeakerDevice copyWith({
    bool? isOn,
    double? value,
  }) {
    return SpeakerDevice(
      id: id,
      name: name,
      room: room,
      isOn: isOn ?? this.isOn,
      value: value ?? this.value,
      minValue: minValue,
      maxValue: maxValue,
      unit: unit,
    );
  }
}
