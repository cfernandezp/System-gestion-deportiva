import 'package:equatable/equatable.dart';

/// Modelo de respuesta de activar_cuenta_jugador
/// E001-HU-005: CA-001, CA-006
class ActivacionCuentaResponseModel extends Equatable {
  final String usuarioId;
  final String authUserId;
  final String celular;
  final String nombreCompleto;
  final String estado;
  final int gruposActivos;
  final String mensaje;

  const ActivacionCuentaResponseModel({
    required this.usuarioId,
    required this.authUserId,
    required this.celular,
    required this.nombreCompleto,
    required this.estado,
    required this.gruposActivos,
    required this.mensaje,
  });

  /// Crea instancia desde JSON del backend
  factory ActivacionCuentaResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return ActivacionCuentaResponseModel(
      usuarioId: data['usuario_id'] ?? '',
      authUserId: data['auth_user_id'] ?? '',
      celular: data['celular'] ?? '',
      nombreCompleto: data['nombre_completo'] ?? '',
      estado: data['estado'] ?? 'aprobado',
      gruposActivos: data['grupos_activos'] ?? 0,
      mensaje: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        usuarioId,
        authUserId,
        celular,
        nombreCompleto,
        estado,
        gruposActivos,
        mensaje,
      ];
}
