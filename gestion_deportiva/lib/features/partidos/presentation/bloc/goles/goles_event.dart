import 'package:equatable/equatable.dart';

/// Eventos del BLoC de goles
/// E004-HU-003: Registrar Gol
abstract class GolesEvent extends Equatable {
  const GolesEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar goles de un partido
class CargarGolesEvent extends GolesEvent {
  /// ID del partido
  final String partidoId;

  const CargarGolesEvent({required this.partidoId});

  @override
  List<Object?> get props => [partidoId];
}

/// CA-001, CA-002, CA-003: Evento para registrar un gol
/// CA-004: Soporte para autogol
/// CA-006: Minuto automatico
/// CA-007: jugadorId null = gol sin asignar
/// RN-001 a RN-008: Validaciones en backend
class RegistrarGolEvent extends GolesEvent {
  /// ID del partido
  final String partidoId;

  /// Color del equipo que anota (recibe el punto)
  final String equipoAnotador;

  /// ID del jugador que anoto (null = sin asignar)
  final String? jugadorId;

  /// Si es autogol (gol en contra)
  final bool esAutogol;

  const RegistrarGolEvent({
    required this.partidoId,
    required this.equipoAnotador,
    this.jugadorId,
    this.esAutogol = false,
  });

  @override
  List<Object?> get props => [partidoId, equipoAnotador, jugadorId, esAutogol];
}

/// CA-005: Evento para eliminar/deshacer un gol
/// RN-005: Ventana de deshacer de 30 segundos
class EliminarGolEvent extends GolesEvent {
  /// ID del gol a eliminar
  final String golId;

  const EliminarGolEvent({required this.golId});

  @override
  List<Object?> get props => [golId];
}

/// Evento para limpiar el estado del ultimo gol registrado
/// Usado despues de mostrar confirmacion al usuario
class LimpiarUltimoGolEvent extends GolesEvent {
  const LimpiarUltimoGolEvent();
}

/// Evento para reiniciar el estado del bloc
class ResetGolesEvent extends GolesEvent {
  const ResetGolesEvent();
}
