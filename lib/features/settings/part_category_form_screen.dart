import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/utils/category_key_slug.dart';
import '../../data/models/part_category_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/part_category_repository.dart';
import '../../di/injection.dart';
import '../shared/form_field_spacing.dart';
import '../shared/page_scaffold.dart';

class PartCategoryFormScreen extends StatefulWidget {
  const PartCategoryFormScreen({this.category, super.key});

  final PartCategoryModel? category;

  bool get isEdit => category != null;

  @override
  State<PartCategoryFormScreen> createState() => _PartCategoryFormScreenState();
}

class _PartCategoryFormScreenState extends State<PartCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _key;
  late final TextEditingController _sortOrder;
  late bool _isActive;
  bool _keyEdited = false;
  bool _saving = false;
  String? _keyError;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _name = TextEditingController(text: c?.name ?? '');
    _key = TextEditingController(text: c?.key ?? '');
    _sortOrder = TextEditingController(text: '${c?.sortOrder ?? 0}');
    _isActive = c?.isActive ?? true;
    _keyEdited = c != null;
  }

  @override
  void dispose() {
    _name.dispose();
    _key.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    if (!_keyEdited && !widget.isEdit) {
      _key.text = slugifyCategoryKey(value);
    }
    setState(() {
      _keyError = null;
      _nameError = null;
    });
  }

  void _applyValidationErrors(DioException e) {
    final data = e.response?.data;
    if (data is! Map || data['errors'] is! Map) return;
    final errors = Map<String, dynamic>.from(data['errors'] as Map);
    setState(() {
      _keyError = _firstError(errors['key']);
      _nameError = _firstError(errors['name']);
    });
  }

  String? _firstError(dynamic field) {
    if (field is List && field.isNotEmpty) return field.first.toString();
    if (field is String) return field;
    return null;
  }

  Future<void> _save() async {
    if (!context.read<ConnectivityCubit>().state.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.internetRequired)),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _keyError = null;
      _nameError = null;
    });

    final repo = getIt<PartCategoryRepository>();
    final key = _key.text.trim();
    final name = _name.text.trim();
    final sortOrder = int.tryParse(_sortOrder.text.trim()) ?? 0;

    try {
      if (widget.isEdit) {
        await repo.update(
          widget.category!.id,
          name: name,
          sortOrder: sortOrder,
          isActive: _isActive,
        );
      } else {
        await repo.create(
          key: key,
          name: name,
          sortOrder: sortOrder,
          isActive: _isActive,
        );
      }
      if (mounted) context.pop(true);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        _applyValidationErrors(e);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? e.toString())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deactivate() async {
    final l10n = context.l10n;
    final role =
        context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    if (!RolePermissions.canPerform(AppAction.partCategoryDeactivate, role)) {
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deactivateCategoryTitle),
        content: Text(l10n.deactivateCategoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deactivate),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await getIt<PartCategoryRepository>().deactivate(widget.category!.id);
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role =
        context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canDeactivate = widget.isEdit &&
        RolePermissions.canPerform(AppAction.partCategoryDeactivate, role);

    return PageScaffold(
      title: widget.isEdit ? l10n.editCategory : l10n.addCategory,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: l10n.categoryName,
                errorText: _nameError,
              ),
              onChanged: _onNameChanged,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: kFormFieldSpacing),
            TextFormField(
              controller: _key,
              enabled: !widget.isEdit,
              decoration: InputDecoration(
                labelText: l10n.categoryKey,
                errorText: _keyError,
                helperText: l10n.categoryKeyHint,
              ),
              onChanged: (_) {
                _keyEdited = true;
                setState(() => _keyError = null);
              },
              validator: (v) {
                final k = v?.trim() ?? '';
                if (k.isEmpty) return l10n.fieldRequired;
                if (!isValidCategoryKey(k)) return l10n.categoryKeyInvalid;
                return null;
              },
            ),
            const SizedBox(height: kFormFieldSpacing),
            TextFormField(
              controller: _sortOrder,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.sortOrder),
            ),
            if (widget.isEdit) ...[
              const SizedBox(height: kFormFieldSpacing),
              SwitchListTile(
                title: Text(l10n.categoryActive),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                if (canDeactivate) ...[
                  OutlinedButton(
                    onPressed: _saving ? null : _deactivate,
                    child: Text(l10n.deactivate),
                  ),
                  const SizedBox(width: 12),
                ],
                const Spacer(),
                TextButton(
                  onPressed: _saving ? null : () => context.pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
