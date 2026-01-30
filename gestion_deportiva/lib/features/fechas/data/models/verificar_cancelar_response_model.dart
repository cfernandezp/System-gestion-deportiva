import 'package:equatable/equatable.dart';

/// Modelo de datos de verificacion de cancelacion
/// E003-HU-007: Cancelar Inscripcion
///
/// Criterios de Aceptacion:
/// - CA-001: Opcion de cancelar visible segun condiciones
/// - CA-002: Mensaje de confirmacion
/// - CA-005: Mensaje si inscripciones cerradas
///
/// Reglas de Negocio:
/// - RN-001: Cancelacion libre si fecha abierta
/// - RN-002: Bloqueo si fecha cerrada
/// - RN-003: Indica si deuda sera anulada
class VerificarCancelarDataModel extends Equatable {
  /// CA-001: Indica si el usuario puede cancelar su inscripcion
  final bool puedeCancelar;

  /// ID de la inscripcion (si existe)
  final String? inscripcionId;

  /// Estado actual de la fecha
  final String fechaEstado;

  /// RN-001: Indica si la cancelacion es libre (fecha abierta)
  final bool cancelacionLibre;

  /// RN-003: Indica si la deuda sera anulada al cancelar
  final bool? deudaSeraAnulada;

  /// CA-002: Mensaje de confirmacion para mostrar en dialogo
  final String? mensajeConfirmacion;

  /// CA-005: Motivo por el cual no puede cancelar
  final String? motivo;

  /// CA-005: Mensaje descriptivo si no puede cancelar
  final String? mensaje;

  const VerificarCancelarDataModel({
    required this.puedeCancelar,
    this.inscripcionId,
    required this.fechaEstado,
    required this.cancelacionLibre,
    this.deudaSeraAnulada,
    this.mensajeConfirmacion,
    this.motivo,
    this.mensaje,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  ///
  /// Response format del backend (puede cancelar):
  /// {
  ///   "puede_cancelar": true,
  ///   "inscripcion_id": "uuid",
  ///   "fecha_estado": "abierta",
  ///   "cancelacion_libre": true,
  ///   "deuda_sera_anulada": true,
  ///   "mensaje_confirmacion": "Estas seguro de cancelar tu inscripcion?"
  /// }
  ///
  /// Response format del backend (no puede cancelar):
  /// {
  ///   "puede_cancelar": false,
  ///   "inscripcion_id": "uuid",
  ///   "fecha_estado": "cerrada",
  ///   "cancelacion_libre": false,
  ///   "motivo": "fecha_cerrada",
  ///   "mensaje": "Las inscripciones estan cerradas. Contacta al administrador"
  /// }
  factory VerificarCancelarDataModel.fromJson(Map<String, dynamic> json) {
    return VerificarCancelarDataModel(
      puedeCancelar: json['puede_cancelar'] ?? false,
      inscripcionId: json['inscripcion_id'],
      fechaEstado: json['fecha_estado'] ?? '',
      cancelacionLibre: json['cancelacion_libre'] ?? false,
      deudaSeraAnulada: json['deuda_sera_anulada'],
      mensajeConfirmacion: json['mensaje_confirmacion'],
      motivo: json['motivo'],
      mensaje: json['mensaje'],
    );
  }

  /// RN-002: Verifica si la fecha esta cerrada
  bool get fechaCerrada => fechaEstado != 'abierta';

  /// Verifica si el motivo es fecha cerrada
  bool get esFechaCerrada => motivo == 'fecha_cerrada';

  /// Verifica si el usuario no esta inscrito
  bool get noEstaInscrito => motivo == 'no_inscrito';

  @override
  List<Object?> get props => [
        puedeCancelar,
        inscripcionId,
        fechaEstado,
        cancelacionLibre,
        deudaSeraAnulada,
        mensajeConfirmacion,
        motivo,
        mensaje,
      ];
}

/// Wrapper de respuesta completa del RPC verificar_puede_cancelar
/// Sigue el formato estandar de response: {success, data, message}
/// E003-HU-007: Verificacion previa a cancelacion
class VerificarCancelarRpcResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Datos de la respuesta (null si error)
  final VerificarCancelarDataModel? data;

  /// Mensaje descriptivo del servidor (opcional)
  final String? message;

  const VerificarCancelarRpcResponseModel({
    required this.success,
    this.data,
    this.message,
  });

  /// Crea instancia desde JSON completo del backend
  factory VerificarCancelarRpcResponseModel.fromJson(
      Map<String, dynamic> json) {
    final dataJson = json['data'] as Map<String, dynamic>?;

    return VerificarCancelarRpcResponseModel(
      success: json['success'] ?? false,
      data: dataJson != null
          ? VerificarCancelarDataModel.fromJson(dataJson)
          : null,
      message: json['message'],
    );
  }

  @override
  List<Object?> get props => [success, data, message];
}
