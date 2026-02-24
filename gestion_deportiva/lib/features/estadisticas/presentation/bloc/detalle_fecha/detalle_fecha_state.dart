import 'package:equatable/equatable.dart';

import '../../../data/models/resultados_fecha_model.dart';

/// Estados del BLoC de Detalle de Fecha
/// E006-HU-004: Detalle de resultados de una fecha
abstract class DetalleFechaState extends Equatable {
  const DetalleFechaState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class DetalleFechaInitial extends DetalleFechaState {
  const DetalleFechaInitial();
}

/// Cargando detalle de la fecha
class DetalleFechaLoading extends DetalleFechaState {
  const DetalleFechaLoading();
}

/// CA-002 a CA-006: Detalle cargado exitosamente
class DetalleFechaLoaded extends DetalleFechaState {
  final DetalleFechaResultadosModel detalle;

  const DetalleFechaLoaded({required this.detalle});

  @override
  List<Object?> get props => [detalle];
}

/// Error al cargar detalle
class DetalleFechaError extends DetalleFechaState {
  final String message;
  final String? hint;

  const DetalleFechaError({required this.message, this.hint});

  @override
  List<Object?> get props => [message, hint];
}
