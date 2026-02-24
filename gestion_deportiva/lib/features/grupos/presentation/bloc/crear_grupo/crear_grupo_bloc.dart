import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../planes/domain/services/plan_service.dart';
import '../../../domain/repositories/grupos_repository.dart';
import 'crear_grupo_event.dart';
import 'crear_grupo_state.dart';

/// E002-HU-001: BLoC para crear grupo deportivo
/// CA-001 a CA-007, RN-001 a RN-008
class CrearGrupoBloc extends Bloc<CrearGrupoEvent, CrearGrupoState> {
  final GruposRepository repository;
  final PlanService planService;

  CrearGrupoBloc({
    required this.repository,
    required this.planService,
  }) : super(const CrearGrupoInitial()) {
    on<CrearGrupoSubmitEvent>(_onCrearGrupoSubmit);
  }

  Future<void> _onCrearGrupoSubmit(
    CrearGrupoSubmitEvent event,
    Emitter<CrearGrupoState> emit,
  ) async {
    // Validacion frontend: nombre requerido
    final nombreLimpio = event.nombre.trim();
    if (nombreLimpio.isEmpty) {
      emit(const CrearGrupoError(
        message: 'El nombre del grupo es obligatorio',
        hint: 'nombre_requerido',
      ));
      return;
    }

    if (nombreLimpio.length > 100) {
      emit(const CrearGrupoError(
        message: 'El nombre no puede exceder 100 caracteres',
        hint: 'nombre_muy_largo',
      ));
      return;
    }

    // RN-004: Validar lema max 100 chars
    if (event.lema != null && event.lema!.trim().length > 100) {
      emit(const CrearGrupoError(
        message: 'El lema no puede exceder 100 caracteres',
        hint: 'lema_muy_largo',
      ));
      return;
    }

    emit(const CrearGrupoLoading());

    // CA-006 / RN-007: Verificar limite de grupos via PlanService
    final countResult = await repository.contarGruposComoAdmin();
    final currentCount = countResult.fold(
      (_) => 0,
      (count) => count,
    );

    final permisoResult = await planService.verificarLimite(
      recurso: 'grupos_por_admin',
      cantidadActual: currentCount,
    );

    final limiteAlcanzado = permisoResult.fold(
      (_) => false,
      (permiso) => !permiso.permitido,
    );

    if (limiteAlcanzado) {
      final plan = planService.planActual;
      emit(CrearGrupoLimiteAlcanzado(
        message:
            'Has alcanzado el limite de grupos de tu plan${plan != null ? " (${plan.nombre})" : ""}. Actualiza tu plan para crear mas grupos.',
        limiteActual: plan?.maxGruposPorAdmin ?? 1,
      ));
      return;
    }

    // CA-003 / RN-003: Subir logo si se proporciono
    String? logoUrl;
    if (event.imagenLogo != null) {
      emit(const CrearGrupoSubiendoLogo());

      final logoResult = await repository.subirLogo(event.imagenLogo!);
      final logoFailed = logoResult.fold(
        (failure) {
          emit(CrearGrupoError(
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

      emit(const CrearGrupoLoading());
    }

    // Crear grupo via RPC
    debugPrint('[CrearGrupoBloc] Creando grupo: $nombreLimpio');

    final result = await repository.crearGrupo(
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

        emit(CrearGrupoError(message: mensaje, hint: hint));
      },
      (response) => emit(CrearGrupoSuccess(response: response)),
    );
  }

  /// Mapea hints del backend a mensajes amigables
  String _mapearErrorBackend(String hint, String mensajeDefault) {
    switch (hint) {
      case 'nombre_requerido':
        return 'El nombre del grupo es obligatorio';
      case 'nombre_duplicado':
        return 'Ya tienes un grupo con ese nombre. Elige otro nombre.';
      case 'nombre_muy_largo':
        return 'El nombre no puede exceder 100 caracteres';
      case 'lema_muy_largo':
        return 'El lema no puede exceder 100 caracteres';
      case 'limite_grupos_alcanzado':
        return 'Has alcanzado el limite de grupos de tu plan. Actualiza tu plan para crear mas grupos.';
      case 'no_autenticado':
        return 'Debes iniciar sesion para crear un grupo';
      case 'usuario_no_encontrado':
        return 'No se encontro tu perfil de usuario';
      default:
        return mensajeDefault;
    }
  }
}
