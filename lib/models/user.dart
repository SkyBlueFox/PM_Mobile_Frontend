enum Role {
  admin,
  user,
}

class AppUser {
  final String name;
  final String email;
  final Role role;

  const AppUser({
    required this.name,
    required this.email,
    required this.role,
  });

  AppUser copyWith({
    String? name,
    String? email,
    Role? role,
  }) {
    return AppUser(
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '';
    final email = json['email']?.toString() ?? '';
    final roleString = json['role']?.toString().toUpperCase() ?? 'USER';

    return AppUser(
      name: name,
      email: email,
      role: _roleFromString(roleString),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'role': role.name.toUpperCase(),
      };

  static Role _roleFromString(String role) {
    switch (role) {
      case 'ADMIN':
        return Role.admin;
      case 'USER':
        return Role.user;
      default:
        return Role.user;
    }
  }
}