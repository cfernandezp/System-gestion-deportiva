import 'package:equatable/equatable.dart';

/// Eventos del BLoC de Detalle de Fecha
/// E006-HU-004: Detalle de resultados de una fecha
abstract class DetalleFechaEvent extends Equatable {
  const DetalleFechaEvent();

  @override
  List<Object?> get props => [];
}

/// CA-002: Cargar detalle de una fecha especifica
class CargarDetalleFechaEvent extends DetalleFechaEvent {
  final String fechaId;
  final String grupoId;

  const CargarDetalleFechaEvent({
    required this.fechaId,
    required this.grupoId,
  });

  @override
  List<Object?> get props => [fechaId, grupoId];
}
