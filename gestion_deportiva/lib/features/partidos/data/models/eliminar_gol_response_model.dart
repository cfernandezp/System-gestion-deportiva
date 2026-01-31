import 'package:equatable/equatable.dart';

import 'gol_eliminado_model.dart';
import 'marcador_model.dart';

/// Modelo de respuesta para eliminar_gol RPC
/// E004-HU-003: Registrar Gol - CA-005: Deshacer gol
/// RN-005: Ventana de deshacer
class EliminarGolResponseModel extends Equatable {
  /// Si la operacion fue exitosa
  final bool success;

  /// Informacion del gol eliminado
  final GolEliminadoModel? golEliminado;

  /// ID del partido
  final String? partidoId;

  /// Marcador actualizado despues de eliminar
  final MarcadorModel? marcador;

  /// Marcador en texto: "NARANJA 2 - 0 VERDE"
  final String? marcadorTexto;

  /// Mensaje de la operacion
  final String message;

  const EliminarGolResponseModel({
    required this.success,
    this.golEliminado,
    this.partidoId,
    this.marcador,
    this.marcadorTexto,
    required this.message,
  });

  /// Factory desde JSON del backend
  /// Response de eliminar_gol RPC
  factory EliminarGolResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    GolEliminadoModel? golEliminado;
    String? partidoId;
    MarcadorModel? marcador;
    String? marcadorTexto;

    if (data != null) {
      // Parsear gol eliminado
      final golJson = data['gol_eliminado'] as Map<String, dynamic>?;
      if (golJson != null) {
        golEliminado = GolEliminadoModel.fromJson(golJson);
      }

      partidoId = data['partido_id'] as String?;

      // Parsear marcador
      final marcadorJson = data['marcador'] as Map<String, dynamic>?;
      if (marcadorJson != null) {
        marcador = MarcadorModel.fromJson(marcadorJson);
      }

      marcadorTexto = data['marcador_texto'] as String?;
    }

    return EliminarGolResponseModel(
      success: json['success'] as bool? ?? false,
      golEliminado: golEliminado,
      partidoId: partidoId,
      marcador: marcador,
      marcadorTexto: marcadorTexto,
      message: json['message'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        success,
        golEliminado,
        partidoId,
        marcador,
        marcadorTexto,
        message,
      ];
}
