import 'package:equatable/equatable.dart';

import '../../../data/models/resultados_fecha_model.dart';

/// Estados del BLoC de Resultados por Fecha
/// E006-HU-004: Historial de fechas finalizadas
abstract class ResultadosFechaState extends Equatable {
  const ResultadosFechaState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ResultadosFechaInitial extends ResultadosFechaState {
  const ResultadosFechaInitial();
}

/// Cargando historial de fechas
class ResultadosFechaLoading extends ResultadosFechaState {
  const ResultadosFechaLoading();
}

/// CA-001, CA-007: Historial de fechas cargado exitosamente
class HistorialFechasLoaded extends ResultadosFechaState {
  final HistorialFechasResponseModel historial;
  final int? anioActual;
  final int? mesActual;
  final bool soloMias;

  const HistorialFechasLoaded({
    required this.historial,
    this.anioActual,
    this.mesActual,
    this.soloMias = false,
  });

  @override
  List<Object?> get props => [historial, anioActual, mesActual, soloMias];
}

/// Error al cargar historial
class ResultadosFechaError extends ResultadosFechaState {
  final String message;
  final String? hint;

  const ResultadosFechaError({required this.message, this.hint});

  @override
  List<Object?> get props => [message, hint];
}
