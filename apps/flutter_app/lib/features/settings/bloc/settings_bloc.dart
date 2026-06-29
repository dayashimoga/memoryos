import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class SettingsThemeChanged extends SettingsEvent {
  final ThemeMode themeMode;
  const SettingsThemeChanged(this.themeMode);
  @override
  List<Object?> get props => [themeMode];
}

class SettingsLanguageChanged extends SettingsEvent {
  final String languageCode;
  const SettingsLanguageChanged(this.languageCode);
  @override
  List<Object?> get props => [languageCode];
}

// State
class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final String languageCode;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.languageCode = 'en',
  });

  SettingsState copyWith({ThemeMode? themeMode, String? languageCode}) => SettingsState(
        themeMode: themeMode ?? this.themeMode,
        languageCode: languageCode ?? this.languageCode,
      );

  @override
  List<Object?> get props => [themeMode, languageCode];
}

// Bloc
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<SettingsThemeChanged>((event, emit) {
      emit(state.copyWith(themeMode: event.themeMode));
    });
    on<SettingsLanguageChanged>((event, emit) {
      emit(state.copyWith(languageCode: event.languageCode));
    });
  }
}
