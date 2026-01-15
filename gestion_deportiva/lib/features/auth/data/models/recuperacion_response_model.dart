import 'package:equatable/equatable.dart';

/// Modelo de respuesta para solicitar recuperacion de contrasena
/// Mapea la respuesta JSON de la funcion RPC solicitar_recuperacion_contrasena
///
/// Response Success del Backend:
/// ```json
/// {
///   "success": true,
///   "data": {
///     "email_enviado": true,
///     "token": "abc123...",
///     "token_id": "uuid",
///     "expira_en_minutos": 60,
///     "usuario_nombre": "Juan Perez"
///   },
///   "message": "Si el email esta registrado, recibiras instrucciones..."
/// }
/// ```
class SolicitudRecuperacionModel extends Equatable {
  final bool emailEnviado;
  final String? token;
  final String? tokenId;
  final int? expiraEnMinutos;
  final String? usuarioNombre;
  final String mensaje;

  const SolicitudRecuperacionModel({
    required this.emailEnviado,
    this.token,
    this.tokenId,
    this.expiraEnMinutos,
    this.usuarioNombre,
    required this.mensaje,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory SolicitudRecuperacionModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return SolicitudRecuperacionModel(
      emailEnviado: data['email_enviado'] ?? false,
      token: data['token'],
      tokenId: data['token_id'],
      expiraEnMinutos: data['expira_en_minutos'],
      usuarioNombre: data['usuario_nombre'],
      mensaje: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        emailEnviado,
        token,
        tokenId,
        expiraEnMinutos,
        usuarioNombre,
        mensaje,
      ];
}

/// Modelo de respuesta para validar token de recuperacion
/// Mapea la respuesta JSON de la funcion RPC validar_token_recuperacion
///
/// Response Success del Backend:
/// ```json
/// {
///   "success": true,
///   "data": {
///     "valido": true,
///     "email": "user@email.com",
///     "nombre": "Usuario",
///     "minutos_restantes": 45
///   },
///   "message": "Token valido"
/// }
/// ```
class ValidarTokenModel extends Equatable {
  final bool valido;
  final String? email;
  final String? nombre;
  final int? minutosRestantes;
  final String mensaje;

  const ValidarTokenModel({
    required this.valido,
    this.email,
    this.nombre,
    this.minutosRestantes,
    required this.mensaje,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory ValidarTokenModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return ValidarTokenModel(
      valido: data['valido'] ?? false,
      email: data['email'],
      nombre: data['nombre'],
      minutosRestantes: data['minutos_restantes'],
      mensaje: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        valido,
        email,
        nombre,
        minutosRestantes,
        mensaje,
      ];
}

/// Modelo de respuesta para restablecer contrasena
/// Mapea la respuesta JSON de la funcion RPC restablecer_contrasena
///
/// Response Success del Backend:
/// ```json
/// {
///   "success": true,
///   "data": {
///     "email": "user@email.com",
///     "sesiones_cerradas": true
///   },
///   "message": "Contrasena actualizada exitosamente..."
/// }
/// ```
class RestablecerContrasenaModel extends Equatable {
  final String email;
  final bool sesionesCerradas;
  final String mensaje;

  const RestablecerContrasenaModel({
    required this.email,
    required this.sesionesCerradas,
    required this.mensaje,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory RestablecerContrasenaModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return RestablecerContrasenaModel(
      email: data['email'] ?? '',
      sesionesCerradas: data['sesiones_cerradas'] ?? false,
      mensaje: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        email,
        sesionesCerradas,
        mensaje,
      ];
}
