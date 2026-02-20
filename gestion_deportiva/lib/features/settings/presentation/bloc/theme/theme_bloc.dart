import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/theme_repository.dart';
import 'theme_event.dart';
import 'theme_state.dart';

/// BLoC para gestionar el tema de la aplicacion
/// CA-001: Detectar preferencia del SO al abrir
/// CA-002: Cambio inmediato sin reinicio
/// CA-004: Persistencia local
/// RN-001: ThemeMode.system como default
/// RN-002: Tres opciones (Sistema, Oscuro, Claro)
/// RN-003: Persistencia local via SharedPreferences
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeRepository repository;

  ThemeBloc({required this.repository}) : super(const ThemeState()) {
    on<LoadThemeEvent>(_onLoadTheme);
    on<ChangeThemeEvent>(_onChangeTheme);
  }

  Future<void> _onLoadTheme(
    LoadThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    final themeMode = await repository.getThemeMode();
    emit(state.copyWith(themeMode: themeMode));
  }

  Future<void> _onChangeTheme(
    ChangeThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    emit(state.copyWith(themeMode: event.themeMode));
    await repository.saveThemeMode(event.themeMode);
  }
}
