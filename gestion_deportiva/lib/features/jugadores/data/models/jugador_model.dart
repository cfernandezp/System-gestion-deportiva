import 'package:equatable/equatable.dart';

import '../../../profile/data/models/perfil_model.dart';

/// Modelo de jugador para la lista
/// E002-HU-003: Lista de Jugadores
/// RN-002: Solo informacion publica (no email/telefono)
class JugadorModel extends Equatable {
  final String jugadorId;
  final String nombreCompleto;
  final String apodo;
  final PosicionJugador? posicionPreferida;
  final String? fotoUrl;
  final DateTime fechaIngreso;
  final String fechaIngresoFormato;

  const JugadorModel({
    required this.jugadorId,
    required this.nombreCompleto,
    required this.apodo,
    this.posicionPreferida,
    this.fotoUrl,
    required this.fechaIngreso,
    required this.fechaIngresoFormato,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory JugadorModel.fromJson(Map<String, dynamic> json) {
    return JugadorModel(
      jugadorId: json['jugador_id'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      apodo: json['apodo'] ?? 'Sin apodo',
      posicionPreferida: json['posicion_preferida'] != null
          ? PosicionJugador.fromString(json['posicion_preferida'])
          : null,
      fotoUrl: json['foto_url'],
      fechaIngreso: json['fecha_ingreso'] != null
          ? DateTime.parse(json['fecha_ingreso']).toLocal()
          : DateTime.now(),
      fechaIngresoFormato: json['fecha_ingreso_formato'] ?? '',
    );
  }

  /// Verifica si tiene foto (RN-002)
  bool get tieneFoto => fotoUrl != null && fotoUrl!.isNotEmpty;

  /// Texto para mostrar posicion (CA-002, RN-002)
  String get posicionDisplay =>
      posicionPreferida?.displayName ?? 'Sin definir';

  /// Iniciales para avatar generico
  String get iniciales {
    final palabras = nombreCompleto.trim().split(' ');
    if (palabras.isEmpty) return '?';
    if (palabras.length == 1) return palabras[0][0].toUpperCase();
    return '${palabras[0][0]}${palabras[palabras.length - 1][0]}'.toUpperCase();
  }

  @override
  List<Object?> get props => [
        jugadorId,
        nombreCompleto,
        apodo,
        posicionPreferida,
        fotoUrl,
        fechaIngreso,
        fechaIngresoFormato,
      ];
}

/// Enum para tipo de ordenamiento
enum OrdenCampo {
  nombre,
  fechaIngreso;

  String get valor {
    switch (this) {
      case OrdenCampo.nombre:
        return 'nombre';
      case OrdenCampo.fechaIngreso:
        return 'fecha_ingreso';
    }
  }

  String get displayName {
    switch (this) {
      case OrdenCampo.nombre:
        return 'Nombre';
      case OrdenCampo.fechaIngreso:
        return 'Fecha de ingreso';
    }
  }
}

/// Enum para direccion de ordenamiento
enum OrdenDireccion {
  asc,
  desc;

  String get valor => name;

  String get displayName {
    switch (this) {
      case OrdenDireccion.asc:
        return 'Ascendente';
      case OrdenDireccion.desc:
        return 'Descendente';
    }
  }

  /// Icono para UI
  String get icono => this == OrdenDireccion.asc ? 'arrow_upward' : 'arrow_downward';
}

/// Modelo de filtros aplicados
class FiltrosJugadores extends Equatable {
  final String? busqueda;
  final OrdenCampo ordenCampo;
  final OrdenDireccion ordenDireccion;

  const FiltrosJugadores({
    this.busqueda,
    this.ordenCampo = OrdenCampo.nombre,
    this.ordenDireccion = OrdenDireccion.asc,
  });

  FiltrosJugadores copyWith({
    String? busqueda,
    OrdenCampo? ordenCampo,
    OrdenDireccion? ordenDireccion,
    bool clearBusqueda = false,
  }) {
    return FiltrosJugadores(
      busqueda: clearBusqueda ? null : (busqueda ?? this.busqueda),
      ordenCampo: ordenCampo ?? this.ordenCampo,
      ordenDireccion: ordenDireccion ?? this.ordenDireccion,
    );
  }

  @override
  List<Object?> get props => [busqueda, ordenCampo, ordenDireccion];
}

/// Modelo de respuesta para listar_jugadores
class ListaJugadoresResponseModel extends Equatable {
  final bool success;
  final List<JugadorModel> jugadores;
  final int total;
  final FiltrosJugadores filtros;
  final String message;

  const ListaJugadoresResponseModel({
    required this.success,
    required this.jugadores,
    required this.total,
    required this.filtros,
    required this.message,
  });

  factory ListaJugadoresResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final jugadoresList = data['jugadores'] as List? ?? [];
    final filtrosData = data['filtros'] as Map<String, dynamic>? ?? {};

    return ListaJugadoresResponseModel(
      success: json['success'] ?? false,
      jugadores: jugadoresList
          .map((j) => JugadorModel.fromJson(j as Map<String, dynamic>))
          .toList(),
      total: data['total'] ?? 0,
      filtros: FiltrosJugadores(
        busqueda: filtrosData['busqueda'],
        ordenCampo: filtrosData['orden_campo'] == 'fecha_ingreso'
            ? OrdenCampo.fechaIngreso
            : OrdenCampo.nombre,
        ordenDireccion: filtrosData['orden_direccion'] == 'desc'
            ? OrdenDireccion.desc
            : OrdenDireccion.asc,
      ),
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [success, jugadores, total, filtros, message];
}
