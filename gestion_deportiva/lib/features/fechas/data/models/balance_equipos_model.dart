import 'package:equatable/equatable.dart';

/// Modelo de balance de equipos
/// E003-HU-005: Asignar Equipos
/// CA-006: Advertencia de desbalance
/// RN-006: Balance de Equipos (Advertencia)
///
/// JSON esperado del RPC confirmar_equipos:
/// {
///   "desbalanceado": false,
///   "diferencia_maxima": 0
/// }
class BalanceEquiposModel extends Equatable {
  /// RN-006: Indica si hay desbalance (diferencia > 1)
  final bool desbalanceado;

  /// RN-006: Maxima diferencia entre equipos
  final int diferenciaMaxima;

  const BalanceEquiposModel({
    required this.desbalanceado,
    required this.diferenciaMaxima,
  });

  /// Crea instancia desde JSON del backend
  factory BalanceEquiposModel.fromJson(Map<String, dynamic> json) {
    return BalanceEquiposModel(
      desbalanceado: json['desbalanceado'] ?? false,
      diferenciaMaxima: json['diferencia_maxima'] ?? 0,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'desbalanceado': desbalanceado,
      'diferencia_maxima': diferenciaMaxima,
    };
  }

  /// Indica si los equipos estan balanceados
  bool get estaBalanceado => !desbalanceado;

  /// Mensaje de estado del balance
  String get mensajeBalance {
    if (estaBalanceado) {
      return 'Equipos balanceados';
    }
    return 'Desbalance de $diferenciaMaxima jugador${diferenciaMaxima > 1 ? "es" : ""}';
  }

  @override
  List<Object?> get props => [desbalanceado, diferenciaMaxima];
}
