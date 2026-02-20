import 'package:flutter/material.dart';

/// Contrato para el repositorio de tema
/// RN-003: Persistencia local de preferencia de tema
abstract class ThemeRepository {
  /// Obtiene el ThemeMode guardado localmente
  /// Retorna ThemeMode.system si no hay preferencia guardada (RN-001)
  Future<ThemeMode> getThemeMode();

  /// Guarda la preferencia de tema localmente (RN-003)
  Future<void> saveThemeMode(ThemeMode mode);
}
