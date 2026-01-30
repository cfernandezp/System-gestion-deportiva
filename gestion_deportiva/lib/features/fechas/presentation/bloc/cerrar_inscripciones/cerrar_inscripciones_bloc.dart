import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/fechas_repository.dart';
import 'cerrar_inscripciones_event.dart';
import 'cerrar_inscripciones_state.dart';

/// BLoC para gestionar cerrar/reabrir inscripciones de fechas
/// E003-HU-004: Cerrar Inscripciones
///
/// Criterios de Aceptacion:
/// - CA-001: Boton cerrar inscripciones visible para admin
/// - CA-002: Confirmacion con resumen (inscritos, formato)
/// - CA-003: Advertencia si menos de 6 jugadores (no bloqueante)
/// - CA-004: Estado actualizado a 'cerrada'
/// - CA-005: Bloqueo de nuevas inscripciones (backend)
/// - CA-006: Reabrir inscripciones (solo admin)
/// - CA-007: Notificacion de cierre a inscritos (backend)
///
/// Reglas de Negocio:
/// - RN-001: Solo administradores pueden cerrar/reabrir
/// - RN-002: Solo fechas con estado 'abierta' se pueden cerrar
/// - RN-003: Advertencia si menos de 6 jugadores (minimo recomendado)
/// - RN-004: Registro de auditoria (cerrado_por, cerrado_at)
/// - RN-005: Solo fechas con estado 'cerrada' se pueden reabrir
/// - RN-006: Al reabrir, inscripciones y deudas se mantienen
class CerrarInscripcionesBloc
    extends Bloc<CerrarInscripcionesEvent, CerrarInscripcionesState> {
  final FechasRepository repository;

  CerrarInscripcionesBloc({required this.repository})
      : super(const CerrarInscripcionesInitial()) {
    on<CerrarInscripcionesSubmitEvent>(_onCerrarInscripciones);
    on<ReabrirInscripcionesSubmitEvent>(_onReabrirInscripciones);
    on<CerrarInscripcionesResetEvent>(_onReset);
  }

  /// CA-001 a CA-004, CA-007: Procesar cierre de inscripciones
  /// RN-001 a RN-004, RN-006: Validaciones en backend
  Future<void> _onCerrarInscripciones(
    CerrarInscripcionesSubmitEvent event,
    Emitter<CerrarInscripcionesState> emit,
  ) async {
    // Emitir estado de carga
    emit(const CerrarInscripcionesLoading());

    // Llamar al repositorio
    final result = await repository.cerrarInscripciones(event.fechaId);

    // Procesar resultado
    result.fold(
      (failure) {
        // Extraer datos del ServerFailure
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(CerrarInscripcionesError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        // CA-004: Exito - inscripciones cerradas
        if (response.success && response.data != null) {
          emit(CerrarInscripcionesSuccess(
            data: response.data!,
            message: response.message,
          ));
        } else {
          // Respuesta inesperada
          emit(const CerrarInscripcionesError(
            message: 'Error inesperado al cerrar inscripciones',
          ));
        }
      },
    );
  }

  /// CA-006: Procesar reapertura de inscripciones
  /// RN-001, RN-005, RN-006: Validaciones en backend
  Future<void> _onReabrirInscripciones(
    ReabrirInscripcionesSubmitEvent event,
    Emitter<CerrarInscripcionesState> emit,
  ) async {
    // Emitir estado de carga
    emit(const ReabrirInscripcionesLoading());

    // Llamar al repositorio
    final result = await repository.reabrirInscripciones(event.fechaId);

    // Procesar resultado
    result.fold(
      (failure) {
        // Extraer datos del ServerFailure
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(ReabrirInscripcionesError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        // CA-006: Exito - inscripciones reabiertas
        if (response.success && response.data != null) {
          emit(ReabrirInscripcionesSuccess(
            data: response.data!,
            message: response.message,
          ));
        } else {
          // Respuesta inesperada
          emit(const ReabrirInscripcionesError(
            message: 'Error inesperado al reabrir inscripciones',
          ));
        }
      },
    );
  }

  /// Reiniciar estado del bloc
  void _onReset(
    CerrarInscripcionesResetEvent event,
    Emitter<CerrarInscripcionesState> emit,
  ) {
    emit(const CerrarInscripcionesInitial());
  }
}
