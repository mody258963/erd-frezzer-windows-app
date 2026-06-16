import 'package:flutter/material.dart';

import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/l10n/return_resolution_labels.dart';
import '../../core/utils/return_approval_helper.dart';

/// Dialog to pick approve [resolution] with line summary and API hints.
class ApproveReturnDialog extends StatefulWidget {
  const ApproveReturnDialog({
    required this.returnRow,
    required this.lines,
    super.key,
  });

  final Map<String, dynamic> returnRow;
  final List<ReturnLineInfo> lines;

  static Future<String?> show(
    BuildContext context, {
    required Map<String, dynamic> returnRow,
    required List<ReturnLineInfo> lines,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => ApproveReturnDialog(returnRow: returnRow, lines: lines),
    );
  }

  @override
  State<ApproveReturnDialog> createState() => _ApproveReturnDialogState();
}

class _ApproveReturnDialogState extends State<ApproveReturnDialog> {
  late String _resolution;
  late final List<String> _choices;

  @override
  void initState() {
    super.initState();
    _choices = resolutionsForApprove(widget.returnRow, widget.lines);
    _resolution = suggestCustomerResolution(widget.returnRow, widget.lines);
    if (!_choices.contains(_resolution)) {
      _resolution = _choices.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = returnTotalValue(widget.lines);
    final hasDefective = widget.lines.any((i) => i.isDefective);

    return AlertDialog(
      title: Text(l10n.approve),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasDefective)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      l10n.returnDefectiveHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              if (hasDefective) const SizedBox(height: 8),
              Text(
                l10n.returnLinesSummary,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              for (final line in widget.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          line.partLabel ?? line.partId,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${line.quantity} × ${formatMoney(context, line.unitPrice)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              const Divider(height: 20),
              Text(
                '${l10n.total}: ${formatMoney(context, total)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _resolution,
                decoration: InputDecoration(labelText: l10n.returnResolution),
                isExpanded: true,
                items: [
                  for (final r in _choices)
                    DropdownMenuItem(
                      value: r,
                      child: Text(localizeReturnResolution(context, r)),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _resolution = v);
                },
              ),
              const SizedBox(height: 8),
              Text(
                resolutionEffectHint(context, _resolution, hasDefective),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _resolution),
          child: Text(l10n.approve),
        ),
      ],
    );
  }
}
