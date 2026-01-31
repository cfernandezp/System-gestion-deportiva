import 'package:equatable/equatable.dart';

import '../../../data/models/gol_model.dart';
import '../../../data/models/marcador_model.dart';

/// Estados del BLoC de goles
/// E004-HU-003: Registrar Gol
abstract class GolesState extends Equatable {
  const GolesState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - Sin datos cargados
class GolesInitial extends GolesState {
  const GolesInitial();
}

/// Estado de carga - Obteniendo datos del servidor
class GolesLoading extends GolesState {
  /// Datos previos (para mostrar mientras carga)
  final List<GolModel>? golesPrevios;
  final MarcadorModel? marcadorPrevio;

  const GolesLoading({
    this.golesPrevios,
    this.marcadorPrevio,
  });

  @override
  List<Object?> get props => [golesPrevios, marcadorPrevio];
}

/// Estado con goles cargados
/// CA-003: Marcador actualizado
/// CA-005: Informacion para deshacer
class GolesLoaded extends GolesState {
  /// ID del partido
  final String partidoId;

  /// Lista de todos los goles ordenados cronologicamente
  final List<GolModel> goles;

  /// Goles del equipo local
  final int golesLocal;

  /// Goles del equipo visitante
  final int golesVisitante;

  /// Marcador actual
  final MarcadorModel? marcador;

  /// Ultimo gol registrado (para mostrar confirmacion/deshacer)
  final GolModel? ultimoGol;

  /// CA-005: Si el ultimo gol puede deshacerse (dentro de ventana de 30 seg)
  final bool puedeDeshacer;

  /// Timestamp del ultimo gol para calcular ventana de deshacer
  final DateTime? timestampUltimoGol;

  const GolesLoaded({
    required this.partidoId,
    required this.goles,
    required this.golesLocal,
    required this.golesVisitante,
    this.marcador,
    this.ultimoGol,
    this.puedeDeshacer = false,
    this.timestampUltimoGol,
  });

  /// Total de goles en el partido
  int get totalGoles => goles.length;

  /// Marcador en texto: "2 - 1"
  String get marcadorTexto => '$golesLocal - $golesVisitante';

  /// Copia con nuevo gol agregado
  GolesLoaded copyWithNuevoGol({
    required GolModel gol,
    required MarcadorModel marcador,
  }) {
    return GolesLoaded(
      partidoId: partidoId,
      goles: [...goles, gol],
      golesLocal: marcador.golesLocal,
      golesVisitante: marcador.golesVisitante,
      marcador: marcador,
      ultimoGol: gol,
      puedeDeshacer: true,
      timestampUltimoGol: DateTime.now(),
    );
  }

  /// Copia sin ultimo gol (despues de limpiar)
  GolesLoaded copyWithoutUltimoGol() {
    return GolesLoaded(
      partidoId: partidoId,
      goles: goles,
      golesLocal: golesLocal,
      golesVisitante: golesVisitante,
      marcador: marcador,
      ultimoGol: null,
      puedeDeshacer: false,
      timestampUltimoGol: null,
    );
  }

  @override
  List<Object?> get props => [
        partidoId,
        goles,
        golesLocal,
        golesVisitante,
        marcador,
        ultimoGol,
        puedeDeshacer,
        timestampUltimoGol,
      ];
}

/// CA-003: Estado de gol registrado exitosamente
/// Emitido brevemente antes de volver a GolesLoaded
class GolRegistrado extends GolesState {
  /// Gol que se registro
  final GolModel gol;

  /// Marcador actualizado
  final MarcadorModel marcador;

  /// RN-008: Advertencia si marcador inusual (10+ goles)
  final String? advertencia;

  /// Mensaje de exito
  final String message;

  const GolRegistrado({
    required this.gol,
    required this.marcador,
    this.advertencia,
    required this.message,
  });

  /// RN-008: Si tiene advertencia de marcador inusual
  bool get tieneAdvertencia => advertencia != null && advertencia!.isNotEmpty;

  @override
  List<Object?> get props => [gol, marcador, advertencia, message];
}

/// CA-005: Estado de gol eliminado exitosamente
class GolEliminado extends GolesState {
  /// Marcador actualizado despues de eliminar
  final MarcadorModel marcador;

  /// Mensaje de exito
  final String message;

  const GolEliminado({
    required this.marcador,
    required this.message,
  });

  @override
  List<Object?> get props => [marcador, message];
}

/// Estado de procesamiento - Registrando o eliminando gol
class GolesProcesando extends GolesState {
  /// Tipo de operacion: 'registrando' o 'eliminando'
  final String operacion;

  /// Datos previos para mostrar mientras procesa
  final List<GolModel>? golesPrevios;
  final MarcadorModel? marcadorPrevio;

  const GolesProcesando({
    required this.operacion,
    this.golesPrevios,
    this.marcadorPrevio,
  });

  @override
  List<Object?> get props => [operacion, golesPrevios, marcadorPrevio];
}

/// Estado de error
class GolesError extends GolesState {
  /// Mensaje de error para mostrar al usuario
  final String message;

  /// Codigo de error del backend (opcional)
  final String? code;

  /// Hint del backend para identificar tipo de error
  /// Valores posibles:
  /// - no_autenticado: Usuario no ha iniciado sesion
  /// - partido_id_requerido: Falta partido_id
  /// - equipo_anotador_requerido: Falta equipo anotador
  /// - sin_permisos: Usuario no es admin aprobado (RN-001)
  /// - partido_no_encontrado: Partido no existe
  /// - partido_pausado: Partido esta pausado (RN-007)
  /// - partido_no_en_curso: Partido no esta en curso (RN-002)
  /// - equipo_invalido: Color de equipo invalido
  /// - equipo_no_participa: Equipo no juega en este partido
  /// - jugador_no_encontrado: Jugador no existe
  /// - jugador_sin_asignacion: Jugador no tiene equipo en el partido
  /// - jugador_equipo_incorrecto: Jugador no pertenece al equipo anotador (RN-003)
  /// - jugador_equipo_incorrecto_autogol: En autogol, jugador debe ser del equipo contrario
  /// - gol_id_requerido: Falta gol_id
  /// - gol_no_encontrado: Gol no existe
  final String? hint;

  /// Datos previos (para recuperar estado)
  final List<GolModel>? golesPrevios;
  final MarcadorModel? marcadorPrevio;

  const GolesError({
    required this.message,
    this.code,
    this.hint,
    this.golesPrevios,
    this.marcadorPrevio,
  });

  /// RN-001: Error por usuario sin permisos
  bool get esSinPermisos => hint == 'sin_permisos';

  /// RN-002: Error por partido no en curso
  bool get esPartidoNoEnCurso => hint == 'partido_no_en_curso';

  /// RN-007: Error por partido pausado
  bool get esPartidoPausado => hint == 'partido_pausado';

  /// RN-003: Error por jugador de equipo incorrecto
  bool get esJugadorEquipoIncorrecto =>
      hint == 'jugador_equipo_incorrecto' ||
      hint == 'jugador_equipo_incorrecto_autogol';

  @override
  List<Object?> get props => [message, code, hint, golesPrevios, marcadorPrevio];
}
