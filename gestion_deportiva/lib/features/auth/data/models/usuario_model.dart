import 'package:equatable/equatable.dart';

/// Modelo de usuario para mapear respuestas del backend
/// Convierte snake_case (BD) a camelCase (Dart)
class UsuarioModel extends Equatable {
  final String usuarioId;
  final String authUserId;
  final String nombreCompleto;
  final String email;
  final String estado;
  final String rol;
  final String? motivoRechazo;
  final DateTime? creadoEn;

  const UsuarioModel({
    required this.usuarioId,
    required this.authUserId,
    required this.nombreCompleto,
    required this.email,
    required this.estado,
    required this.rol,
    this.motivoRechazo,
    this.creadoEn,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      usuarioId: json['usuario_id'] ?? '',
      authUserId: json['auth_user_id'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      email: json['email'] ?? '',
      estado: json['estado'] ?? '',
      rol: json['rol'] ?? 'jugador',
      motivoRechazo: json['motivo_rechazo'],
      creadoEn: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : null,
    );
  }

  /// Convierte a JSON para enviar al backend
  /// Mapeo: camelCase -> snake_case
  Map<String, dynamic> toJson() {
    return {
      'usuario_id': usuarioId,
      'auth_user_id': authUserId,
      'nombre_completo': nombreCompleto,
      'email': email,
      'estado': estado,
      'rol': rol,
      'motivo_rechazo': motivoRechazo,
      'created_at': creadoEn?.toUtc().toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        usuarioId,
        authUserId,
        nombreCompleto,
        email,
        estado,
        rol,
        motivoRechazo,
        creadoEn,
      ];
}
