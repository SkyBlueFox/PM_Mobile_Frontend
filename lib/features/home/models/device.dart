enum RoomType { all, bedroom, living }

String roomLabel(RoomType t) {
  switch (t) {
    case RoomType.all:
      return 'ทั้งหมด';
    case RoomType.bedroom:
      return 'ห้องนอน';
    case RoomType.living:
      return 'ห้องนั่งเล่น';
  }
}

abstract class Device {
  final String id;
  final String name;
  final RoomType room;

  const Device({
    required this.id,
    required this.name,
    required this.room,
  });
}

mixin Toggleable {
  bool get isOn;
}

mixin Quantifiable {
  double get value;
  double get minValue;
  double get maxValue;
  String get unit;
}
