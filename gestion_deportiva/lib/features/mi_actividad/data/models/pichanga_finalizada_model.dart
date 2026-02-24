import 'package:equatable/equatable.dart';

/// Modelo de pichanga finalizada recientemente
/// Representa la ultima fecha finalizada donde el jugador participo
class PichangaFinalizadaModel extends Equatable {
  final String fechaId;
  final String fecha;
  final String fechaHora;
  final String lugar;
  final String? miEquipoColor;
  final int? miEquipoNumero;
  final int misGoles;
  final int totalPartidos;
  final int finalizadaHaceHoras;

  const PichangaFinalizadaModel({
    required this.fechaId,
    required this.fecha,
    required this.fechaHora,
    required this.lugar,
    this.miEquipoColor,
    this.miEquipoNumero,
    required this.misGoles,
    required this.totalPartidos,
    required this.finalizadaHaceHoras,
  });

  /// Factory desde JSON del backend
  factory PichangaFinalizadaModel.fromJson(Map<String, dynamic> json) {
    return PichangaFinalizadaModel(
      fechaId: json['fecha_id'] as String? ?? '',
      fecha: json['fecha'] as String? ?? '',
      fechaHora: json['fecha_hora'] as String? ?? '',
      lugar: json['lugar'] as String? ?? '',
      miEquipoColor: json['mi_equipo_color'] as String?,
      miEquipoNumero: json['mi_equipo_numero'] as int?,
      misGoles: json['mis_goles'] as int? ?? 0,
      totalPartidos: json['total_partidos'] as int? ?? 0,
      finalizadaHaceHoras: json['finalizada_hace_horas'] as int? ?? 0,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'fecha_id': fechaId,
      'fecha': fecha,
      'fecha_hora': fechaHora,
      'lugar': lugar,
      if (miEquipoColor != null) 'mi_equipo_color': miEquipoColor,
      if (miEquipoNumero != null) 'mi_equipo_numero': miEquipoNumero,
      'mis_goles': misGoles,
      'total_partidos': totalPartidos,
      'finalizada_hace_horas': finalizadaHaceHoras,
    };
  }

  @override
  List<Object?> get props => [
        fechaId,
        fecha,
        fechaHora,
        lugar,
        miEquipoColor,
        miEquipoNumero,
        misGoles,
        totalPartidos,
        finalizadaHaceHoras,
      ];
}
