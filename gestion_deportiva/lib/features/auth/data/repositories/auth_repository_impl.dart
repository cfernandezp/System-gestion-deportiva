import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/cerrar_sesion_response_model.dart';
import '../models/login_response_model.dart';
import '../models/recuperacion_response_model.dart';
import '../models/registro_admin_response_model.dart';
import '../models/activacion_cuenta_response_model.dart';
import '../models/registro_response_model.dart';
import '../models/validacion_password_model.dart';
import '../models/verificar_estado_model.dart';
import '../models/verificar_invitacion_model.dart';

/// Implementacion del repositorio de autenticacion
/// Maneja errores y convierte excepciones a Failures
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, RegistroResponseModel>> registrarUsuario({
    required String nombreCompleto,
    required String email,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.registrarUsuario(
        nombreCompleto: nombreCompleto,
        email: email,
        password: password,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    }
  }

  @override
  Future<Either<Failure, ValidacionPasswordModel>> validarPassword({
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.validarPassword(
        password: password,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    }
  }

  @override
  Future<Either<Failure, VerificarEstadoModel>> verificarEstadoUsuario({
    required String authUserId,
  }) async {
    try {
      final result = await remoteDataSource.verificarEstadoUsuario(
        authUserId: authUserId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    }
  }

  @override
  Future<Either<Failure, LoginResponseModel>> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.iniciarSesion(
        email: email,
        password: password,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    }
  }

  @override
  Future<Either<Failure, VerificarBloqueoModel>> verificarBloqueoLogin({
    required String email,
  }) async {
    try {
      final result = await remoteDataSource.verificarBloqueoLogin(
        email: email,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    }
  }

  @override
  Future<Either<Failure, CerrarSesionResponseModel>> cerrarSesion() async {
    try {
      final result = await remoteDataSource.cerrarSesion();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    }
  }

  @override
  Future<Either<Failure, SolicitudRecuperacionModel>> solicitarRecuperacion({
    required String email,
  }) async {
    try {
      final result = await remoteDataSource.solicitarRecuperacion(
        email: email,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    }
  }

  @override
  Future<Either<Failure, ValidarTokenModel>> validarTokenRecuperacion({
    required String token,
  }) async {
    try {
      final result = await remoteDataSource.validarTokenRecuperacion(
        token: token,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    }
  }

  @override
  Future<Either<Failure, RestablecerContrasenaModel>> restablecerContrasena({
    required String token,
    required String nuevaContrasena,
    required String confirmarContrasena,
  }) async {
    try {
      final result = await remoteDataSource.restablecerContrasena(
        token: token,
        nuevaContrasena: nuevaContrasena,
        confirmarContrasena: confirmarContrasena,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    }
  }

  /// E001-HU-001: Registrar administrador
  @override
  Future<Either<Failure, RegistroAdminResponseModel>> registrarAdministrador({
    required String celular,
    required String nombreCompleto,
    required String password,
    required String preguntaSeguridad,
    required String respuestaSeguridad,
    String? emailRespaldo,
  }) async {
    try {
      final result = await remoteDataSource.registrarAdministrador(
        celular: celular,
        nombreCompleto: nombreCompleto,
        password: password,
        preguntaSeguridad: preguntaSeguridad,
        respuestaSeguridad: respuestaSeguridad,
        emailRespaldo: emailRespaldo,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    }
  }

  /// E001-HU-005: Verificar invitacion pendiente
  @override
  Future<Either<Failure, VerificarInvitacionModel>> verificarInvitacionPendiente({
    required String celular,
  }) async {
    try {
      final result = await remoteDataSource.verificarInvitacionPendiente(
        celular: celular,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    }
  }

  /// E001-HU-005: Activar cuenta de jugador invitado
  @override
  Future<Either<Failure, ActivacionCuentaResponseModel>> activarCuentaJugador({
    required String celular,
    required String nombreCompleto,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.activarCuentaJugador(
        celular: celular,
        nombreCompleto: nombreCompleto,
        password: password,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
        hint: e.hint,
      ));
    }
  }
}
