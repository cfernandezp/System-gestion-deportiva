import 'package:equatable/equatable.dart';

/// Eventos del Bloc de Session
/// HU-004: Cierre de Sesion
abstract class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Verificar si hay una sesion activa
/// Se dispara al iniciar la app para determinar estado de autenticacion
class CheckSessionEvent extends SessionEvent {
  const CheckSessionEvent();
}

/// Evento: Cerrar sesion del usuario
/// HU-004: CA-002 - Cierre de sesion exitoso
class LogoutEvent extends SessionEvent {
  const LogoutEvent();
}

/// Evento: Marcar sesion como autenticada despues de login exitoso
class SessionAuthenticatedEvent extends SessionEvent {
  final String usuarioId;
  final String nombreCompleto;
  final String email;
  final String rol;

  const SessionAuthenticatedEvent({
    required this.usuarioId,
    required this.nombreCompleto,
    required this.email,
    required this.rol,
  });

  @override
  List<Object?> get props => [usuarioId, nombreCompleto, email, rol];
}
