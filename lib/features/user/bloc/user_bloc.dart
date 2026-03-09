import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/user_repository.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final AppUserRepository repository;

  UserBloc(this.repository) : super(UserInitial()) {

    /// GET /api/users
    on<FetchUsers>((event, emit) async {
      emit(UserLoading());

      try {
        final users = await repository.fetchAppUsers();
        emit(UsersLoaded(users));
      } catch (e) {
        emit(UserError(e.toString()));
      }
    });

    /// GET /api/users/{id}
    on<FetchUserById>((event, emit) async {
      emit(UserLoading());

      try {
        final user = await repository.fetchAppUserById(event.userId);

        if (user == null) {
          emit(UserError("User not found"));
          return;
        }

        emit(UserLoaded(user));
      } catch (e) {
        emit(UserError(e.toString()));
      }
    });

    /// POST /api/users
    on<CreateUser>((event, emit) async {
      emit(UserLoading());

      try {
        await repository.createAppUser(
          name: event.name,
          email: event.email,
        );

        emit(UserActionSuccess());
      } catch (e) {
        emit(UserError(e.toString()));
      }
    });

    /// DELETE /api/users/{id}
    on<DeleteUser>((event, emit) async {
      emit(UserLoading());

      try {
        await repository.deleteAppUser(event.userId);

        emit(UserActionSuccess());
      } catch (e) {
        emit(UserError(e.toString()));
      }
    });
  }
}