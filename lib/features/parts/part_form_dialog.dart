import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/api/dio_client.dart';
import '../../core/utils/part_image_validation.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/part_category_model.dart';
import '../../data/repositories/part_category_repository.dart';
import '../../di/injection.dart';
import '../shared/form_field_spacing.dart';
import '../shared/image_lightbox.dart';
import '../shared/loading_error.dart';
import '../shared/part_network_image.dart';

/// Result of the part create/edit dialog.
class PartFormResult {
  const PartFormResult({
    required this.code,
    required this.name,
    required this.categoryKey,
    required this.unit,
    required this.sellPrice,
    required this.costPrice,
    required this.minStock,
    this.initialQuantity = 0,
    this.isActive = true,
    this.pendingImagePath,
    this.removeImage = false,
  });

  final String code;
  final String name;
  final String categoryKey;
  final String unit;
  final double sellPrice;
  final double costPrice;
  final int minStock;
  final int initialQuantity;
  final bool isActive;
  final String? pendingImagePath;
  final bool removeImage;
}

class PartFormDialog extends StatefulWidget {
  const PartFormDialog({
    super.key,
    this.initialCode,
    this.initialName,
    this.initialCategoryKey,
    this.initialUnit,
    this.initialSellPrice,
    this.initialCostPrice,
    this.initialMinStock,
    this.initialImageUrl,
    this.isEdit = false,
    this.branchLabel,
  });

  final String? initialCode;
  final String? initialName;
  final String? initialCategoryKey;
  final String? initialUnit;
  final double? initialSellPrice;
  final double? initialCostPrice;
  final int? initialMinStock;
  final String? initialImageUrl;
  final bool isEdit;
  final String? branchLabel;

  @override
  State<PartFormDialog> createState() => _PartFormDialogState();
}

class _PartFormDialogState extends State<PartFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _sell;
  late final TextEditingController _cost;
  late final TextEditingController _minStock;
  late final TextEditingController _openingQty;

  List<PartCategoryModel> _categories = [];
  List<PartUnitOption> _units = [];
  String? _categoryKey;
  String? _unit;
  bool _loadingMeta = true;
  String? _metaError;
  String? _pendingImagePath;
  bool _removeImage = false;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.initialCode ?? '');
    _name = TextEditingController(text: widget.initialName ?? '');
    _sell = TextEditingController(text: '${widget.initialSellPrice ?? 0}');
    _cost = TextEditingController(text: '${widget.initialCostPrice ?? 0}');
    _minStock = TextEditingController(text: '${widget.initialMinStock ?? 0}');
    _openingQty = TextEditingController(text: '0');
    _categoryKey = widget.initialCategoryKey;
    _unit = widget.initialUnit;
    _loadMeta();
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _sell.dispose();
    _cost.dispose();
    _minStock.dispose();
    _openingQty.dispose();
    super.dispose();
  }

  PartCategoryRepository _categoryRepo() {
    if (getIt.isRegistered<PartCategoryRepository>()) {
      return getIt<PartCategoryRepository>();
    }
    return PartCategoryRepository(getIt<DioClient>().dio);
  }

  Future<void> _loadMeta() async {
    setState(() {
      _loadingMeta = true;
      _metaError = null;
    });
    try {
      final repo = _categoryRepo();
      final categories = await repo.list();
      final units = await repo.listUnits();

      String? catKey = _categoryKey;
      if (catKey == null || catKey.isEmpty) {
        catKey = categories.isNotEmpty ? categories.first.key : null;
      } else if (!categories.any((c) => c.key == catKey)) {
        catKey = categories.isNotEmpty ? categories.first.key : catKey;
      }

      String? unitVal = _unit;
      if (unitVal == null ||
          unitVal.isEmpty ||
          !units.any((u) => u.value == unitVal)) {
        unitVal = units.any((u) => u.value == 'pc')
            ? 'pc'
            : (units.isNotEmpty ? units.first.value : null);
      }

      setState(() {
        _categories = categories;
        _units = units;
        _categoryKey = catKey;
        _unit = unitVal;
        _loadingMeta = false;
      });
    } catch (e) {
      setState(() {
        _metaError = e.toString();
        _loadingMeta = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final l10n = context.l10n;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    final err = validatePartImagePath(path);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            err == 'too_large' ? l10n.partImageTooLarge : l10n.partImageInvalidType,
          ),
        ),
      );
      return;
    }
    setState(() {
      _pendingImagePath = path;
      _removeImage = false;
    });
  }

  void _removeExistingImage() {
    setState(() {
      _pendingImagePath = null;
      _removeImage = true;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryKey == null || _unit == null) return;

    Navigator.pop(
      context,
      PartFormResult(
        code: _code.text.trim(),
        name: _name.text.trim(),
        categoryKey: _categoryKey!,
        unit: _unit!,
        sellPrice: double.tryParse(_sell.text.trim()) ?? 0,
        costPrice: double.tryParse(_cost.text.trim()) ?? 0,
        minStock: int.tryParse(_minStock.text.trim()) ?? 0,
        initialQuantity: int.tryParse(_openingQty.text.trim()) ?? 0,
        pendingImagePath: _pendingImagePath,
        removeImage: _removeImage,
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final l10n = context.l10n;
    final hasNetwork = !_removeImage &&
        _pendingImagePath == null &&
        widget.initialImageUrl != null &&
        widget.initialImageUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.partImage, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 72,
                child: _pendingImagePath != null
                    ? LightboxTapTarget(
                        onTap: () => showImageLightbox(
                          context,
                          file: File(_pendingImagePath!),
                        ),
                        child: Image.file(
                          File(_pendingImagePath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : hasNetwork
                        ? PartNetworkImage(
                            imageUrl: widget.initialImageUrl,
                            width: 72,
                            height: 72,
                            circular: false,
                            placeholderIcon: Icons.image_outlined,
                          )
                        : const ColoredBox(
                            color: Color(0xFFE0E0E0),
                            child: Icon(Icons.image_outlined, size: 40),
                          ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text(l10n.choosePartImage),
                ),
                if (hasNetwork || _pendingImagePath != null)
                  TextButton(
                    onPressed: _removeExistingImage,
                    child: Text(l10n.removePartImage),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.isEdit ? l10n.editPart : l10n.newPart),
      titlePadding: kDialogTitlePadding,
      contentPadding: kDialogContentPadding,
      actionsPadding: kDialogActionsPadding,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      content: SizedBox(
        width: 460,
        child: _loadingMeta
            ? const SizedBox(
                height: 200,
                child: LoadingView(),
              )
            : _metaError != null
                ? _DialogMetaError(
                    message: _metaError!,
                    onRetry: _loadMeta,
                  )
                : _categories.isEmpty || _units.isEmpty
                    ? SizedBox(
                        height: 120,
                        child: Center(child: Text(l10n.failedLoadPartMeta)),
                      )
                    : Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: spacedFormFields([
                              if (!widget.isEdit &&
                                  widget.branchLabel != null &&
                                  widget.branchLabel!.isNotEmpty)
                                InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: l10n.branch,
                                  ),
                                  child: Text(widget.branchLabel!),
                                ),
                              _buildImageSection(context),
                              TextFormField(
                                controller: _code,
                                decoration:
                                    InputDecoration(labelText: l10n.code),
                                textDirection: TextDirection.ltr,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? l10n.fieldRequired
                                    : null,
                              ),
                              TextFormField(
                                controller: _name,
                                decoration:
                                    InputDecoration(labelText: l10n.name),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? l10n.fieldRequired
                                    : null,
                              ),
                              DropdownButtonFormField<String>(
                                initialValue: _categories
                                        .any((c) => c.key == _categoryKey)
                                    ? _categoryKey
                                    : _categories.first.key,
                                decoration: InputDecoration(
                                  labelText: l10n.selectCategory,
                                ),
                                isExpanded: true,
                                items: [
                                  for (final c in _categories)
                                    DropdownMenuItem(
                                      value: c.key,
                                      child: Text(c.name),
                                    ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _categoryKey = v),
                                validator: (v) =>
                                    v == null ? l10n.fieldRequired : null,
                              ),
                              DropdownButtonFormField<String>(
                                initialValue: _units.any((u) => u.value == _unit)
                                    ? _unit
                                    : _units.first.value,
                                decoration: InputDecoration(
                                  labelText: l10n.selectUnit,
                                ),
                                isExpanded: true,
                                items: [
                                  for (final u in _units)
                                    DropdownMenuItem(
                                      value: u.value,
                                      child: Text(
                                        localizePartUnitLabel(
                                          context,
                                          u.value,
                                          u.label,
                                        ),
                                      ),
                                    ),
                                ],
                                onChanged: (v) => setState(() => _unit = v),
                                validator: (v) =>
                                    v == null ? l10n.fieldRequired : null,
                              ),
                              TextFormField(
                                controller: _sell,
                                decoration: InputDecoration(
                                  labelText: l10n.sellPrice,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                textDirection: TextDirection.ltr,
                              ),
                              if (widget.isEdit)
                                InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: l10n.catalogCostRollup,
                                    helperText: l10n.catalogCostRollupHint,
                                  ),
                                  child: Text(
                                    formatMoney(
                                      context,
                                      widget.initialCostPrice ?? 0,
                                    ),
                                    textDirection: TextDirection.ltr,
                                  ),
                                )
                              else
                                TextFormField(
                                  controller: _cost,
                                  decoration: InputDecoration(
                                    labelText: l10n.costPrice,
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  textDirection: TextDirection.ltr,
                                ),
                              TextFormField(
                                controller: _minStock,
                                decoration: InputDecoration(
                                  labelText: l10n.minStock,
                                ),
                                keyboardType: TextInputType.number,
                                textDirection: TextDirection.ltr,
                              ),
                              if (!widget.isEdit)
                                TextFormField(
                                  controller: _openingQty,
                                  decoration: InputDecoration(
                                    labelText: l10n.openingQuantity,
                                  ),
                                  keyboardType: TextInputType.number,
                                  textDirection: TextDirection.ltr,
                                ),
                            ]),
                          ),
                        ),
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _loadingMeta ||
                  _metaError != null ||
                  _categories.isEmpty ||
                  _units.isEmpty
              ? null
              : _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Compact error for inside [AlertDialog] (avoids [ErrorView] overflow).
class _DialogMetaError extends StatelessWidget {
  const _DialogMetaError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.failedLoadPartMeta,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }
}
