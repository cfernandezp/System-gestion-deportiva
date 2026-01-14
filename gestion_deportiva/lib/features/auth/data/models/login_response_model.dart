import 'package:equatable/equatable.dart';

/// Modelo de respuesta del inicio de sesion
/// Mapea la respuesta JSON de la funcion RPC iniciar_sesion
///
/// Response Success del Backend:
/// ```json
/// {
///   "success": true,
///   "data": {
///     "usuario_id": "uuid",
///     "auth_user_id": "uuid",
///     "nombre_completo": "Juan Perez",
///     "email": "juan@example.com",
///     "rol": "jugador",
///     "estado": "aprobado"
///   },
///   "message": "Inicio de sesion exitoso"
/// }
/// ```
class LoginResponseModel extends Equatable {
  final String usuarioId;
  final String authUserId;
  final String nombreCompleto;
  final String email;
  final String rol;
  final String estado;
  final String mensaje;

  const LoginResponseModel({
    required this.usuarioId,
    required this.authUserId,
    required this.nombreCompleto,
    required this.email,
    required this.rol,
    required this.estado,
    required this.mensaje,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return LoginResponseModel(
      usuarioId: data['usuario_id'] ?? '',
      authUserId: data['auth_user_id'] ?? '',
      nombreCompleto: data['nombre_completo'] ?? '',
      email: data['email'] ?? '',
      rol: data['rol'] ?? 'jugador',
      estado: data['estado'] ?? '',
      mensaje: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        usuarioId,
        authUserId,
        nombreCompleto,
        email,
        rol,
        estado,
        mensaje,
      ];
}

/// Modelo para verificar estado de bloqueo de login
/// Mapea la respuesta JSON de la funcion RPC verificar_bloqueo_login
///
/// Response Success del Backend:
/// ```json
/// {
///   "success": true,
///   "data": {
///     "bloqueado": false,
///     "intentos_fallidos": 2,
///     "intentos_restantes": 3
///   },
///   "message": "No hay bloqueo activo"
/// }
/// ```
class VerificarBloqueoModel extends Equatable {
  final bool bloqueado;
  final int intentosFallidos;
  final int intentosRestantes;
  final int? minutosRestantes;
  final String mensaje;

  const VerificarBloqueoModel({
    required this.bloqueado,
    required this.intentosFallidos,
    required this.intentosRestantes,
    this.minutosRestantes,
    required this.mensaje,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory VerificarBloqueoModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return VerificarBloqueoModel(
      bloqueado: data['bloqueado'] ?? false,
      intentosFallidos: data['intentos_fallidos'] ?? 0,
      intentosRestantes: data['intentos_restantes'] ?? 5,
      minutosRestantes: data['minutos_restantes'],
      mensaje: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        bloqueado,
        intentosFallidos,
        intentosRestantes,
        minutosRestantes,
        mensaje,
      ];
}
