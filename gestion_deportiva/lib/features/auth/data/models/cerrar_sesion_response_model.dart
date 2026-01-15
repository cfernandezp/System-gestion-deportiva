import 'package:equatable/equatable.dart';

/// Modelo de respuesta del cierre de sesion
/// Mapea la respuesta JSON de la funcion RPC cerrar_sesion
/// HU-004: Cierre de Sesion
///
/// Response Success del Backend:
/// ```json
/// {
///   "success": true,
///   "data": {
///     "usuario_id": "uuid",
///     "email": "user@example.com",
///     "fecha_cierre": "2026-01-14T10:30:00-05:00",
///     "sesion_invalidada": true
///   },
///   "message": "Sesion cerrada exitosamente"
/// }
/// ```
class CerrarSesionResponseModel extends Equatable {
  final String usuarioId;
  final String email;
  final DateTime fechaCierre;
  final bool sesionInvalidada;
  final String mensaje;

  const CerrarSesionResponseModel({
    required this.usuarioId,
    required this.email,
    required this.fechaCierre,
    required this.sesionInvalidada,
    required this.mensaje,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory CerrarSesionResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return CerrarSesionResponseModel(
      usuarioId: data['usuario_id'] ?? '',
      email: data['email'] ?? '',
      // Parsear fecha UTC y convertir a local (Zona horaria Peru)
      fechaCierre: data['fecha_cierre'] != null
          ? DateTime.parse(data['fecha_cierre']).toLocal()
          : DateTime.now(),
      sesionInvalidada: data['sesion_invalidada'] ?? false,
      mensaje: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        usuarioId,
        email,
        fechaCierre,
        sesionInvalidada,
        mensaje,
      ];
}
