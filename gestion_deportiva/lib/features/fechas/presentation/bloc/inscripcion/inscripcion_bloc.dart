import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/fechas_repository.dart';
import 'inscripcion_event.dart';
import 'inscripcion_state.dart';

/// BLoC para gestionar inscripciones a fechas de pichanga
/// E003-HU-002: Inscribirse a Fecha
///
/// Criterios de Aceptacion:
/// - CA-001: Ver fecha disponible (detalle con inscritos)
/// - CA-002: Boton de inscripcion cuando no inscrito
/// - CA-003: Confirmar inscripcion con mensaje de exito
/// - CA-004: Ya inscrito - mostrar indicador y boton cancelar
/// - CA-005: Inscripciones cerradas - mostrar mensaje
/// - CA-006: Contador de inscritos actualizado
///
/// Reglas de Negocio:
/// - RN-001: Solo usuarios aprobados pueden inscribirse
/// - RN-002: Solo fechas con estado 'abierta' permiten inscripcion
/// - RN-003: Inscripcion unica por fecha
/// - RN-004: Inscripcion genera deuda automatica
class InscripcionBloc extends Bloc<InscripcionEvent, InscripcionState> {
  final FechasRepository repository;

  /// ID de la fecha actual (para refrescar)
  String? _fechaIdActual;

  InscripcionBloc({required this.repository})
      : super(const InscripcionInitial()) {
    on<CargarFechaDetalleEvent>(_onCargarFechaDetalle);
    on<InscribirseEvent>(_onInscribirse);
    on<CancelarInscripcionEvent>(_onCancelarInscripcion);
    on<ResetInscripcionEvent>(_onReset);
    on<RefrescarFechaDetalleEvent>(_onRefrescar);
  }

  /// CA-001, CA-006: Cargar detalle de fecha con inscritos
  Future<void> _onCargarFechaDetalle(
    CargarFechaDetalleEvent event,
    Emitter<InscripcionState> emit,
  ) async {
    _fechaIdActual = event.fechaId;
    emit(const InscripcionLoading());

    final result = await repository.obtenerFechaDetalle(event.fechaId);

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(InscripcionError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        if (response.success && response.data != null) {
          emit(InscripcionFechaDetalleCargado(fechaDetalle: response.data!));
        } else {
          emit(InscripcionError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al cargar detalle de fecha',
          ));
        }
      },
    );
  }

  /// CA-002, CA-003: Procesar inscripcion a fecha
  /// RN-001 a RN-004: Validaciones en backend
  Future<void> _onInscribirse(
    InscribirseEvent event,
    Emitter<InscripcionState> emit,
  ) async {
    // Obtener estado actual para mantener datos
    final estadoActual = state;
    final fechaDetalleActual = estadoActual is InscripcionFechaDetalleCargado
        ? estadoActual.fechaDetalle
        : null;

    emit(InscripcionProcesando(
      fechaDetalle: fechaDetalleActual,
      esInscripcion: true,
    ));

    final result = await repository.inscribirseFecha(event.fechaId);

    await result.fold(
      (failure) async {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(InscripcionError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
          fechaDetalle: fechaDetalleActual,
        ));
      },
      (response) async {
        if (response.success && response.inscripcion != null) {
          // Recargar detalle para obtener lista actualizada (CA-006)
          final detalleResult =
              await repository.obtenerFechaDetalle(event.fechaId);
          final fechaDetalleActualizado = detalleResult.fold(
            (_) => fechaDetalleActual,
            (r) => r.data,
          );

          emit(InscripcionExitosa(
            inscripcion: response.inscripcion!,
            message: response.message,
            fechaDetalle: fechaDetalleActualizado,
          ));
        } else {
          emit(InscripcionError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al inscribirse',
            fechaDetalle: fechaDetalleActual,
          ));
        }
      },
    );
  }

  /// CA-004: Procesar cancelacion de inscripcion
  Future<void> _onCancelarInscripcion(
    CancelarInscripcionEvent event,
    Emitter<InscripcionState> emit,
  ) async {
    // Obtener estado actual para mantener datos
    final estadoActual = state;
    final fechaDetalleActual = estadoActual is InscripcionFechaDetalleCargado
        ? estadoActual.fechaDetalle
        : (estadoActual is InscripcionExitosa
            ? estadoActual.fechaDetalle
            : null);

    emit(InscripcionProcesando(
      fechaDetalle: fechaDetalleActual,
      esInscripcion: false,
    ));

    final result = await repository.cancelarInscripcion(event.fechaId);

    await result.fold(
      (failure) async {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(InscripcionError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
          fechaDetalle: fechaDetalleActual,
        ));
      },
      (response) async {
        if (response.success) {
          // Recargar detalle para obtener lista actualizada (CA-006)
          final detalleResult =
              await repository.obtenerFechaDetalle(event.fechaId);
          final fechaDetalleActualizado = detalleResult.fold(
            (_) => fechaDetalleActual,
            (r) => r.data,
          );

          emit(CancelacionExitosa(
            message: response.message,
            fechaDetalle: fechaDetalleActualizado,
          ));
        } else {
          emit(InscripcionError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al cancelar inscripcion',
            fechaDetalle: fechaDetalleActual,
          ));
        }
      },
    );
  }

  /// Reiniciar estado del bloc
  void _onReset(
    ResetInscripcionEvent event,
    Emitter<InscripcionState> emit,
  ) {
    _fechaIdActual = null;
    emit(const InscripcionInitial());
  }

  /// Refrescar detalle de fecha actual
  Future<void> _onRefrescar(
    RefrescarFechaDetalleEvent event,
    Emitter<InscripcionState> emit,
  ) async {
    if (_fechaIdActual != null) {
      add(CargarFechaDetalleEvent(fechaId: _fechaIdActual!));
    }
  }
}
