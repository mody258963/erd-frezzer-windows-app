import 'package:flutter/material.dart';

import '../../data/models/part_model.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/part_repository.dart';
import '../../di/injection.dart';

/// Active parts from the catalog.
Future<List<PartModel>> loadActiveParts({int perPage = 500}) async {
  final all = await getIt<PartRepository>().list(perPage: perPage);
  return all.where((p) => p.isActive).toList();
}

String partDisplayLabel(PartModel part) => '${part.code} — ${part.name}';

/// Part selectable for transfers, with optional on-hand qty at a branch.
class PartPickOption {
  const PartPickOption({
    required this.partId,
    required this.label,
    this.availableQty,
  });

  final String partId;
  final String label;
  final int? availableQty;
}

/// Parts at a branch (any qty) plus catalog items not yet stocked there.
Future<List<PartPickOption>> loadPartsForBranchAdjust(String branchId) async {
  final options = <PartPickOption>[];
  final seen = <String>{};

  try {
    final stock = await getIt<InventoryRepository>().byBranch(branchId);
    for (final s in stock) {
      seen.add(s.partId);
      final part = s.part;
      final label =
          part != null ? partDisplayLabel(part) : s.partId;
      options.add(
        PartPickOption(
          partId: s.partId,
          label: label,
          availableQty: s.quantity,
        ),
      );
    }
  } catch (_) {
    // Continue with catalog-only list.
  }

  try {
    final parts = await loadActiveParts();
    for (final p in parts) {
      if (seen.contains(p.id)) continue;
      options.add(
        PartPickOption(
          partId: p.id,
          label: partDisplayLabel(p),
          availableQty: 0,
        ),
      );
    }
  } catch (_) {
    if (options.isEmpty) rethrow;
  }

  options.sort((a, b) => a.label.compareTo(b.label));
  return options;
}

/// Parts in stock at [fromBranchId]; falls back to full catalog if none listed.
Future<List<PartPickOption>> loadPartsForBranchTransfer(String fromBranchId) async {
  try {
    final stock = await getIt<InventoryRepository>().byBranch(fromBranchId);
    final options = <PartPickOption>[];
    for (final s in stock) {
      if (s.quantity <= 0) continue;
      final part = s.part;
      final label = part != null
          ? partDisplayLabel(part)
          : s.partId;
      options.add(
        PartPickOption(
          partId: s.partId,
          label: label,
          availableQty: s.quantity,
        ),
      );
    }
    if (options.isNotEmpty) {
      options.sort((a, b) => a.label.compareTo(b.label));
      return options;
    }
  } catch (_) {
    // Fall through to catalog.
  }

  final parts = await loadActiveParts();
  return parts
      .map(
        (p) => PartPickOption(
          partId: p.id,
          label: partDisplayLabel(p),
        ),
      )
      .toList();
}

/// Dropdown that shows part names; submits part id to the API.
class PartDropdown extends StatelessWidget {
  const PartDropdown({
    required this.options,
    required this.value,
    required this.onChanged,
    required this.label,
    this.validator,
    this.hint,
    super.key,
  });

  final List<PartPickOption> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String? Function(String?)? validator;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final selected =
        value != null && options.any((p) => p.partId == value) ? value : null;

    return DropdownButtonFormField<String>(
      value: selected,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      isExpanded: true,
      items: [
        for (final p in options)
          DropdownMenuItem(
            value: p.partId,
            child: Text(
              p.availableQty != null
                  ? '${p.label} (${p.availableQty})'
                  : p.label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: options.isEmpty ? null : onChanged,
      validator: validator,
    );
  }
}
