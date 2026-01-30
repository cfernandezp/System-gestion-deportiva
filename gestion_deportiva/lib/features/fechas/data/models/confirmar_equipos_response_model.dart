import 'package:equatable/equatable.dart';

import 'balance_equipos_model.dart';
import 'equipo_confirmado_model.dart';

/// Modelo de respuesta del RPC confirmar_equipos
/// E003-HU-005: Asignar Equipos
/// CA-007: Confirmar asignacion
/// RN-005: Asignacion Completa Requerida
/// RN-006: Balance de Equipos
/// RN-007: Notificacion de Asignacion
///
/// JSON Response Success:
/// {
///   "success": true,
///   "data": {
///     "fecha_id": "uuid",
///     "total_jugadores": 12,
///     "equipos": [
///       {"equipo": "naranja", "cantidad": 6},
///       {"equipo": "verde", "cantidad": 6}
///     ],
///     "balance": {
///       "desbalanceado": false,
///       "diferencia_maxima": 0
///     },
///     "notificaciones_enviadas": 12
///   },
///   "message": "Equipos confirmados exitosamente"
/// }
class ConfirmarEquiposResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Datos de confirmacion (null si error)
  final ConfirmarEquiposDataModel? data;

  /// Mensaje del servidor
  final String message;

  const ConfirmarEquiposResponseModel({
    required this.success,
    this.data,
    this.message = '',
  });

  /// Crea instancia desde JSON del backend
  factory ConfirmarEquiposResponseModel.fromJson(Map<String, dynamic> json) {
    return ConfirmarEquiposResponseModel(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? ConfirmarEquiposDataModel.fromJson(
              json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [success, data, message];
}

/// Modelo de datos de confirmacion de equipos
class ConfirmarEquiposDataModel extends Equatable {
  /// ID de la fecha
  final String fechaId;

  /// Total de jugadores asignados
  final int totalJugadores;

  /// Lista de equipos con cantidades
  final List<EquipoConfirmadoModel> equipos;

  /// CA-006, RN-006: Estado del balance de equipos
  final BalanceEquiposModel balance;

  /// RN-007: Cantidad de notificaciones enviadas
  final int notificacionesEnviadas;

  const ConfirmarEquiposDataModel({
    required this.fechaId,
    required this.totalJugadores,
    required this.equipos,
    required this.balance,
    required this.notificacionesEnviadas,
  });

  /// Crea instancia desde JSON del backend
  factory ConfirmarEquiposDataModel.fromJson(Map<String, dynamic> json) {
    final equiposList = json['equipos'] as List<dynamic>? ?? [];

    return ConfirmarEquiposDataModel(
      fechaId: json['fecha_id'] ?? '',
      totalJugadores: json['total_jugadores'] ?? 0,
      equipos: equiposList
          .map((e) => EquipoConfirmadoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      balance: BalanceEquiposModel.fromJson(
          json['balance'] as Map<String, dynamic>? ?? {}),
      notificacionesEnviadas: json['notificaciones_enviadas'] ?? 0,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'fecha_id': fechaId,
      'total_jugadores': totalJugadores,
      'equipos': equipos.map((e) => e.toJson()).toList(),
      'balance': balance.toJson(),
      'notificaciones_enviadas': notificacionesEnviadas,
    };
  }

  /// Verifica si se enviaron todas las notificaciones
  bool get todasNotificacionesEnviadas =>
      notificacionesEnviadas == totalJugadores;

  @override
  List<Object?> get props => [
        fechaId,
        totalJugadores,
        equipos,
        balance,
        notificacionesEnviadas,
      ];
}
