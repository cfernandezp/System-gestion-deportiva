import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/usuario_admin_model.dart';

/// Interface del repositorio de administracion
/// HU-005: Gestion de Roles
/// Define el contrato para operaciones de admin
abstract class AdminRepository {
  /// Lista todos los usuarios con su rol actual
  /// Permite busqueda por nombre o email
  /// HU-005: CA-001, CA-005, RN-006, RN-007
  /// Retorna [ListarUsuariosResponseModel] si exito, [Failure] si error
  Future<Either<Failure, ListarUsuariosResponseModel>> listarUsuarios({
    String? busqueda,
  });

  /// Cambia el rol de un usuario especifico
  /// HU-005: CA-002, CA-003, CA-004
  /// Retorna [CambiarRolResponseModel] si exito, [Failure] si error
  Future<Either<Failure, CambiarRolResponseModel>> cambiarRolUsuario({
    required String usuarioId,
    required String nuevoRol,
  });
}
