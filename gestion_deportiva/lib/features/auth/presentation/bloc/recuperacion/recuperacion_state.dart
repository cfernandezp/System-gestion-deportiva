import 'package:equatable/equatable.dart';

/// Estados del Bloc de Recuperacion de Contrasena
/// E001-HU-007: Recuperacion de Contrasena (celular-based)
abstract class RecuperacionState extends Equatable {
  const RecuperacionState();

  @override
  List<Object?> get props => [];
}

/// Estado: Inicial (formulario de celular vacio)
class RecuperacionInitial extends RecuperacionState {
  const RecuperacionInitial();
}

/// Estado: Cargando (procesando solicitud)
class RecuperacionLoading extends RecuperacionState {
  const RecuperacionLoading();
}

/// Estado: Tipo de recuperacion identificado
/// Contiene informacion para decidir el siguiente paso del flujo
class TipoRecuperacionIdentificado extends RecuperacionState {
  /// Tipo: 'admin', 'jugador', 'no_encontrado'
  final String tipo;
  final String celular;
  final String? preguntaSeguridad;
  final bool? tieneEmailRespaldo;
  final String? emailRespaldoMascara;
  final String? mensaje;

  const TipoRecuperacionIdentificado({
    required this.tipo,
    required this.celular,
    this.preguntaSeguridad,
    this.tieneEmailRespaldo,
    this.emailRespaldoMascara,
    this.mensaje,
  });

  @override
  List<Object?> get props => [
        tipo,
        celular,
        preguntaSeguridad,
        tieneEmailRespaldo,
        emailRespaldoMascara,
        mensaje,
      ];
}

/// Estado: Codigo validado exitosamente - mostrar formulario nueva contrasena
class CodigoValidado extends RecuperacionState {
  final String celular;
  final String codigo;

  const CodigoValidado({
    required this.celular,
    required this.codigo,
  });

  @override
  List<Object?> get props => [celular, codigo];
}

/// Estado: Contrasena restablecida exitosamente
class RecuperacionExitosa extends RecuperacionState {
  final String mensaje;
  final bool sesionesCerradas;

  const RecuperacionExitosa({
    required this.mensaje,
    required this.sesionesCerradas,
  });

  @override
  List<Object?> get props => [mensaje, sesionesCerradas];
}

/// Estado: Respuesta de pregunta incorrecta, pero tiene email de respaldo
class RespuestaIncorrectaConEmail extends RecuperacionState {
  final String celular;
  final String emailMascara;

  const RespuestaIncorrectaConEmail({
    required this.celular,
    required this.emailMascara,
  });

  @override
  List<Object?> get props => [celular, emailMascara];
}

/// Estado: Respuesta de pregunta incorrecta, sin email de respaldo
class RespuestaIncorrectaSinEmail extends RecuperacionState {
  final String celular;
  final String mensaje;

  const RespuestaIncorrectaSinEmail({
    required this.celular,
    required this.mensaje,
  });

  @override
  List<Object?> get props => [celular, mensaje];
}

/// Estado: Email de recuperacion enviado al admin
class EmailRecuperacionEnviado extends RecuperacionState {
  final String emailMascara;
  final String celular;
  final String? debugCodigo;

  const EmailRecuperacionEnviado({
    required this.emailMascara,
    required this.celular,
    this.debugCodigo,
  });

  @override
  List<Object?> get props => [emailMascara, celular, debugCodigo];
}

/// Estado: Cuenta bloqueada temporalmente
class RecuperacionBloqueada extends RecuperacionState {
  final String mensaje;

  const RecuperacionBloqueada({required this.mensaje});

  @override
  List<Object?> get props => [mensaje];
}

/// Estado: Error generico en recuperacion
class RecuperacionError extends RecuperacionState {
  final String mensaje;
  final String? hint;

  const RecuperacionError({
    required this.mensaje,
    this.hint,
  });

  @override
  List<Object?> get props => [mensaje, hint];
}
