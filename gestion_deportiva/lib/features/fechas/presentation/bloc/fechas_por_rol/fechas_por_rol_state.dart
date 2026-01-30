import 'package:equatable/equatable.dart';

import '../../../data/models/listar_fechas_por_rol_response_model.dart';

/// Estados del BLoC de fechas por rol
/// E003-HU-009: Listar Fechas por Rol
abstract class FechasPorRolState extends Equatable {
  const FechasPorRolState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - Sin datos cargados
class FechasPorRolInitial extends FechasPorRolState {
  const FechasPorRolInitial();
}

/// Estado de carga - Obteniendo lista de fechas
class FechasPorRolLoading extends FechasPorRolState {
  const FechasPorRolLoading();
}

/// Estado con lista de fechas cargadas exitosamente
class FechasPorRolLoaded extends FechasPorRolState {
  /// Lista de fechas
  final List<FechaPorRolModel> fechas;

  /// Seccion actual: 'proximas', 'pasadas', 'todas'
  final String seccion;

  /// Total de fechas encontradas
  final int total;

  /// Indica si el usuario es admin
  final bool esAdmin;

  /// Mensaje del servidor
  final String message;

  /// Filtros aplicados (solo admin)
  final FiltrosAplicadosModel? filtrosAplicados;

  const FechasPorRolLoaded({
    required this.fechas,
    required this.seccion,
    required this.total,
    required this.esAdmin,
    required this.message,
    this.filtrosAplicados,
  });

  /// Indica si hay fechas
  bool get hayFechas => fechas.isNotEmpty;

  /// Fechas donde el usuario esta inscrito
  List<FechaPorRolModel> get fechasInscritas =>
      fechas.where((f) => f.usuarioInscrito).toList();

  /// Fechas donde el usuario puede inscribirse
  List<FechaPorRolModel> get fechasParaInscribirse =>
      fechas.where((f) => f.puedeInscribirse).toList();

  /// Indica si hay filtros activos
  bool get hayFiltrosActivos =>
      filtrosAplicados != null && filtrosAplicados!.hayFiltros;

  @override
  List<Object?> get props =>
      [fechas, seccion, total, esAdmin, message, filtrosAplicados];
}

/// Estado sin fechas - Lista vacia
class FechasPorRolEmpty extends FechasPorRolState {
  /// Seccion actual
  final String seccion;

  /// Mensaje descriptivo
  final String message;

  /// Indica si el usuario es admin
  final bool esAdmin;

  const FechasPorRolEmpty({
    required this.seccion,
    required this.message,
    this.esAdmin = false,
  });

  @override
  List<Object?> get props => [seccion, message, esAdmin];
}

/// Estado de refrescando - Manteniendo datos anteriores
class FechasPorRolRefreshing extends FechasPorRolState {
  /// Lista de fechas actual (mientras se refresca)
  final List<FechaPorRolModel> fechasActuales;

  /// Seccion actual
  final String seccion;

  /// Indica si el usuario es admin
  final bool esAdmin;

  const FechasPorRolRefreshing({
    required this.fechasActuales,
    required this.seccion,
    required this.esAdmin,
  });

  @override
  List<Object?> get props => [fechasActuales, seccion, esAdmin];
}

/// Estado de error - Fallo al cargar fechas
class FechasPorRolError extends FechasPorRolState {
  /// Mensaje de error para mostrar al usuario
  final String message;

  /// Codigo de error del backend (opcional)
  final String? code;

  /// Hint del backend para identificar tipo de error
  final String? hint;

  /// Seccion que se intento cargar
  final String? seccion;

  /// Fechas anteriores (si se tenia antes del error)
  final List<FechaPorRolModel>? fechasAnteriores;

  const FechasPorRolError({
    required this.message,
    this.code,
    this.hint,
    this.seccion,
    this.fechasAnteriores,
  });

  /// Indica si hay datos anteriores para mostrar
  bool get hayDatosAnteriores =>
      fechasAnteriores != null && fechasAnteriores!.isNotEmpty;

  @override
  List<Object?> get props =>
      [message, code, hint, seccion, fechasAnteriores];
}
