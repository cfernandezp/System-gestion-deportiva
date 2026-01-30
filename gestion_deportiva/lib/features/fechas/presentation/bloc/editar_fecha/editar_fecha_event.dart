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
/// - duracionHoras: Nueva duracion (1 o 2 horas)
/// - lugar: Nuevo lugar (minimo 3 caracteres)
class EditarFechaSubmitEvent extends EditarFechaEvent {
  /// ID de la fecha a editar (p_fecha_id)
  final String fechaId;

  /// Nueva fecha y hora de inicio (p_fecha_hora_inicio)
  /// RN-004: Debe ser futura
  final DateTime fechaHoraInicio;

  /// Nueva duracion en horas (p_duracion_horas)
  /// RN-003: Solo 1 o 2 horas permitidas
  final int duracionHoras;

  /// Nuevo lugar de la pichanga (p_lugar)
  /// Minimo 3 caracteres
  final String lugar;

  const EditarFechaSubmitEvent({
    required this.fechaId,
    required this.fechaHoraInicio,
    required this.duracionHoras,
    required this.lugar,
  });

  @override
  List<Object?> get props => [fechaId, fechaHoraInicio, duracionHoras, lugar];
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
  final int duracionHoras;

  /// Lugar actual
  final String lugar;

  /// Costo actual (para mostrar advertencia si cambia)
  final double costoActual;

  /// Total de inscritos (para mostrar advertencia)
  final int totalInscritos;

  const EditarFechaInicializarEvent({
    required this.fechaId,
    required this.fechaHoraInicio,
    required this.duracionHoras,
    required this.lugar,
    required this.costoActual,
    required this.totalInscritos,
  });

  @override
  List<Object?> get props => [
        fechaId,
        fechaHoraInicio,
        duracionHoras,
        lugar,
        costoActual,
        totalInscritos,
      ];
}
