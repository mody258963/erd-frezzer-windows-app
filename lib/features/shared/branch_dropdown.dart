import 'package:flutter/material.dart';

import '../../data/models/branch_model.dart';
import '../../data/repositories/branch_repository.dart';
import '../../di/injection.dart';

/// Active branches from the API.
Future<List<BranchModel>> loadActiveBranches() async {
  final all = await getIt<BranchRepository>().list();
  return all.where((b) => b.isActive).toList();
}

Map<String, String> branchNameById(Iterable<BranchModel> branches) {
  return {for (final b in branches) b.id: b.name};
}

String resolveBranchName(
  Map<String, String> names,
  dynamic branchId, {
  Map<String, dynamic>? row,
  String branchKey = 'branch',
}) {
  final nested = row?[branchKey];
  if (nested is Map && nested['name'] != null) {
    return '${nested['name']}';
  }
  final id = branchId?.toString() ?? '';
  if (id.isEmpty) return '—';
  return names[id] ?? id;
}

/// Dropdown that shows branch names; submits branch id to the API.
class BranchDropdown extends StatelessWidget {
  const BranchDropdown({
    required this.branches,
    required this.value,
    required this.onChanged,
    required this.label,
    this.validator,
    super.key,
  });

  final List<BranchModel> branches;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final selected =
        value != null && branches.any((b) => b.id == value) ? value : null;

    return DropdownButtonFormField<String>(
      value: selected,
      decoration: InputDecoration(labelText: label),
      isExpanded: true,
      items: [
        for (final b in branches)
          DropdownMenuItem(
            value: b.id,
            child: Text(b.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: branches.isEmpty ? null : onChanged,
      validator: validator,
    );
  }
}
