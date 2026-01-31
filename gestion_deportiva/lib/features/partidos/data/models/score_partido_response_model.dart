import 'package:equatable/equatable.dart';

import 'score_partido_model.dart';

/// Modelo de respuesta del RPC obtener_score_partido
/// E004-HU-004: Ver Score en Vivo
class ScorePartidoResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Datos del score del partido
  final ScorePartidoModel? score;

  /// Mensaje informativo
  final String message;

  const ScorePartidoResponseModel({
    required this.success,
    this.score,
    this.message = '',
  });

  /// Factory desde JSON del backend
  /// RPC: obtener_score_partido(p_partido_id)
  factory ScorePartidoResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return ScorePartidoResponseModel(
      success: json['success'] as bool? ?? false,
      score: data != null ? ScorePartidoModel.fromJson(data) : null,
      message: json['message'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [success, score, message];
}
