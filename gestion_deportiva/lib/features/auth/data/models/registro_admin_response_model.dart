import 'package:equatable/equatable.dart';

/// Modelo de respuesta del registro de administrador
/// E001-HU-001: Mapea la respuesta JSON de la funcion RPC registrar_administrador
class RegistroAdminResponseModel extends Equatable {
  final String usuarioId;
  final String authUserId;
  final String celular;
  final String nombreCompleto;
  final String estado;
  final String rol;
  final bool requiereCrearGrupo;
  final String mensaje;

  const RegistroAdminResponseModel({
    required this.usuarioId,
    required this.authUserId,
    required this.celular,
    required this.nombreCompleto,
    required this.estado,
    required this.rol,
    required this.requiereCrearGrupo,
    required this.mensaje,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory RegistroAdminResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return RegistroAdminResponseModel(
      usuarioId: data['usuario_id'] ?? '',
      authUserId: data['auth_user_id'] ?? '',
      celular: data['celular'] ?? '',
      nombreCompleto: data['nombre_completo'] ?? '',
      estado: data['estado'] ?? 'aprobado',
      rol: data['rol'] ?? 'admin',
      requiereCrearGrupo: data['requiere_crear_grupo'] ?? true,
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
        rol,
        requiereCrearGrupo,
        mensaje,
      ];
}
