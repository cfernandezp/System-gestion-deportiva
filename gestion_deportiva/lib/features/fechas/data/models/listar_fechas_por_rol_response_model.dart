import 'package:equatable/equatable.dart';

import 'fecha_model.dart';

/// Modelo del indicador visual para una fecha
/// E003-HU-009: listar_fechas_por_rol RPC
/// Indica el estado visual de la fecha (color, icono, texto)
class IndicadorFechaModel extends Equatable {
  /// Color hexadecimal del indicador
  final String color;

  /// Nombre del icono a mostrar
  final String icono;

  /// Texto descriptivo del indicador
  final String texto;

  const IndicadorFechaModel({
    required this.color,
    required this.icono,
    required this.texto,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory IndicadorFechaModel.fromJson(Map<String, dynamic> json) {
    return IndicadorFechaModel(
      color: json['color'] ?? '#9E9E9E',
      icono: json['icono'] ?? 'info',
      texto: json['texto'] ?? '',
    );
  }

  /// Indicador por defecto cuando no hay datos
  factory IndicadorFechaModel.empty() {
    return const IndicadorFechaModel(
      color: '#9E9E9E',
      icono: 'info',
      texto: 'Sin estado',
    );
  }

  @override
  List<Object?> get props => [color, icono, texto];
}

/// Modelo de fecha para listar por rol
/// E003-HU-009: listar_fechas_por_rol RPC
/// Version con indicador visual y permisos de accion
class FechaPorRolModel extends Equatable {
  /// ID de la fecha
  final String id;

  /// Fecha y hora de inicio (UTC convertida a local)
  final DateTime fechaHoraInicio;

  /// Fecha formateada para mostrar (DD/MM/YYYY)
  final String fechaFormato;

  /// Hora formateada para mostrar (HH:MI)
  final String horaFormato;

  /// Lugar de la pichanga
  final String lugar;

  /// Duracion en horas
  final int duracionHoras;

  /// Numero de equipos
  final int numEquipos;

  /// Costo por jugador
  final double costoPorJugador;

  /// Costo formateado para mostrar (S/ XX.XX)
  final String costoFormato;

  /// Estado de la fecha
  final EstadoFecha estado;

  /// Total de inscritos actuales
  final int totalInscritos;

  /// Indica si el usuario actual esta inscrito
  final bool usuarioInscrito;

  /// Equipo asignado al usuario (azul, rojo, amarillo, null)
  final String? equipoAsignado;

  /// Numero del equipo (1, 2, 3, null)
  final int? numeroEquipo;

  /// Indica si el usuario puede inscribirse
  final bool puedeInscribirse;

  /// Indica si el usuario puede cancelar su inscripcion
  final bool puedeCancelar;

  /// Indicador visual de la fecha
  final IndicadorFechaModel indicador;

  const FechaPorRolModel({
    required this.id,
    required this.fechaHoraInicio,
    required this.fechaFormato,
    required this.horaFormato,
    required this.lugar,
    required this.duracionHoras,
    required this.numEquipos,
    required this.costoPorJugador,
    required this.costoFormato,
    required this.estado,
    required this.totalInscritos,
    required this.usuarioInscrito,
    this.equipoAsignado,
    this.numeroEquipo,
    required this.puedeInscribirse,
    required this.puedeCancelar,
    required this.indicador,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory FechaPorRolModel.fromJson(Map<String, dynamic> json) {
    return FechaPorRolModel(
      id: json['id'] ?? '',
      fechaHoraInicio: json['fecha_hora_inicio'] != null
          ? DateTime.parse(json['fecha_hora_inicio'].toString()).toLocal()
          : DateTime.now(),
      fechaFormato: json['fecha_formato'] ?? '',
      horaFormato: json['hora_formato'] ?? '',
      lugar: json['lugar'] ?? '',
      duracionHoras: json['duracion_horas'] ?? 1,
      numEquipos: json['num_equipos'] ?? 2,
      costoPorJugador: (json['costo_por_jugador'] ?? 0).toDouble(),
      costoFormato: json['costo_formato'] ?? 'S/ 0.00',
      estado: EstadoFecha.fromString(json['estado'] ?? 'abierta'),
      totalInscritos: json['total_inscritos'] ?? 0,
      usuarioInscrito: json['usuario_inscrito'] ?? false,
      equipoAsignado: json['equipo_asignado'],
      numeroEquipo: json['numero_equipo'],
      puedeInscribirse: json['puede_inscribirse'] ?? false,
      puedeCancelar: json['puede_cancelar'] ?? false,
      indicador: json['indicador'] != null
          ? IndicadorFechaModel.fromJson(
              json['indicador'] as Map<String, dynamic>)
          : IndicadorFechaModel.empty(),
    );
  }

  /// Fecha y hora formateadas juntas
  String get fechaHoraDisplay => '$fechaFormato $horaFormato';

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
        id,
        fechaHoraInicio,
        fechaFormato,
        horaFormato,
        lugar,
        duracionHoras,
        numEquipos,
        costoPorJugador,
        costoFormato,
        estado,
        totalInscritos,
        usuarioInscrito,
        equipoAsignado,
        numeroEquipo,
        puedeInscribirse,
        puedeCancelar,
        indicador,
      ];
}

/// Modelo de filtros aplicados
/// E003-HU-009: listar_fechas_por_rol RPC
class FiltrosAplicadosModel extends Equatable {
  /// Estado filtrado (opcional)
  final String? estado;

  /// Fecha desde filtrada (opcional)
  final DateTime? fechaDesde;

  /// Fecha hasta filtrada (opcional)
  final DateTime? fechaHasta;

  const FiltrosAplicadosModel({
    this.estado,
    this.fechaDesde,
    this.fechaHasta,
  });

  /// Crea instancia desde JSON del backend
  factory FiltrosAplicadosModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const FiltrosAplicadosModel();
    }
    return FiltrosAplicadosModel(
      estado: json['estado'],
      fechaDesde: json['fecha_desde'] != null
          ? DateTime.parse(json['fecha_desde'].toString()).toLocal()
          : null,
      fechaHasta: json['fecha_hasta'] != null
          ? DateTime.parse(json['fecha_hasta'].toString()).toLocal()
          : null,
    );
  }

  /// Indica si hay algun filtro activo
  bool get hayFiltros => estado != null || fechaDesde != null || fechaHasta != null;

  @override
  List<Object?> get props => [estado, fechaDesde, fechaHasta];
}

/// Modelo de respuesta al listar fechas por rol
/// E003-HU-009: listar_fechas_por_rol RPC
class ListarFechasPorRolResponseModel extends Equatable {
  /// Indica si la operacion fue exitosa
  final bool success;

  /// Mensaje del servidor
  final String message;

  /// Lista de fechas
  final List<FechaPorRolModel> fechas;

  /// Seccion actual (proximas, pasadas, todas)
  final String seccion;

  /// Total de fechas encontradas
  final int total;

  /// Indica si el usuario es admin
  final bool esAdmin;

  /// Filtros aplicados (solo para admin)
  final FiltrosAplicadosModel? filtrosAplicados;

  const ListarFechasPorRolResponseModel({
    required this.success,
    required this.message,
    required this.fechas,
    required this.seccion,
    required this.total,
    required this.esAdmin,
    this.filtrosAplicados,
  });

  /// Crea instancia desde JSON del backend
  /// Estructura: { success, data: { fechas: [...], seccion, total, es_admin, filtros_aplicados }, message }
  factory ListarFechasPorRolResponseModel.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] as Map<String, dynamic>? ?? {};
    final fechasJson = dataMap['fechas'] as List<dynamic>? ?? [];
    final fechas = fechasJson
        .map((e) => FechaPorRolModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ListarFechasPorRolResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      fechas: fechas,
      seccion: dataMap['seccion'] ?? 'proximas',
      total: dataMap['total'] ?? fechas.length,
      esAdmin: dataMap['es_admin'] ?? false,
      filtrosAplicados: dataMap['filtros_aplicados'] != null
          ? FiltrosAplicadosModel.fromJson(
              dataMap['filtros_aplicados'] as Map<String, dynamic>?)
          : null,
    );
  }

  /// Indica si hay fechas
  bool get hayFechas => fechas.isNotEmpty;

  /// Fechas donde el usuario esta inscrito
  List<FechaPorRolModel> get fechasInscritas =>
      fechas.where((f) => f.usuarioInscrito).toList();

  /// Fechas donde el usuario puede inscribirse
  List<FechaPorRolModel> get fechasParaInscribirse =>
      fechas.where((f) => f.puedeInscribirse).toList();

  @override
  List<Object?> get props => [
        success,
        message,
        fechas,
        seccion,
        total,
        esAdmin,
        filtrosAplicados,
      ];
}
