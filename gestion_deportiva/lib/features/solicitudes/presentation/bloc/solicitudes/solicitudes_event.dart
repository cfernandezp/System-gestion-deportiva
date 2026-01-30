import 'package:equatable/equatable.dart';

/// Eventos del Bloc de Solicitudes
/// E001-HU-006: Gestionar Solicitudes de Registro
abstract class SolicitudesEvent extends Equatable {
  const SolicitudesEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Cargar lista de solicitudes pendientes
/// CA-003: Lista con nombre, email, fecha registro, dias pendiente
/// CA-004: Ordenar por antiguedad (mas antiguas primero)
class CargarSolicitudesEvent extends SolicitudesEvent {
  const CargarSolicitudesEvent();
}

/// Evento: Aprobar una solicitud de usuario
/// CA-005: Aprobar con seleccion de rol (default "Jugador")
class AprobarSolicitudEvent extends SolicitudesEvent {
  final String usuarioId;
  final String nombreUsuario;
  final String rol;

  const AprobarSolicitudEvent({
    required this.usuarioId,
    required this.nombreUsuario,
    required this.rol,
  });

  @override
  List<Object?> get props => [usuarioId, nombreUsuario, rol];
}

/// Evento: Rechazar una solicitud de usuario
/// CA-006: Rechazar con motivo opcional
class RechazarSolicitudEvent extends SolicitudesEvent {
  final String usuarioId;
  final String nombreUsuario;
  final String? motivo;

  const RechazarSolicitudEvent({
    required this.usuarioId,
    required this.nombreUsuario,
    this.motivo,
  });

  @override
  List<Object?> get props => [usuarioId, nombreUsuario, motivo];
}

/// Evento: Limpiar mensaje de exito/error
class LimpiarMensajeSolicitudesEvent extends SolicitudesEvent {
  const LimpiarMensajeSolicitudesEvent();
}
