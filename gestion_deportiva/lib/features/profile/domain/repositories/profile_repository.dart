import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/perfil_model.dart';

/// Interface del repositorio de perfil
/// E002-HU-001: Ver Perfil Propio
/// Define el contrato para operaciones de perfil
abstract class ProfileRepository {
  /// Obtiene el perfil del usuario autenticado
  /// CA-001: Acceso al perfil desde seccion "Mi Perfil"
  /// CA-002: Muestra todos los datos visibles
  /// CA-003: Campos opcionales vacios muestran "No especificado"
  /// RN-001: Solo puede ver su propio perfil
  /// Retorna [PerfilResponseModel] si exito, [Failure] si error
  Future<Either<Failure, PerfilResponseModel>> obtenerPerfilPropio();
}
