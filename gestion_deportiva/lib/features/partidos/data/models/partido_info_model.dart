import 'package:equatable/equatable.dart';

/// Modelo de informacion basica del partido
/// E004-HU-003: Registrar Gol
/// Usado en obtener_goles_partido response
class PartidoInfoModel extends Equatable {
  /// Color del equipo local
  final String equipoLocal;

  /// Color del equipo visitante
  final String equipoVisitante;

  /// Duracion del partido en minutos
  final int duracionMinutos;

  /// Estado actual del partido
  final String estado;

  const PartidoInfoModel({
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.duracionMinutos,
    required this.estado,
  });

  /// Factory desde JSON del backend
  /// Mapea snake_case a camelCase
  factory PartidoInfoModel.fromJson(Map<String, dynamic> json) {
    return PartidoInfoModel(
      equipoLocal: json['equipo_local'] as String,
      equipoVisitante: json['equipo_visitante'] as String,
      duracionMinutos: json['duracion_minutos'] as int,
      estado: json['estado'] as String,
    );
  }

  /// Si el partido esta en curso
  bool get estaEnCurso => estado == 'en_curso';

  /// Si el partido esta pausado
  bool get estaPausado => estado == 'pausado';

  /// Si el partido esta finalizado
  bool get estaFinalizado => estado == 'finalizado';

  @override
  List<Object?> get props => [
        equipoLocal,
        equipoVisitante,
        duracionMinutos,
        estado,
      ];
}
