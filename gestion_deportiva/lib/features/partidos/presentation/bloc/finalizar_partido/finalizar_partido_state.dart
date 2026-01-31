import 'package:equatable/equatable.dart';

import '../../../data/models/finalizar_partido_response_model.dart';

/// Estados del BLoC de finalizar partido
/// E004-HU-005: Finalizar Partido
abstract class FinalizarPartidoState extends Equatable {
  const FinalizarPartidoState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - Sin accion pendiente
class FinalizarPartidoInitial extends FinalizarPartidoState {
  const FinalizarPartidoInitial();
}

/// Estado de carga - Procesando finalizacion
class FinalizarPartidoLoading extends FinalizarPartidoState {
  const FinalizarPartidoLoading();
}

/// CA-006: Estado que requiere confirmacion
/// Se emite cuando el usuario intenta finalizar antes de tiempo
class FinalizarPartidoRequiereConfirmacion extends FinalizarPartidoState {
  /// ID del partido pendiente de confirmar
  final String partidoId;

  /// Mensaje informativo
  final String message;

  const FinalizarPartidoRequiereConfirmacion({
    required this.partidoId,
    this.message = 'El tiempo del partido aun no ha terminado',
  });

  @override
  List<Object?> get props => [partidoId, message];
}

/// CA-005: Estado de exito con resumen del partido
/// Contiene marcador, goleadores, duracion y sugerencia (si aplica)
class FinalizarPartidoSuccess extends FinalizarPartidoState {
  /// Respuesta completa con resumen del partido
  final FinalizarPartidoResponseModel response;

  const FinalizarPartidoSuccess({required this.response});

  /// Indica si se finalizo anticipadamente
  bool get finalizadoAnticipado => response.finalizadoAnticipado;

  /// CA-004: Indica si hay sugerencia de siguiente partido
  bool get tieneSugerenciaSiguiente => response.tieneSugerenciaSiguiente;

  /// CA-005: Marcador final
  MarcadorFinalModel? get marcador => response.marcador;

  /// CA-005: Resultado del partido
  ResultadoPartidoModel? get resultado => response.resultado;

  /// CA-005: Lista de goleadores
  GoleadoresModel? get goleadores => response.goleadores;

  /// CA-005: Duracion del partido
  DuracionPartidoModel? get duracion => response.duracion;

  /// CA-004: Sugerencia de siguiente partido (3 equipos)
  SugerenciaSiguienteModel? get sugerenciaSiguiente =>
      response.sugerenciaSiguiente;

  @override
  List<Object?> get props => [response];
}

/// Estado de error
class FinalizarPartidoError extends FinalizarPartidoState {
  /// Mensaje de error para mostrar al usuario
  final String message;

  /// Codigo de error del backend (opcional)
  final String? code;

  /// Hint del backend para identificar tipo de error
  /// Valores posibles:
  /// - no_autenticado: Usuario no ha iniciado sesion
  /// - sin_permisos: Usuario no es admin aprobado
  /// - partido_no_encontrado: El partido no existe
  /// - partido_no_en_curso: El partido no esta en_curso ni pausado
  /// - requiere_confirmacion: Tiempo no terminado, necesita confirmar
  final String? hint;

  /// ID del partido (para reintentar)
  final String? partidoId;

  const FinalizarPartidoError({
    required this.message,
    this.code,
    this.hint,
    this.partidoId,
  });

  /// Error por requerir confirmacion anticipada
  bool get esRequiereConfirmacion => hint == 'requiere_confirmacion';

  /// Error por usuario sin permisos
  bool get esSinPermisos => hint == 'sin_permisos';

  /// Error por partido no encontrado
  bool get esPartidoNoEncontrado => hint == 'partido_no_encontrado';

  @override
  List<Object?> get props => [message, code, hint, partidoId];
}
