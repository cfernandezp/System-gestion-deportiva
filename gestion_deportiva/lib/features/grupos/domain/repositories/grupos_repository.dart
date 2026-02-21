import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/crear_grupo_response_model.dart';
import '../../data/models/invitar_jugador_response_model.dart';
import '../../data/models/miembro_grupo_model.dart';
import '../../data/models/mi_grupo_model.dart';

/// Repositorio abstracto para operaciones de grupos
/// E002-HU-001: Crear Grupo Deportivo
abstract class GruposRepository {
  /// Crea un nuevo grupo deportivo
  /// CA-001 a CA-007
  Future<Either<Failure, CrearGrupoResponseModel>> crearGrupo({
    required String nombre,
    String? lema,
    String? reglas,
    String? logoUrl,
  });

  /// Sube el logo del grupo a Storage
  /// CA-003 / RN-003
  Future<Either<Failure, String>> subirLogo(File imagen);

  /// Cuenta grupos activos donde el usuario es admin creador
  /// CA-006: Para validar limite
  Future<Either<Failure, int>> contarGruposComoAdmin();

  /// E002-HU-002: Obtiene todos los grupos del usuario
  /// CA-001: Lista con logo, nombre, rol, miembros
  Future<Either<Failure, List<MiGrupoModel>>> obtenerMisGrupos();

  /// E002-HU-002: Registra acceso a un grupo
  /// CA-004 / RN-003: Actualiza ultimo_acceso
  Future<Either<Failure, void>> registrarAccesoGrupo(String grupoId);

  /// E001-HU-004: Invita un jugador al grupo
  /// CA-001 a CA-004, CA-006, CA-007
  Future<Either<Failure, InvitarJugadorResponseModel>> invitarJugadorGrupo({
    required String grupoId,
    required String celular,
  });

  /// E001-HU-004: Obtiene miembros del grupo
  /// CA-005: Lista con estado
  Future<Either<Failure, List<MiembroGrupoModel>>> obtenerMiembrosGrupo(String grupoId);
}
