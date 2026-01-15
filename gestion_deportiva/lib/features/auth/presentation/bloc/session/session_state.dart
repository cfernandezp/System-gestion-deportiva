import 'package:equatable/equatable.dart';

/// Estados del Bloc de Session
/// HU-004: Cierre de Sesion
abstract class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

/// Estado: Verificando sesion (inicial)
/// Se muestra mientras se verifica si hay sesion activa
class SessionLoading extends SessionState {
  const SessionLoading();
}

/// Estado: Usuario autenticado
/// HU-004: RN-001 - Opcion de cierre disponible mientras este autenticado
class SessionAuthenticated extends SessionState {
  final String usuarioId;
  final String nombreCompleto;
  final String email;
  final String rol;

  const SessionAuthenticated({
    required this.usuarioId,
    required this.nombreCompleto,
    required this.email,
    required this.rol,
  });

  @override
  List<Object?> get props => [usuarioId, nombreCompleto, email, rol];
}

/// Estado: Usuario no autenticado
/// HU-004: CA-002, CA-003, CA-004 - Post-logout estado
class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

/// Estado: Error durante cierre de sesion
class SessionError extends SessionState {
  final String message;

  const SessionError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Estado: Cerrando sesion (loading durante logout)
class SessionLoggingOut extends SessionState {
  const SessionLoggingOut();
}
