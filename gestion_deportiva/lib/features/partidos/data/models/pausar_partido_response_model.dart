import 'package:equatable/equatable.dart';

import 'estado_partido.dart';

/// Modelo de respuesta para pausar_partido RPC
/// E004-HU-001: Iniciar Partido - CA-005
class PausarPartidoResponseModel extends Equatable {
  final bool success;
  final String partidoId;
  final EstadoPartido estado;
  final String? pausadoAtFormato;
  final int tiempoRestanteSegundos;
  final String? pausadoPorNombre;
  final String message;

  const PausarPartidoResponseModel({
    required this.success,
    required this.partidoId,
    required this.estado,
    this.pausadoAtFormato,
    required this.tiempoRestanteSegundos,
    this.pausadoPorNombre,
    required this.message,
  });

  /// Crea instancia desde JSON del backend
  /// Response format:
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "partido_id": "uuid",
  ///     "estado": "pausado",
  ///     "pausado_at_formato": "15:35:00",
  ///     "tiempo_restante_segundos": 900,
  ///     "pausado_por_nombre": "Admin"
  ///   },
  ///   "message": "Partido pausado: NARANJA vs VERDE. Tiempo restante: 15 minutos"
  /// }
  factory PausarPartidoResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return PausarPartidoResponseModel(
      success: json['success'] ?? false,
      partidoId: data['partido_id'] ?? '',
      estado: EstadoPartido.fromString(data['estado'] ?? 'pausado'),
      pausadoAtFormato: data['pausado_at_formato'],
      tiempoRestanteSegundos: data['tiempo_restante_segundos'] ?? 0,
      pausadoPorNombre: data['pausado_por_nombre'],
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        success,
        partidoId,
        estado,
        pausadoAtFormato,
        tiempoRestanteSegundos,
        pausadoPorNombre,
        message,
      ];
}
