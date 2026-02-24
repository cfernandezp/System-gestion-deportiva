import 'package:equatable/equatable.dart';

import '../../../../core/utils/date_utils.dart';

/// Modelo de grupo deportivo
/// E002-HU-001: Crear Grupo Deportivo
class GrupoModel extends Equatable {
  final String id;
  final String nombre;
  final String? logoUrl;
  final String? lema;
  final String? reglas;
  final String tipoDeporte;
  final String adminCreadorId;
  final String planId;
  final int limiteJugadores;
  final bool activo;
  final DateTime? createdAt;

  const GrupoModel({
    required this.id,
    required this.nombre,
    this.logoUrl,
    this.lema,
    this.reglas,
    required this.tipoDeporte,
    required this.adminCreadorId,
    required this.planId,
    required this.limiteJugadores,
    required this.activo,
    this.createdAt,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory GrupoModel.fromJson(Map<String, dynamic> json) {
    return GrupoModel(
      id: json['grupo_id'] ?? json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      logoUrl: json['logo_url'],
      lema: json['lema'],
      reglas: json['reglas'],
      tipoDeporte: json['tipo_deporte'] ?? 'Futbol',
      adminCreadorId: json['admin_creador_id'] ?? '',
      planId: json['plan_id'] ?? '',
      limiteJugadores: json['limite_jugadores'] ?? 25,
      activo: json['activo'] ?? true,
      createdAt: AppDateUtils.tryParseUtcToLocal(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        logoUrl,
        lema,
        reglas,
        tipoDeporte,
        adminCreadorId,
        planId,
        limiteJugadores,
        activo,
        createdAt,
      ];
}
