import 'package:flutter/material.dart';

import '../../core/l10n/l10n_extension.dart';

/// Credit customer collection schedule: daily or weekly (Saturday).
class SettlementCycleDropdown extends StatelessWidget {
  const SettlementCycleDropdown({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DropdownButtonFormField<String>(
      initialValue: value == 'daily' ? 'daily' : 'weekly',
      decoration: InputDecoration(labelText: l10n.settlementCycleLabel),
      isExpanded: true,
      items: [
        DropdownMenuItem(
          value: 'weekly',
          child: Text(l10n.settlementCycleWeekly),
        ),
        DropdownMenuItem(
          value: 'daily',
          child: Text(l10n.settlementCycleDaily),
        ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
