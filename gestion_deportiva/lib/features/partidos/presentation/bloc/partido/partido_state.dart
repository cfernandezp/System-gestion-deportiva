import 'package:equatable/equatable.dart';

import '../../../data/models/partido_model.dart';

/// Estados del BLoC de partido
/// E004-HU-001: Iniciar Partido
abstract class PartidoState extends Equatable {
  const PartidoState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - Sin datos cargados
class PartidoInitial extends PartidoState {
  const PartidoInitial();
}

/// Estado de carga - Obteniendo datos del servidor
class PartidoLoading extends PartidoState {
  const PartidoLoading();
}

/// CA-004, CA-006: Estado sin partido activo - Puede iniciar uno nuevo
class SinPartidoActivo extends PartidoState {
  /// Indica si puede iniciar un nuevo partido
  final bool puedeIniciarPartido;

  /// ID de la fecha actual
  final String fechaId;

  /// Mensaje informativo
  final String message;

  const SinPartidoActivo({
    this.puedeIniciarPartido = true,
    required this.fechaId,
    this.message = 'No hay partido activo',
  });

  @override
  List<Object?> get props => [puedeIniciarPartido, fechaId, message];
}

/// CA-003, CA-004: Estado con partido en curso
/// El temporizador esta activo y contando
class PartidoEnCurso extends PartidoState {
  /// Datos del partido
  final PartidoModel partido;

  /// Indica si puede pausar (solo admin)
  final bool puedePausar;

  /// Mensaje informativo
  final String message;

  const PartidoEnCurso({
    required this.partido,
    this.puedePausar = false,
    this.message = '',
  });

  /// Tiempo restante formateado (MM:SS)
  String get tiempoRestanteDisplay => partido.tiempoRestanteDisplay;

  /// Nombre del enfrentamiento
  String get enfrentamientoDisplay => partido.enfrentamientoDisplay;

  /// Indica si el tiempo ya termino
  bool get tiempoTerminado => partido.tiempoTerminado;

  @override
  List<Object?> get props => [partido, puedePausar, message];
}

/// CA-005: Estado con partido pausado
class PartidoPausado extends PartidoState {
  /// Datos del partido
  final PartidoModel partido;

  /// Indica si puede reanudar (solo admin)
  final bool puedeReanudar;

  /// Mensaje informativo
  final String message;

  const PartidoPausado({
    required this.partido,
    this.puedeReanudar = false,
    this.message = '',
  });

  /// Tiempo restante formateado (MM:SS)
  String get tiempoRestanteDisplay => partido.tiempoRestanteDisplay;

  /// Nombre del enfrentamiento
  String get enfrentamientoDisplay => partido.enfrentamientoDisplay;

  @override
  List<Object?> get props => [partido, puedeReanudar, message];
}

/// Estado de procesamiento - Iniciando, pausando o reanudando partido
class PartidoProcesando extends PartidoState {
  /// Partido actual (si existe)
  final PartidoModel? partido;

  /// Tipo de operacion en curso
  final String operacion;

  const PartidoProcesando({
    this.partido,
    required this.operacion,
  });

  @override
  List<Object?> get props => [partido, operacion];
}

/// Estado de error
class PartidoError extends PartidoState {
  /// Mensaje de error para mostrar al usuario
  final String message;

  /// Codigo de error del backend (opcional)
  final String? code;

  /// Hint del backend para identificar tipo de error
  /// Valores posibles:
  /// - no_autenticado: Usuario no ha iniciado sesion
  /// - sin_permisos: Usuario no es admin aprobado (RN-001)
  /// - fecha_no_encontrada: La fecha no existe
  /// - fecha_no_en_juego: La fecha no esta en estado en_juego (RN-002)
  /// - partido_activo_existe: Ya hay un partido en_curso o pausado (RN-005)
  /// - equipo_local_sin_jugadores: Equipo local sin jugadores (RN-003)
  /// - equipo_visitante_sin_jugadores: Equipo visitante sin jugadores (RN-003)
  /// - equipos_iguales: Mismo equipo como local y visitante (RN-006)
  /// - partido_no_encontrado: El partido no existe
  /// - partido_no_en_curso: El partido no esta en_curso (para pausar)
  /// - partido_no_pausado: El partido no esta pausado (para reanudar)
  final String? hint;

  /// Partido actual (si existia antes del error)
  final PartidoModel? partido;

  /// ID de la fecha (para reintentar)
  final String? fechaId;

  const PartidoError({
    required this.message,
    this.code,
    this.hint,
    this.partido,
    this.fechaId,
  });

  /// RN-001: Error por usuario sin permisos
  bool get esSinPermisos => hint == 'sin_permisos';

  /// RN-002: Error por fecha no en juego
  bool get esFechaNoEnJuego => hint == 'fecha_no_en_juego';

  /// RN-005: Error por partido activo existente
  bool get esPartidoActivoExiste => hint == 'partido_activo_existe';

  /// RN-003: Error por equipo sin jugadores
  bool get esEquipoSinJugadores =>
      hint == 'equipo_local_sin_jugadores' ||
      hint == 'equipo_visitante_sin_jugadores';

  /// RN-006: Error por equipos iguales
  bool get esEquiposIguales => hint == 'equipos_iguales';

  @override
  List<Object?> get props => [message, code, hint, partido, fechaId];
}
