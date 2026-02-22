import 'package:equatable/equatable.dart';

/// Modelo de respuesta del RPC marcar_ausente
/// Gestion flexible en_juego: Marcar jugador como ausente
///
/// JSON Response:
/// {
///   "success": true,
///   "data": {
///     "inscripcion_id": "uuid",
///     "fecha_id": "uuid",
///     "usuario_id": "uuid",
///     "jugador_nombre": "string",
///     "equipo_anterior": "naranja|null",
///     "estado_nuevo": "ausente",
///     "marcado_por": "string"
///   },
///   "message": "Jugador marcado como ausente"
/// }
class MarcarAusenteResponseModel extends Equatable {
  final bool success;
  final MarcarAusenteDataModel? data;
  final String message;

  const MarcarAusenteResponseModel({
    required this.success,
    this.data,
    this.message = '',
  });

  factory MarcarAusenteResponseModel.fromJson(Map<String, dynamic> json) {
    return MarcarAusenteResponseModel(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? MarcarAusenteDataModel.fromJson(
              json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [success, data, message];
}

class MarcarAusenteDataModel extends Equatable {
  final String inscripcionId;
  final String fechaId;
  final String usuarioId;
  final String jugadorNombre;
  final String? equipoAnterior;
  final String estadoNuevo;
  final String marcadoPor;

  const MarcarAusenteDataModel({
    required this.inscripcionId,
    required this.fechaId,
    required this.usuarioId,
    required this.jugadorNombre,
    this.equipoAnterior,
    required this.estadoNuevo,
    required this.marcadoPor,
  });

  factory MarcarAusenteDataModel.fromJson(Map<String, dynamic> json) {
    return MarcarAusenteDataModel(
      inscripcionId: json['inscripcion_id'] ?? '',
      fechaId: json['fecha_id'] ?? '',
      usuarioId: json['usuario_id'] ?? '',
      jugadorNombre: json['jugador_nombre'] ?? '',
      equipoAnterior: json['equipo_anterior'],
      estadoNuevo: json['estado_nuevo'] ?? 'ausente',
      marcadoPor: json['marcado_por'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        inscripcionId,
        fechaId,
        usuarioId,
        jugadorNombre,
        equipoAnterior,
        estadoNuevo,
        marcadoPor,
      ];
}
