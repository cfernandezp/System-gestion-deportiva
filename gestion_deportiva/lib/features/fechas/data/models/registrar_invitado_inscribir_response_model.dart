import 'package:equatable/equatable.dart';

/// Modelo de respuesta del RPC registrar_invitado_y_inscribir
/// Gestion flexible en_juego: Registro rapido de invitado + inscripcion
///
/// JSON Response:
/// {
///   "success": true,
///   "data": {
///     "usuario_id": "uuid",
///     "miembro_id": "uuid",
///     "inscripcion_id": "uuid",
///     "pago_id": "uuid",
///     "nombre": "string",
///     "fecha_id": "uuid",
///     "grupo_id": "uuid",
///     "inscripcion_tardia": true,
///     "total_inscritos": 15
///   },
///   "message": "Invitado registrado e inscrito exitosamente"
/// }
class RegistrarInvitadoInscribirResponseModel extends Equatable {
  final bool success;
  final RegistrarInvitadoInscribirDataModel? data;
  final String message;

  const RegistrarInvitadoInscribirResponseModel({
    required this.success,
    this.data,
    this.message = '',
  });

  factory RegistrarInvitadoInscribirResponseModel.fromJson(
      Map<String, dynamic> json) {
    return RegistrarInvitadoInscribirResponseModel(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? RegistrarInvitadoInscribirDataModel.fromJson(
              json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [success, data, message];
}

class RegistrarInvitadoInscribirDataModel extends Equatable {
  final String usuarioId;
  final String miembroId;
  final String inscripcionId;
  final String pagoId;
  final String nombre;
  final String fechaId;
  final String grupoId;
  final bool inscripcionTardia;
  final int totalInscritos;

  const RegistrarInvitadoInscribirDataModel({
    required this.usuarioId,
    required this.miembroId,
    required this.inscripcionId,
    required this.pagoId,
    required this.nombre,
    required this.fechaId,
    required this.grupoId,
    this.inscripcionTardia = false,
    this.totalInscritos = 0,
  });

  factory RegistrarInvitadoInscribirDataModel.fromJson(
      Map<String, dynamic> json) {
    return RegistrarInvitadoInscribirDataModel(
      usuarioId: json['usuario_id'] ?? '',
      miembroId: json['miembro_id'] ?? '',
      inscripcionId: json['inscripcion_id'] ?? '',
      pagoId: json['pago_id'] ?? '',
      nombre: json['nombre'] ?? '',
      fechaId: json['fecha_id'] ?? '',
      grupoId: json['grupo_id'] ?? '',
      inscripcionTardia: json['inscripcion_tardia'] ?? false,
      totalInscritos: json['total_inscritos'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        usuarioId,
        miembroId,
        inscripcionId,
        pagoId,
        nombre,
        fechaId,
        grupoId,
        inscripcionTardia,
        totalInscritos,
      ];
}
