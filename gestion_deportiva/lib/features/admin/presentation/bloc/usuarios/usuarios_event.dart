import 'package:equatable/equatable.dart';

/// Eventos del Bloc de Usuarios
/// HU-005: Gestion de Roles
abstract class UsuariosEvent extends Equatable {
  const UsuariosEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Cargar lista de usuarios
/// CA-001: Lista de usuarios con rol actual
class CargarUsuariosEvent extends UsuariosEvent {
  const CargarUsuariosEvent();
}

/// Evento: Buscar usuarios por nombre o email
/// CA-005: Busqueda de usuarios
/// RN-007: Busqueda case-insensitive
class BuscarUsuariosEvent extends UsuariosEvent {
  final String query;

  const BuscarUsuariosEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Evento: Cambiar rol de un usuario
/// CA-002: Modificar rol
/// CA-003: Roles disponibles
/// CA-004: Restriccion de auto-modificacion
class CambiarRolEvent extends UsuariosEvent {
  final String usuarioId;
  final String nuevoRol;

  const CambiarRolEvent({
    required this.usuarioId,
    required this.nuevoRol,
  });

  @override
  List<Object?> get props => [usuarioId, nuevoRol];
}

/// Evento: Limpiar mensaje de exito/error
class LimpiarMensajeEvent extends UsuariosEvent {
  const LimpiarMensajeEvent();
}
