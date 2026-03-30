abstract class UserEvent {}

class FetchUsers extends UserEvent {}

class FetchUserByEmail extends UserEvent {
  final String userEmail;

  FetchUserByEmail(this.userEmail);
}

class CreateUser extends UserEvent {
  final String name;
  final String email;

  CreateUser({
    required this.name,
    required this.email,
  });
}

class UpdateUserName extends UserEvent {
  final String email;
  final String name;

  UpdateUserName({
    required this.email,
    required this.name,
  });
}

class DeleteUser extends UserEvent {
  final String userEmail;

  DeleteUser(this.userEmail);
}