import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/login_bloc.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/catalog/catalog_branch.dart';
import '../../di/injection.dart';
import '../../core/catalog/catalog_refresh_scheduler.dart';
import '../../data/repositories/catalog_sync_repository.dart';
import '../../di/injection.dart';
import '../../router/route_paths.dart';
import '../shared/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(getIt(), getIt<AuthCubit>()),
      child: Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLogo(size: 120),
                        const SizedBox(height: 24),
                        Text(
                          context.l10n.appTitle,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.appSubtitle,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xCCFFFFFF),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          context.l10n.appTagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Color(0xB3FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: ColoredBox(
                color: AppColors.surfaceContainerHighest,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: BlocConsumer<LoginBloc, LoginState>(
                        listener: (context, state) async {
                          if (state.status == LoginStatus.success) {
                            final user = getIt<AuthCubit>().state.user;
                            final branchId = await resolveCatalogBranchId(user);
                            if (branchId != null) {
                              try {
                                await getIt<CatalogSyncRepository>()
                                    .refresh(branchId);
                              } catch (_) {}
                            }
                            getIt<CatalogRefreshScheduler>().start();
                            if (context.mounted) {
                              context.go(RoutePaths.dashboard);
                            }
                          }
                        },
                        builder: (context, state) {
                          final l10n = context.l10n;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.welcomeBack,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.signInToContinue,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 32),
                              TextField(
                                controller: _email,
                                decoration: InputDecoration(
                                  labelText: l10n.email,
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _password,
                                decoration: InputDecoration(
                                  labelText: l10n.password,
                                  prefixIcon:
                                      const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscure = !_obscure,
                                    ),
                                  ),
                                ),
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) {
                                  if (state.status != LoginStatus.loading) {
                                    _submit(context);
                                  }
                                },
                              ),
                              if (state.errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorContainer,
                                    borderRadius: BorderRadius.circular(
                                      AppColors.inputRadius,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        size: 20,
                                        color: AppColors.onErrorContainer,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          state.errorMessage!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors
                                                    .onErrorContainer,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 28),
                              FilledButton(
                                onPressed:
                                    state.status == LoginStatus.loading
                                        ? null
                                        : () => _submit(context),
                                child: state.status == LoginStatus.loading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.onPrimary,
                                        ),
                                      )
                                    : Text(l10n.signIn),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    context.read<LoginBloc>().add(
          LoginEvent(_email.text, _password.text),
        );
  }
}
