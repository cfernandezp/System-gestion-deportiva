import 'package:equatable/equatable.dart';

/// Enum para posiciones de jugador (RN-004)
enum PosicionJugador {
  arquero,
  defensa,
  mediocampista,
  delantero;

  /// Convierte string de BD a enum
  static PosicionJugador? fromString(String? value) {
    if (value == null) return null;
    return PosicionJugador.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => PosicionJugador.arquero, // Default si no coincide
    );
  }

  /// Nombre para mostrar en UI
  String get displayName {
    switch (this) {
      case PosicionJugador.arquero:
        return 'Arquero';
      case PosicionJugador.defensa:
        return 'Defensa';
      case PosicionJugador.mediocampista:
        return 'Mediocampista';
      case PosicionJugador.delantero:
        return 'Delantero';
    }
  }
}

/// Modelo del perfil de usuario
/// E002-HU-001: Ver Perfil Propio
/// Mapea respuesta de RPC obtener_perfil_propio()
class PerfilModel extends Equatable {
  final String usuarioId;
  final String nombreCompleto;
  final String apodo;
  final String email;
  final String? telefono;
  final PosicionJugador? posicionPreferida;
  final String? fotoUrl;
  final DateTime fechaIngreso;
  final String fechaIngresoFormato;
  final String antiguedad;
  final String estado;
  final String rol;

  const PerfilModel({
    required this.usuarioId,
    required this.nombreCompleto,
    required this.apodo,
    required this.email,
    this.telefono,
    this.posicionPreferida,
    this.fotoUrl,
    required this.fechaIngreso,
    required this.fechaIngresoFormato,
    required this.antiguedad,
    required this.estado,
    required this.rol,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory PerfilModel.fromJson(Map<String, dynamic> json) {
    return PerfilModel(
      usuarioId: json['usuario_id'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      apodo: json['apodo'] ?? 'Dato pendiente de completar',
      email: json['email'] ?? '',
      telefono: json['telefono'],
      posicionPreferida: json['posicion_preferida'] != null
          ? PosicionJugador.fromString(json['posicion_preferida'])
          : null,
      fotoUrl: json['foto_url'],
      fechaIngreso: json['fecha_ingreso'] != null
          ? DateTime.parse(json['fecha_ingreso']).toLocal()
          : DateTime.now(),
      fechaIngresoFormato: json['fecha_ingreso_formato'] ?? '',
      antiguedad: json['antiguedad'] ?? '',
      estado: json['estado'] ?? '',
      rol: json['rol'] ?? 'jugador',
    );
  }

  /// Verifica si el telefono esta especificado (RN-003)
  bool get tieneTelefono => telefono != null && telefono!.isNotEmpty;

  /// Verifica si la posicion esta especificada (RN-003)
  bool get tienePosicion => posicionPreferida != null;

  /// Verifica si tiene foto (RN-003)
  bool get tieneFoto => fotoUrl != null && fotoUrl!.isNotEmpty;

  /// Texto para mostrar telefono (CA-003)
  String get telefonoDisplay => tieneTelefono ? telefono! : 'No especificado';

  /// Texto para mostrar posicion (CA-003, RN-004)
  String get posicionDisplay =>
      tienePosicion ? posicionPreferida!.displayName : 'No especificado';

  /// Texto para mostrar el rol formateado
  String get rolDisplay {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'jugador':
        return 'Jugador';
      case 'arbitro':
        return 'Arbitro';
      case 'delegado':
        return 'Delegado';
      default:
        return rol;
    }
  }

  @override
  List<Object?> get props => [
        usuarioId,
        nombreCompleto,
        apodo,
        email,
        telefono,
        posicionPreferida,
        fotoUrl,
        fechaIngreso,
        fechaIngresoFormato,
        antiguedad,
        estado,
        rol,
      ];
}

/// Modelo de respuesta para obtener_perfil_propio
class PerfilResponseModel extends Equatable {
  final bool success;
  final PerfilModel? data;
  final String message;

  const PerfilResponseModel({
    required this.success,
    this.data,
    required this.message,
  });

  factory PerfilResponseModel.fromJson(Map<String, dynamic> json) {
    return PerfilResponseModel(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? PerfilModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'] ?? '',
    );
  }

  @override
  List<Object?> get props => [success, data, message];
}
