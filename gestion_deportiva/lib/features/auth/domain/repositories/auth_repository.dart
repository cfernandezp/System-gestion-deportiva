import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/cerrar_sesion_response_model.dart';
import '../../data/models/login_response_model.dart';
import '../../data/models/recuperacion_response_model.dart';
import '../../data/models/registro_admin_response_model.dart';
import '../../data/models/activacion_cuenta_response_model.dart';
import '../../data/models/registro_response_model.dart';
import '../../data/models/validacion_password_model.dart';
import '../../data/models/verificar_estado_model.dart';
import '../../data/models/verificar_invitacion_model.dart';

/// Interface del repositorio de autenticacion
/// Define el contrato para operaciones de auth
abstract class AuthRepository {
  /// Registra un nuevo usuario en el sistema
  /// Retorna [RegistroResponseModel] si exito, [Failure] si error
  Future<Either<Failure, RegistroResponseModel>> registrarUsuario({
    required String nombreCompleto,
    required String email,
    required String password,
  });

  /// Valida los requisitos de seguridad del password
  /// Retorna [ValidacionPasswordModel] con resultado de validacion
  Future<Either<Failure, ValidacionPasswordModel>> validarPassword({
    required String password,
  });

  /// Verifica si el usuario puede acceder al sistema
  /// Retorna [VerificarEstadoModel] con estado y permisos
  Future<Either<Failure, VerificarEstadoModel>> verificarEstadoUsuario({
    required String authUserId,
  });

  /// Inicia sesion de usuario
  /// HU-002: CA-002, CA-003
  /// Retorna [LoginResponseModel] si exito, [Failure] si error
  Future<Either<Failure, LoginResponseModel>> iniciarSesion({
    required String email,
    required String password,
  });

  /// Verifica si un email esta bloqueado por intentos fallidos
  /// HU-002: RN-007
  /// Retorna [VerificarBloqueoModel] con estado de bloqueo
  Future<Either<Failure, VerificarBloqueoModel>> verificarBloqueoLogin({
    required String email,
  });

  /// Cierra la sesion del usuario actual
  /// HU-004: CA-002, RN-002, RN-004
  /// Retorna [CerrarSesionResponseModel] si exito, [Failure] si error
  Future<Either<Failure, CerrarSesionResponseModel>> cerrarSesion();

  /// Solicita recuperacion de contrasena
  /// HU-003: CA-001, CA-002, CA-003, RN-001
  Future<Either<Failure, SolicitudRecuperacionModel>> solicitarRecuperacion({
    required String email,
  });

  /// Valida token de recuperacion
  /// HU-003: CA-004, CA-005
  Future<Either<Failure, ValidarTokenModel>> validarTokenRecuperacion({
    required String token,
  });

  /// Restablece contrasena con token valido
  /// HU-003: CA-006, RN-004, RN-005, RN-006
  Future<Either<Failure, RestablecerContrasenaModel>> restablecerContrasena({
    required String token,
    required String nuevaContrasena,
    required String confirmarContrasena,
  });

  /// E001-HU-001: Registra un nuevo administrador
  /// RN-001: Celular como identificador unico
  /// RN-006: Cuenta activa inmediatamente
  Future<Either<Failure, RegistroAdminResponseModel>> registrarAdministrador({
    required String celular,
    required String nombreCompleto,
    required String password,
    required String preguntaSeguridad,
    required String respuestaSeguridad,
    String? emailRespaldo,
  });

  /// E001-HU-005: Verifica si un celular tiene invitacion pendiente
  /// CA-001, CA-002, CA-004
  Future<Either<Failure, VerificarInvitacionModel>> verificarInvitacionPendiente({
    required String celular,
  });

  /// E001-HU-005: Activa cuenta de jugador invitado
  /// CA-001, CA-005, CA-006, RN-002, RN-003, RN-005
  Future<Either<Failure, ActivacionCuentaResponseModel>> activarCuentaJugador({
    required String celular,
    required String nombreCompleto,
    required String password,
  });
}
