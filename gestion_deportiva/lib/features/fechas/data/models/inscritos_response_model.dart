import 'package:equatable/equatable.dart';

import 'inscrito_fecha_model.dart';

/// Modelo con informacion basica de la fecha
/// E003-HU-003: Ver Inscritos
/// Parte de la respuesta de obtener_inscritos_fecha
class FechaInfoModel extends Equatable {
  /// Fecha formateada (DD/MM/YYYY)
  final String fechaFormato;

  /// Hora formateada (HH:MI)
  final String horaFormato;

  /// Lugar de la pichanga
  final String lugar;

  /// Estado de la fecha (abierta, cerrada, etc.)
  final String estado;

  const FechaInfoModel({
    required this.fechaFormato,
    required this.horaFormato,
    required this.lugar,
    required this.estado,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory FechaInfoModel.fromJson(Map<String, dynamic> json) {
    return FechaInfoModel(
      fechaFormato: json['fecha_formato'] ?? '',
      horaFormato: json['hora_formato'] ?? '',
      lugar: json['lugar'] ?? '',
      estado: json['estado'] ?? '',
    );
  }

  @override
  List<Object?> get props => [fechaFormato, horaFormato, lugar, estado];
}

/// Modelo de datos de inscritos a una fecha
/// E003-HU-003: Ver Inscritos
/// Estructura del campo "data" en la respuesta del RPC
///
/// CA-003: Total de inscritos
/// CA-002: Lista de inscritos con su informacion
class InscritosFechaDataModel extends Equatable {
  /// ID de la fecha consultada
  final String fechaId;

  /// Informacion basica de la fecha
  final FechaInfoModel fechaInfo;

  /// CA-003: Total de jugadores inscritos
  final int total;

  /// CA-002: Lista de jugadores inscritos
  /// Ordenados por orden de inscripcion (RN-003)
  final List<InscritoFechaModel> inscritos;

  const InscritosFechaDataModel({
    required this.fechaId,
    required this.fechaInfo,
    required this.total,
    required this.inscritos,
  });

  /// Crea instancia desde JSON del backend
  /// JSON esperado:
  /// {
  ///   "fecha_id": "uuid",
  ///   "fecha_info": {...},
  ///   "total": 5,
  ///   "inscritos": [...]
  /// }
  factory InscritosFechaDataModel.fromJson(Map<String, dynamic> json) {
    final inscritosJson = json['inscritos'] as List<dynamic>? ?? [];
    final inscritos = inscritosJson
        .map((e) => InscritoFechaModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return InscritosFechaDataModel(
      fechaId: json['fecha_id'] ?? '',
      fechaInfo: json['fecha_info'] != null
          ? FechaInfoModel.fromJson(json['fecha_info'] as Map<String, dynamic>)
          : const FechaInfoModel(
              fechaFormato: '',
              horaFormato: '',
              lugar: '',
              estado: '',
            ),
      total: json['total'] ?? inscritos.length,
      inscritos: inscritos,
    );
  }

  /// CA-004: Verifica si la lista esta vacia
  bool get estaVacia => inscritos.isEmpty;

  /// Verifica si hay inscritos
  bool get tieneInscritos => inscritos.isNotEmpty;

  @override
  List<Object?> get props => [fechaId, fechaInfo, total, inscritos];
}

/// Modelo de respuesta del RPC obtener_inscritos_fecha
/// E003-HU-003: Ver Inscritos
///
/// Estructura JSON completa:
/// {
///   "success": true,
///   "data": {
///     "fecha_id": "uuid",
///     "fecha_info": {...},
///     "total": 5,
///     "inscritos": [...]
///   },
///   "message": "5 jugadores anotados"
/// }
class InscritosFechaResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Datos de inscritos
  final InscritosFechaDataModel? data;

  /// Mensaje del servidor
  /// CA-003: "X jugadores anotados"
  /// CA-004: "Aun no hay jugadores anotados"
  final String message;

  const InscritosFechaResponseModel({
    required this.success,
    this.data,
    required this.message,
  });

  /// Crea instancia desde JSON del backend
  factory InscritosFechaResponseModel.fromJson(Map<String, dynamic> json) {
    return InscritosFechaResponseModel(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? InscritosFechaDataModel.fromJson(
              json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'] ?? '',
    );
  }

  /// Total de inscritos (acceso directo)
  int get total => data?.total ?? 0;

  /// Lista de inscritos (acceso directo)
  List<InscritoFechaModel> get inscritos => data?.inscritos ?? [];

  /// CA-004: Lista vacia
  bool get estaVacia => data?.estaVacia ?? true;

  @override
  List<Object?> get props => [success, data, message];
}
