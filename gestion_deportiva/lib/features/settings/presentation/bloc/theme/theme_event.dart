import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

/// Carga la preferencia de tema guardada localmente
/// CA-001: Detectar preferencia del dispositivo al abrir por primera vez
/// CA-004: Persistencia de preferencia al reabrir la app
class LoadThemeEvent extends ThemeEvent {
  const LoadThemeEvent();
}

/// Cambia el tema de la app
/// CA-002: Cambio inmediato sin reiniciar
/// CA-003: Opciones: Sistema, Oscuro, Claro
class ChangeThemeEvent extends ThemeEvent {
  final ThemeMode themeMode;

  const ChangeThemeEvent(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}
