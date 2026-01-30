import 'package:equatable/equatable.dart';

/// Eventos del BLoC de fechas por rol
/// E003-HU-009: Listar Fechas por Rol
abstract class FechasPorRolEvent extends Equatable {
  const FechasPorRolEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar fechas segun rol del usuario
/// Parametros:
/// - seccion: 'proximas', 'pasadas', 'todas' (default: 'proximas')
/// - filtroEstado: Estado especifico a filtrar (solo admin)
/// - fechaDesde: Fecha minima del rango (solo admin)
/// - fechaHasta: Fecha maxima del rango (solo admin)
class CargarFechasPorRolEvent extends FechasPorRolEvent {
  /// Seccion a mostrar: 'proximas', 'pasadas', 'todas'
  final String seccion;

  /// Filtro por estado (opcional, solo admin)
  final String? filtroEstado;

  /// Fecha desde para filtrar (opcional, solo admin)
  final DateTime? fechaDesde;

  /// Fecha hasta para filtrar (opcional, solo admin)
  final DateTime? fechaHasta;

  const CargarFechasPorRolEvent({
    this.seccion = 'proximas',
    this.filtroEstado,
    this.fechaDesde,
    this.fechaHasta,
  });

  @override
  List<Object?> get props => [seccion, filtroEstado, fechaDesde, fechaHasta];
}

/// Evento para cambiar la seccion actual
/// Recarga automaticamente las fechas de la nueva seccion
class CambiarSeccionEvent extends FechasPorRolEvent {
  /// Nueva seccion a mostrar: 'proximas', 'pasadas', 'todas'
  final String seccion;

  const CambiarSeccionEvent({required this.seccion});

  @override
  List<Object?> get props => [seccion];
}

/// Evento para refrescar la lista de fechas
/// Mantiene los filtros y seccion actuales
class RefrescarFechasEvent extends FechasPorRolEvent {
  const RefrescarFechasEvent();
}

/// Evento para aplicar filtros (solo admin)
class AplicarFiltrosEvent extends FechasPorRolEvent {
  /// Filtro por estado (opcional)
  final String? filtroEstado;

  /// Fecha desde para filtrar (opcional)
  final DateTime? fechaDesde;

  /// Fecha hasta para filtrar (opcional)
  final DateTime? fechaHasta;

  const AplicarFiltrosEvent({
    this.filtroEstado,
    this.fechaDesde,
    this.fechaHasta,
  });

  @override
  List<Object?> get props => [filtroEstado, fechaDesde, fechaHasta];
}

/// Evento para limpiar filtros
class LimpiarFiltrosEvent extends FechasPorRolEvent {
  const LimpiarFiltrosEvent();
}

/// Evento para reiniciar el estado del bloc
class ResetFechasPorRolEvent extends FechasPorRolEvent {
  const ResetFechasPorRolEvent();
}
