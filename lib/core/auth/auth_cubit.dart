import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../di/injection.dart';
import '../catalog/catalog_refresh_scheduler.dart';
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
        getIt<CatalogRefreshScheduler>().start();
        return;
      } catch (_) {
        final cached = await _authRepository.getCachedUser();
        if (cached != null) {
          emit(AuthState(status: AuthStatus.authenticated, user: cached));
          getIt<CatalogRefreshScheduler>().start();
          return;
        }
      }
    } else {
      final cached = await _authRepository.getCachedUser();
      if (cached != null) {
        emit(AuthState(status: AuthStatus.authenticated, user: cached));
        getIt<CatalogRefreshScheduler>().start();
        return;
      }
    }

    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void setUserAuthenticated(UserModel user) {
    emit(AuthState(status: AuthStatus.authenticated, user: user));
    getIt<CatalogRefreshScheduler>().start();
  }

  Future<void> signOut({bool callApi = true}) async {
    getIt<CatalogRefreshScheduler>().stop();
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
    getIt<CatalogRefreshScheduler>().stop();
    await _authRepository.clearSessionLocal();
    emit(AuthState.unauthenticated);
  }
}
