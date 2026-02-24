import 'package:equatable/equatable.dart';

import '../../../data/models/estadisticas_mensuales_model.dart';

/// Estados del BLoC de Estadisticas Mensuales
/// E006-HU-005: Estadisticas agregadas por mes
abstract class EstadisticasMensualesState extends Equatable {
  const EstadisticasMensualesState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class EstadisticasMensualesInitial extends EstadisticasMensualesState {
  const EstadisticasMensualesInitial();
}

/// Cargando estadisticas mensuales
class EstadisticasMensualesLoading extends EstadisticasMensualesState {
  const EstadisticasMensualesLoading();
}

/// CA-001 a CA-008: Estadisticas mensuales cargadas exitosamente
class EstadisticasMensualesLoaded extends EstadisticasMensualesState {
  final EstadisticasMensualesResponseModel estadisticas;
  final int anioSeleccionado;
  final int mesSeleccionado;

  const EstadisticasMensualesLoaded({
    required this.estadisticas,
    required this.anioSeleccionado,
    required this.mesSeleccionado,
  });

  @override
  List<Object?> get props => [estadisticas, anioSeleccionado, mesSeleccionado];
}

/// Error al cargar estadisticas mensuales
class EstadisticasMensualesError extends EstadisticasMensualesState {
  final String message;
  final String? hint;

  const EstadisticasMensualesError({required this.message, this.hint});

  @override
  List<Object?> get props => [message, hint];
}
