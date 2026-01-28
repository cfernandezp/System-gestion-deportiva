import 'color_equipo.dart';

/// Modelo para la respuesta de obtener_mi_equipo RPC
/// E003-HU-006: Ver Mi Equipo
/// CA-001, CA-002, CA-003, CA-005, CA-006, RN-001, RN-003
class MiEquipoResponseModel {
  final bool success;
  final MiEquipoDataModel? data;
  final String message;

  MiEquipoResponseModel({
    required this.success,
    this.data,
    required this.message,
  });

  factory MiEquipoResponseModel.fromJson(Map<String, dynamic> json) {
    return MiEquipoResponseModel(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null
          ? MiEquipoDataModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String? ?? '',
    );
  }
}

/// Modelo con los datos de mi equipo
class MiEquipoDataModel {
  final bool estaInscrito;
  final bool tieneEquipo;
  final bool equiposAsignados;
  final String? mensaje;
  final EquipoInfoModel? miEquipo;
  final List<CompaneroModel> companeros;
  final int totalCompaneros;

  MiEquipoDataModel({
    required this.estaInscrito,
    required this.tieneEquipo,
    required this.equiposAsignados,
    this.mensaje,
    this.miEquipo,
    this.companeros = const [],
    this.totalCompaneros = 0,
  });

  factory MiEquipoDataModel.fromJson(Map<String, dynamic> json) {
    return MiEquipoDataModel(
      estaInscrito: json['esta_inscrito'] as bool? ?? false,
      tieneEquipo: json['tiene_equipo'] as bool? ?? false,
      equiposAsignados: json['equipos_asignados'] as bool? ?? false,
      mensaje: json['mensaje'] as String?,
      miEquipo: json['mi_equipo'] != null
          ? EquipoInfoModel.fromJson(json['mi_equipo'] as Map<String, dynamic>)
          : null,
      companeros: (json['companeros'] as List<dynamic>?)
              ?.map((e) => CompaneroModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCompaneros: json['total_companeros'] as int? ?? 0,
    );
  }
}

/// Modelo con la informacion del equipo
/// CA-001: Ver mi equipo asignado
/// CA-002: Color visual destacado
class EquipoInfoModel {
  final String colorEquipo;
  final int numeroEquipo;
  final String nombreEquipo;
  final String colorHex;
  final DateTime? asignadoAt;
  final String? asignadoAtFormato;
  final String? asignadoPor;

  EquipoInfoModel({
    required this.colorEquipo,
    required this.numeroEquipo,
    required this.nombreEquipo,
    required this.colorHex,
    this.asignadoAt,
    this.asignadoAtFormato,
    this.asignadoPor,
  });

  factory EquipoInfoModel.fromJson(Map<String, dynamic> json) {
    return EquipoInfoModel(
      colorEquipo: json['color_equipo'] as String? ?? '',
      numeroEquipo: json['numero_equipo'] as int? ?? 0,
      nombreEquipo: json['nombre_equipo'] as String? ?? '',
      colorHex: json['color_hex'] as String? ?? '#9E9E9E',
      asignadoAt: json['asignado_at'] != null
          ? DateTime.tryParse(json['asignado_at'].toString())
          : null,
      asignadoAtFormato: json['asignado_at_formato'] as String?,
      asignadoPor: json['asignado_por'] as String?,
    );
  }

  /// Obtiene el ColorEquipo enum
  ColorEquipo? get colorEquipoEnum => ColorEquipo.fromString(colorEquipo);
}

/// Modelo para un companero de equipo
/// CA-003: Lista de companeros
/// RN-003: Solo informacion publica (foto, apodo)
class CompaneroModel {
  final String usuarioId;
  final String nombre;
  final String nombreCompleto;
  final String? fotoUrl;
  final bool esTu;

  CompaneroModel({
    required this.usuarioId,
    required this.nombre,
    required this.nombreCompleto,
    this.fotoUrl,
    this.esTu = false,
  });

  factory CompaneroModel.fromJson(Map<String, dynamic> json) {
    return CompaneroModel(
      usuarioId: json['usuario_id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      nombreCompleto: json['nombre_completo'] as String? ?? '',
      fotoUrl: json['foto_url'] as String?,
      esTu: json['es_tu'] as bool? ?? false,
    );
  }
}
