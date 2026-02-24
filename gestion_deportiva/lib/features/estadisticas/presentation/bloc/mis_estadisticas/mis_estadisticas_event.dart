import 'package:equatable/equatable.dart';

/// Eventos del BLoC de Mis Estadisticas
/// E006-HU-003: Dashboard personal
abstract class MisEstadisticasEvent extends Equatable {
  const MisEstadisticasEvent();

  @override
  List<Object?> get props => [];
}

/// CA-001: Cargar mis estadisticas del grupo activo
class CargarMisEstadisticasEvent extends MisEstadisticasEvent {
  final String grupoId;

  const CargarMisEstadisticasEvent({required this.grupoId});

  @override
  List<Object?> get props => [grupoId];
}
