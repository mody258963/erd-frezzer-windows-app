import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/auth/auth_cubit.dart';
import 'core/connectivity/connectivity_cubit.dart';
import 'core/l10n/l10n_extension.dart';
import 'core/settings/settings_service.dart';
import 'core/theme/app_theme.dart';
import 'di/injection.dart';
import 'features/sync/sync_bloc.dart';
import 'router/app_router.dart';

class FrostPartsApp extends StatefulWidget {
  const FrostPartsApp({super.key});

  @override
  State<FrostPartsApp> createState() => FrostPartsAppState();
}

class FrostPartsAppState extends State<FrostPartsApp> {
  late final _router = createAppRouter();
  late Locale _locale = getIt<SettingsService>().locale;

  Locale get currentLocale => _locale;

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  void initState() {
    super.initState();
    getIt<ConnectivityCubit>().onBecameOnline = () {
      getIt<SyncBloc>().add(const SyncEvent());
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<AuthCubit>()),
        BlocProvider.value(value: getIt<ConnectivityCubit>()),
        BlocProvider.value(value: getIt<SyncBloc>()),
      ],
      child: MaterialApp.router(
        title: 'نور الإسلام',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(locale: _locale),
        locale: _locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supported) {
          if (locale != null) {
            for (final s in supported) {
              if (s.languageCode == locale.languageCode) return s;
            }
          }
          return const Locale('ar');
        },
        builder: (context, child) {
          final isRtl = _locale.languageCode == 'ar';
          return Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          );
        },
        routerConfig: _router,
      ),
    );
  }
}
