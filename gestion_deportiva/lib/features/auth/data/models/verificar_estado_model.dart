import 'package:equatable/equatable.dart';

/// Modelo de respuesta de verificacion de estado de usuario
/// Mapea la respuesta JSON de la funcion RPC verificar_estado_usuario
class VerificarEstadoModel extends Equatable {
  final bool puedeAcceder;
  final String? usuarioId;
  final String? nombreCompleto;
  final String? email;
  final String estado;
  final String? rol;
  final String mensaje;

  const VerificarEstadoModel({
    required this.puedeAcceder,
    this.usuarioId,
    this.nombreCompleto,
    this.email,
    required this.estado,
    this.rol,
    required this.mensaje,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory VerificarEstadoModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return VerificarEstadoModel(
      puedeAcceder: data['puede_acceder'] ?? false,
      usuarioId: data['usuario_id'],
      nombreCompleto: data['nombre_completo'],
      email: data['email'],
      estado: data['estado'] ?? 'pendiente_aprobacion',
      rol: data['rol'],
      mensaje: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        puedeAcceder,
        usuarioId,
        nombreCompleto,
        email,
        estado,
        rol,
        mensaje,
      ];
}
