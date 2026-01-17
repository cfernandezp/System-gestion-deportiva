import 'package:equatable/equatable.dart';

/// Modelo de Inscripcion a una fecha
/// E003-HU-002: Inscribirse a Fecha
/// Representa el estado de inscripcion del usuario actual
class InscripcionModel extends Equatable {
  /// ID de la inscripcion
  final String inscripcionId;

  /// ID de la fecha a la que se inscribio
  final String fechaId;

  /// ID del miembro inscrito
  final String miembroId;

  /// Nombre del miembro inscrito
  final String nombreMiembro;

  /// Estado de la inscripcion (confirmada, cancelada)
  final String estado;

  /// Fecha de inscripcion
  final DateTime fechaInscripcion;

  /// RN-004: Indica si se genero deuda automatica
  final bool deudaGenerada;

  /// Monto de la deuda generada (si aplica)
  final double? montoDeuda;

  const InscripcionModel({
    required this.inscripcionId,
    required this.fechaId,
    required this.miembroId,
    required this.nombreMiembro,
    required this.estado,
    required this.fechaInscripcion,
    this.deudaGenerada = false,
    this.montoDeuda,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory InscripcionModel.fromJson(Map<String, dynamic> json) {
    return InscripcionModel(
      inscripcionId: json['inscripcion_id'] ?? '',
      fechaId: json['fecha_id'] ?? '',
      miembroId: json['miembro_id'] ?? '',
      nombreMiembro: json['nombre_miembro'] ?? '',
      estado: json['estado'] ?? 'confirmada',
      fechaInscripcion: json['fecha_inscripcion'] != null
          ? DateTime.parse(json['fecha_inscripcion']).toLocal()
          : DateTime.now(),
      deudaGenerada: json['deuda_generada'] ?? false,
      montoDeuda: json['monto_deuda'] != null
          ? (json['monto_deuda'] as num).toDouble()
          : null,
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'inscripcion_id': inscripcionId,
      'fecha_id': fechaId,
      'miembro_id': miembroId,
      'nombre_miembro': nombreMiembro,
      'estado': estado,
      'fecha_inscripcion': fechaInscripcion.toUtc().toIso8601String(),
      'deuda_generada': deudaGenerada,
      'monto_deuda': montoDeuda,
    };
  }

  /// CA-004: Verifica si la inscripcion esta activa
  bool get estaActiva => estado == 'confirmada';

  /// Verifica si fue cancelada
  bool get estaCancelada => estado == 'cancelada';

  @override
  List<Object?> get props => [
        inscripcionId,
        fechaId,
        miembroId,
        nombreMiembro,
        estado,
        fechaInscripcion,
        deudaGenerada,
        montoDeuda,
      ];
}

/// Modelo de respuesta al inscribirse a una fecha
/// E003-HU-002: Inscribirse a Fecha
class InscripcionResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Mensaje del servidor
  final String message;

  /// Datos de la inscripcion (si fue exitosa)
  final InscripcionModel? inscripcion;

  const InscripcionResponseModel({
    required this.success,
    required this.message,
    this.inscripcion,
  });

  /// Crea instancia desde JSON del backend
  factory InscripcionResponseModel.fromJson(Map<String, dynamic> json) {
    return InscripcionResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      inscripcion: json['data'] != null
          ? InscripcionModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [success, message, inscripcion];
}

/// Modelo de respuesta al cancelar inscripcion
/// E003-HU-002: CA-004 Cancelar inscripcion
class CancelarInscripcionResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Mensaje del servidor
  final String message;

  const CancelarInscripcionResponseModel({
    required this.success,
    required this.message,
  });

  /// Crea instancia desde JSON del backend
  factory CancelarInscripcionResponseModel.fromJson(Map<String, dynamic> json) {
    return CancelarInscripcionResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [success, message];
}
