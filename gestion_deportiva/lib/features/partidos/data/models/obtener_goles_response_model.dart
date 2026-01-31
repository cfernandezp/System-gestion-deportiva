import 'package:equatable/equatable.dart';

import 'gol_model.dart';
import 'marcador_model.dart';
import 'partido_info_model.dart';

/// Modelo de respuesta para obtener_goles_partido RPC
/// E004-HU-003: Registrar Gol
/// Obtiene lista de goles y marcador de un partido
class ObtenerGolesResponseModel extends Equatable {
  /// Si la operacion fue exitosa
  final bool success;

  /// ID del partido
  final String? partidoId;

  /// Informacion basica del partido
  final PartidoInfoModel? partido;

  /// Marcador actual
  final MarcadorModel? marcador;

  /// Marcador en texto: "NARANJA 2 - 1 VERDE"
  final String? marcadorTexto;

  /// Lista de goles ordenados cronologicamente
  final List<GolModel> goles;

  /// Total de goles en el partido
  final int totalGoles;

  /// Mensaje de la operacion
  final String message;

  const ObtenerGolesResponseModel({
    required this.success,
    this.partidoId,
    this.partido,
    this.marcador,
    this.marcadorTexto,
    required this.goles,
    required this.totalGoles,
    required this.message,
  });

  /// Factory desde JSON del backend
  /// Response de obtener_goles_partido RPC
  factory ObtenerGolesResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    String? partidoId;
    PartidoInfoModel? partido;
    MarcadorModel? marcador;
    String? marcadorTexto;
    List<GolModel> goles = [];
    int totalGoles = 0;

    if (data != null) {
      partidoId = data['partido_id'] as String?;

      // Parsear informacion del partido
      final partidoJson = data['partido'] as Map<String, dynamic>?;
      if (partidoJson != null) {
        partido = PartidoInfoModel.fromJson(partidoJson);
      }

      // Parsear marcador
      final marcadorJson = data['marcador'] as Map<String, dynamic>?;
      if (marcadorJson != null) {
        marcador = MarcadorModel.fromJson(marcadorJson);
      }

      marcadorTexto = data['marcador_texto'] as String?;

      // Parsear lista de goles
      final golesJson = data['goles'] as List<dynamic>? ?? [];
      goles = golesJson
          .map((g) => GolModel.fromJson(g as Map<String, dynamic>))
          .toList();

      totalGoles = data['total_goles'] as int? ?? goles.length;
    }

    return ObtenerGolesResponseModel(
      success: json['success'] as bool? ?? false,
      partidoId: partidoId,
      partido: partido,
      marcador: marcador,
      marcadorTexto: marcadorTexto,
      goles: goles,
      totalGoles: totalGoles,
      message: json['message'] as String? ?? '',
    );
  }

  /// Goles del equipo local
  List<GolModel> get golesLocal {
    if (partido == null) return [];
    return goles
        .where((g) => g.equipoAnotador == partido!.equipoLocal)
        .toList();
  }

  /// Goles del equipo visitante
  List<GolModel> get golesVisitante {
    if (partido == null) return [];
    return goles
        .where((g) => g.equipoAnotador == partido!.equipoVisitante)
        .toList();
  }

  @override
  List<Object?> get props => [
        success,
        partidoId,
        partido,
        marcador,
        marcadorTexto,
        goles,
        totalGoles,
        message,
      ];
}
