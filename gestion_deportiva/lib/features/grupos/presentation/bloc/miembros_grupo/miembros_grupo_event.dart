import 'package:equatable/equatable.dart';

/// Eventos del Bloc MiembrosGrupo
/// E002-HU-005: Ver Miembros del Grupo
abstract class MiembrosGrupoEvent extends Equatable {
  const MiembrosGrupoEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar miembros del grupo
class CargarMiembrosGrupoEvent extends MiembrosGrupoEvent {
  final String grupoId;

  const CargarMiembrosGrupoEvent({required this.grupoId});

  @override
  List<Object?> get props => [grupoId];
}

/// CA-003 / RN-004: Filtrar miembros por rol
/// rol = null -> quitar filtro (mostrar todos)
class FiltrarPorRolEvent extends MiembrosGrupoEvent {
  final String? rol;

  const FiltrarPorRolEvent({this.rol});

  @override
  List<Object?> get props => [rol];
}

/// CA-004 / RN-005: Buscar miembros por nombre
/// Busqueda parcial, case-insensitive, en tiempo real
class BuscarMiembroEvent extends MiembrosGrupoEvent {
  final String query;

  const BuscarMiembroEvent({required this.query});

  @override
  List<Object?> get props => [query];
}
