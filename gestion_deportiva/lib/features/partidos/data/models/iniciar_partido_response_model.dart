import 'package:equatable/equatable.dart';

import 'partido_model.dart';

/// Modelo de respuesta para iniciar_partido RPC
/// E004-HU-001: Iniciar Partido - CA-003
class IniciarPartidoResponseModel extends Equatable {
  final bool success;
  final PartidoModel? partido;
  final String message;

  const IniciarPartidoResponseModel({
    required this.success,
    this.partido,
    required this.message,
  });

  /// Crea instancia desde JSON del backend
  /// Response format:
  /// {
  ///   "success": true,
  ///   "data": { partido data },
  ///   "message": "Partido iniciado: NARANJA vs VERDE - 20 minutos"
  /// }
  factory IniciarPartidoResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return IniciarPartidoResponseModel(
      success: json['success'] ?? false,
      partido: data != null ? PartidoModel.fromJson(data) : null,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [success, partido, message];
}
