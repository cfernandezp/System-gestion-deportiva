import 'package:equatable/equatable.dart';

/// Eventos del BLoC de Estadisticas Mensuales
/// E006-HU-005: Estadisticas agregadas por mes
abstract class EstadisticasMensualesEvent extends Equatable {
  const EstadisticasMensualesEvent();

  @override
  List<Object?> get props => [];
}

/// CA-001: Cargar estadisticas mensuales del grupo activo
/// Si anio y mes son null, carga el mes actual
class CargarEstadisticasMensualesEvent extends EstadisticasMensualesEvent {
  final String grupoId;
  final int? anio;
  final int? mes;

  const CargarEstadisticasMensualesEvent({
    required this.grupoId,
    this.anio,
    this.mes,
  });

  @override
  List<Object?> get props => [grupoId, anio, mes];
}

/// CA-001: Cambiar mes seleccionado
class CambiarMesEvent extends EstadisticasMensualesEvent {
  final String grupoId;
  final int anio;
  final int mes;

  const CambiarMesEvent({
    required this.grupoId,
    required this.anio,
    required this.mes,
  });

  @override
  List<Object?> get props => [grupoId, anio, mes];
}
