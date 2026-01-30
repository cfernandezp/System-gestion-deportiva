import 'package:equatable/equatable.dart';

import 'estado_partido.dart';
import 'equipo_partido_model.dart';

/// Modelo de Partido en vivo
/// E004-HU-001: Iniciar Partido
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
  final int tiempoPausadoSegundos;
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
    required this.tiempoPausadoSegundos,
    this.tiempoRestanteFormato,
    this.tiempoTranscurridoFormato,
    this.tiempoTerminado = false,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory PartidoModel.fromJson(Map<String, dynamic> json) {
    return PartidoModel(
      id: json['id'] ?? json['partido_id'] ?? '',
      fechaId: json['fecha_id'] ?? '',
      equipoLocal: EquipoPartidoModel.fromJson(
        json['equipo_local'] as Map<String, dynamic>? ?? {},
      ),
      equipoVisitante: EquipoPartidoModel.fromJson(
        json['equipo_visitante'] as Map<String, dynamic>? ?? {},
      ),
      duracionMinutos: json['duracion_minutos'] ?? 0,
      estado: EstadoPartido.fromString(json['estado'] ?? 'pendiente'),
      horaInicioFormato: json['hora_inicio_formato'],
      horaFinEstimadaFormato: json['hora_fin_estimada_formato'],
      tiempoRestanteSegundos: json['tiempo_restante_segundos'] ?? 0,
      tiempoPausadoSegundos: json['tiempo_pausado_segundos'] ??
          json['tiempo_pausado_total_segundos'] ??
          0,
      tiempoRestanteFormato: json['tiempo_restante_formato'],
      tiempoTranscurridoFormato: json['tiempo_transcurrido_formato'],
      tiempoTerminado: json['tiempo_terminado'] ?? false,
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
      'estado': estado.valor,
      'hora_inicio_formato': horaInicioFormato,
      'hora_fin_estimada_formato': horaFinEstimadaFormato,
      'tiempo_restante_segundos': tiempoRestanteSegundos,
      'tiempo_pausado_segundos': tiempoPausadoSegundos,
    };
  }

  /// Crea una copia con tiempo restante actualizado (para countdown local)
  PartidoModel copyWithTiempoRestante(int nuevoTiempoRestante) {
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

  /// Crea una copia con nuevo estado
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

  /// Formatea segundos a MM:SS
  static String _formatearTiempo(int segundos) {
    if (segundos < 0) segundos = 0;
    final minutos = segundos ~/ 60;
    final segs = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }

  /// Titulo del partido para UI
  String get titulo =>
      '${equipoLocal.displayName} vs ${equipoVisitante.displayName}';

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
        tiempoRestanteFormato,
        tiempoTranscurridoFormato,
        tiempoTerminado,
      ];
}
