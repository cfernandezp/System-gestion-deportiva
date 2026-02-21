import 'package:equatable/equatable.dart';

import '../../../data/models/mi_grupo_model.dart';

/// Eventos del BLoC SeleccionGrupo
/// E001-HU-003: Seleccion de Grupo Post-Login
abstract class SeleccionGrupoEvent extends Equatable {
  const SeleccionGrupoEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar grupos del usuario para seleccion
/// CA-001: Mostrar lista de grupos
/// CA-003: Si tiene 1 solo grupo, auto-seleccionar (solo en login)
/// E002-HU-007: forzarSeleccion=true omite auto-skip (cambio de grupo)
class CargarGruposParaSeleccionEvent extends SeleccionGrupoEvent {
  final bool forzarSeleccion;

  const CargarGruposParaSeleccionEvent({this.forzarSeleccion = false});

  @override
  List<Object?> get props => [forzarSeleccion];
}

/// CA-002: Usuario selecciona un grupo de la lista
class GrupoSeleccionadoEvent extends SeleccionGrupoEvent {
  final MiGrupoModel grupo;

  const GrupoSeleccionadoEvent({required this.grupo});

  @override
  List<Object?> get props => [grupo];
}
