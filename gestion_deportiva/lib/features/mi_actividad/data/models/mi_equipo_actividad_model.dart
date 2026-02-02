import 'package:equatable/equatable.dart';

/// Modelo de mi equipo en la actividad
/// E004-HU-008: Mi Actividad en Vivo
/// Representa el equipo asignado al jugador con color y numero
class MiEquipoActividadModel extends Equatable {
  final String color;
  final String colorHex;
  final int numero;

  const MiEquipoActividadModel({
    required this.color,
    required this.colorHex,
    required this.numero,
  });

  /// Factory desde JSON del backend
  factory MiEquipoActividadModel.fromJson(Map<String, dynamic> json) {
    return MiEquipoActividadModel(
      color: json['color'] as String? ?? '',
      colorHex: json['color_hex'] as String? ?? '#FFFFFF',
      numero: json['numero'] as int? ?? 1,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'color': color,
      'color_hex': colorHex,
      'numero': numero,
    };
  }

  @override
  List<Object?> get props => [color, colorHex, numero];
}
