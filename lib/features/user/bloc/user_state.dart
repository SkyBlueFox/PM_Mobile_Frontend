import 'package:equatable/equatable.dart';
import '../../../models/user.dart';

enum UserStatus {
  initial,
  loading,
  ready,
  saving,
  deleting,
  failure,
  success,
}

class UserState extends Equatable {
  final UserStatus status;
  final List<AppUser> users;
  final AppUser? user;
  final String? error;

  const UserState({
    this.status = UserStatus.initial,
    this.users = const [],
    this.user,
    this.error,
  });

  UserState copyWith({
    UserStatus? status,
    List<AppUser>? users,
    AppUser? user,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return UserState(
      status: status ?? this.status,
      users: users ?? this.users,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, users, user, error];
}