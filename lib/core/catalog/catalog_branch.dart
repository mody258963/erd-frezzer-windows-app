import '../../data/models/user_model.dart';
import '../../core/settings/settings_service.dart';
import '../../di/injection.dart';
import '../../features/shared/branch_dropdown.dart';

/// Branch used for inventory/catalog sync (POS offline cache).
Future<String?> resolveCatalogBranchId(
  UserModel? user, {
  SettingsService? settings,
}) async {
  if (user == null) return null;

  final assigned = user.branchId;
  if (assigned != null && assigned.isNotEmpty) return assigned;

  final prefs = settings ?? getIt<SettingsService>();
  final saved = prefs.posBranchId;
  if (saved != null && saved.isNotEmpty) {
    final allowed = user.accessibleBranchIds;
    if (allowed == null || allowed.contains(saved)) return saved;
  }

  if (user.canSelectBranch) {
    final branches = await loadActiveBranches(
      allowedIds: user.accessibleBranchIds,
    );
    if (branches.isNotEmpty) return branches.first.id;
  }

  return null;
}
