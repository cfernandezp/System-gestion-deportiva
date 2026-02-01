// E003-HU-011: Inscribir Jugador como Admin
// Modelos para la respuesta de inscripcion administrativa

/// Modelo de jugador disponible para inscripcion
/// CA-002: Lista de jugadores aprobados que no estan inscritos
class JugadorDisponibleModel {
  final String id;
  final String nombreCompleto;
  final String? apodo;
  final String nombreDisplay;
  final String? posicionPreferida;
  final String? fotoUrl;

  const JugadorDisponibleModel({
    required this.id,
    required this.nombreCompleto,
    this.apodo,
    required this.nombreDisplay,
    this.posicionPreferida,
    this.fotoUrl,
  });

  factory JugadorDisponibleModel.fromJson(Map<String, dynamic> json) {
    return JugadorDisponibleModel(
      id: json['id'] as String,
      nombreCompleto: json['nombre_completo'] as String,
      apodo: json['apodo'] as String?,
      nombreDisplay: json['nombre_display'] as String? ?? json['nombre_completo'] as String,
      posicionPreferida: json['posicion_preferida'] as String?,
      fotoUrl: json['foto_url'] as String?,
    );
  }

  /// Inicial para avatar
  String get inicial => nombreDisplay.isNotEmpty ? nombreDisplay[0].toUpperCase() : '?';
}

/// Modelo de respuesta de listar jugadores disponibles
/// RPC: listar_jugadores_disponibles_inscripcion
class ListarJugadoresDisponiblesResponseModel {
  final bool success;
  final List<JugadorDisponibleModel> jugadores;
  final int total;
  final String message;

  const ListarJugadoresDisponiblesResponseModel({
    required this.success,
    required this.jugadores,
    required this.total,
    required this.message,
  });

  factory ListarJugadoresDisponiblesResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final jugadoresList = data['jugadores'] as List<dynamic>? ?? [];

    return ListarJugadoresDisponiblesResponseModel(
      success: json['success'] as bool? ?? false,
      jugadores: jugadoresList
          .map((j) => JugadorDisponibleModel.fromJson(j as Map<String, dynamic>))
          .toList(),
      total: data['total'] as int? ?? 0,
      message: json['message'] as String? ?? '',
    );
  }

  bool get estaVacia => jugadores.isEmpty;
}

/// Modelo de datos de inscripcion realizada
class InscripcionAdminDataModel {
  final String inscripcionId;
  final String fechaId;
  final String jugadorId;
  final String jugadorNombre;
  final String fechaFormato;
  final String lugar;
  final double costoPorJugador;
  final String costoFormato;
  final String pagoId;
  final String estadoInscripcion;
  final String estadoPago;
  final int totalInscritos;
  final String inscritoPorId;
  final String inscritoPorNombre;

  const InscripcionAdminDataModel({
    required this.inscripcionId,
    required this.fechaId,
    required this.jugadorId,
    required this.jugadorNombre,
    required this.fechaFormato,
    required this.lugar,
    required this.costoPorJugador,
    required this.costoFormato,
    required this.pagoId,
    required this.estadoInscripcion,
    required this.estadoPago,
    required this.totalInscritos,
    required this.inscritoPorId,
    required this.inscritoPorNombre,
  });

  factory InscripcionAdminDataModel.fromJson(Map<String, dynamic> json) {
    return InscripcionAdminDataModel(
      inscripcionId: json['inscripcion_id'] as String,
      fechaId: json['fecha_id'] as String,
      jugadorId: json['jugador_id'] as String,
      jugadorNombre: json['jugador_nombre'] as String,
      fechaFormato: json['fecha_formato'] as String? ?? '',
      lugar: json['lugar'] as String? ?? '',
      costoPorJugador: (json['costo_por_jugador'] as num?)?.toDouble() ?? 0.0,
      costoFormato: json['costo_formato'] as String? ?? '',
      pagoId: json['pago_id'] as String,
      estadoInscripcion: json['estado_inscripcion'] as String? ?? 'inscrito',
      estadoPago: json['estado_pago'] as String? ?? 'pendiente',
      totalInscritos: json['total_inscritos'] as int? ?? 0,
      inscritoPorId: json['inscrito_por_id'] as String,
      inscritoPorNombre: json['inscrito_por_nombre'] as String? ?? '',
    );
  }
}

/// Modelo de respuesta de inscribir jugador como admin
/// RPC: inscribir_jugador_admin
/// CA-004: Confirmacion de inscripcion exitosa
class InscribirJugadorAdminResponseModel {
  final bool success;
  final InscripcionAdminDataModel? data;
  final String message;

  const InscribirJugadorAdminResponseModel({
    required this.success,
    this.data,
    required this.message,
  });

  factory InscribirJugadorAdminResponseModel.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'] as Map<String, dynamic>?;

    return InscribirJugadorAdminResponseModel(
      success: json['success'] as bool? ?? false,
      data: dataJson != null ? InscripcionAdminDataModel.fromJson(dataJson) : null,
      message: json['message'] as String? ?? '',
    );
  }
}
