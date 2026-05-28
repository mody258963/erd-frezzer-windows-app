import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/auth_state.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/connectivity/connectivity_state.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_role.dart';
import '../../di/injection.dart';
import '../../router/route_paths.dart';
import '../shared/app_logo.dart';
import '../shared/shell_content_panel.dart';
import '../shared/status_chip.dart';
import '../sync/sync_bloc.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        final user = auth.user;
        if (user == null) return const SizedBox.shrink();

        return BlocBuilder<ConnectivityCubit, ConnectivityState>(
          builder: (context, conn) {
            final destinations = RolePermissions.visibleDestinations(
              user.role,
              conn.isOnline,
            );
            final location = GoRouterState.of(context).uri.path;
            final l10n = context.l10n;
            return Scaffold(
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(
                    isOnline: conn.isOnline,
                    userName: user.name,
                    role: user.role,
                    branchName: user.branchName ?? '—',
                    onSync: conn.isOnline
                        ? () => getIt<SyncBloc>().add(const SyncEvent())
                        : null,
                  ),
                  if (!conn.isOnline)
                    MaterialBanner(
                      content: Text(l10n.offlineBanner),
                      leading: const Icon(Icons.cloud_off),
                      actions: [
                        TextButton(
                          onPressed: () => ScaffoldMessenger.of(context)
                              .hideCurrentMaterialBanner(),
                          child: Text(l10n.dismiss),
                        ),
                      ],
                    ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      textDirection: Directionality.of(context),
                      children: [
                        _NavRail(
                          destinations: destinations,
                          location: location,
                        ),
                        const VerticalDivider(width: 1, thickness: 1),
                        Expanded(
                          child: ColoredBox(
                            color: AppColors.surface,
                            child: ShellContentPanel(child: child),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _NavRail extends StatelessWidget {
  const _NavRail({
    required this.destinations,
    required this.location,
  });

  static const double _width = 272;

  final List<NavDestination> destinations;
  final String location;

  int _selectedIndex() {
    if (location.startsWith(RoutePaths.settings)) {
      final i = destinations.indexWhere((d) => d.routeKey == 'settings');
      if (i >= 0) return i;
    }
    for (var i = 0; i < destinations.length; i++) {
      final path = destinations[i].path;
      if (location == path || location.startsWith('$path/')) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = _selectedIndex();
    final theme = Theme.of(context);
    return SizedBox(
      width: _width,
      child: Material(
        color: AppColors.navRailBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: AppLogo(size: 88)),
                  const SizedBox(height: 12),
                  Text(
                    l10n.appTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.navRailSelected,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.navRailForeground.withValues(alpha: 0.2),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsetsDirectional.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                itemCount: destinations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final d = destinations[i];
                  return _NavItem(
                    label: navLabel(context, d.labelKey),
                    selected: i == selected,
                    onTap: () => context.go(d.path),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 20),
              child: TextButton(
                onPressed: () async {
                  await context.read<AuthCubit>().signOut();
                  if (context.mounted) context.go(RoutePaths.login);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.navRailForeground,
                  padding: const EdgeInsetsDirectional.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  alignment: AlignmentDirectional.centerStart,
                ),
                child: Text(
                  l10n.logout,
                  textAlign: TextAlign.start,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navRailForeground,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? AppColors.navRailIndicator.withValues(alpha: 0.35)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              label,
              textAlign: TextAlign.start,
              style: theme.textTheme.titleSmall?.copyWith(
                color: selected
                    ? AppColors.navRailSelected
                    : AppColors.navRailForeground,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 16,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isOnline,
    required this.userName,
    required this.role,
    required this.branchName,
    this.onSync,
  });

  final bool isOnline;
  final String userName;
  final UserRole role;
  final String branchName;
  final VoidCallback? onSync;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        textDirection: Directionality.of(context),
        children: [
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              textDirection: Directionality.of(context),
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: Directionality.of(context),
                  children: [
                    const AppLogo(size: 44),
                    const SizedBox(width: 12),
                    Text(
                      l10n.appTitle,
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                StatusChip(
                  label: isOnline ? l10n.online : l10n.offline,
                  variant: isOnline
                      ? StatusChipVariant.success
                      : StatusChipVariant.warning,
                ),
                _InfoChip(icon: Icons.store, label: branchName),
                _InfoChip(icon: Icons.person, label: '$userName · ${role.name}'),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: Directionality.of(context),
            children: [
              if (onSync != null)
                FilledButton.tonalIcon(
                  onPressed: onSync,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.onPrimary.withValues(alpha: 0.15),
                    foregroundColor: AppColors.onPrimary,
                  ),
                  icon: const Icon(Icons.sync, size: 18),
                  label: Text(l10n.sync),
                ),
              if (onSync != null) const SizedBox(width: 8),
              IconButton(
                tooltip: l10n.settingsTitle,
                onPressed: () => context.go(RoutePaths.settings),
                icon: const Icon(
                  Icons.settings_outlined,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: Directionality.of(context),
        children: [
          Icon(icon, size: 14, color: AppColors.onPrimary.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Text(
            label,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onPrimary,
                ),
          ),
        ],
      ),
    );
  }
}
