import 'package:equatable/equatable.dart';

import 'gol_model.dart';
import 'marcador_model.dart';

/// Modelo de respuesta para registrar_gol RPC
/// E004-HU-003: Registrar Gol
/// CA-003: Registro rapido con marcador actualizado
class RegistrarGolResponseModel extends Equatable {
  /// Si la operacion fue exitosa
  final bool success;

  /// Gol registrado
  final GolModel? gol;

  /// Marcador actualizado
  final MarcadorModel? marcador;

  /// Marcador en texto: "NARANJA 2 - 1 VERDE"
  final String? marcadorTexto;

  /// Advertencia si marcador inusual (RN-008)
  final String? advertencia;

  /// Mensaje de la operacion
  final String message;

  const RegistrarGolResponseModel({
    required this.success,
    this.gol,
    this.marcador,
    this.marcadorTexto,
    this.advertencia,
    required this.message,
  });

  /// Factory desde JSON del backend
  /// Response de registrar_gol RPC
  factory RegistrarGolResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    GolModel? gol;
    MarcadorModel? marcador;
    String? marcadorTexto;
    String? advertencia;

    if (data != null) {
      // Construir GolModel desde los campos de data
      gol = GolModel(
        id: data['gol_id'] as String,
        equipoAnotador: data['equipo_anotador'] as String,
        jugadorId: data['jugador_id'] as String?,
        jugadorNombre: data['jugador_nombre'] as String?,
        minuto: data['minuto'] as int,
        esAutogol: data['es_autogol'] as bool? ?? false,
      );

      // Parsear marcador
      final marcadorJson = data['marcador'] as Map<String, dynamic>?;
      if (marcadorJson != null) {
        marcador = MarcadorModel.fromJson(marcadorJson);
      }

      marcadorTexto = data['marcador_texto'] as String?;
      advertencia = data['advertencia'] as String?;
    }

    return RegistrarGolResponseModel(
      success: json['success'] as bool? ?? false,
      gol: gol,
      marcador: marcador,
      marcadorTexto: marcadorTexto,
      advertencia: advertencia,
      message: json['message'] as String? ?? '',
    );
  }

  /// RN-008: Indica si hay advertencia de marcador inusual
  bool get tieneAdvertencia => advertencia != null && advertencia!.isNotEmpty;

  @override
  List<Object?> get props => [
        success,
        gol,
        marcador,
        marcadorTexto,
        advertencia,
        message,
      ];
}
