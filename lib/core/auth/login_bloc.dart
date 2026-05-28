import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';
import 'auth_cubit.dart';

class LoginEvent extends Equatable {
  const LoginEvent(this.email, this.password);
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    this.errorMessage,
  });

  final LoginStatus status;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, errorMessage];
}

enum LoginStatus { initial, loading, success, failure }

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc(this._authRepository, this._authCubit)
      : super(const LoginState()) {
    on<LoginEvent>(_onLogin);
  }

  final AuthRepository _authRepository;
  final AuthCubit _authCubit;

  Future<void> _onLogin(LoginEvent event, Emitter<LoginState> emit) async {
    emit(const LoginState(status: LoginStatus.loading));
    try {
      final user = await _authRepository.login(
        email: event.email.trim(),
        password: event.password,
      );
      _authCubit.setUserAuthenticated(user);
      emit(const LoginState(status: LoginStatus.success));
    } on DioException catch (e) {
      final msg = _extractMessage(e);
      emit(LoginState(status: LoginStatus.failure, errorMessage: msg));
    } catch (e) {
      emit(LoginState(status: LoginStatus.failure, errorMessage: e.toString()));
    }
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      if (data['message'] != null) return data['message'].toString();
    }
    return 'Login failed. Check credentials and API URL.';
  }
}
