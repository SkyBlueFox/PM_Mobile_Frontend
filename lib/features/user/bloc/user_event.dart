abstract class UserEvent {}

/// Load all users
class FetchUsers extends UserEvent {}

/// Get single user
class FetchUserById extends UserEvent {
  final String userId;

  FetchUserById(this.userId);
}

/// Create user
class CreateUser extends UserEvent {
  final String name;
  final String email;

  CreateUser({
    required this.name,
    required this.email,
  });
}

/// Delete user
class DeleteUser extends UserEvent {
  final String userId;

  DeleteUser(this.userId);
}