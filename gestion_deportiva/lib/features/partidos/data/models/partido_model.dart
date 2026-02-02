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
  final String? fechaId; // Nullable: obtener_partido_activo no lo envia
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
  final int golesLocal; // Agregado: obtener_partido_activo lo envia
  final int golesVisitante; // Agregado: obtener_partido_activo lo envia

  const PartidoModel({
    required this.id,
    this.fechaId, // Ahora opcional
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
    this.golesLocal = 0,
    this.golesVisitante = 0,
  });

  /// Factory desde JSON del backend (respuesta de iniciar_partido u obtener_partido_activo)
  factory PartidoModel.fromJson(Map<String, dynamic> json) {
    // Manejar id que puede venir como 'partido_id' o 'id'
    final id = json['partido_id'] as String? ?? json['id'] as String? ?? '';

    // Manejar hora_inicio: puede venir como 'hora_inicio_formato' o 'hora_inicio'
    // El backend puede enviar 'hora_inicio' (HH:MM) o 'hora_inicio_formato'
    final horaInicio = json['hora_inicio_formato'] as String? ??
        json['hora_inicio'] as String?;

    // Manejar hora_fin_estimada: puede venir como 'hora_fin_estimada_formato' o 'hora_fin_estimada'
    final horaFinEstimada = json['hora_fin_estimada_formato'] as String? ??
        json['hora_fin_estimada'] as String?;

    return PartidoModel(
      id: id,
      fechaId: json['fecha_id'] as String?, // Nullable: obtener_partido_activo no lo envia
      equipoLocal: EquipoPartidoModel.fromJson(
        json['equipo_local'] as Map<String, dynamic>,
      ),
      equipoVisitante: EquipoPartidoModel.fromJson(
        json['equipo_visitante'] as Map<String, dynamic>,
      ),
      duracionMinutos: json['duracion_minutos'] as int? ?? 0,
      estado: EstadoPartido.fromString(json['estado'] as String? ?? 'en_curso'),
      horaInicioFormato: horaInicio,
      horaFinEstimadaFormato: horaFinEstimada,
      tiempoRestanteSegundos: json['tiempo_restante_segundos'] as int? ?? 0,
      tiempoPausadoSegundos: json['tiempo_pausado_segundos'] as int?,
      tiempoRestanteFormato: json['tiempo_restante_formato'] as String?,
      tiempoTranscurridoFormato: json['tiempo_transcurrido_formato'] as String?,
      tiempoTerminado: json['tiempo_terminado'] as bool? ?? false,
      golesLocal: json['goles_local'] as int? ?? 0,
      golesVisitante: json['goles_visitante'] as int? ?? 0,
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (fechaId != null) 'fecha_id': fechaId,
      'equipo_local': equipoLocal.toJson(),
      'equipo_visitante': equipoVisitante.toJson(),
      'duracion_minutos': duracionMinutos,
      'estado': estado.toBackend(),
      'hora_inicio_formato': horaInicioFormato,
      'hora_fin_estimada_formato': horaFinEstimadaFormato,
      'tiempo_restante_segundos': tiempoRestanteSegundos,
      'tiempo_pausado_segundos': tiempoPausadoSegundos,
      'goles_local': golesLocal,
      'goles_visitante': golesVisitante,
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
      golesLocal: golesLocal,
      golesVisitante: golesVisitante,
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
      golesLocal: golesLocal,
      golesVisitante: golesVisitante,
    );
  }

  /// Crea copia con goles actualizados
  PartidoModel copyWithGoles({int? golesLocal, int? golesVisitante}) {
    return PartidoModel(
      id: id,
      fechaId: fechaId,
      equipoLocal: equipoLocal,
      equipoVisitante: equipoVisitante,
      duracionMinutos: duracionMinutos,
      estado: estado,
      horaInicioFormato: horaInicioFormato,
      horaFinEstimadaFormato: horaFinEstimadaFormato,
      tiempoRestanteSegundos: tiempoRestanteSegundos,
      tiempoPausadoSegundos: tiempoPausadoSegundos,
      tiempoRestanteFormato: tiempoRestanteFormato,
      tiempoTranscurridoFormato: tiempoTranscurridoFormato,
      tiempoTerminado: tiempoTerminado,
      golesLocal: golesLocal ?? this.golesLocal,
      golesVisitante: golesVisitante ?? this.golesVisitante,
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

  /// Calcula el tiempo transcurrido en segundos
  /// duracion_minutos * 60 - tiempo_restante
  /// Si tiempo_restante es negativo, el transcurrido supera la duracion
  int get tiempoTranscurridoSegundos {
    return (duracionMinutos * 60) - tiempoRestanteSegundos;
  }

  /// Tiempo transcurrido calculado dinamicamente
  /// - Si < duracion: "MM:SS" normal (ej: "05:30")
  /// - Si >= duracion: "+MM:SS" tiempo extra (ej: "+02:15")
  String get tiempoTranscurridoDisplay {
    final duracionSegundos = duracionMinutos * 60;
    final transcurrido = tiempoTranscurridoSegundos;

    if (transcurrido <= duracionSegundos) {
      // Tiempo normal: mostrar MM:SS limitado a duracion
      final segundosMostrar = transcurrido.clamp(0, duracionSegundos);
      return _formatearTiempo(segundosMostrar);
    } else {
      // Tiempo extra: mostrar cuanto tiempo extra lleva
      final tiempoExtra = transcurrido - duracionSegundos;
      return '+${_formatearTiempo(tiempoExtra)}';
    }
  }

  /// Indica si estamos en tiempo extra (pasamos de la duracion)
  /// Verifica tanto tiempo restante negativo como tiempo transcurrido > duracion
  bool get enTiempoExtra {
    if (tiempoRestanteSegundos < 0) return true;
    // Verificacion adicional: si tiempo transcurrido supera duracion
    final duracionSegundos = duracionMinutos * 60;
    return tiempoTranscurridoSegundos > duracionSegundos;
  }

  /// Tiempo extra en segundos (positivo, cuanto tiempo extra lleva)
  int get tiempoExtraSegundos {
    if (tiempoRestanteSegundos < 0) {
      return tiempoRestanteSegundos.abs();
    }
    final duracionSegundos = duracionMinutos * 60;
    final transcurrido = tiempoTranscurridoSegundos;
    if (transcurrido > duracionSegundos) {
      return transcurrido - duracionSegundos;
    }
    return 0;
  }

  /// Nombre del enfrentamiento para mostrar
  String get enfrentamientoDisplay {
    return '${equipoLocal.color.displayName.toUpperCase()} vs ${equipoVisitante.color.displayName.toUpperCase()}';
  }

  /// Marcador formateado para mostrar
  String get marcadorDisplay => '$golesLocal - $golesVisitante';

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
        golesLocal,
        golesVisitante,
      ];
}
