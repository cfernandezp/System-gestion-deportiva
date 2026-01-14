import 'package:equatable/equatable.dart';

/// Modelo de respuesta del registro de usuario
/// Mapea la respuesta JSON de la funcion RPC registrar_usuario
class RegistroResponseModel extends Equatable {
  final String usuarioId;
  final String authUserId;
  final String email;
  final String estado;
  final String rol;
  final String mensaje;

  const RegistroResponseModel({
    required this.usuarioId,
    required this.authUserId,
    required this.email,
    required this.estado,
    required this.rol,
    required this.mensaje,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory RegistroResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return RegistroResponseModel(
      usuarioId: data['usuario_id'] ?? '',
      authUserId: data['auth_user_id'] ?? '',
      email: data['email'] ?? '',
      estado: data['estado'] ?? 'pendiente_aprobacion',
      rol: data['rol'] ?? 'jugador',
      mensaje: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        usuarioId,
        authUserId,
        email,
        estado,
        rol,
        mensaje,
      ];
}
