class Room {
  final int id;
  final String name;

  const Room({
    required this.id,
    required this.name,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['room_id'] as int,
      name: json['room_name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'room_id': id,
        'room_name': name,
      };
}

class RoomsResponse {
  final List<Room> data;

  const RoomsResponse({required this.data});

  factory RoomsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List).cast<Map<String, dynamic>>();
    return RoomsResponse(data: list.map(Room.fromJson).toList());
  }
}
