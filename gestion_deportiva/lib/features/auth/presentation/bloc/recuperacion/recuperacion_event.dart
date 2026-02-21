import 'package:equatable/equatable.dart';

/// Eventos del Bloc de Recuperacion de Contrasena
/// E001-HU-007: Recuperacion de Contrasena (celular-based)
abstract class RecuperacionEvent extends Equatable {
  const RecuperacionEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Identificar tipo de recuperacion segun celular
/// Determina si es admin, jugador o no encontrado
class IdentificarTipoRecuperacionEvent extends RecuperacionEvent {
  final String celular;

  const IdentificarTipoRecuperacionEvent({required this.celular});

  @override
  List<Object?> get props => [celular];
}

/// Evento: Validar codigo de recuperacion (jugador o admin via email)
class ValidarCodigoEvent extends RecuperacionEvent {
  final String celular;
  final String codigo;

  const ValidarCodigoEvent({
    required this.celular,
    required this.codigo,
  });

  @override
  List<Object?> get props => [celular, codigo];
}

/// Evento: Restablecer contrasena usando codigo validado
class RestablecerConCodigoEvent extends RecuperacionEvent {
  final String celular;
  final String codigo;
  final String nuevaContrasena;
  final String confirmarContrasena;

  const RestablecerConCodigoEvent({
    required this.celular,
    required this.codigo,
    required this.nuevaContrasena,
    required this.confirmarContrasena,
  });

  @override
  List<Object?> get props => [celular, codigo, nuevaContrasena, confirmarContrasena];
}

/// Evento: Restablecer contrasena usando pregunta de seguridad (admin)
class RestablecerConPreguntaEvent extends RecuperacionEvent {
  final String celular;
  final String respuesta;
  final String nuevaContrasena;
  final String confirmarContrasena;

  const RestablecerConPreguntaEvent({
    required this.celular,
    required this.respuesta,
    required this.nuevaContrasena,
    required this.confirmarContrasena,
  });

  @override
  List<Object?> get props => [celular, respuesta, nuevaContrasena, confirmarContrasena];
}

/// Evento: Solicitar recuperacion via email de respaldo (admin)
class SolicitarEmailRecuperacionEvent extends RecuperacionEvent {
  final String celular;

  const SolicitarEmailRecuperacionEvent({required this.celular});

  @override
  List<Object?> get props => [celular];
}

/// Evento: Resetear estado del bloc (volver al inicio)
class RecuperacionResetEvent extends RecuperacionEvent {
  const RecuperacionResetEvent();
}
