import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit(this._dio) : super(const ConnectivityState()) {
    _subscription = Connectivity().onConnectivityChanged.listen((_) {
      checkConnectivity();
    });
    checkConnectivity();
  }

  final Dio _dio;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _wasOnline = false;

  Future<void> checkConnectivity() async {
    emit(state.copyWith(checking: true));
    final results = await Connectivity().checkConnectivity();
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);
    if (!hasNetwork) {
      _emitOnline(false, hasNetwork: false);
      return;
    }
    try {
      final response = await _dio.get<dynamic>(
        '/health',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      _emitOnline(response.statusCode == 200, hasNetwork: true);
    } catch (_) {
      _emitOnline(false, hasNetwork: true);
    }
  }

  void _emitOnline(bool online, {required bool hasNetwork}) {
    final becameOnline = online && !_wasOnline;
    _wasOnline = online;
    emit(
      ConnectivityState(
        isOnline: online,
        hasNetwork: hasNetwork,
        checking: false,
      ),
    );
    if (becameOnline) {
      onBecameOnline?.call();
    }
  }

  void Function()? onBecameOnline;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
