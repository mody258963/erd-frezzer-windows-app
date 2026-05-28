import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/workers/sync_worker.dart';

class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

class SyncState extends Equatable {
  const SyncState({
    this.status = SyncStatus.idle,
    this.result,
  });

  final SyncStatus status;
  final SyncResult? result;

  @override
  List<Object?> get props => [status, result];
}

enum SyncStatus { idle, syncing, done, partialFailure }

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc(this._worker) : super(const SyncState()) {
    on<SyncEvent>(_onSync);
  }

  final SyncWorker _worker;

  Future<void> _onSync(SyncEvent event, Emitter<SyncState> emit) async {
    emit(const SyncState(status: SyncStatus.syncing));
    final result = await _worker.syncAll();
    if (result.stoppedForAuth) {
      emit(SyncState(status: SyncStatus.done, result: result));
      return;
    }
    final status = result.failed > 0
        ? SyncStatus.partialFailure
        : SyncStatus.done;
    emit(SyncState(status: status, result: result));
  }
}
