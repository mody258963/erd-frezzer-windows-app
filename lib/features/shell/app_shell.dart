import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/auth_state.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/branch/branch_filter_cubit.dart';
import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/connectivity/connectivity_state.dart';
import '../../core/layout/app_breakpoints.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
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
            return LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                final narrow = AppBreakpoints.isNarrow(size);
                return Scaffold(
                  body: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBar(
                        isOnline: conn.isOnline,
                        user: user,
                        narrow: narrow,
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
                              onPressed: () => ScaffoldMessenger.of(
                                context,
                              ).hideCurrentMaterialBanner(),
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
                              narrow: narrow,
                            ),
                            const VerticalDivider(width: 1, thickness: 1),
                            Expanded(
                              child: ColoredBox(
                                color: AppColors.surface,
                                child: ShellContentPanel(
                                  padding: EdgeInsets.all(narrow ? 8 : 16),
                                  child: child,
                                ),
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
      },
    );
  }
}

class _NavRail extends StatelessWidget {
  const _NavRail({
    required this.destinations,
    required this.location,
    this.narrow = false,
  });

  static const double _width = 272;
  static const double _narrowWidth = 72;

  final List<NavDestination> destinations;
  final String location;
  final bool narrow;

  int _selectedIndex() {
    if (location.startsWith(RoutePaths.settings)) {
      final i = destinations.indexWhere((d) => d.routeKey == 'settings');
      if (i >= 0) return i;
    }
    for (var i = 0; i < destinations.length; i++) {
      final path = destinations[i].path;
      if (location == path || location.startsWith('$path/')) return i;
      if (destinations[i].routeKey == 'customers' &&
          location.startsWith(RoutePaths.invoices)) {
        return i;
      }
      if (destinations[i].routeKey == 'branches' &&
          (location.startsWith(RoutePaths.transfers) ||
              location.startsWith(RoutePaths.branchFinance))) {
        return i;
      }
      if (destinations[i].routeKey == 'parts' &&
          location.startsWith(RoutePaths.inventory)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = _selectedIndex();
    final theme = Theme.of(context);
    return SizedBox(
      width: narrow ? _narrowWidth : _width,
      child: Material(
        color: AppColors.navRailBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (narrow)
              const SizedBox(height: 8)
            else
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
            if (!narrow)
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.navRailForeground.withValues(alpha: 0.2),
              ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsetsDirectional.symmetric(
                  vertical: narrow ? 8 : 12,
                  horizontal: narrow ? 8 : 12,
                ),
                itemCount: destinations.length,
                separatorBuilder: (_, __) => SizedBox(height: narrow ? 2 : 4),
                itemBuilder: (context, i) {
                  final d = destinations[i];
                  return _NavItem(
                    label: navLabel(context, d.labelKey),
                    icon: IconData(d.icon, fontFamily: 'MaterialIcons'),
                    selected: i == selected,
                    narrow: narrow,
                    onTap: () => context.go(d.path),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                narrow ? 8 : 12,
                8,
                narrow ? 8 : 12,
                narrow ? 12 : 20,
              ),
              child: narrow
                  ? Tooltip(
                      message: l10n.logout,
                      child: IconButton(
                        onPressed: () async {
                          await context.read<AuthCubit>().signOut();
                          if (context.mounted) context.go(RoutePaths.login);
                        },
                        icon: const Icon(Icons.logout),
                        color: AppColors.navRailForeground,
                      ),
                    )
                  : TextButton(
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
    this.icon,
    this.narrow = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final bool narrow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (narrow && icon != null) {
      return Tooltip(
        message: label,
        child: Material(
          color: selected
              ? AppColors.navRailIndicator.withValues(alpha: 0.35)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 44,
              child: Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: selected
                      ? AppColors.navRailSelected
                      : AppColors.navRailForeground,
                ),
              ),
            ),
          ),
        ),
      );
    }

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

class _TopBar extends StatefulWidget {
  const _TopBar({
    required this.isOnline,
    required this.user,
    this.narrow = false,
    this.onSync,
  });

  final bool isOnline;
  final UserModel user;
  final bool narrow;
  final VoidCallback? onSync;

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  @override
  void initState() {
    super.initState();
    if (widget.user.canSelectBranch) {
      context.read<BranchFilterCubit>().loadBranches();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = widget.user;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.narrow ? 12 : 20,
        vertical: widget.narrow ? 6 : 10,
      ),
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
                    AppLogo(size: widget.narrow ? 32 : 44),
                    if (!widget.narrow) ...[
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
                  ],
                ),
                StatusChip(
                  label: widget.isOnline ? l10n.online : l10n.offline,
                  variant: widget.isOnline
                      ? StatusChipVariant.success
                      : StatusChipVariant.warning,
                ),
                if (!widget.narrow && user.canSelectBranch)
                  const _AdminBranchFilter()
                else if (!widget.narrow &&
                    user.branchName != null &&
                    user.branchName!.isNotEmpty)
                  _InfoChip(
                    icon: Icons.store,
                    label: '${l10n.branch}: ${user.branchName}',
                  ),
                if (!widget.narrow)
                  _InfoChip(
                    icon: Icons.person,
                    label: '${user.name} · ${user.role.name}',
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: Directionality.of(context),
            children: [
              if (widget.onSync != null)
                widget.narrow
                    ? IconButton(
                        tooltip: l10n.sync,
                        onPressed: widget.onSync,
                        icon: const Icon(Icons.sync, size: 20),
                        color: AppColors.onPrimary,
                      )
                    : FilledButton.tonalIcon(
                        onPressed: widget.onSync,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.onPrimary.withValues(
                            alpha: 0.15,
                          ),
                          foregroundColor: AppColors.onPrimary,
                        ),
                        icon: const Icon(Icons.sync, size: 18),
                        label: Text(l10n.sync),
                      ),
              if (widget.onSync != null && !widget.narrow)
                const SizedBox(width: 8),
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

class _AdminBranchFilter extends StatelessWidget {
  const _AdminBranchFilter();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<BranchFilterCubit, BranchFilterState>(
      builder: (context, filter) {
        if (filter.isFiltered) {
          final selectedName = filter.branchNameFor(filter.selectedBranchId);
          return InputChip(
            avatar: const Icon(Icons.filter_alt, size: 16),
            label: Text(
              selectedName != null
                  ? '${l10n.branchFilterLabel}: $selectedName'
                  : l10n.branchFilterLabel,
            ),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => context.read<BranchFilterCubit>().clearFilter(),
            labelStyle: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.onPrimary),
            backgroundColor: AppColors.onPrimary.withValues(alpha: 0.12),
            deleteIconColor: AppColors.onPrimary,
            side: BorderSide.none,
          );
        }

        final dropdownValue =
            filter.selectedBranchId != null &&
                filter.branches.any((b) => b.id == filter.selectedBranchId)
            ? filter.selectedBranchId
            : null;

        return Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.onPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: dropdownValue,
              isDense: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: AppColors.onPrimary.withValues(alpha: 0.9),
              ),
              dropdownColor: AppColors.primary,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.onPrimary),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.branchFilterAll),
                ),
                for (final b in filter.branches)
                  DropdownMenuItem<String?>(
                    value: b.id,
                    child: Text(b.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: filter.loading
                  ? null
                  : (id) => context.read<BranchFilterCubit>().selectBranch(id),
            ),
          ),
        );
      },
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
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: Directionality.of(context),
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.onPrimary.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            textAlign: TextAlign.start,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.onPrimary),
          ),
        ],
      ),
    );
  }
}
