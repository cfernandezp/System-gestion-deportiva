import 'package:equatable/equatable.dart';

import '../../../data/models/inscrito_fecha_model.dart';
import '../../../data/models/inscritos_response_model.dart';

/// Estados del BLoC de inscritos a fechas
/// E003-HU-003: Ver Inscritos
abstract class InscritosState extends Equatable {
  const InscritosState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - Sin datos cargados
class InscritosInitial extends InscritosState {
  const InscritosInitial();
}

/// Estado de carga - Obteniendo lista de inscritos
class InscritosLoading extends InscritosState {
  const InscritosLoading();
}

/// CA-001, CA-002, CA-003: Estado con lista de inscritos cargada
/// Muestra total y lista de jugadores anotados
class InscritosLoaded extends InscritosState {
  /// Datos completos de la respuesta
  final InscritosFechaDataModel data;

  /// CA-003: Total de jugadores anotados
  final int total;

  /// CA-002: Lista de inscritos con su informacion
  final List<InscritoFechaModel> inscritos;

  /// Mensaje del servidor (ej: "5 jugadores anotados")
  final String message;

  /// Indica si el realtime esta activo
  final bool realtimeActivo;

  const InscritosLoaded({
    required this.data,
    required this.total,
    required this.inscritos,
    required this.message,
    this.realtimeActivo = false,
  });

  /// CA-004: Lista vacia
  bool get estaVacia => inscritos.isEmpty;

  /// Verifica si hay inscritos
  bool get tieneInscritos => inscritos.isNotEmpty;

  /// CA-005: Obtiene el inscrito que es usuario actual (si existe)
  InscritoFechaModel? get usuarioActual {
    try {
      return inscritos.firstWhere((i) => i.esUsuarioActual);
    } catch (_) {
      return null;
    }
  }

  /// Verifica si el usuario actual esta inscrito
  bool get usuarioEstaInscrito => usuarioActual != null;

  /// Crea copia con nuevos valores
  InscritosLoaded copyWith({
    InscritosFechaDataModel? data,
    int? total,
    List<InscritoFechaModel>? inscritos,
    String? message,
    bool? realtimeActivo,
  }) {
    return InscritosLoaded(
      data: data ?? this.data,
      total: total ?? this.total,
      inscritos: inscritos ?? this.inscritos,
      message: message ?? this.message,
      realtimeActivo: realtimeActivo ?? this.realtimeActivo,
    );
  }

  @override
  List<Object?> get props => [data, total, inscritos, message, realtimeActivo];
}

/// Estado de error - Fallo al obtener inscritos
class InscritosError extends InscritosState {
  /// Mensaje de error para mostrar al usuario
  final String message;

  /// Codigo de error del backend (opcional)
  final String? code;

  /// Hint del backend para identificar tipo de error
  /// Valores posibles segun HU:
  /// - no_autenticado: Usuario no ha iniciado sesion
  /// - fecha_id_requerido: No se envio parametro
  /// - usuario_no_encontrado: Usuario no existe
  /// - usuario_no_aprobado: Usuario no esta aprobado (RN-001)
  /// - fecha_no_encontrada: La fecha no existe
  final String? hint;

  const InscritosError({
    required this.message,
    this.code,
    this.hint,
  });

  /// RN-001: Error por usuario no aprobado
  bool get esUsuarioNoAprobado => hint == 'usuario_no_aprobado';

  /// Error por no autenticado
  bool get esNoAutenticado => hint == 'no_autenticado';

  /// Error por fecha no encontrada
  bool get esFechaNoEncontrada => hint == 'fecha_no_encontrada';

  @override
  List<Object?> get props => [message, code, hint];
}
