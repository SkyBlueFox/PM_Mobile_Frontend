abstract class UserEvent {}

class FetchUsers extends UserEvent {}

class FetchUserById extends UserEvent {
  final int userId;

  FetchUserById(this.userId);
}

class CreateUser extends UserEvent {
  final String name;
  final String email;

  CreateUser({
    required this.name,
    required this.email,
  });
}

class DeleteUser extends UserEvent {
  final String userEmail;

  DeleteUser(this.userEmail);
}