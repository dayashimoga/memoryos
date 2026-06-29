import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:memoryos/core/router/app_router.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/di/service_locator.dart';
import 'package:memoryos/features/settings/bloc/settings_bloc.dart';

/// Root application widget.
class MemoryOSApp extends StatelessWidget {
  const MemoryOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: ServiceLocator.providers,
      child: DynamicColorBuilder(
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
                shortcuts: {
                  // ⌘K / Ctrl+K — command palette
                  LogicalKeySet(
                          LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK):
                      _CommandPaletteIntent(),
                  LogicalKeySet(
                          LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
                      _CommandPaletteIntent(),
                },
                actions: {
                  _CommandPaletteIntent: CallbackAction<_CommandPaletteIntent>(
                    onInvoke: (_) {
                      // Navigate to search — the shell intercepts ⌘K
                      AppRouter.router.go('/search');
                      return null;
                    },
                  ),
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _CommandPaletteIntent extends Intent {}
