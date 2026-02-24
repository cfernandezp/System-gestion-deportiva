import 'package:equatable/equatable.dart';

import '../../../../core/utils/date_utils.dart';

/// Modelo de un grupo en la lista "Mis Grupos"
/// E002-HU-002: Ver Mis Grupos
/// CA-001 / RN-002: Logo, nombre, rol, cantidad miembros
class MiGrupoModel extends Equatable {
  final String grupoId;
  final String nombre;
  final String? logoUrl;
  final String? lema;
  final String tipoDeporte;
  final bool activo;
  final String miRol;
  final int cantidadMiembros;
  final DateTime? ultimoAcceso;
  final String planNombre;

  const MiGrupoModel({
    required this.grupoId,
    required this.nombre,
    this.logoUrl,
    this.lema,
    required this.tipoDeporte,
    required this.activo,
    required this.miRol,
    required this.cantidadMiembros,
    this.ultimoAcceso,
    this.planNombre = 'Gratis',
  });

  factory MiGrupoModel.fromJson(Map<String, dynamic> json) {
    return MiGrupoModel(
      grupoId: json['grupo_id'] ?? '',
      nombre: json['nombre'] ?? '',
      logoUrl: json['logo_url'],
      lema: json['lema'],
      tipoDeporte: json['tipo_deporte'] ?? 'Futbol',
      activo: json['activo'] ?? true,
      miRol: json['mi_rol'] ?? 'jugador',
      cantidadMiembros: json['cantidad_miembros'] ?? 0,
      ultimoAcceso: AppDateUtils.tryParseUtcToLocal(json['ultimo_acceso']),
      planNombre: json['plan_nombre'] ?? 'Gratis',
    );
  }

  /// CA-002: Texto de rol formateado para UI
  String get rolFormateado {
    switch (miRol) {
      case 'admin':
        return 'Admin';
      case 'coadmin':
        return 'Co-Admin';
      case 'jugador':
        return 'Jugador';
      case 'invitado':
        return 'Invitado';
      default:
        return miRol;
    }
  }

  /// Si es admin o coadmin del grupo
  bool get esAdminOCoadmin => miRol == 'admin' || miRol == 'coadmin';

  /// Si el plan es gratuito
  bool get esPlanGratis => planNombre.toLowerCase() == 'gratis';

  /// Nombre del plan con prefijo "Plan" para display
  String get planDisplay => esPlanGratis ? 'Plan Gratis' : planNombre;

  @override
  List<Object?> get props => [
        grupoId,
        nombre,
        logoUrl,
        lema,
        tipoDeporte,
        activo,
        miRol,
        cantidadMiembros,
        ultimoAcceso,
        planNombre,
      ];
}
