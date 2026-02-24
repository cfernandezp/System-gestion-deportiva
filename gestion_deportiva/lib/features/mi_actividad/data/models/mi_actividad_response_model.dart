import 'package:equatable/equatable.dart';

import 'pichanga_activa_model.dart';
import 'mi_equipo_actividad_model.dart';
import 'partido_actividad_model.dart';
import 'partido_en_curso_model.dart';
import 'proxima_pichanga_model.dart';
import 'pichanga_finalizada_model.dart';

/// Modelo de respuesta completa de mi actividad en vivo
/// E004-HU-008: Mi Actividad en Vivo
/// Parsea la respuesta del RPC obtener_mi_actividad_vivo()
class MiActividadResponseModel extends Equatable {
  final bool success;
  final String tipoActividad;
  final PichangaActivaModel? pichangaActiva;
  final MiEquipoActividadModel? miEquipo;
  final int misGolesTotales;
  final List<PartidoActividadModel> partidos;
  final PartidoEnCursoModel? partidoEnCurso;
  final ProximaPichangaModel? proximaPichanga;
  final PichangaFinalizadaModel? pichangaFinalizada;
  final String message;
  final String? mensajeSinActividad;

  const MiActividadResponseModel({
    required this.success,
    required this.tipoActividad,
    this.pichangaActiva,
    this.miEquipo,
    required this.misGolesTotales,
    required this.partidos,
    this.partidoEnCurso,
    this.proximaPichanga,
    this.pichangaFinalizada,
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
        tipoActividad: 'sin_actividad',
        misGolesTotales: 0,
        partidos: [],
        message: message,
      );
    }

    // Nuevo campo tipo_actividad del backend
    final tipoActividad = dataMap['tipo_actividad'] as String? ?? 'sin_actividad';
    final mensajeSinActividad = dataMap['mensaje'] as String?;

    // Parsear proxima pichanga
    final proximaPichangaJson = dataMap['proxima_pichanga'] as Map<String, dynamic>?;
    final proximaPichanga = proximaPichangaJson != null
        ? ProximaPichangaModel.fromJson(proximaPichangaJson)
        : null;

    // Parsear pichanga finalizada
    final pichangaFinalizadaJson = dataMap['pichanga_finalizada'] as Map<String, dynamic>?;
    final pichangaFinalizada = pichangaFinalizadaJson != null
        ? PichangaFinalizadaModel.fromJson(pichangaFinalizadaJson)
        : null;

    // Verificar si hay pichanga activa
    final pichangaActivaJson = dataMap['pichanga_activa'] as Map<String, dynamic>?;

    if (pichangaActivaJson == null) {
      // Sin pichanga activa
      return MiActividadResponseModel(
        success: success,
        tipoActividad: tipoActividad,
        misGolesTotales: 0,
        partidos: [],
        message: message,
        mensajeSinActividad: mensajeSinActividad,
        proximaPichanga: proximaPichanga,
        pichangaFinalizada: pichangaFinalizada,
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
      tipoActividad: tipoActividad,
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
      proximaPichanga: proximaPichanga,
      pichangaFinalizada: pichangaFinalizada,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': {
        'tipo_actividad': tipoActividad,
        if (pichangaActiva != null) 'pichanga_activa': pichangaActiva!.toJson(),
        if (miEquipo != null) 'mi_equipo': miEquipo!.toJson(),
        'mis_goles_totales': misGolesTotales,
        'partidos': partidos.map((e) => e.toJson()).toList(),
        if (partidoEnCurso != null) 'partido_en_curso': partidoEnCurso!.toJson(),
        if (proximaPichanga != null) 'proxima_pichanga': proximaPichanga!.toJson(),
        if (pichangaFinalizada != null) 'pichanga_finalizada': pichangaFinalizada!.toJson(),
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
        tipoActividad,
        pichangaActiva,
        miEquipo,
        misGolesTotales,
        partidos,
        partidoEnCurso,
        proximaPichanga,
        pichangaFinalizada,
        message,
        mensajeSinActividad,
      ];
}
