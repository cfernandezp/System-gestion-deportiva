import 'package:equatable/equatable.dart';

/// Eventos del BLoC de editar fecha
/// E003-HU-008: Editar Fecha
abstract class EditarFechaEvent extends Equatable {
  const EditarFechaEvent();

  @override
  List<Object?> get props => [];
}

/// CA-003: Evento para editar una fecha de pichanga
/// Parametros segun RPC backend:
/// - fechaId: UUID de la fecha a editar
/// - fechaHoraInicio: Nueva fecha y hora de inicio
/// - duracionHoras: Nueva duracion en horas (1, 1.5, 2, ..., 5)
/// - lugar: Nuevo lugar (minimo 3 caracteres)
/// - numEquipos: Numero de equipos (2-4)
/// - costoPorJugador: Costo por jugador en soles (0-100)
class EditarFechaSubmitEvent extends EditarFechaEvent {
  /// ID de la fecha a editar (p_fecha_id)
  final String fechaId;

  /// Nueva fecha y hora de inicio (p_fecha_hora_inicio)
  /// RN-004: Debe ser futura
  final DateTime fechaHoraInicio;

  /// Nueva duracion en horas (p_duracion_horas)
  final double duracionHoras;

  /// Nuevo lugar de la pichanga (p_lugar)
  /// Minimo 3 caracteres
  final String lugar;

  /// Numero de equipos (2-4)
  final int numEquipos;

  /// Costo por jugador en soles (0-100)
  final double costoPorJugador;

  const EditarFechaSubmitEvent({
    required this.fechaId,
    required this.fechaHoraInicio,
    required this.duracionHoras,
    required this.lugar,
    required this.numEquipos,
    required this.costoPorJugador,
  });

  @override
  List<Object?> get props => [fechaId, fechaHoraInicio, duracionHoras, lugar, numEquipos, costoPorJugador];
}

/// Evento para reiniciar el estado del formulario
class EditarFechaResetEvent extends EditarFechaEvent {
  const EditarFechaResetEvent();
}

/// Evento para inicializar el formulario con datos actuales de la fecha
/// CA-003: Formulario precargado con valores actuales
class EditarFechaInicializarEvent extends EditarFechaEvent {
  /// ID de la fecha
  final String fechaId;

  /// Fecha y hora actual
  final DateTime fechaHoraInicio;

  /// Duracion actual
  final double duracionHoras;

  /// Lugar actual
  final String lugar;

  /// Numero de equipos actual
  final int numEquipos;

  /// Costo actual
  final double costoActual;

  /// Total de inscritos (para mostrar advertencia)
  final int totalInscritos;

  const EditarFechaInicializarEvent({
    required this.fechaId,
    required this.fechaHoraInicio,
    required this.duracionHoras,
    required this.lugar,
    required this.numEquipos,
    required this.costoActual,
    required this.totalInscritos,
  });

  @override
  List<Object?> get props => [
        fechaId,
        fechaHoraInicio,
        duracionHoras,
        lugar,
        numEquipos,
        costoActual,
        totalInscritos,
      ];
}
