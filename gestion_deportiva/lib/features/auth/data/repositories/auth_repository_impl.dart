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

  /// E001-HU-007: Identificar tipo de recuperacion
  @override
  Future<Either<Failure, TipoRecuperacionModel>> identificarTipoRecuperacion({
    required String celular,
  }) async {
    try {
      final result = await remoteDataSource.identificarTipoRecuperacion(
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

  /// E001-HU-007: Generar codigo de recuperacion
  @override
  Future<Either<Failure, GenerarCodigoModel>> generarCodigoRecuperacion({
    required String celularJugador,
  }) async {
    try {
      final result = await remoteDataSource.generarCodigoRecuperacion(
        celularJugador: celularJugador,
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

  /// E001-HU-007: Validar codigo de recuperacion
  @override
  Future<Either<Failure, ValidarCodigoModel>> validarCodigoRecuperacion({
    required String celular,
    required String codigo,
  }) async {
    try {
      final result = await remoteDataSource.validarCodigoRecuperacion(
        celular: celular,
        codigo: codigo,
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

  /// E001-HU-007: Restablecer contrasena con codigo
  @override
  Future<Either<Failure, RestablecerResultModel>> restablecerContrasenaConCodigo({
    required String celular,
    required String codigo,
    required String nuevaContrasena,
    required String confirmarContrasena,
  }) async {
    try {
      final result = await remoteDataSource.restablecerContrasenaConCodigo(
        celular: celular,
        codigo: codigo,
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

  /// E001-HU-007: Restablecer contrasena con pregunta de seguridad
  @override
  Future<Either<Failure, RestablecerResultModel>> restablecerContrasenaConPregunta({
    required String celular,
    required String respuesta,
    required String nuevaContrasena,
    required String confirmarContrasena,
  }) async {
    try {
      final result = await remoteDataSource.restablecerContrasenaConPregunta(
        celular: celular,
        respuesta: respuesta,
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

  /// E001-HU-007: Solicitar recuperacion via email admin
  @override
  Future<Either<Failure, RecuperacionEmailModel>> solicitarRecuperacionEmailAdmin({
    required String celular,
  }) async {
    try {
      final result = await remoteDataSource.solicitarRecuperacionEmailAdmin(
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
