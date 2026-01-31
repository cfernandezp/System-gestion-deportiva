import 'package:equatable/equatable.dart';

/// Modelo de marcador de partido
/// E004-HU-003: Registrar Gol
/// Representa el marcador actual del partido
class MarcadorModel extends Equatable {
  /// Color del equipo local
  final String equipoLocal;

  /// Goles del equipo local
  final int golesLocal;

  /// Color del equipo visitante
  final String equipoVisitante;

  /// Goles del equipo visitante
  final int golesVisitante;

  const MarcadorModel({
    required this.equipoLocal,
    required this.golesLocal,
    required this.equipoVisitante,
    required this.golesVisitante,
  });

  /// Factory desde JSON del backend
  /// Mapea snake_case a camelCase
  factory MarcadorModel.fromJson(Map<String, dynamic> json) {
    return MarcadorModel(
      equipoLocal: json['equipo_local'] as String,
      golesLocal: json['goles_local'] as int,
      equipoVisitante: json['equipo_visitante'] as String,
      golesVisitante: json['goles_visitante'] as int,
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'equipo_local': equipoLocal,
      'goles_local': golesLocal,
      'equipo_visitante': equipoVisitante,
      'goles_visitante': golesVisitante,
    };
  }

  /// Total de goles en el partido
  int get totalGoles => golesLocal + golesVisitante;

  /// Marcador formateado: "NARANJA 2 - 1 VERDE"
  String get texto =>
      '${equipoLocal.toUpperCase()} $golesLocal - $golesVisitante ${equipoVisitante.toUpperCase()}';

  /// Marcador corto: "2 - 1"
  String get textoCorto => '$golesLocal - $golesVisitante';

  @override
  List<Object?> get props => [
        equipoLocal,
        golesLocal,
        equipoVisitante,
        golesVisitante,
      ];
}
