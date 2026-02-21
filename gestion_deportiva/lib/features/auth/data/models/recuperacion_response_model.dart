import 'package:equatable/equatable.dart';

/// Modelo de respuesta para identificar tipo de recuperacion
/// E001-HU-007: Recuperacion de Contrasena
/// RPC: identificar_tipo_recuperacion(p_celular)
///
/// Response:
/// ```json
/// {
///   "success": true,
///   "data": {
///     "tipo": "admin"|"jugador"|"no_encontrado",
///     "pregunta_seguridad": "...",
///     "tiene_email_respaldo": true,
///     "email_respaldo_mascara": "j***@gmail.com",
///     "mensaje": "..."
///   }
/// }
/// ```
class TipoRecuperacionModel extends Equatable {
  final String tipo;
  final String? preguntaSeguridad;
  final bool? tieneEmailRespaldo;
  final String? emailRespaldoMascara;
  final String? mensaje;

  const TipoRecuperacionModel({
    required this.tipo,
    this.preguntaSeguridad,
    this.tieneEmailRespaldo,
    this.emailRespaldoMascara,
    this.mensaje,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory TipoRecuperacionModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return TipoRecuperacionModel(
      tipo: data['tipo'] ?? 'no_encontrado',
      preguntaSeguridad: data['pregunta_seguridad'],
      tieneEmailRespaldo: data['tiene_email_respaldo'],
      emailRespaldoMascara: data['email_respaldo_mascara'],
      mensaje: data['mensaje'],
    );
  }

  @override
  List<Object?> get props => [
        tipo,
        preguntaSeguridad,
        tieneEmailRespaldo,
        emailRespaldoMascara,
        mensaje,
      ];
}

/// Modelo de respuesta para generar codigo de recuperacion (admin genera para jugador)
/// E001-HU-007: Recuperacion de Contrasena
/// RPC: generar_codigo_recuperacion(p_celular_jugador) -> authenticated
///
/// Response:
/// ```json
/// {
///   "success": true,
///   "data": {
///     "codigo": "123456",
///     "celular_jugador": "987654321",
///     "expira_en_minutos": 30,
///     "mensaje_para_jugador": "..."
///   },
///   "message": "..."
/// }
/// ```
class GenerarCodigoModel extends Equatable {
  final String codigo;
  final String celularJugador;
  final int expiraEnMinutos;
  final String mensajeParaJugador;

  const GenerarCodigoModel({
    required this.codigo,
    required this.celularJugador,
    required this.expiraEnMinutos,
    required this.mensajeParaJugador,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory GenerarCodigoModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return GenerarCodigoModel(
      codigo: data['codigo'] ?? '',
      celularJugador: data['celular_jugador'] ?? '',
      expiraEnMinutos: data['expira_en_minutos'] ?? 30,
      mensajeParaJugador: data['mensaje_para_jugador'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        codigo,
        celularJugador,
        expiraEnMinutos,
        mensajeParaJugador,
      ];
}

/// Modelo de respuesta para validar codigo de recuperacion
/// E001-HU-007: Recuperacion de Contrasena
/// RPC: validar_codigo_recuperacion(p_celular, p_codigo)
///
/// Response:
/// ```json
/// {
///   "success": true,
///   "data": {
///     "codigo_valido": true,
///     "celular": "987654321"
///   }
/// }
/// ```
class ValidarCodigoModel extends Equatable {
  final bool codigoValido;
  final String celular;

  const ValidarCodigoModel({
    required this.codigoValido,
    required this.celular,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory ValidarCodigoModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return ValidarCodigoModel(
      codigoValido: data['codigo_valido'] ?? false,
      celular: data['celular'] ?? '',
    );
  }

  @override
  List<Object?> get props => [codigoValido, celular];
}

/// Modelo de respuesta para restablecer contrasena (con codigo o pregunta)
/// E001-HU-007: Recuperacion de Contrasena
/// RPC: restablecer_contrasena_con_codigo / restablecer_contrasena_con_pregunta
///
/// Response:
/// ```json
/// {
///   "success": true,
///   "data": {
///     "contrasena_actualizada": true,
///     "sesiones_cerradas": true
///   },
///   "message": "..."
/// }
/// ```
class RestablecerResultModel extends Equatable {
  final bool contrasenaActualizada;
  final bool sesionesCerradas;
  final String mensaje;

  const RestablecerResultModel({
    required this.contrasenaActualizada,
    required this.sesionesCerradas,
    required this.mensaje,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory RestablecerResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return RestablecerResultModel(
      contrasenaActualizada: data['contrasena_actualizada'] ?? false,
      sesionesCerradas: data['sesiones_cerradas'] ?? false,
      mensaje: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [contrasenaActualizada, sesionesCerradas, mensaje];
}

/// Modelo de respuesta para recuperacion via email de admin
/// E001-HU-007: Recuperacion de Contrasena
/// RPC: solicitar_recuperacion_email_admin(p_celular)
///
/// Response:
/// ```json
/// {
///   "success": true,
///   "data": {
///     "email_respaldo_mascara": "j***@gmail.com",
///     "expira_en_minutos": 30,
///     "_debug_codigo": "123456"
///   },
///   "message": "..."
/// }
/// ```
class RecuperacionEmailModel extends Equatable {
  final String emailRespaldoMascara;
  final int expiraEnMinutos;
  final String? debugCodigo;

  const RecuperacionEmailModel({
    required this.emailRespaldoMascara,
    required this.expiraEnMinutos,
    this.debugCodigo,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory RecuperacionEmailModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return RecuperacionEmailModel(
      emailRespaldoMascara: data['email_respaldo_mascara'] ?? '',
      expiraEnMinutos: data['expira_en_minutos'] ?? 30,
      debugCodigo: data['_debug_codigo'],
    );
  }

  @override
  List<Object?> get props => [emailRespaldoMascara, expiraEnMinutos, debugCodigo];
}
