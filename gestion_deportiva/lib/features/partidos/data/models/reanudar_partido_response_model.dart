import 'package:equatable/equatable.dart';

import 'estado_partido.dart';

/// Modelo de respuesta para reanudar_partido RPC
/// E004-HU-001: Iniciar Partido - CA-005
class ReanudarPartidoResponseModel extends Equatable {
  final bool success;
  final String partidoId;
  final EstadoPartido estado;
  final String? horaFinEstimadaFormato;
  final int tiempoRestanteSegundos;
  final int tiempoPausaActualSegundos;
  final int tiempoPausadoTotalSegundos;
  final String message;

  const ReanudarPartidoResponseModel({
    required this.success,
    required this.partidoId,
    required this.estado,
    this.horaFinEstimadaFormato,
    required this.tiempoRestanteSegundos,
    required this.tiempoPausaActualSegundos,
    required this.tiempoPausadoTotalSegundos,
    required this.message,
  });

  /// Crea instancia desde JSON del backend
  /// Response format:
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "partido_id": "uuid",
  ///     "estado": "en_curso",
  ///     "hora_fin_estimada_formato": "15:55:00",
  ///     "tiempo_restante_segundos": 900,
  ///     "tiempo_pausa_actual_segundos": 120,
  ///     "tiempo_pausado_total_segundos": 120
  ///   },
  ///   "message": "Partido reanudado: NARANJA vs VERDE. Tiempo restante: 15 minutos. Estuvo pausado 2 minutos."
  /// }
  factory ReanudarPartidoResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return ReanudarPartidoResponseModel(
      success: json['success'] ?? false,
      partidoId: data['partido_id'] ?? '',
      estado: EstadoPartido.fromString(data['estado'] ?? 'en_curso'),
      horaFinEstimadaFormato: data['hora_fin_estimada_formato'],
      tiempoRestanteSegundos: data['tiempo_restante_segundos'] ?? 0,
      tiempoPausaActualSegundos: data['tiempo_pausa_actual_segundos'] ?? 0,
      tiempoPausadoTotalSegundos: data['tiempo_pausado_total_segundos'] ?? 0,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        success,
        partidoId,
        estado,
        horaFinEstimadaFormato,
        tiempoRestanteSegundos,
        tiempoPausaActualSegundos,
        tiempoPausadoTotalSegundos,
        message,
      ];
}
