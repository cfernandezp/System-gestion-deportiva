import 'package:equatable/equatable.dart';

import 'fecha_model.dart';

/// Modelo de Response para crear_fecha RPC
/// E003-HU-001: Crear Fecha
/// CA-006: Confirmacion de creacion con resumen
class CrearFechaResponseModel extends Equatable {
  final bool success;
  final FechaModel? fecha;
  final String message;

  const CrearFechaResponseModel({
    required this.success,
    this.fecha,
    required this.message,
  });

  /// Crea instancia desde JSON del backend
  /// Response format:
  /// {
  ///   "success": true,
  ///   "data": { fecha_id, fecha_hora_inicio, ... },
  ///   "message": "Fecha creada exitosamente..."
  /// }
  factory CrearFechaResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return CrearFechaResponseModel(
      success: json['success'] ?? false,
      fecha: data != null ? FechaModel.fromJson(data) : null,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [success, fecha, message];
}
