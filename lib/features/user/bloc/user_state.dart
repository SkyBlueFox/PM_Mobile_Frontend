import '../../../models/user.dart';

abstract class UserState {}

/// Initial
class UserInitial extends UserState {}

/// Loading state
class UserLoading extends UserState {}

/// List of users loaded
class UsersLoaded extends UserState {
  final List<AppUser> users;

  UsersLoaded(this.users);
}

/// Single user loaded
class UserLoaded extends UserState {
  final AppUser user;

  UserLoaded(this.user);
}

/// Success after create/delete
class UserActionSuccess extends UserState {}

/// Error
class UserError extends UserState {
  final String message;

  UserError(this.message);
}