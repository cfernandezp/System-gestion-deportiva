import 'package:equatable/equatable.dart';

import '../../../data/models/finalizar_fecha_response_model.dart';

/// Estados del BLoC de finalizar fecha
/// E003-HU-010: Finalizar Fecha
abstract class FinalizarFechaState extends Equatable {
  const FinalizarFechaState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial del BLoC
class FinalizarFechaInitial extends FinalizarFechaState {
  const FinalizarFechaInitial();
}

/// Estado de carga mientras se procesa la finalizacion
class FinalizarFechaLoading extends FinalizarFechaState {
  const FinalizarFechaLoading();
}

/// Estado de exito cuando la fecha fue finalizada
/// CA-006: Estado actualizado a finalizada con mensaje de exito
class FinalizarFechaSuccess extends FinalizarFechaState {
  /// Datos de la fecha finalizada
  final FinalizarFechaDataModel data;

  /// Mensaje de confirmacion del servidor
  final String message;

  const FinalizarFechaSuccess({
    required this.data,
    required this.message,
  });

  @override
  List<Object?> get props => [data, message];
}

/// Estado de error cuando falla la finalizacion
/// Incluye hints del backend para mensajes contextuales
class FinalizarFechaError extends FinalizarFechaState {
  /// Mensaje de error
  final String message;

  /// Codigo de error (opcional)
  final String? code;

  /// Hint para identificar el tipo de error
  /// Valores posibles: no_autenticado, fecha_id_requerido, usuario_no_encontrado,
  /// sin_permisos, fecha_no_encontrada, estado_invalido, descripcion_incidente_requerida
  final String? hint;

  const FinalizarFechaError({
    required this.message,
    this.code,
    this.hint,
  });

  @override
  List<Object?> get props => [message, code, hint];
}
