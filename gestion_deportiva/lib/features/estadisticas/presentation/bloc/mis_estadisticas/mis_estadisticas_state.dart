import 'package:equatable/equatable.dart';

import '../../../data/models/mis_estadisticas_model.dart';

/// Estados del BLoC de Mis Estadisticas
/// E006-HU-003: Dashboard personal
abstract class MisEstadisticasState extends Equatable {
  const MisEstadisticasState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class MisEstadisticasInitial extends MisEstadisticasState {
  const MisEstadisticasInitial();
}

/// Cargando estadisticas
class MisEstadisticasLoading extends MisEstadisticasState {
  const MisEstadisticasLoading();
}

/// CA-001 a CA-008: Estadisticas cargadas exitosamente
class MisEstadisticasLoaded extends MisEstadisticasState {
  final MisEstadisticasResponseModel estadisticas;

  const MisEstadisticasLoaded({required this.estadisticas});

  @override
  List<Object?> get props => [estadisticas];
}

/// Error al cargar estadisticas
class MisEstadisticasError extends MisEstadisticasState {
  final String message;
  final String? hint;

  const MisEstadisticasError({required this.message, this.hint});

  @override
  List<Object?> get props => [message, hint];
}
