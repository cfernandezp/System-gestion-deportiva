import 'package:equatable/equatable.dart';

/// Modelo de detalle de gol individual
/// E004-HU-008: Mi Actividad en Vivo
/// Representa un gol anotado por el jugador con el minuto
class GolDetalleModel extends Equatable {
  final int minuto;
  final bool esAutogol;

  const GolDetalleModel({
    required this.minuto,
    required this.esAutogol,
  });

  /// Factory desde JSON del backend
  factory GolDetalleModel.fromJson(Map<String, dynamic> json) {
    return GolDetalleModel(
      minuto: json['minuto'] as int? ?? 0,
      esAutogol: json['es_autogol'] as bool? ?? false,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'minuto': minuto,
      'es_autogol': esAutogol,
    };
  }

  @override
  List<Object?> get props => [minuto, esAutogol];
}
