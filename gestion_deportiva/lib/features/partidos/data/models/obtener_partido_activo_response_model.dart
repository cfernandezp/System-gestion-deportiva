import 'package:equatable/equatable.dart';

import 'partido_model.dart';

/// Modelo de respuesta para obtener_partido_activo RPC
/// E004-HU-001: Iniciar Partido - CA-004
class ObtenerPartidoActivoResponseModel extends Equatable {
  final bool success;
  final bool partidoActivo;
  final PartidoModel? partido;
  final bool puedePausar;
  final bool puedeReanudar;
  final bool puedeIniciarPartido;
  final String message;

  const ObtenerPartidoActivoResponseModel({
    required this.success,
    required this.partidoActivo,
    this.partido,
    this.puedePausar = false,
    this.puedeReanudar = false,
    this.puedeIniciarPartido = false,
    required this.message,
  });

  /// Crea instancia desde JSON del backend
  /// Response format (con partido activo):
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "partido_activo": true,
  ///     "partido": { partido data },
  ///     "puede_pausar": true,
  ///     "puede_reanudar": false
  ///   },
  ///   "message": "Partido en curso: NARANJA vs VERDE"
  /// }
  ///
  /// Response format (sin partido activo):
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "partido_activo": false,
  ///     "partido": null,
  ///     "puede_iniciar_partido": true
  ///   },
  ///   "message": "No hay partido activo en esta fecha"
  /// }
  factory ObtenerPartidoActivoResponseModel.fromJson(
      Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final partidoData = data['partido'] as Map<String, dynamic>?;

    return ObtenerPartidoActivoResponseModel(
      success: json['success'] as bool? ?? false,
      partidoActivo: data['partido_activo'] as bool? ?? false,
      partido: partidoData != null ? PartidoModel.fromJson(partidoData) : null,
      puedePausar: data['puede_pausar'] as bool? ?? false,
      puedeReanudar: data['puede_reanudar'] as bool? ?? false,
      puedeIniciarPartido: data['puede_iniciar_partido'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        success,
        partidoActivo,
        partido,
        puedePausar,
        puedeReanudar,
        puedeIniciarPartido,
        message,
      ];
}
