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

/// E002-HU-006 CA-001: Eliminar jugador del grupo
class EliminarJugadorEvent extends MiembrosGrupoEvent {
  final String grupoId;
  final String miembroId;
  final String nombreJugador;

  const EliminarJugadorEvent({
    required this.grupoId,
    required this.miembroId,
    required this.nombreJugador,
  });

  @override
  List<Object?> get props => [grupoId, miembroId, nombreJugador];
}

/// E002-HU-004 CA-001: Promover jugador a co-admin
class PromoverACoadminEvent extends MiembrosGrupoEvent {
  final String grupoId;
  final String miembroId;
  final String nombreJugador;

  const PromoverACoadminEvent({
    required this.grupoId,
    required this.miembroId,
    required this.nombreJugador,
  });

  @override
  List<Object?> get props => [grupoId, miembroId, nombreJugador];
}

/// E002-HU-004 CA-002: Degradar co-admin a jugador
class DegradarCoadminEvent extends MiembrosGrupoEvent {
  final String grupoId;
  final String miembroId;
  final String nombreJugador;

  const DegradarCoadminEvent({
    required this.grupoId,
    required this.miembroId,
    required this.nombreJugador,
  });

  @override
  List<Object?> get props => [grupoId, miembroId, nombreJugador];
}

/// E002-HU-008: Eliminar invitado del grupo
class EliminarInvitadoEvent extends MiembrosGrupoEvent {
  final String grupoId;
  final String miembroId;
  final String nombreInvitado;

  const EliminarInvitadoEvent({
    required this.grupoId,
    required this.miembroId,
    required this.nombreInvitado,
  });

  @override
  List<Object?> get props => [grupoId, miembroId, nombreInvitado];
}
