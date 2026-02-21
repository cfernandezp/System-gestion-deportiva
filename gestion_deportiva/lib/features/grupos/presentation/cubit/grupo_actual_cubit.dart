import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/mi_grupo_model.dart';

/// E001-HU-003: Estado global del grupo actualmente seleccionado
/// Singleton: mantiene el grupo activo durante toda la sesion
/// CA-002: Al seleccionar grupo, se establece aqui
/// CA-003: Auto-skip con 1 solo grupo
/// CA-005: Cambiar de grupo reemplaza el valor
/// E002-HU-007: Tracking de total de grupos para swap condicional
class GrupoActualCubit extends Cubit<MiGrupoModel?> {
  GrupoActualCubit() : super(null);

  /// E002-HU-007 RN-005: Total de grupos del usuario
  int _totalGrupos = 0;

  /// CA-002: Seleccionar un grupo como activo
  void seleccionarGrupo(MiGrupoModel grupo) {
    emit(grupo);
  }

  /// E002-HU-007: Establecer total de grupos del usuario
  void setTotalGrupos(int total) {
    _totalGrupos = total;
  }

  /// Limpiar seleccion (logout, etc.)
  void limpiarGrupo() {
    _totalGrupos = 0;
    emit(null);
  }

  /// Grupo actualmente seleccionado
  MiGrupoModel? get grupoActual => state;

  /// Si hay un grupo seleccionado
  bool get tieneGrupoSeleccionado => state != null;

  /// E002-HU-007 RN-005: Si tiene multiples grupos (para mostrar swap button)
  bool get tieneMultiplesGrupos => _totalGrupos > 1;
}
