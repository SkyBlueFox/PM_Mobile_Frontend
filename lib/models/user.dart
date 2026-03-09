class AppUser {
  final String name;
  final String email;

  const AppUser({
    required this.name,
    required this.email,
  });

  AppUser copyWith({
    String? name,
    String? email,
  }) {
    return AppUser(
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    // รองรับทั้ง schema ปกติ และ fallback
    final name = json['name']?.toString() ?? '';
    final email = json['email']?.toString() ?? '';

    return AppUser(
      name: name,
      email: email,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
      };
}

class UsersResponse {
  final List<AppUser> data;

  const UsersResponse({required this.data});

  factory UsersResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final List list = raw is List ? raw : const [];

    return UsersResponse(
      data: list
          .whereType<Map>()
          .map((e) => AppUser.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}