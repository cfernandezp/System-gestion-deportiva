import 'package:equatable/equatable.dart';

/// Eventos del Bloc de Recuperacion de Contrasena
/// HU-003: Recuperacion de Contrasena
abstract class RecuperacionEvent extends Equatable {
  const RecuperacionEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Solicitar recuperacion de contrasena
/// CA-001, CA-002, CA-003, RN-001
class SolicitarRecuperacionEvent extends RecuperacionEvent {
  final String email;

  const SolicitarRecuperacionEvent({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Evento: Validar token de recuperacion
/// CA-004, CA-005
class ValidarTokenEvent extends RecuperacionEvent {
  final String token;

  const ValidarTokenEvent({required this.token});

  @override
  List<Object?> get props => [token];
}

/// Evento: Restablecer contrasena con token
/// CA-006, RN-004, RN-005, RN-006
class RestablecerContrasenaEvent extends RecuperacionEvent {
  final String token;
  final String nuevaContrasena;
  final String confirmarContrasena;

  const RestablecerContrasenaEvent({
    required this.token,
    required this.nuevaContrasena,
    required this.confirmarContrasena,
  });

  @override
  List<Object?> get props => [token, nuevaContrasena, confirmarContrasena];
}

/// Evento: Resetear estado del bloc
class RecuperacionResetEvent extends RecuperacionEvent {
  const RecuperacionResetEvent();
}
