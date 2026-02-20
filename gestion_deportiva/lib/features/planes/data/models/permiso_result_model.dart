import 'package:equatable/equatable.dart';

/// Resultado de la consulta "puede hacer X?"
/// E000-HU-002: CA-013, RN-009
/// Respuesta clara: SI (permitido) o NO (motivo + detalles)
class PermisoResultModel extends Equatable {
  /// SI o NO
  final bool permitido;

  /// Motivo si NO: 'limite_alcanzado', 'feature_no_disponible'
  final String? motivo;

  /// Cantidad actual (solo para limites numericos)
  final int? limiteActual;

  /// Limite maximo del plan (solo para limites numericos)
  final int? limiteMaximo;

  /// Nombre del plan actual
  final String? planNombre;

  /// Plan minimo requerido para desbloquear (si NO permitido)
  final String? planRequerido;

  /// Mensaje descriptivo para el usuario
  final String? mensaje;

  const PermisoResultModel({
    required this.permitido,
    this.motivo,
    this.limiteActual,
    this.limiteMaximo,
    this.planNombre,
    this.planRequerido,
    this.mensaje,
  });

  /// Crea instancia desde JSON del backend (RPC verificar_permiso_plan)
  factory PermisoResultModel.fromJson(Map<String, dynamic> json) {
    return PermisoResultModel(
      permitido: json['permitido'] ?? false,
      motivo: json['motivo'],
      limiteActual: json['limite_actual'],
      limiteMaximo: json['limite_maximo'],
      planNombre: json['plan_nombre'],
      planRequerido: json['plan_requerido'],
      mensaje: json['mensaje'],
    );
  }

  /// RN-009: Indica si el motivo es limite alcanzado
  bool get esLimiteAlcanzado => motivo == 'limite_alcanzado';

  /// RN-009: Indica si el motivo es feature no disponible
  bool get esFeatureNoDisponible => motivo == 'feature_no_disponible';

  @override
  List<Object?> get props => [
        permitido,
        motivo,
        limiteActual,
        limiteMaximo,
        planNombre,
        planRequerido,
        mensaje,
      ];
}
