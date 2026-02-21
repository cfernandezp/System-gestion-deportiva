import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/grupos_repository.dart';
import 'editar_grupo_event.dart';
import 'editar_grupo_state.dart';

/// E002-HU-003: BLoC para editar grupo deportivo
/// CA-001 a CA-005, RN-001 a RN-004
class EditarGrupoBloc extends Bloc<EditarGrupoEvent, EditarGrupoState> {
  final GruposRepository repository;

  EditarGrupoBloc({
    required this.repository,
  }) : super(const EditarGrupoInitial()) {
    on<CargarDetalleGrupoEvent>(_onCargarDetalle);
    on<EditarGrupoSubmitEvent>(_onEditarGrupoSubmit);
  }

  /// Carga el detalle del grupo para precargar el formulario
  Future<void> _onCargarDetalle(
    CargarDetalleGrupoEvent event,
    Emitter<EditarGrupoState> emit,
  ) async {
    emit(const EditarGrupoLoading());

    final result = await repository.obtenerDetalleGrupo(event.grupoId);

    result.fold(
      (failure) => emit(EditarGrupoError(
        message: failure.message,
        hint: failure is ServerFailure ? failure.hint : null,
      )),
      (grupo) => emit(EditarGrupoDetalleCargado(grupo: grupo)),
    );
  }

  /// Edita el grupo: sube logo si hay nuevo, luego llama RPC editar_grupo
  Future<void> _onEditarGrupoSubmit(
    EditarGrupoSubmitEvent event,
    Emitter<EditarGrupoState> emit,
  ) async {
    // Validacion frontend: nombre requerido
    final nombreLimpio = event.nombre.trim();
    if (nombreLimpio.isEmpty) {
      emit(const EditarGrupoError(
        message: 'El nombre del grupo es obligatorio',
        hint: 'nombre_requerido',
      ));
      return;
    }

    if (nombreLimpio.length > 100) {
      emit(const EditarGrupoError(
        message: 'El nombre no puede exceder 100 caracteres',
        hint: 'nombre_muy_largo',
      ));
      return;
    }

    // RN-003: Validar lema max 100 chars
    if (event.lema != null && event.lema!.trim().length > 100) {
      emit(const EditarGrupoError(
        message: 'El lema no puede exceder 100 caracteres',
        hint: 'lema_muy_largo',
      ));
      return;
    }

    // CA-003 / RN-003: Subir logo si se proporciono nuevo
    String? logoUrl;
    if (event.imagenLogo != null) {
      emit(const EditarGrupoSubiendoLogo());

      final logoResult = await repository.subirLogo(event.imagenLogo!);
      final logoFailed = logoResult.fold(
        (failure) {
          emit(EditarGrupoError(
            message: failure.message,
            hint: failure is ServerFailure ? failure.hint : null,
          ));
          return true;
        },
        (url) {
          logoUrl = url;
          return false;
        },
      );

      if (logoFailed) return;
    }

    emit(const EditarGrupoGuardando());

    // Editar grupo via RPC
    debugPrint('[EditarGrupoBloc] Editando grupo: ${event.grupoId}');

    final result = await repository.editarGrupo(
      grupoId: event.grupoId,
      nombre: nombreLimpio,
      lema: event.lema?.trim(),
      reglas: event.reglas?.trim(),
      logoUrl: logoUrl,
    );

    result.fold(
      (failure) {
        String mensaje = failure.message;
        String? hint;

        if (failure is ServerFailure) {
          hint = failure.hint;
          mensaje = _mapearErrorBackend(failure.hint ?? '', failure.message);
        }

        emit(EditarGrupoError(message: mensaje, hint: hint));
      },
      (response) => emit(EditarGrupoSuccess(response: response)),
    );
  }

  /// Mapea hints del backend a mensajes amigables
  String _mapearErrorBackend(String hint, String mensajeDefault) {
    switch (hint) {
      case 'nombre_requerido':
        return 'El nombre del grupo es obligatorio';
      case 'nombre_duplicado':
        return 'Ya tienes otro grupo con ese nombre. Elige otro nombre.';
      case 'nombre_muy_largo':
        return 'El nombre no puede exceder 100 caracteres';
      case 'lema_muy_largo':
        return 'El lema no puede exceder 100 caracteres';
      case 'sin_permisos':
        return 'Solo el administrador o co-administrador pueden editar el grupo';
      case 'grupo_no_encontrado':
        return 'El grupo no existe o no esta activo';
      case 'no_autenticado':
        return 'Debes iniciar sesion para editar un grupo';
      case 'usuario_no_encontrado':
        return 'No se encontro tu perfil de usuario';
      default:
        return mensajeDefault;
    }
  }
}
