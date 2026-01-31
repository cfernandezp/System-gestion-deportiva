import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/partidos_repository.dart';
import 'finalizar_partido_event.dart';
import 'finalizar_partido_state.dart';

/// BLoC para gestionar la finalizacion de partidos
/// E004-HU-005: Finalizar Partido
///
/// Criterios de Aceptacion:
/// - CA-001: Boton "Finalizar Partido" visible cuando partido activo
/// - CA-004: Sugerencia de rotacion para 3 equipos
/// - CA-005: Resumen con marcador, goleadores, duracion
/// - CA-006: Confirmacion si tiempo no ha terminado
class FinalizarPartidoBloc
    extends Bloc<FinalizarPartidoEvent, FinalizarPartidoState> {
  final PartidosRepository repository;

  FinalizarPartidoBloc({required this.repository})
      : super(const FinalizarPartidoInitial()) {
    on<FinalizarPartidoRequested>(_onFinalizarPartidoRequested);
    on<ConfirmarFinalizacionAnticipada>(_onConfirmarFinalizacionAnticipada);
    on<CancelarFinalizacion>(_onCancelarFinalizacion);
    on<ResetFinalizarPartido>(_onReset);
  }

  /// CA-001: Manejar solicitud de finalizar partido
  /// CA-006: Si tiempo no termino, solicita confirmacion
  Future<void> _onFinalizarPartidoRequested(
    FinalizarPartidoRequested event,
    Emitter<FinalizarPartidoState> emit,
  ) async {
    // CA-006: Si el tiempo no ha terminado, pedir confirmacion
    if (!event.tiempoTerminado) {
      emit(FinalizarPartidoRequiereConfirmacion(
        partidoId: event.partidoId,
        message:
            'El tiempo del partido aun no ha terminado. Desea finalizar de todas formas?',
      ));
      return;
    }

    // Si el tiempo ya termino, finalizar directamente
    await _finalizarPartido(event.partidoId, false, emit);
  }

  /// CA-006: Confirmar finalizacion anticipada
  Future<void> _onConfirmarFinalizacionAnticipada(
    ConfirmarFinalizacionAnticipada event,
    Emitter<FinalizarPartidoState> emit,
  ) async {
    await _finalizarPartido(event.partidoId, true, emit);
  }

  /// Cancelar finalizacion (volver a estado inicial)
  void _onCancelarFinalizacion(
    CancelarFinalizacion event,
    Emitter<FinalizarPartidoState> emit,
  ) {
    emit(const FinalizarPartidoInitial());
  }

  /// Reiniciar estado
  void _onReset(
    ResetFinalizarPartido event,
    Emitter<FinalizarPartidoState> emit,
  ) {
    emit(const FinalizarPartidoInitial());
  }

  /// Llama al repositorio para finalizar el partido
  /// CA-004, CA-005: Recibe resumen con marcador, goleadores, duracion y sugerencia
  Future<void> _finalizarPartido(
    String partidoId,
    bool confirmarAnticipado,
    Emitter<FinalizarPartidoState> emit,
  ) async {
    emit(const FinalizarPartidoLoading());

    final result = await repository.finalizarPartido(
      partidoId,
      confirmarAnticipado: confirmarAnticipado,
    );

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;

        // Si el backend responde con requiere_confirmacion, emitir ese estado
        if (serverFailure?.hint == 'requiere_confirmacion') {
          emit(FinalizarPartidoRequiereConfirmacion(
            partidoId: partidoId,
            message: failure.message,
          ));
        } else {
          emit(FinalizarPartidoError(
            message: failure.message,
            code: serverFailure?.code,
            hint: serverFailure?.hint,
            partidoId: partidoId,
          ));
        }
      },
      (response) {
        if (response.success) {
          emit(FinalizarPartidoSuccess(response: response));
        } else {
          emit(FinalizarPartidoError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al finalizar partido',
            partidoId: partidoId,
          ));
        }
      },
    );
  }
}
