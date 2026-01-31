import 'package:equatable/equatable.dart';

import 'equipo_score_model.dart';
import 'gol_model.dart';
import 'estado_partido.dart';

/// Modelo del score en vivo de un partido
/// E004-HU-004: Ver Score en Vivo
/// CA-001: Marcador visible (Equipo1 [goles] - [goles] Equipo2)
/// CA-002: Colores de equipo
/// CA-003: Actualizacion en tiempo real
/// CA-004: Lista de goles
/// CA-005: Tiempo restante junto al score
/// CA-006: Indicador de equipo ganando
/// CA-007: Empate visible
class ScorePartidoModel extends Equatable {
  /// ID del partido
  final String partidoId;

  /// Score del equipo local
  final int scoreLocal;

  /// Score del equipo visitante
  final int scoreVisitante;

  /// Datos del equipo local (color, goles)
  final EquipoScoreModel equipoLocal;

  /// Datos del equipo visitante (color, goles)
  final EquipoScoreModel equipoVisitante;

  /// Lista de goles del partido ordenada por minuto
  final List<GolModel> goles;

  /// Tiempo restante en segundos (puede ser negativo para tiempo extra)
  final int tiempoRestanteSegundos;

  /// Estado actual del partido
  final EstadoPartido estadoPartido;

  /// Indica si el equipo local esta ganando
  /// CA-006: Indicador de equipo ganando
  final bool ganaLocal;

  /// Indica si el equipo visitante esta ganando
  /// CA-006: Indicador de equipo ganando
  final bool ganaVisitante;

  /// Indica si hay empate
  /// CA-007: Empate visible
  final bool empate;

  /// Indica si hubo un gol reciente (ultimos 5 segundos)
  final bool hayGolReciente;

  /// Timestamp del ultimo gol (para animaciones)
  final DateTime? ultimoGolAt;

  const ScorePartidoModel({
    required this.partidoId,
    required this.scoreLocal,
    required this.scoreVisitante,
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.goles,
    required this.tiempoRestanteSegundos,
    required this.estadoPartido,
    required this.ganaLocal,
    required this.ganaVisitante,
    required this.empate,
    this.hayGolReciente = false,
    this.ultimoGolAt,
  });

  /// Factory desde JSON del backend
  /// RPC: obtener_score_partido(p_partido_id)
  factory ScorePartidoModel.fromJson(Map<String, dynamic> json) {
    final golesJson = json['goles'] as List<dynamic>? ?? [];
    final golesList = golesJson
        .map((g) => GolModel.fromJson(g as Map<String, dynamic>))
        .toList();

    // Ordenar goles por minuto
    golesList.sort((a, b) => a.minuto.compareTo(b.minuto));

    final scoreLocal = json['score_local'] as int? ?? 0;
    final scoreVisitante = json['score_visitante'] as int? ?? 0;

    // Calcular indicadores
    final ganaLocal = scoreLocal > scoreVisitante;
    final ganaVisitante = scoreVisitante > scoreLocal;
    final empate = scoreLocal == scoreVisitante;

    // Verificar si hay gol reciente
    DateTime? ultimoGolAt;
    bool hayGolReciente = false;
    if (golesList.isNotEmpty) {
      // Filtrar goles con createdAt no null y encontrar el mas reciente
      final golesConFecha = golesList.where((g) => g.createdAt != null).toList();
      if (golesConFecha.isNotEmpty) {
        final ultimoGol = golesConFecha.reduce(
          (a, b) => a.createdAt!.isAfter(b.createdAt!) ? a : b,
        );
        ultimoGolAt = ultimoGol.createdAt;
        if (ultimoGolAt != null) {
          final diferencia = DateTime.now().difference(ultimoGolAt);
          hayGolReciente = diferencia.inSeconds < 5;
        }
      }
    }

    return ScorePartidoModel(
      partidoId: json['partido_id'] as String,
      scoreLocal: scoreLocal,
      scoreVisitante: scoreVisitante,
      equipoLocal: EquipoScoreModel.fromJson(
        json['equipo_local'] as Map<String, dynamic>,
      ),
      equipoVisitante: EquipoScoreModel.fromJson(
        json['equipo_visitante'] as Map<String, dynamic>,
      ),
      goles: golesList,
      tiempoRestanteSegundos: json['tiempo_restante_segundos'] as int? ?? 0,
      estadoPartido: EstadoPartido.fromString(
        json['estado_partido'] as String? ?? 'en_curso',
      ),
      ganaLocal: ganaLocal,
      ganaVisitante: ganaVisitante,
      empate: empate,
      hayGolReciente: hayGolReciente,
      ultimoGolAt: ultimoGolAt,
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'partido_id': partidoId,
      'score_local': scoreLocal,
      'score_visitante': scoreVisitante,
      'equipo_local': equipoLocal.toJson(),
      'equipo_visitante': equipoVisitante.toJson(),
      'goles': goles.map((g) => g.toJson()).toList(),
      'tiempo_restante_segundos': tiempoRestanteSegundos,
      'estado_partido': estadoPartido.toBackend(),
      'gana_local': ganaLocal,
      'gana_visitante': ganaVisitante,
      'empate': empate,
      'hay_gol_reciente': hayGolReciente,
    };
  }

  /// Tiempo restante formateado (MM:SS o -MM:SS)
  /// CA-005: Tiempo restante junto al score
  String get tiempoRestanteDisplay {
    final esNegativo = tiempoRestanteSegundos < 0;
    final segundosAbsolutos = tiempoRestanteSegundos.abs();
    final minutos = segundosAbsolutos ~/ 60;
    final segs = segundosAbsolutos % 60;
    final tiempo =
        '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
    return esNegativo ? '-$tiempo' : tiempo;
  }

  /// Score formateado para display (ej: "2 - 1")
  String get scoreDisplay => '$scoreLocal - $scoreVisitante';

  /// Crea copia con tiempo actualizado
  ScorePartidoModel copyWithTiempo(int nuevoTiempo) {
    return ScorePartidoModel(
      partidoId: partidoId,
      scoreLocal: scoreLocal,
      scoreVisitante: scoreVisitante,
      equipoLocal: equipoLocal,
      equipoVisitante: equipoVisitante,
      goles: goles,
      tiempoRestanteSegundos: nuevoTiempo,
      estadoPartido: estadoPartido,
      ganaLocal: ganaLocal,
      ganaVisitante: ganaVisitante,
      empate: empate,
      hayGolReciente: hayGolReciente,
      ultimoGolAt: ultimoGolAt,
    );
  }

  /// Crea copia con nuevo gol agregado
  ScorePartidoModel copyWithNuevoGol(GolModel nuevoGol) {
    final nuevosGoles = [...goles, nuevoGol];
    nuevosGoles.sort((a, b) => a.minuto.compareTo(b.minuto));

    // Recalcular scores basado en equipoAnotador
    // El equipo anotador recibe el punto, a menos que sea autogol
    int nuevoScoreLocal = 0;
    int nuevoScoreVisitante = 0;
    for (final gol in nuevosGoles) {
      final esEquipoLocal =
          gol.equipoAnotador.toLowerCase() == equipoLocal.color.name;
      if (esEquipoLocal) {
        if (gol.esAutogol) {
          nuevoScoreVisitante++;
        } else {
          nuevoScoreLocal++;
        }
      } else {
        if (gol.esAutogol) {
          nuevoScoreLocal++;
        } else {
          nuevoScoreVisitante++;
        }
      }
    }

    final nuevoGanaLocal = nuevoScoreLocal > nuevoScoreVisitante;
    final nuevoGanaVisitante = nuevoScoreVisitante > nuevoScoreLocal;
    final nuevoEmpate = nuevoScoreLocal == nuevoScoreVisitante;

    return ScorePartidoModel(
      partidoId: partidoId,
      scoreLocal: nuevoScoreLocal,
      scoreVisitante: nuevoScoreVisitante,
      equipoLocal: EquipoScoreModel(
        color: equipoLocal.color,
        goles: nuevoScoreLocal,
        esLocal: true,
      ),
      equipoVisitante: EquipoScoreModel(
        color: equipoVisitante.color,
        goles: nuevoScoreVisitante,
        esLocal: false,
      ),
      goles: nuevosGoles,
      tiempoRestanteSegundos: tiempoRestanteSegundos,
      estadoPartido: estadoPartido,
      ganaLocal: nuevoGanaLocal,
      ganaVisitante: nuevoGanaVisitante,
      empate: nuevoEmpate,
      hayGolReciente: true,
      ultimoGolAt: nuevoGol.createdAt,
    );
  }

  /// Crea copia actualizando el flag de gol reciente
  ScorePartidoModel copyWithGolReciente(bool reciente) {
    return ScorePartidoModel(
      partidoId: partidoId,
      scoreLocal: scoreLocal,
      scoreVisitante: scoreVisitante,
      equipoLocal: equipoLocal,
      equipoVisitante: equipoVisitante,
      goles: goles,
      tiempoRestanteSegundos: tiempoRestanteSegundos,
      estadoPartido: estadoPartido,
      ganaLocal: ganaLocal,
      ganaVisitante: ganaVisitante,
      empate: empate,
      hayGolReciente: reciente,
      ultimoGolAt: ultimoGolAt,
    );
  }

  @override
  List<Object?> get props => [
        partidoId,
        scoreLocal,
        scoreVisitante,
        equipoLocal,
        equipoVisitante,
        goles,
        tiempoRestanteSegundos,
        estadoPartido,
        ganaLocal,
        ganaVisitante,
        empate,
        hayGolReciente,
        ultimoGolAt,
      ];
}
