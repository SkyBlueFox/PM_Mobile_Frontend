import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/user_repository.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final AppUserRepository repository;

  UserBloc(this.repository) : super(const UserState()) {
    on<FetchUsers>((event, emit) async {
      emit(state.copyWith(
        status: UserStatus.loading,
        clearError: true,
      ));

      try {
        final users = await repository.fetchAppUsers();
        emit(state.copyWith(
          status: UserStatus.ready,
          users: users,
          clearError: true,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: UserStatus.failure,
          error: e.toString(),
        ));
      }
    });

    on<FetchUserById>((event, emit) async {
      emit(state.copyWith(
        status: UserStatus.loading,
        clearError: true,
      ));

      try {
        final user = await repository.fetchAppUserById(event.userId);

        if (user == null) {
          emit(state.copyWith(
            status: UserStatus.failure,
            error: 'User not found',
          ));
          return;
        }

        emit(state.copyWith(
          status: UserStatus.ready,
          user: user,
          clearError: true,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: UserStatus.failure,
          error: e.toString(),
        ));
      }
    });

    on<CreateUser>((event, emit) async {
      emit(state.copyWith(
        status: UserStatus.saving,
        clearError: true,
      ));

      try {
        await repository.createAppUser(
          name: event.name,
          email: event.email,
        );

        emit(state.copyWith(
          status: UserStatus.success,
          clearError: true,
        ));

        final users = await repository.fetchAppUsers();
        emit(state.copyWith(
          status: UserStatus.ready,
          users: users,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: UserStatus.failure,
          error: e.toString(),
        ));
      }
    });

    on<DeleteUser>((event, emit) async {
      emit(state.copyWith(
        status: UserStatus.deleting,
        clearError: true,
      ));

      try {
        await repository.deleteAppUser(event.userEmail);

        emit(state.copyWith(
          status: UserStatus.success,
          clearError: true,
        ));

        final users = await repository.fetchAppUsers();
        emit(state.copyWith(
          status: UserStatus.ready,
          users: users,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: UserStatus.failure,
          error: e.toString(),
        ));
      }
    });
  }
}