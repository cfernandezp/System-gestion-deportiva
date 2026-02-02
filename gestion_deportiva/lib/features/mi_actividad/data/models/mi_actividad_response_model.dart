import 'package:equatable/equatable.dart';

import 'pichanga_activa_model.dart';
import 'mi_equipo_actividad_model.dart';
import 'partido_actividad_model.dart';
import 'partido_en_curso_model.dart';

/// Modelo de respuesta completa de mi actividad en vivo
/// E004-HU-008: Mi Actividad en Vivo
/// Parsea la respuesta del RPC obtener_mi_actividad_vivo()
class MiActividadResponseModel extends Equatable {
  final bool success;
  final PichangaActivaModel? pichangaActiva;
  final MiEquipoActividadModel? miEquipo;
  final int misGolesTotales;
  final List<PartidoActividadModel> partidos;
  final PartidoEnCursoModel? partidoEnCurso;
  final String message;
  final String? mensajeSinActividad;

  const MiActividadResponseModel({
    required this.success,
    this.pichangaActiva,
    this.miEquipo,
    required this.misGolesTotales,
    required this.partidos,
    this.partidoEnCurso,
    required this.message,
    this.mensajeSinActividad,
  });

  /// Factory desde JSON del backend
  /// Maneja tanto respuesta con pichanga activa como sin pichanga activa
  factory MiActividadResponseModel.fromJson(Map<String, dynamic> json) {
    final success = json['success'] as bool? ?? false;
    final message = json['message'] as String? ?? '';
    final dataMap = json['data'] as Map<String, dynamic>?;

    if (dataMap == null) {
      return MiActividadResponseModel(
        success: success,
        misGolesTotales: 0,
        partidos: [],
        message: message,
      );
    }

    // Verificar si hay pichanga activa
    final pichangaActivaJson = dataMap['pichanga_activa'] as Map<String, dynamic>?;
    final mensajeSinActividad = dataMap['mensaje'] as String?;

    if (pichangaActivaJson == null) {
      // Sin pichanga activa
      return MiActividadResponseModel(
        success: success,
        misGolesTotales: 0,
        partidos: [],
        message: message,
        mensajeSinActividad: mensajeSinActividad,
      );
    }

    // Con pichanga activa
    final miEquipoJson = dataMap['mi_equipo'] as Map<String, dynamic>?;
    final misGolesTotales = dataMap['mis_goles_totales'] as int? ?? 0;
    final partidosJson = dataMap['partidos'] as List<dynamic>? ?? [];
    final partidoEnCursoJson = dataMap['partido_en_curso'] as Map<String, dynamic>?;

    final partidos = partidosJson
        .map((e) => PartidoActividadModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return MiActividadResponseModel(
      success: success,
      pichangaActiva: PichangaActivaModel.fromJson(pichangaActivaJson),
      miEquipo: miEquipoJson != null
          ? MiEquipoActividadModel.fromJson(miEquipoJson)
          : null,
      misGolesTotales: misGolesTotales,
      partidos: partidos,
      partidoEnCurso: partidoEnCursoJson != null
          ? PartidoEnCursoModel.fromJson(partidoEnCursoJson)
          : null,
      message: message,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': {
        if (pichangaActiva != null) 'pichanga_activa': pichangaActiva!.toJson(),
        if (miEquipo != null) 'mi_equipo': miEquipo!.toJson(),
        'mis_goles_totales': misGolesTotales,
        'partidos': partidos.map((e) => e.toJson()).toList(),
        if (partidoEnCurso != null) 'partido_en_curso': partidoEnCurso!.toJson(),
        if (mensajeSinActividad != null) 'mensaje': mensajeSinActividad,
      },
      'message': message,
    };
  }

  /// Indica si hay pichanga activa
  bool get hayPichangaActiva => pichangaActiva != null;

  /// Indica si estoy jugando en el partido en curso
  bool get estoyJugandoAhora =>
      partidoEnCurso != null &&
      partidoEnCurso!.partidoId != null &&
      partidoEnCurso!.estoyJugando;

  @override
  List<Object?> get props => [
        success,
        pichangaActiva,
        miEquipo,
        misGolesTotales,
        partidos,
        partidoEnCurso,
        message,
        mensajeSinActividad,
      ];
}
