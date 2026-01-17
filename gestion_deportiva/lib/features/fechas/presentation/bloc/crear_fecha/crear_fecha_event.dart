import 'package:equatable/equatable.dart';

/// Eventos del BLoC de crear fecha
/// E003-HU-001: Crear Fecha
abstract class CrearFechaEvent extends Equatable {
  const CrearFechaEvent();

  @override
  List<Object?> get props => [];
}

/// CA-006: Evento para crear una fecha de pichanga
class CrearFechaSubmitEvent extends CrearFechaEvent {
  /// Fecha y hora de inicio (CA-002, RN-004)
  final DateTime fechaHoraInicio;

  /// Duracion en horas (CA-002)
  final int duracionHoras;

  /// Nombre de cancha o direccion (CA-005)
  final String lugar;

  /// Numero de equipos (2-4)
  final int numEquipos;

  /// Costo por jugador en soles
  final double costoPorJugador;

  const CrearFechaSubmitEvent({
    required this.fechaHoraInicio,
    required this.duracionHoras,
    required this.lugar,
    required this.numEquipos,
    required this.costoPorJugador,
  });

  @override
  List<Object?> get props => [
        fechaHoraInicio,
        duracionHoras,
        lugar,
        numEquipos,
        costoPorJugador,
      ];
}

/// Evento para reiniciar el estado del formulario
class CrearFechaResetEvent extends CrearFechaEvent {
  const CrearFechaResetEvent();
}
