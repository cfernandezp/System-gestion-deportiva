import 'package:equatable/equatable.dart';

import '../../../data/models/score_partido_model.dart';

/// Estados del BLoC de Score en Vivo
/// E004-HU-004: Ver Score en Vivo
abstract class ScoreState extends Equatable {
  const ScoreState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - Sin datos cargados
class ScoreInitial extends ScoreState {
  const ScoreInitial();
}

/// Estado de carga - Obteniendo datos del servidor
class ScoreLoading extends ScoreState {
  /// Score previo (para mostrar mientras carga)
  final ScorePartidoModel? scorePrevio;

  const ScoreLoading({this.scorePrevio});

  @override
  List<Object?> get props => [scorePrevio];
}

/// Estado con score cargado y actualizandose en tiempo real
/// CA-001: Marcador visible
/// CA-002: Colores de equipo
/// CA-003: Actualizacion en tiempo real
/// CA-004: Lista de goles
/// CA-005: Tiempo restante
/// CA-006: Indicador equipo ganando
/// CA-007: Empate visible
class ScoreLoaded extends ScoreState {
  /// Datos completos del score
  final ScorePartidoModel score;

  /// Indica si esta suscrito a realtime
  final bool suscritoRealtime;

  /// Mensaje informativo
  final String message;

  const ScoreLoaded({
    required this.score,
    this.suscritoRealtime = false,
    this.message = '',
  });

  /// CA-001: Score del equipo local
  int get scoreLocal => score.scoreLocal;

  /// CA-001: Score del equipo visitante
  int get scoreVisitante => score.scoreVisitante;

  /// CA-001: Score formateado "2 - 1"
  String get scoreDisplay => score.scoreDisplay;

  /// CA-005: Tiempo restante formateado
  String get tiempoRestanteDisplay => score.tiempoRestanteDisplay;

  /// CA-006: Indica si el local esta ganando
  bool get ganaLocal => score.ganaLocal;

  /// CA-006: Indica si el visitante esta ganando
  bool get ganaVisitante => score.ganaVisitante;

  /// CA-007: Indica si hay empate
  bool get empate => score.empate;

  /// Indica si hubo gol reciente (para animacion)
  bool get hayGolReciente => score.hayGolReciente;

  /// Cantidad de goles en el partido
  int get totalGoles => score.goles.length;

  /// Crea copia con tiempo actualizado
  ScoreLoaded copyWithTiempo(int nuevoTiempo) {
    return ScoreLoaded(
      score: score.copyWithTiempo(nuevoTiempo),
      suscritoRealtime: suscritoRealtime,
      message: message,
    );
  }

  /// Crea copia con gol reciente actualizado
  ScoreLoaded copyWithGolReciente(bool reciente) {
    return ScoreLoaded(
      score: score.copyWithGolReciente(reciente),
      suscritoRealtime: suscritoRealtime,
      message: message,
    );
  }

  /// Crea copia con nuevo score
  ScoreLoaded copyWithScore(ScorePartidoModel nuevoScore) {
    return ScoreLoaded(
      score: nuevoScore,
      suscritoRealtime: suscritoRealtime,
      message: message,
    );
  }

  @override
  List<Object?> get props => [score, suscritoRealtime, message];
}

/// Estado de error
class ScoreError extends ScoreState {
  /// Mensaje de error para mostrar al usuario
  final String message;

  /// Codigo de error del backend (opcional)
  final String? code;

  /// Hint del backend para identificar tipo de error
  final String? hint;

  /// Score previo (para recuperar estado o mostrar datos)
  final ScorePartidoModel? scorePrevio;

  /// ID del partido (para reintentar)
  final String? partidoId;

  const ScoreError({
    required this.message,
    this.code,
    this.hint,
    this.scorePrevio,
    this.partidoId,
  });

  @override
  List<Object?> get props => [message, code, hint, scorePrevio, partidoId];
}
