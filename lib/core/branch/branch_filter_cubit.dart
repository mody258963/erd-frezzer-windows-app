import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/branch_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/branch_repository.dart';
import '../events/app_refresh_bus.dart';
import '../settings/settings_service.dart';

class BranchFilterState extends Equatable {
  const BranchFilterState({
    this.selectedBranchId,
    this.branches = const [],
    this.loading = false,
  });

  final String? selectedBranchId;
  final List<BranchModel> branches;
  final bool loading;

  String? branchNameFor(String? id) {
    if (id == null) return null;
    for (final b in branches) {
      if (b.id == id) return b.name;
    }
    return null;
  }

  bool get isFiltered => selectedBranchId != null && selectedBranchId!.isNotEmpty;

  @override
  List<Object?> get props => [selectedBranchId, branches, loading];

  BranchFilterState copyWith({
    String? selectedBranchId,
    bool clearBranch = false,
    List<BranchModel>? branches,
    bool? loading,
  }) {
    return BranchFilterState(
      selectedBranchId:
          clearBranch ? null : (selectedBranchId ?? this.selectedBranchId),
      branches: branches ?? this.branches,
      loading: loading ?? this.loading,
    );
  }
}

/// Admin-only global branch scope (`?branch_id=` on API calls).
class BranchFilterCubit extends Cubit<BranchFilterState> {
  BranchFilterCubit(this._branches, this._settings, this._refreshBus)
      : super(
          BranchFilterState(
            selectedBranchId: _settings.adminBranchFilterId,
          ),
        );

  final BranchRepository _branches;
  final SettingsService _settings;
  final AppRefreshBus _refreshBus;

  /// Branch id for API scope.
  ///
  /// Users with [UserModel.canSelectBranch]: selected filter branch, or null (all).
  /// Branch-locked users: always [UserModel.branchId].
  String? apiBranchId(UserModel? user) {
    if (user == null) return null;
    if (user.canSelectBranch) {
      final id = state.selectedBranchId;
      if (id == null || id.isEmpty) return null;
      return id;
    }
    final assigned = user.branchId;
    if (assigned == null || assigned.isEmpty) return null;
    return assigned;
  }

  /// @deprecated Use [apiBranchId].
  String? effectiveBranchId(UserModel? user) => apiBranchId(user);

  Future<void> loadBranches() async {
    emit(state.copyWith(loading: true));
    try {
      final list = await _branches.listActive();
      var selectedId = state.selectedBranchId;
      if (selectedId != null &&
          selectedId.isNotEmpty &&
          !list.any((b) => b.id == selectedId)) {
        await _settings.setAdminBranchFilterId(null);
        selectedId = null;
      }
      if (selectedId == null && state.selectedBranchId != null) {
        emit(state.copyWith(branches: list, loading: false, clearBranch: true));
      } else {
        emit(state.copyWith(branches: list, loading: false));
      }
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
  }

  Future<void> selectBranch(String? id) async {
    if (id == null || id.isEmpty) {
      await _settings.setAdminBranchFilterId(null);
      emit(state.copyWith(clearBranch: true));
    } else {
      await _settings.setAdminBranchFilterId(id);
      await _settings.setPosBranchId(id);
      emit(state.copyWith(selectedBranchId: id));
    }
    _refreshBus.notifyAll();
  }

  Future<void> clearFilter() => selectBranch(null);
}
