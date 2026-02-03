import 'package:equatable/equatable.dart';

/// Eventos del BLoC de resumen de jornada
/// E004-HU-007: Resumen de Jornada
abstract class ResumenJornadaEvent extends Equatable {
  const ResumenJornadaEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar el resumen de una jornada
/// CA-001: Mostrar tabla de posiciones
/// CA-002: Mostrar estadisticas
/// CA-003: Mostrar goleadores
class CargarResumenJornada extends ResumenJornadaEvent {
  /// ID de la fecha/jornada
  final String fechaId;

  const CargarResumenJornada({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// Evento para refrescar el resumen (pull to refresh)
class RefrescarResumen extends ResumenJornadaEvent {
  /// ID de la fecha/jornada
  final String fechaId;

  const RefrescarResumen({required this.fechaId});

  @override
  List<Object?> get props => [fechaId];
}

/// Evento para reiniciar el estado del bloc
class ResetResumenJornada extends ResumenJornadaEvent {
  const ResetResumenJornada();
}
