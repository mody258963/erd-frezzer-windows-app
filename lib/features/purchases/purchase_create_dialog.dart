import 'package:flutter/material.dart';

import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/utils/sale_quantity.dart';
import '../../data/models/branch_model.dart';
import '../../data/models/part_model.dart';
import '../../data/models/supplier_model.dart';
import '../shared/branch_dropdown.dart';
import '../shared/part_search_field.dart';

class PurchaseCreateDialogResult {
  const PurchaseCreateDialogResult({
    required this.supplierId,
    required this.branchId,
    required this.description,
    required this.paymentType,
    required this.lines,
    this.installmentCount = 3,
    this.installmentStartDate,
  });

  final String supplierId;
  final String branchId;
  final String description;
  final String paymentType;
  final List<PurchaseLineDraft> lines;
  final int installmentCount;
  final String? installmentStartDate;
}

class PurchaseLineDraft {
  PurchaseLineDraft({
    this.partId,
    this.quantity = 1,
    this.unitCost = 0,
    this.unit,
    this.unitLabel,
  });

  String? partId;
  double quantity;
  double unitCost;
  String? unit;
  String? unitLabel;
}

class PurchaseCreateDialog extends StatefulWidget {
  const PurchaseCreateDialog({
    required this.suppliers,
    required this.parts,
    required this.branches,
    required this.initialBranchId,
    required this.showBranchPicker,
    super.key,
  });

  final List<SupplierModel> suppliers;
  final List<PartModel> parts;
  final List<BranchModel> branches;
  final String initialBranchId;
  final bool showBranchPicker;

  @override
  State<PurchaseCreateDialog> createState() => _PurchaseCreateDialogState();
}

class _PurchaseCreateDialogState extends State<PurchaseCreateDialog> {
  late String? _supplierId;
  late String? _branchId;
  late String _paymentType;
  late int _installmentCount;
  final _description = TextEditingController();
  final _installmentStart = TextEditingController(
    text: DateTime.now()
        .add(const Duration(days: 30))
        .toIso8601String()
        .split('T')
        .first,
  );
  final _lines = <PurchaseLineDraft>[PurchaseLineDraft()];
  final _qtyControllers = <TextEditingController>[];
  final _costControllers = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    _supplierId =
        widget.suppliers.isNotEmpty ? widget.suppliers.first.id : null;
    _branchId = widget.initialBranchId;
    _paymentType = 'immediate';
    _installmentCount = 3;
    _addLineControllers(0);
  }

  void _addLineControllers(int index) {
    while (_qtyControllers.length <= index) {
      _qtyControllers.add(TextEditingController(text: '1'));
      _costControllers.add(TextEditingController(text: '0'));
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _installmentStart.dispose();
    for (final c in _qtyControllers) {
      c.dispose();
    }
    for (final c in _costControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addLine() {
    setState(() {
      _lines.add(PurchaseLineDraft());
      _addLineControllers(_lines.length - 1);
    });
  }

  void _removeLine(int index) {
    if (_lines.length <= 1) return;
    setState(() {
      _qtyControllers[index].dispose();
      _costControllers[index].dispose();
      _lines.removeAt(index);
      _qtyControllers.removeAt(index);
      _costControllers.removeAt(index);
    });
  }

  void _onPartSelected(int index, PartModel? part) {
    setState(() {
      _lines[index].partId = part?.id;
      _lines[index].unit = part?.unit;
      _lines[index].unitLabel = part?.unitLabel;
      if (part != null) {
        _lines[index].unitCost = part.costPrice;
        _costControllers[index].text = part.costPrice.toStringAsFixed(2);
        final qty = defaultSaleQuantity(part.unit);
        _lines[index].quantity = qty;
        _qtyControllers[index].text =
            formatSaleQuantity(qty, unit: part.unit);
      }
    });
  }

  void _save() {
    final l10n = context.l10n;
    if (_supplierId == null ||
        _branchId == null ||
        _branchId!.isEmpty ||
        widget.suppliers.isEmpty) {
      return;
    }

    for (var i = 0; i < _lines.length; i++) {
      final rawQty =
          double.tryParse(_qtyControllers[i].text.replaceAll(',', '')) ??
              _lines[i].quantity;
      _lines[i].quantity =
          normalizeSaleQuantity(rawQty, _lines[i].unit);
      _lines[i].unitCost =
          double.tryParse(_costControllers[i].text.replaceAll(',', '')) ??
              _lines[i].unitCost;
    }

    final validLines = _lines
        .where(
          (l) =>
              l.partId != null &&
              !isSaleQuantityTooLow(l.quantity, l.unit),
        )
        .toList();
    if (validLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addAtLeastOneLine)),
      );
      return;
    }

    Navigator.pop(
      context,
      PurchaseCreateDialogResult(
        supplierId: _supplierId!,
        branchId: _branchId!,
        description: _description.text.trim(),
        paymentType: _paymentType,
        lines: validLines,
        installmentCount: _installmentCount,
        installmentStartDate: _installmentStart.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.newPurchase),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showBranchPicker) ...[
                BranchDropdown(
                  branches: widget.branches,
                  value: _branchId,
                  label: l10n.branch,
                  onChanged: (v) => setState(() => _branchId = v),
                ),
                const SizedBox(height: 12),
              ],
              if (widget.suppliers.isEmpty)
                Text(
                  l10n.noSuppliersHint,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                )
              else
                DropdownButtonFormField<String>(
                  value: _supplierId,
                  decoration: InputDecoration(labelText: l10n.supplier),
                  items: [
                    for (final s in widget.suppliers)
                      DropdownMenuItem(value: s.id, child: Text(s.name)),
                  ],
                  onChanged: (v) => setState(() => _supplierId = v),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                decoration: InputDecoration(labelText: l10n.description),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'immediate',
                    label: Text(l10n.paymentImmediate),
                  ),
                  ButtonSegment(
                    value: 'installments',
                    label: Text(l10n.paymentInstallments),
                  ),
                ],
                selected: {_paymentType},
                onSelectionChanged: (s) =>
                    setState(() => _paymentType = s.first),
              ),
              if (_paymentType == 'installments') ...[
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(labelText: l10n.installmentCount),
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      _installmentCount = int.tryParse(v) ?? _installmentCount,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _installmentStart,
                  decoration:
                      InputDecoration(labelText: l10n.installmentStartDate),
                ),
              ],
              const SizedBox(height: 16),
              Text(l10n.lineItems, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              for (var i = 0; i < _lines.length; i++) ...[
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: PartSearchField(
                                parts: widget.parts,
                                value: _lines[i].partId,
                                label: l10n.part,
                                onSelected: (p) => _onPartSelected(i, p),
                              ),
                            ),
                            IconButton(
                              tooltip: l10n.removeFromCart,
                              icon: const Icon(Icons.delete_outline),
                              onPressed: _lines.length > 1
                                  ? () => _removeLine(i)
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _qtyControllers[i],
                                decoration: InputDecoration(
                                  labelText: l10n.qty,
                                  suffixText: _lines[i].unit != null
                                      ? localizePartUnitLabel(
                                          context,
                                          _lines[i].unit!,
                                          _lines[i].unitLabel ?? '',
                                        )
                                      : null,
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal:
                                      isFractionalSaleUnit(_lines[i].unit),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _costControllers[i],
                                decoration:
                                    InputDecoration(labelText: l10n.unitCost),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              OutlinedButton.icon(
                onPressed: _addLine,
                icon: const Icon(Icons.add),
                label: Text(l10n.addLine),
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
          onPressed: widget.suppliers.isEmpty ||
                  _supplierId == null ||
                  _branchId == null ||
                  _branchId!.isEmpty
              ? null
              : _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
