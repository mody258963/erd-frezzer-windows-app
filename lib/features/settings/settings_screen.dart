import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/user_role.dart';
import '../../core/settings/settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local/app_database.dart';
import '../../di/injection.dart';
import '../../router/route_paths.dart';
import '../shared/page_scaffold.dart';
import 'widgets/business_capital_card.dart';
import 'widgets/owner_cash_out_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _apiUrl;
  bool _offlineCashOnly = false;
  bool _autoPrint = false;
  String _localeCode = 'ar';
  String? _lastSync;

  @override
  void initState() {
    super.initState();
    final settings = getIt<SettingsService>();
    _apiUrl = TextEditingController(text: settings.apiBaseUrl);
    _offlineCashOnly = settings.offlineCashOnly;
    _autoPrint = settings.autoPrintOnSale;
    _localeCode = settings.localeCode;
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    final v = await getIt<AppDatabase>().getMeta('last_catalog_sync');
    setState(() => _lastSync = v);
  }

  @override
  void dispose() {
    _apiUrl.dispose();
    super.dispose();
  }

  Future<void> _applyLocale(String code) async {
    await getIt<SettingsService>().setLocaleCode(code);
    setState(() => _localeCode = code);
    if (!mounted) return;
    context.findAncestorStateOfType<FrostPartsAppState>()?.setLocale(Locale(code));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role =
        context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canManageCategories =
        RolePermissions.canPerform(AppAction.partCategoryManage, role);
    final canManageUsers =
        RolePermissions.canPerform(AppAction.userManage, role);
    final canViewCapital =
        RolePermissions.canPerform(AppAction.capitalView, role);
    final canEditCapital =
        RolePermissions.canPerform(AppAction.capitalEdit, role);
    return PageScaffold(
      title: l10n.settingsTitle,
      subtitle: l10n.settingsSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canViewCapital) ...[
            BusinessCapitalCard(role: role),
            const SizedBox(height: 16),
          ],
          if (canEditCapital) ...[
            OwnerCashOutCard(role: role),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.language, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _localeCode,
                    decoration: InputDecoration(labelText: l10n.language),
                    items: [
                      DropdownMenuItem(value: 'ar', child: Text(l10n.languageArabic)),
                      DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
                    ],
                    onChanged: (v) {
                      if (v != null) _applyLocale(v);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.offlineCashOnly),
                  subtitle: Text(l10n.offlineCashOnlyHint),
                  value: _offlineCashOnly,
                  onChanged: (v) async {
                    await getIt<SettingsService>().setOfflineCashOnly(v);
                    setState(() => _offlineCashOnly = v);
                  },
                ),
                SwitchListTile(
                  title: Text(l10n.autoPrintOnSale),
                  value: _autoPrint,
                  onChanged: (v) async {
                    await getIt<SettingsService>().setAutoPrintOnSale(v);
                    setState(() => _autoPrint = v);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    child: Icon(
                      Icons.sync,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(l10n.lastCatalogSync),
                  subtitle: Text(_lastSync ?? l10n.never),
                ),
                if (canManageUsers)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryContainer,
                      child: Icon(
                        Icons.people_outline,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                    ),
                    title: Text(l10n.usersTitle),
                    subtitle: Text(l10n.usersSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(RoutePaths.settingsUsers),
                  ),
                if (canManageCategories)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryContainer,
                      child: Icon(
                        Icons.category_outlined,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                    ),
                    title: Text(l10n.partCategoriesTitle),
                    subtitle: Text(l10n.partCategoriesSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(RoutePaths.partCategories),
                  ),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.print)),
                  title: Text(l10n.printerSettings),
                  subtitle: Text(l10n.openPrinterSettings),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(RoutePaths.printerSettings),
                ),
              ],
            ),
          ),
        
        ],
      ),
    );
  }
}
