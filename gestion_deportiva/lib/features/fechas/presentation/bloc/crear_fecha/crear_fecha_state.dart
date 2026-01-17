import 'package:equatable/equatable.dart';

import '../../../data/models/fecha_model.dart';

/// Estados del BLoC de crear fecha
/// E003-HU-001: Crear Fecha
abstract class CrearFechaState extends Equatable {
  const CrearFechaState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - Formulario listo para llenar
class CrearFechaInitial extends CrearFechaState {
  const CrearFechaInitial();
}

/// Estado de carga - Enviando datos al servidor
class CrearFechaLoading extends CrearFechaState {
  const CrearFechaLoading();
}

/// CA-006: Estado de exito - Fecha creada correctamente
/// Contiene la fecha creada con todos sus datos
class CrearFechaSuccess extends CrearFechaState {
  /// Fecha creada con datos completos del backend
  final FechaModel fecha;

  /// Mensaje de confirmacion del servidor
  /// CA-007: Incluye confirmacion de notificacion a jugadores
  final String message;

  const CrearFechaSuccess({
    required this.fecha,
    required this.message,
  });

  @override
  List<Object?> get props => [fecha, message];
}

/// Estado de error - Fallo al crear la fecha
/// Maneja todos los errores de backend (CA-004, RN-001 a RN-005)
class CrearFechaError extends CrearFechaState {
  /// Mensaje de error para mostrar al usuario
  final String message;

  /// Codigo de error del backend (opcional)
  final String? code;

  /// Hint del backend para identificar tipo de error
  /// Valores posibles:
  /// - no_autenticado: Usuario no ha iniciado sesion
  /// - usuario_no_encontrado: Usuario no existe
  /// - sin_permisos: No es admin aprobado (RN-001)
  /// - fecha_requerida: Fecha/hora no proporcionada
  /// - duracion_requerida: Duracion no proporcionada
  /// - duracion_invalida: Duracion no es 1 o 2 (RN-002)
  /// - lugar_invalido: Lugar vacio o muy corto (CA-005)
  /// - fecha_pasada: Fecha/hora no es futura (CA-004, RN-004)
  /// - fecha_duplicada: Ya existe fecha en ese horario (RN-005)
  final String? hint;

  const CrearFechaError({
    required this.message,
    this.code,
    this.hint,
  });

  /// Verifica si el error es de permisos (RN-001)
  bool get esSinPermisos => hint == 'sin_permisos';

  /// Verifica si el error es por fecha pasada (CA-004)
  bool get esFechaPasada => hint == 'fecha_pasada';

  /// Verifica si el error es por fecha duplicada (RN-005)
  bool get esFechaDuplicada => hint == 'fecha_duplicada';

  @override
  List<Object?> get props => [message, code, hint];
}
