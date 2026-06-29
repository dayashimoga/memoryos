import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memoryos/features/settings/bloc/settings_bloc.dart';

/// Dependency injection / service locator.
class ServiceLocator {
  static final _blocs = <Type, dynamic>{};

  static Future<void> initialize() async {
    // Register BLoCs
    _blocs[SettingsBloc] = SettingsBloc();

    // TODO: Initialize Rust core engine via FFI
    // TODO: Open SQLite database
    // TODO: Start file monitor
  }

  static T get<T>() {
    final instance = _blocs[T];
    if (instance == null) {
      throw StateError('Service $T not registered. Call ServiceLocator.initialize() first.');
    }
    return instance as T;
  }

  /// Returns a list of BlocProvider for use in the widget tree.
  static List<BlocProvider> get providers => [
        BlocProvider<SettingsBloc>(create: (_) => get<SettingsBloc>()),
      ];
}
