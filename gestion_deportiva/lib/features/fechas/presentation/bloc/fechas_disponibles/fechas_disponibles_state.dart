import 'package:equatable/equatable.dart';

import '../../../data/models/fecha_disponible_model.dart';

/// Estados del BLoC de fechas disponibles
/// E003-HU-002: Inscribirse a Fecha
abstract class FechasDisponiblesState extends Equatable {
  const FechasDisponiblesState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - Sin datos cargados
class FechasDisponiblesInitial extends FechasDisponiblesState {
  const FechasDisponiblesInitial();
}

/// Estado de carga - Obteniendo lista de fechas
class FechasDisponiblesLoading extends FechasDisponiblesState {
  const FechasDisponiblesLoading();
}

/// Estado con lista de fechas disponibles cargadas
/// RN-002: Solo muestra fechas con estado 'abierta'
class FechasDisponiblesCargadas extends FechasDisponiblesState {
  /// Lista de fechas disponibles
  final List<FechaDisponibleModel> fechas;

  /// Total de fechas encontradas
  final int total;

  const FechasDisponiblesCargadas({
    required this.fechas,
    required this.total,
  });

  /// Indica si hay fechas disponibles
  bool get hayFechas => fechas.isNotEmpty;

  /// Fechas donde el usuario puede inscribirse
  List<FechaDisponibleModel> get fechasParaInscribirse =>
      fechas.where((f) => f.puedeInscribirse).toList();

  /// Fechas donde el usuario ya esta inscrito
  List<FechaDisponibleModel> get fechasInscritas =>
      fechas.where((f) => f.usuarioInscrito).toList();

  @override
  List<Object?> get props => [fechas, total];
}

/// Estado de refrescando - Manteniendo datos anteriores
class FechasDisponiblesRefrescando extends FechasDisponiblesState {
  /// Lista de fechas actual (mientras se refresca)
  final List<FechaDisponibleModel> fechasActuales;

  const FechasDisponiblesRefrescando({required this.fechasActuales});

  @override
  List<Object?> get props => [fechasActuales];
}

/// Estado de error - Fallo al cargar fechas
class FechasDisponiblesError extends FechasDisponiblesState {
  /// Mensaje de error para mostrar al usuario
  final String message;

  /// Codigo de error del backend (opcional)
  final String? code;

  /// Hint del backend para identificar tipo de error
  final String? hint;

  /// Fechas anteriores (si se tenia antes del error)
  final List<FechaDisponibleModel>? fechasAnteriores;

  const FechasDisponiblesError({
    required this.message,
    this.code,
    this.hint,
    this.fechasAnteriores,
  });

  /// Indica si hay datos anteriores para mostrar
  bool get hayDatosAnteriores =>
      fechasAnteriores != null && fechasAnteriores!.isNotEmpty;

  @override
  List<Object?> get props => [message, code, hint, fechasAnteriores];
}
