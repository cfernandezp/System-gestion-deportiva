import 'package:equatable/equatable.dart';

import 'estado_partido.dart';
import 'equipo_partido_model.dart';

/// Modelo de partido
/// E004-HU-001: Iniciar Partido
/// E004-HU-002: Temporizador con Alarma
/// Representa un partido entre 2 equipos con temporizador
/// Soporta tiempo negativo para tiempo extra (RN-003)
class PartidoModel extends Equatable {
  final String id;
  final String fechaId;
  final EquipoPartidoModel equipoLocal;
  final EquipoPartidoModel equipoVisitante;
  final int duracionMinutos;
  final EstadoPartido estado;
  final String? horaInicioFormato;
  final String? horaFinEstimadaFormato;
  final int tiempoRestanteSegundos;
  final int? tiempoPausadoSegundos;
  final String? tiempoRestanteFormato;
  final String? tiempoTranscurridoFormato;
  final bool tiempoTerminado;

  const PartidoModel({
    required this.id,
    required this.fechaId,
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.duracionMinutos,
    required this.estado,
    this.horaInicioFormato,
    this.horaFinEstimadaFormato,
    required this.tiempoRestanteSegundos,
    this.tiempoPausadoSegundos,
    this.tiempoRestanteFormato,
    this.tiempoTranscurridoFormato,
    this.tiempoTerminado = false,
  });

  /// Factory desde JSON del backend (respuesta de iniciar_partido)
  factory PartidoModel.fromJson(Map<String, dynamic> json) {
    return PartidoModel(
      id: json['partido_id'] as String? ?? json['id'] as String,
      fechaId: json['fecha_id'] as String,
      equipoLocal: EquipoPartidoModel.fromJson(
        json['equipo_local'] as Map<String, dynamic>,
      ),
      equipoVisitante: EquipoPartidoModel.fromJson(
        json['equipo_visitante'] as Map<String, dynamic>,
      ),
      duracionMinutos: json['duracion_minutos'] as int,
      estado: EstadoPartido.fromString(json['estado'] as String),
      horaInicioFormato: json['hora_inicio_formato'] as String?,
      horaFinEstimadaFormato: json['hora_fin_estimada_formato'] as String?,
      tiempoRestanteSegundos: json['tiempo_restante_segundos'] as int? ?? 0,
      tiempoPausadoSegundos: json['tiempo_pausado_segundos'] as int?,
      tiempoRestanteFormato: json['tiempo_restante_formato'] as String?,
      tiempoTranscurridoFormato: json['tiempo_transcurrido_formato'] as String?,
      tiempoTerminado: json['tiempo_terminado'] as bool? ?? false,
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha_id': fechaId,
      'equipo_local': equipoLocal.toJson(),
      'equipo_visitante': equipoVisitante.toJson(),
      'duracion_minutos': duracionMinutos,
      'estado': estado.toBackend(),
      'hora_inicio_formato': horaInicioFormato,
      'hora_fin_estimada_formato': horaFinEstimadaFormato,
      'tiempo_restante_segundos': tiempoRestanteSegundos,
      'tiempo_pausado_segundos': tiempoPausadoSegundos,
    };
  }

  /// Crea copia con tiempo actualizado (para countdown local)
  PartidoModel copyWithTiempo(int nuevoTiempoRestante) {
    return PartidoModel(
      id: id,
      fechaId: fechaId,
      equipoLocal: equipoLocal,
      equipoVisitante: equipoVisitante,
      duracionMinutos: duracionMinutos,
      estado: estado,
      horaInicioFormato: horaInicioFormato,
      horaFinEstimadaFormato: horaFinEstimadaFormato,
      tiempoRestanteSegundos: nuevoTiempoRestante,
      tiempoPausadoSegundos: tiempoPausadoSegundos,
      tiempoRestanteFormato: _formatearTiempo(nuevoTiempoRestante),
      tiempoTranscurridoFormato: tiempoTranscurridoFormato,
      tiempoTerminado: nuevoTiempoRestante <= 0,
    );
  }

  /// Crea copia con nuevo estado
  PartidoModel copyWithEstado(EstadoPartido nuevoEstado) {
    return PartidoModel(
      id: id,
      fechaId: fechaId,
      equipoLocal: equipoLocal,
      equipoVisitante: equipoVisitante,
      duracionMinutos: duracionMinutos,
      estado: nuevoEstado,
      horaInicioFormato: horaInicioFormato,
      horaFinEstimadaFormato: horaFinEstimadaFormato,
      tiempoRestanteSegundos: tiempoRestanteSegundos,
      tiempoPausadoSegundos: tiempoPausadoSegundos,
      tiempoRestanteFormato: tiempoRestanteFormato,
      tiempoTranscurridoFormato: tiempoTranscurridoFormato,
      tiempoTerminado: tiempoTerminado,
    );
  }

  /// Formatea segundos a MM:SS o -MM:SS para tiempo extra
  /// E004-HU-002 CA-006, RN-006: Formato tiempo legible
  /// - Positivo: "05:30" (5 min 30 seg)
  /// - Cero: "00:00"
  /// - Negativo: "-01:15" (1 min 15 seg de tiempo extra)
  static String _formatearTiempo(int segundos) {
    final esNegativo = segundos < 0;
    final segundosAbsolutos = segundos.abs();
    final minutos = segundosAbsolutos ~/ 60;
    final segs = segundosAbsolutos % 60;
    final tiempo =
        '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
    return esNegativo ? '-$tiempo' : tiempo;
  }

  /// Tiempo restante formateado (MM:SS o -MM:SS)
  /// E004-HU-002 CA-001, CA-006: Visualizacion del tiempo
  String get tiempoRestanteDisplay {
    // Usar formato local para soportar tiempo negativo
    return _formatearTiempo(tiempoRestanteSegundos);
  }

  /// Nombre del enfrentamiento para mostrar
  String get enfrentamientoDisplay {
    return '${equipoLocal.color.displayName.toUpperCase()} vs ${equipoVisitante.color.displayName.toUpperCase()}';
  }

  @override
  List<Object?> get props => [
        id,
        fechaId,
        equipoLocal,
        equipoVisitante,
        duracionMinutos,
        estado,
        horaInicioFormato,
        horaFinEstimadaFormato,
        tiempoRestanteSegundos,
        tiempoPausadoSegundos,
        tiempoTerminado,
      ];
}
