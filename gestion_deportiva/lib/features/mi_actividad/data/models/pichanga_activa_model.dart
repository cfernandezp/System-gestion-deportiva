import 'package:equatable/equatable.dart';

/// Modelo de pichanga activa
/// E004-HU-008: Mi Actividad en Vivo
/// Representa una fecha en estado 'en_juego' donde el jugador esta inscrito
class PichangaActivaModel extends Equatable {
  final String fechaId;
  final String fecha;
  final String fechaHora;
  final String lugar;
  final String estado;
  final String? iniciadoAt;

  const PichangaActivaModel({
    required this.fechaId,
    required this.fecha,
    required this.fechaHora,
    required this.lugar,
    required this.estado,
    this.iniciadoAt,
  });

  /// Factory desde JSON del backend
  factory PichangaActivaModel.fromJson(Map<String, dynamic> json) {
    return PichangaActivaModel(
      fechaId: json['fecha_id'] as String? ?? '',
      fecha: json['fecha'] as String? ?? '',
      fechaHora: json['fecha_hora'] as String? ?? '',
      lugar: json['lugar'] as String? ?? '',
      estado: json['estado'] as String? ?? 'en_juego',
      iniciadoAt: json['iniciado_at'] as String?,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'fecha_id': fechaId,
      'fecha': fecha,
      'fecha_hora': fechaHora,
      'lugar': lugar,
      'estado': estado,
      if (iniciadoAt != null) 'iniciado_at': iniciadoAt,
    };
  }

  @override
  List<Object?> get props =>
      [fechaId, fecha, fechaHora, lugar, estado, iniciadoAt];
}
