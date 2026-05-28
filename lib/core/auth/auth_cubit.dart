import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../connectivity/connectivity_cubit.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authRepository, this._connectivityCubit)
      : super(const AuthState());

  final AuthRepository _authRepository;
  final ConnectivityCubit _connectivityCubit;

  Future<void> loadSession() async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    final token = await _authRepository.getStoredToken();
    if (token == null || token.isEmpty) {
      emit(
        const AuthState(status: AuthStatus.unauthenticated),
      );
      return;
    }

    if (_connectivityCubit.state.isOnline) {
      try {
        final user = await _authRepository.me();
        emit(AuthState(status: AuthStatus.authenticated, user: user));
        return;
      } catch (_) {
        final cached = await _authRepository.getCachedUser();
        if (cached != null) {
          emit(AuthState(status: AuthStatus.authenticated, user: cached));
          return;
        }
      }
    } else {
      final cached = await _authRepository.getCachedUser();
      if (cached != null) {
        emit(AuthState(status: AuthStatus.authenticated, user: cached));
        return;
      }
    }

    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void setUserAuthenticated(UserModel user) {
    emit(AuthState(status: AuthStatus.authenticated, user: user));
  }

  Future<void> signOut({bool callApi = true}) async {
    if (callApi) {
      try {
        await _authRepository.logout();
      } catch (_) {
        await _authRepository.clearSessionLocal();
      }
    } else {
      await _authRepository.clearSessionLocal();
    }
    emit(AuthState.unauthenticated);
  }

  Future<void> signOutLocal() async {
    await _authRepository.clearSessionLocal();
    emit(AuthState.unauthenticated);
  }
}
