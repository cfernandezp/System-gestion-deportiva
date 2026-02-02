import 'package:equatable/equatable.dart';

/// Modelo de partido en curso
/// E004-HU-008: Mi Actividad en Vivo
/// Representa el partido actualmente en curso con indicador de participacion
class PartidoEnCursoModel extends Equatable {
  final String? partidoId;
  final bool estoyJugando;

  const PartidoEnCursoModel({
    this.partidoId,
    required this.estoyJugando,
  });

  /// Factory desde JSON del backend
  factory PartidoEnCursoModel.fromJson(Map<String, dynamic> json) {
    return PartidoEnCursoModel(
      partidoId: json['partido_id'] as String?,
      estoyJugando: json['estoy_jugando'] as bool? ?? false,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      if (partidoId != null) 'partido_id': partidoId,
      'estoy_jugando': estoyJugando,
    };
  }

  @override
  List<Object?> get props => [partidoId, estoyJugando];
}
