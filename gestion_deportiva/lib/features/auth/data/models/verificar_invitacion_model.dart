import 'package:equatable/equatable.dart';

/// Modelo de respuesta de verificar_invitacion_pendiente
/// E001-HU-005: CA-001, CA-002, CA-004
class VerificarInvitacionModel extends Equatable {
  final bool tieneInvitacion;
  final bool yaActivo;
  final int gruposPendientes;
  final String mensaje;

  const VerificarInvitacionModel({
    required this.tieneInvitacion,
    required this.yaActivo,
    required this.gruposPendientes,
    required this.mensaje,
  });

  /// Crea instancia desde JSON del backend
  factory VerificarInvitacionModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return VerificarInvitacionModel(
      tieneInvitacion: data['tiene_invitacion'] ?? false,
      yaActivo: data['ya_activo'] ?? false,
      gruposPendientes: data['grupos_pendientes'] ?? 0,
      mensaje: data['mensaje'] ?? '',
    );
  }

  @override
  List<Object?> get props => [tieneInvitacion, yaActivo, gruposPendientes, mensaje];
}
