import 'package:equatable/equatable.dart';

/// Eventos del BLoC de Resultados por Fecha
/// E006-HU-004: Historial de fechas finalizadas
abstract class ResultadosFechaEvent extends Equatable {
  const ResultadosFechaEvent();

  @override
  List<Object?> get props => [];
}

/// CA-001: Cargar historial de fechas finalizadas
class CargarHistorialFechasEvent extends ResultadosFechaEvent {
  final String grupoId;
  final int? anio;
  final int? mes;
  final bool soloMias;

  const CargarHistorialFechasEvent({
    required this.grupoId,
    this.anio,
    this.mes,
    this.soloMias = false,
  });

  @override
  List<Object?> get props => [grupoId, anio, mes, soloMias];
}

/// CA-007: Cambiar filtros del historial
class CambiarFiltroEvent extends ResultadosFechaEvent {
  final int? anio;
  final int? mes;
  final bool? soloMias;

  const CambiarFiltroEvent({
    this.anio,
    this.mes,
    this.soloMias,
  });

  @override
  List<Object?> get props => [anio, mes, soloMias];
}
