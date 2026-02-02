import 'package:equatable/equatable.dart';

import 'gol_detalle_model.dart';

/// Modelo de partido en la actividad del jugador
/// E004-HU-008: Mi Actividad en Vivo
/// Representa un partido con indicador de participacion y goles del jugador
class PartidoActividadModel extends Equatable {
  final String partidoId;
  final String equipoLocal;
  final String equipoVisitante;
  final int golesLocal;
  final int golesVisitante;
  final String estado;
  final int? minutoActual;
  final String? horaInicio;
  final String? horaFin;
  final bool esMiPartido;
  final int misGoles;
  final List<GolDetalleModel> misGolesDetalle;

  const PartidoActividadModel({
    required this.partidoId,
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.golesLocal,
    required this.golesVisitante,
    required this.estado,
    this.minutoActual,
    this.horaInicio,
    this.horaFin,
    required this.esMiPartido,
    required this.misGoles,
    required this.misGolesDetalle,
  });

  /// Factory desde JSON del backend
  factory PartidoActividadModel.fromJson(Map<String, dynamic> json) {
    final misGolesDetalleJson = json['mis_goles_detalle'] as List<dynamic>?;
    final misGolesDetalle = misGolesDetalleJson != null
        ? misGolesDetalleJson
            .map((e) => GolDetalleModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <GolDetalleModel>[];

    return PartidoActividadModel(
      partidoId: json['partido_id'] as String? ?? '',
      equipoLocal: json['equipo_local'] as String? ?? '',
      equipoVisitante: json['equipo_visitante'] as String? ?? '',
      golesLocal: json['goles_local'] as int? ?? 0,
      golesVisitante: json['goles_visitante'] as int? ?? 0,
      estado: json['estado'] as String? ?? 'pendiente',
      minutoActual: json['minuto_actual'] as int?,
      horaInicio: json['hora_inicio'] as String?,
      horaFin: json['hora_fin'] as String?,
      esMiPartido: json['es_mi_partido'] as bool? ?? false,
      misGoles: json['mis_goles'] as int? ?? 0,
      misGolesDetalle: misGolesDetalle,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'partido_id': partidoId,
      'equipo_local': equipoLocal,
      'equipo_visitante': equipoVisitante,
      'goles_local': golesLocal,
      'goles_visitante': golesVisitante,
      'estado': estado,
      if (minutoActual != null) 'minuto_actual': minutoActual,
      if (horaInicio != null) 'hora_inicio': horaInicio,
      if (horaFin != null) 'hora_fin': horaFin,
      'es_mi_partido': esMiPartido,
      'mis_goles': misGoles,
      'mis_goles_detalle': misGolesDetalle.map((e) => e.toJson()).toList(),
    };
  }

  /// Indica si el partido esta en curso
  bool get enCurso => estado == 'en_curso';

  /// Indica si el partido esta finalizado
  bool get finalizado => estado == 'finalizado';

  /// Marcador formateado
  String get marcadorDisplay => '$golesLocal - $golesVisitante';

  /// Enfrentamiento formateado
  String get enfrentamientoDisplay =>
      '${equipoLocal.toUpperCase()} vs ${equipoVisitante.toUpperCase()}';

  @override
  List<Object?> get props => [
        partidoId,
        equipoLocal,
        equipoVisitante,
        golesLocal,
        golesVisitante,
        estado,
        minutoActual,
        horaInicio,
        horaFin,
        esMiPartido,
        misGoles,
        misGolesDetalle,
      ];
}
