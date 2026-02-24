import 'package:equatable/equatable.dart';

/// Modelo de proxima pichanga programada
/// Representa una fecha proxima donde el jugador esta inscrito
class ProximaPichangaModel extends Equatable {
  final String fechaId;
  final String fecha;
  final String fechaHora;
  final String lugar;
  final String costoFormato;
  final int numEquipos;
  final int totalInscritos;
  final String estado;
  final String miInscripcion;

  const ProximaPichangaModel({
    required this.fechaId,
    required this.fecha,
    required this.fechaHora,
    required this.lugar,
    required this.costoFormato,
    required this.numEquipos,
    required this.totalInscritos,
    required this.estado,
    required this.miInscripcion,
  });

  /// Factory desde JSON del backend
  factory ProximaPichangaModel.fromJson(Map<String, dynamic> json) {
    return ProximaPichangaModel(
      fechaId: json['fecha_id'] as String? ?? '',
      fecha: json['fecha'] as String? ?? '',
      fechaHora: json['fecha_hora'] as String? ?? '',
      lugar: json['lugar'] as String? ?? '',
      costoFormato: json['costo_formato'] as String? ?? '',
      numEquipos: json['num_equipos'] as int? ?? 2,
      totalInscritos: json['total_inscritos'] as int? ?? 0,
      estado: json['estado'] as String? ?? 'abierta',
      miInscripcion: json['mi_inscripcion'] as String? ?? '',
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'fecha_id': fechaId,
      'fecha': fecha,
      'fecha_hora': fechaHora,
      'lugar': lugar,
      'costo_formato': costoFormato,
      'num_equipos': numEquipos,
      'total_inscritos': totalInscritos,
      'estado': estado,
      'mi_inscripcion': miInscripcion,
    };
  }

  @override
  List<Object?> get props => [
        fechaId,
        fecha,
        fechaHora,
        lugar,
        costoFormato,
        numEquipos,
        totalInscritos,
        estado,
        miInscripcion,
      ];
}
