import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/fechas_repository.dart';
import 'cancelar_inscripcion_event.dart';
import 'cancelar_inscripcion_state.dart';

/// BLoC para gestionar cancelacion de inscripciones a fechas de pichanga
/// E003-HU-007: Cancelar Inscripcion
///
/// Criterios de Aceptacion:
/// - CA-001: Opcion de cancelar visible segun condiciones
/// - CA-002: Dialogo de confirmacion con mensaje
/// - CA-003: Cancelacion exitosa con deuda anulada (fecha abierta)
/// - CA-004: Re-inscripcion permitida despues de cancelar
/// - CA-005: Mensaje si inscripciones cerradas
/// - CA-006: Admin puede cancelar inscripcion de cualquier jugador
/// - CA-007: Notificacion al admin cuando jugador cancela
///
/// Reglas de Negocio:
/// - RN-001: Cancelacion libre si fecha esta abierta
/// - RN-002: Bloqueo de cancelacion si fecha cerrada (excepto admin)
/// - RN-003: Deuda se anula si fecha abierta o admin lo decide
/// - RN-004: Asignacion de equipo se elimina
/// - RN-005: Notificacion bidireccional (admin<->jugador)
/// - RN-006: Soft delete con auditoria (cancelado_at, cancelado_por)
class CancelarInscripcionBloc
    extends Bloc<CancelarInscripcionEvent, CancelarInscripcionState> {
  final FechasRepository repository;

  CancelarInscripcionBloc({required this.repository})
      : super(const CancelarInscripcionInitial()) {
    on<VerificarPuedeCancelarEvent>(_onVerificarPuedeCancelar);
    on<CancelarInscripcionUsuarioEvent>(_onCancelarInscripcionUsuario);
    on<CancelarInscripcionAdminEvent>(_onCancelarInscripcionAdmin);
    on<ResetCancelarInscripcionEvent>(_onReset);
  }

  /// CA-001, CA-002, CA-005: Verificar si el usuario puede cancelar
  /// Llama a RPC: verificar_puede_cancelar(p_fecha_id)
  Future<void> _onVerificarPuedeCancelar(
    VerificarPuedeCancelarEvent event,
    Emitter<CancelarInscripcionState> emit,
  ) async {
    emit(const CancelarInscripcionLoading(esVerificacion: true));

    final result = await repository.verificarPuedeCancelar(event.fechaId);

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(CancelarInscripcionError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        if (response.success && response.data != null) {
          emit(VerificacionCargada(verificacion: response.data!));
        } else {
          emit(CancelarInscripcionError(
            message: response.message ?? 'Error al verificar cancelacion',
          ));
        }
      },
    );
  }

  /// CA-003, CA-004, CA-007: Cancelar inscripcion del usuario
  /// RN-001, RN-003, RN-004, RN-005, RN-006
  Future<void> _onCancelarInscripcionUsuario(
    CancelarInscripcionUsuarioEvent event,
    Emitter<CancelarInscripcionState> emit,
  ) async {
    emit(const CancelarInscripcionLoading(esVerificacion: false));

    final result =
        await repository.cancelarInscripcionCompleta(event.fechaId);

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(CancelarInscripcionError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        if (response.success && response.data != null) {
          emit(CancelacionUsuarioExitosa(
            cancelacion: response.data!,
            message: response.message,
          ));
        } else {
          emit(CancelarInscripcionError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al cancelar inscripcion',
          ));
        }
      },
    );
  }

  /// CA-006: Cancelar inscripcion por admin
  /// RN-002, RN-003, RN-004, RN-005, RN-006
  Future<void> _onCancelarInscripcionAdmin(
    CancelarInscripcionAdminEvent event,
    Emitter<CancelarInscripcionState> emit,
  ) async {
    emit(const CancelarInscripcionLoading(esVerificacion: false));

    final result = await repository.cancelarInscripcionAdmin(
      inscripcionId: event.inscripcionId,
      anularDeuda: event.anularDeuda,
    );

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(CancelarInscripcionError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        if (response.success && response.data != null) {
          emit(CancelacionAdminExitosa(
            cancelacion: response.data!,
            message: response.message,
          ));
        } else {
          emit(CancelarInscripcionError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al cancelar inscripcion',
          ));
        }
      },
    );
  }

  /// Reiniciar estado del bloc
  void _onReset(
    ResetCancelarInscripcionEvent event,
    Emitter<CancelarInscripcionState> emit,
  ) {
    emit(const CancelarInscripcionInitial());
  }
}
