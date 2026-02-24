import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/crear_grupo_response_model.dart';
import '../../data/models/editar_grupo_response_model.dart';
import '../../data/models/grupo_model.dart';
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

  /// E002-HU-003: Obtiene detalle completo del grupo
  Future<Either<Failure, GrupoModel>> obtenerDetalleGrupo(String grupoId);

  /// E002-HU-003: Edita nombre, logo, lema y reglas del grupo
  /// CA-001 a CA-005, RN-001 a RN-004
  Future<Either<Failure, EditarGrupoResponseModel>> editarGrupo({
    required String grupoId,
    required String nombre,
    String? lema,
    String? reglas,
    String? logoUrl,
  });

  /// E002-HU-006: Elimina jugador del grupo
  Future<Either<Failure, void>> eliminarJugadorGrupo({
    required String grupoId,
    required String miembroId,
  });

  /// E002-HU-004: Promueve jugador a co-admin
  /// CA-001, RN-001 a RN-003
  Future<Either<Failure, Map<String, dynamic>>> promoverACoadmin({
    required String grupoId,
    required String miembroId,
  });

  /// E002-HU-004: Degrada co-admin a jugador
  /// CA-002, RN-001, RN-005
  Future<Either<Failure, Map<String, dynamic>>> degradarCoadmin({
    required String grupoId,
    required String miembroId,
  });

  /// E002-HU-008: Registra un invitado en el grupo
  Future<Either<Failure, Map<String, dynamic>>> registrarInvitado({
    required String grupoId,
    required String nombre,
  });

  /// E002-HU-008: Elimina un invitado del grupo
  Future<Either<Failure, void>> eliminarInvitado({
    required String grupoId,
    required String miembroId,
  });

  /// E002-HU-009: Promueve un invitado a jugador asignandole un celular
  Future<Either<Failure, Map<String, dynamic>>> promoverInvitadoAJugador({
    required String grupoId,
    required String miembroId,
    required String celular,
  });
}
