import 'package:equatable/equatable.dart';

/// Modelo de cambios realizados al editar una fecha
/// E003-HU-008: Editar Fecha
/// CA-006: Resumen de cambios para confirmacion
class CambiosEditarFechaModel extends Equatable {
  /// Indica si cambio la fecha
  final bool fecha;

  /// Indica si cambio la hora
  final bool hora;

  /// Indica si cambio la duracion
  final bool duracion;

  /// Indica si cambio el lugar
  final bool lugar;

  /// Indica si cambio el costo (consecuencia de cambiar duracion)
  final bool costo;

  const CambiosEditarFechaModel({
    required this.fecha,
    required this.hora,
    required this.duracion,
    required this.lugar,
    required this.costo,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory CambiosEditarFechaModel.fromJson(Map<String, dynamic> json) {
    return CambiosEditarFechaModel(
      fecha: json['fecha'] ?? false,
      hora: json['hora'] ?? false,
      duracion: json['duracion'] ?? false,
      lugar: json['lugar'] ?? false,
      costo: json['costo'] ?? false,
    );
  }

  /// Verifica si hubo algun cambio
  bool get huboAlgunCambio => fecha || hora || duracion || lugar || costo;

  @override
  List<Object?> get props => [fecha, hora, duracion, lugar, costo];
}

/// Modelo de respuesta para editar_fecha RPC
/// E003-HU-008: Editar Fecha
/// CA-006: Confirmacion con resumen de cambios
class EditarFechaResponseModel extends Equatable {
  /// ID de la fecha editada
  final String fechaId;

  /// Indica si se realizaron cambios
  final bool cambiosRealizados;

  /// Fecha y hora de inicio (UTC)
  final DateTime fechaHoraInicio;

  /// Fecha y hora local (Peru)
  final DateTime? fechaHoraLocal;

  /// Fecha formateada (DD/MM/YYYY)
  final String fechaFormato;

  /// Hora formateada (HH:MM)
  final String horaFormato;

  /// Duracion en horas (1 o 2)
  final int duracionHoras;

  /// Lugar de la pichanga
  final String lugar;

  /// Numero de equipos (2 o 3)
  final int numEquipos;

  /// Costo por jugador en soles
  final double costoPorJugador;

  /// Costo formateado (S/ X.XX)
  final String costoFormato;

  /// Estado de la fecha
  final String estado;

  /// Descripcion del formato de juego
  final String formatoJuego;

  /// Detalle de que campos cambiaron (CA-006)
  final CambiosEditarFechaModel cambios;

  /// Costo anterior (si cambio) - RN-003
  final double? costoAnterior;

  /// Cantidad de deudas pendientes actualizadas - RN-006
  final int deudasActualizadas;

  /// Cantidad de inscritos notificados - RN-007
  final int inscritosNotificados;

  /// Resumen de cambios en texto legible - CA-006
  final String resumenCambios;

  const EditarFechaResponseModel({
    required this.fechaId,
    required this.cambiosRealizados,
    required this.fechaHoraInicio,
    this.fechaHoraLocal,
    required this.fechaFormato,
    required this.horaFormato,
    required this.duracionHoras,
    required this.lugar,
    required this.numEquipos,
    required this.costoPorJugador,
    required this.costoFormato,
    required this.estado,
    required this.formatoJuego,
    required this.cambios,
    this.costoAnterior,
    required this.deudasActualizadas,
    required this.inscritosNotificados,
    required this.resumenCambios,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  /// Response format:
  /// {
  ///   "success": true,
  ///   "data": { fecha_id, cambios_realizados, ... },
  ///   "message": "Fecha actualizada exitosamente..."
  /// }
  factory EditarFechaResponseModel.fromJson(Map<String, dynamic> json) {
    final cambiosJson = json['cambios'] as Map<String, dynamic>? ?? {};

    return EditarFechaResponseModel(
      fechaId: json['fecha_id'] ?? '',
      cambiosRealizados: json['cambios_realizados'] ?? false,
      fechaHoraInicio: json['fecha_hora_inicio'] != null
          ? DateTime.parse(json['fecha_hora_inicio']).toLocal()
          : DateTime.now(),
      fechaHoraLocal: json['fecha_hora_local'] != null
          ? DateTime.parse(json['fecha_hora_local'])
          : null,
      fechaFormato: json['fecha_formato'] ?? '',
      horaFormato: json['hora_formato'] ?? '',
      duracionHoras: json['duracion_horas'] ?? 1,
      lugar: json['lugar'] ?? '',
      numEquipos: json['num_equipos'] ?? 2,
      costoPorJugador: (json['costo_por_jugador'] ?? 0).toDouble(),
      costoFormato: json['costo_formato'] ?? 'S/ 0.00',
      estado: json['estado'] ?? 'abierta',
      formatoJuego: json['formato_juego'] ?? '',
      cambios: CambiosEditarFechaModel.fromJson(cambiosJson),
      costoAnterior: json['costo_anterior'] != null
          ? (json['costo_anterior']).toDouble()
          : null,
      deudasActualizadas: json['deudas_actualizadas'] ?? 0,
      inscritosNotificados: json['inscritos_notificados'] ?? 0,
      resumenCambios: json['resumen_cambios'] ?? '',
    );
  }

  /// Indica si el costo cambio - RN-003
  bool get costoCambio => cambios.costo;

  /// Indica si hay inscritos afectados - CA-007
  bool get hayInscritosAfectados => inscritosNotificados > 0;

  /// Indica si hay deudas actualizadas - CA-008
  bool get hayDeudasActualizadas => deudasActualizadas > 0;

  @override
  List<Object?> get props => [
        fechaId,
        cambiosRealizados,
        fechaHoraInicio,
        fechaHoraLocal,
        fechaFormato,
        horaFormato,
        duracionHoras,
        lugar,
        numEquipos,
        costoPorJugador,
        costoFormato,
        estado,
        formatoJuego,
        cambios,
        costoAnterior,
        deudasActualizadas,
        inscritosNotificados,
        resumenCambios,
      ];
}

/// Wrapper de respuesta completa del RPC
class EditarFechaRpcResponseModel extends Equatable {
  final bool success;
  final EditarFechaResponseModel? data;
  final String message;

  const EditarFechaRpcResponseModel({
    required this.success,
    this.data,
    required this.message,
  });

  factory EditarFechaRpcResponseModel.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'] as Map<String, dynamic>?;

    return EditarFechaRpcResponseModel(
      success: json['success'] ?? false,
      data: dataJson != null ? EditarFechaResponseModel.fromJson(dataJson) : null,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [success, data, message];
}
