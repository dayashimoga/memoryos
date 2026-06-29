import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:memoryos/core/router/app_router.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/features/settings/bloc/settings_bloc.dart';

/// Root application widget with dynamic Material You color support.
class MemoryOSApp extends StatelessWidget {
  const MemoryOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settingsState) {
            return MaterialApp.router(
              title: 'MemoryOS',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme(dynamicScheme: lightDynamic),
              darkTheme: AppTheme.darkTheme(dynamicScheme: darkDynamic),
              themeMode: settingsState.themeMode,
              routerConfig: AppRouter.router,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('es'),
                Locale('fr'),
                Locale('de'),
                Locale('ja'),
                Locale('zh'),
              ],
            );
          },
        );
      },
    );
  }
}
