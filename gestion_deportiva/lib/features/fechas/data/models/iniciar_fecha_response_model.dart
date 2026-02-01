import 'package:equatable/equatable.dart';

/// Modelo para detalle de equipo en respuesta de iniciar fecha
/// E003-HU-012: Iniciar Fecha
class EquipoDetalleModel extends Equatable {
  /// Color/nombre del equipo
  final String color;

  /// Cantidad de jugadores en el equipo
  final int jugadores;

  const EquipoDetalleModel({
    required this.color,
    required this.jugadores,
  });

  /// Factory para crear desde JSON del backend
  factory EquipoDetalleModel.fromJson(Map<String, dynamic> json) {
    return EquipoDetalleModel(
      color: json['color'] as String,
      jugadores: json['jugadores'] as int,
    );
  }

  @override
  List<Object?> get props => [color, jugadores];
}

/// Modelo de datos para el response de iniciar fecha
/// E003-HU-012: Iniciar Fecha
/// Mapea snake_case del backend a camelCase en Dart
class IniciarFechaDataModel extends Equatable {
  /// UUID de la fecha iniciada
  final String fechaId;

  /// Fecha formateada (DD/MM/YYYY HH24:MI)
  final String fechaFormato;

  /// Lugar de la pichanga
  final String lugar;

  /// Estado anterior de la fecha (siempre 'cerrada')
  final String estadoAnterior;

  /// Estado nuevo de la fecha (siempre 'en_juego')
  final String estadoNuevo;

  /// Hora pactada original (HH24:MI)
  final String horaPactada;

  /// Hora real de inicio (HH24:MI)
  final String horaInicioReal;

  /// UUID del admin que inicio
  final String iniciadoPor;

  /// Nombre del admin que inicio
  final String iniciadoPorNombre;

  /// Timestamp de inicio (ISO 8601)
  final String iniciadoAt;

  /// Timestamp formateado (DD/MM/YYYY HH24:MI)
  final String iniciadoAtFormato;

  /// Total de equipos con jugadores asignados
  final int totalEquipos;

  /// Total de jugadores inscritos
  final int totalJugadores;

  /// Detalle de equipos con sus jugadores
  final List<EquipoDetalleModel> equiposDetalle;

  /// Flag que indica si no hay equipos asignados (warning)
  final bool warningSinEquipos;

  /// Cantidad de notificaciones enviadas
  final int notificacionesEnviadas;

  const IniciarFechaDataModel({
    required this.fechaId,
    required this.fechaFormato,
    required this.lugar,
    required this.estadoAnterior,
    required this.estadoNuevo,
    required this.horaPactada,
    required this.horaInicioReal,
    required this.iniciadoPor,
    required this.iniciadoPorNombre,
    required this.iniciadoAt,
    required this.iniciadoAtFormato,
    required this.totalEquipos,
    required this.totalJugadores,
    required this.equiposDetalle,
    required this.warningSinEquipos,
    required this.notificacionesEnviadas,
  });

  /// Factory para crear desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory IniciarFechaDataModel.fromJson(Map<String, dynamic> json) {
    return IniciarFechaDataModel(
      fechaId: json['fecha_id'] as String,
      fechaFormato: json['fecha_formato'] as String,
      lugar: json['lugar'] as String,
      estadoAnterior: json['estado_anterior'] as String,
      estadoNuevo: json['estado_nuevo'] as String,
      horaPactada: json['hora_pactada'] as String? ?? '',
      horaInicioReal: json['hora_inicio_real'] as String? ?? '',
      iniciadoPor: json['iniciado_por'] as String,
      iniciadoPorNombre: json['iniciado_por_nombre'] as String? ?? '',
      iniciadoAt: json['iniciado_at'] as String,
      iniciadoAtFormato: json['iniciado_at_formato'] as String? ?? '',
      totalEquipos: json['total_equipos'] as int? ?? 0,
      totalJugadores: json['total_jugadores'] as int? ?? 0,
      equiposDetalle: (json['equipos_detalle'] as List<dynamic>?)
              ?.map((e) => EquipoDetalleModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      warningSinEquipos: json['warning_sin_equipos'] as bool? ?? false,
      notificacionesEnviadas: json['notificaciones_enviadas'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        fechaId,
        fechaFormato,
        lugar,
        estadoAnterior,
        estadoNuevo,
        horaPactada,
        horaInicioReal,
        iniciadoPor,
        iniciadoPorNombre,
        iniciadoAt,
        iniciadoAtFormato,
        totalEquipos,
        totalJugadores,
        equiposDetalle,
        warningSinEquipos,
        notificacionesEnviadas,
      ];
}

/// Modelo de response completo para iniciar fecha
/// E003-HU-012: Iniciar Fecha
class IniciarFechaResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Datos de la fecha iniciada
  final IniciarFechaDataModel data;

  /// Mensaje de confirmacion del servidor
  final String message;

  const IniciarFechaResponseModel({
    required this.success,
    required this.data,
    required this.message,
  });

  /// Factory para crear desde JSON del backend
  factory IniciarFechaResponseModel.fromJson(Map<String, dynamic> json) {
    return IniciarFechaResponseModel(
      success: json['success'] as bool,
      data: IniciarFechaDataModel.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String,
    );
  }

  @override
  List<Object?> get props => [success, data, message];
}
