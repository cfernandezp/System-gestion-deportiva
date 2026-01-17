import 'package:equatable/equatable.dart';

import 'fecha_model.dart';

/// Modelo de fecha disponible para listar
/// E003-HU-002: listar_fechas_disponibles RPC
/// Version resumida de fecha para mostrar en listas
class FechaDisponibleModel extends Equatable {
  /// ID de la fecha
  final String fechaId;

  /// Fecha y hora de inicio (UTC convertida a local)
  final DateTime fechaHoraInicio;

  /// Fecha formateada para mostrar
  final String fechaFormato;

  /// Duracion en horas
  final int duracionHoras;

  /// Lugar de la pichanga
  final String lugar;

  /// Costo por jugador
  final double costoPorJugador;

  /// Costo formateado para mostrar
  final String costoFormato;

  /// Estado de la fecha
  final EstadoFecha estado;

  /// Total de inscritos actuales
  final int totalInscritos;

  /// Capacidad maxima
  final int capacidadMaxima;

  /// Indica si el usuario actual esta inscrito
  final bool usuarioInscrito;

  /// Nombre del creador
  final String creadorNombre;

  const FechaDisponibleModel({
    required this.fechaId,
    required this.fechaHoraInicio,
    required this.fechaFormato,
    required this.duracionHoras,
    required this.lugar,
    required this.costoPorJugador,
    required this.costoFormato,
    required this.estado,
    required this.totalInscritos,
    required this.capacidadMaxima,
    required this.usuarioInscrito,
    required this.creadorNombre,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  /// Campos del RPC listar_fechas_disponibles:
  /// id, fecha_hora_inicio, fecha_formato, hora_formato, duracion_horas,
  /// lugar, num_equipos, costo_por_jugador, costo_formato, estado,
  /// formato_juego, total_inscritos, usuario_inscrito, created_at
  factory FechaDisponibleModel.fromJson(Map<String, dynamic> json) {
    return FechaDisponibleModel(
      // El RPC retorna 'id' no 'fecha_id'
      fechaId: json['id'] ?? json['fecha_id'] ?? '',
      fechaHoraInicio: json['fecha_hora_inicio'] != null
          ? DateTime.parse(json['fecha_hora_inicio'].toString()).toLocal()
          : DateTime.now(),
      // Combinar fecha y hora para el formato
      fechaFormato: '${json['fecha_formato'] ?? ''} ${json['hora_formato'] ?? ''}',
      duracionHoras: json['duracion_horas'] ?? 1,
      lugar: json['lugar'] ?? '',
      costoPorJugador: (json['costo_por_jugador'] ?? 0).toDouble(),
      costoFormato: json['costo_formato'] ?? 'S/ 0.00',
      estado: EstadoFecha.fromString(json['estado'] ?? 'abierta'),
      totalInscritos: json['total_inscritos'] ?? 0,
      // El RPC no retorna capacidad_maxima, usar 0 (sin limite)
      capacidadMaxima: json['capacidad_maxima'] ?? 0,
      usuarioInscrito: json['usuario_inscrito'] ?? false,
      // El RPC no retorna creador_nombre directamente
      creadorNombre: json['creador_nombre'] ?? '',
    );
  }

  /// Lugares disponibles (si capacidadMaxima = 0, significa sin limite)
  int get lugaresDisponibles =>
      capacidadMaxima > 0 ? capacidadMaxima - totalInscritos : 999;

  /// Verifica si hay lugares (0 = sin limite = siempre hay lugar)
  bool get hayLugaresDisponibles =>
      capacidadMaxima == 0 || lugaresDisponibles > 0;

  /// RN-002: Solo fechas abiertas permiten inscripcion
  bool get puedeInscribirse =>
      estado == EstadoFecha.abierta && hayLugaresDisponibles && !usuarioInscrito;

  /// Descripcion de ocupacion
  /// Si capacidadMaxima = 0 (sin limite), solo muestra el total de inscritos
  String get ocupacionDisplay =>
      capacidadMaxima > 0 ? '$totalInscritos/$capacidadMaxima' : '$totalInscritos';

  /// Descripcion del formato segun duracion
  String get formatoJuego {
    if (duracionHoras == 1) {
      return '2 equipos';
    } else {
      return '3 equipos (rotacion)';
    }
  }

  @override
  List<Object?> get props => [
        fechaId,
        fechaHoraInicio,
        fechaFormato,
        duracionHoras,
        lugar,
        costoPorJugador,
        costoFormato,
        estado,
        totalInscritos,
        capacidadMaxima,
        usuarioInscrito,
        creadorNombre,
      ];
}

/// Modelo de respuesta al listar fechas disponibles
/// E003-HU-002: listar_fechas_disponibles RPC
class ListarFechasDisponiblesResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Mensaje del servidor
  final String message;

  /// Lista de fechas disponibles
  final List<FechaDisponibleModel> fechas;

  /// Total de fechas encontradas
  final int total;

  const ListarFechasDisponiblesResponseModel({
    required this.success,
    required this.message,
    required this.fechas,
    required this.total,
  });

  /// Crea instancia desde JSON del backend
  /// Estructura: { success, data: { fechas: [...], total }, message }
  factory ListarFechasDisponiblesResponseModel.fromJson(
      Map<String, dynamic> json) {
    // El 'data' es un objeto que contiene 'fechas' y 'total'
    final dataMap = json['data'] as Map<String, dynamic>? ?? {};
    final fechasJson = dataMap['fechas'] as List<dynamic>? ?? [];
    final fechas = fechasJson
        .map((e) => FechaDisponibleModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ListarFechasDisponiblesResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      fechas: fechas,
      total: dataMap['total'] ?? fechas.length,
    );
  }

  @override
  List<Object?> get props => [success, message, fechas, total];
}
