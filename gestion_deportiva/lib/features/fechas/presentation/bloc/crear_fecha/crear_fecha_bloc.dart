import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../data/models/crear_fecha_request_model.dart';
import '../../../domain/repositories/fechas_repository.dart';
import 'crear_fecha_event.dart';
import 'crear_fecha_state.dart';

/// BLoC para gestionar la creacion de fechas de pichanga
/// E003-HU-001: Crear Fecha
class CrearFechaBloc extends Bloc<CrearFechaEvent, CrearFechaState> {
  final FechasRepository repository;

  CrearFechaBloc({required this.repository}) : super(const CrearFechaInitial()) {
    on<CrearFechaSubmitEvent>(_onCrearFecha);
    on<CrearFechaResetEvent>(_onReset);
  }

  /// CA-006: Procesar creacion de fecha
  Future<void> _onCrearFecha(
    CrearFechaSubmitEvent event,
    Emitter<CrearFechaState> emit,
  ) async {
    // Crear modelo de request
    final request = CrearFechaRequestModel(
      fechaHoraInicio: event.fechaHoraInicio,
      duracionHoras: event.duracionHoras,
      lugar: event.lugar,
      numEquipos: event.numEquipos,
      costoPorJugador: event.costoPorJugador,
    );

    // Validacion frontend (CA-004, CA-005, RN-002)
    final errorValidacion = request.validar();
    if (errorValidacion != null) {
      emit(CrearFechaError(message: errorValidacion));
      return;
    }

    // Emitir estado de carga
    emit(const CrearFechaLoading());

    // Llamar al repositorio
    final result = await repository.crearFecha(request);

    // Procesar resultado
    result.fold(
      (failure) {
        // Extraer datos del ServerFailure
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(CrearFechaError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        // CA-006: Exito - fecha creada
        if (response.success && response.fecha != null) {
          emit(CrearFechaSuccess(
            fecha: response.fecha!,
            message: response.message,
          ));
        } else {
          // Respuesta inesperada
          emit(const CrearFechaError(
            message: 'Error inesperado al crear la fecha',
          ));
        }
      },
    );
  }

  /// Reiniciar estado del formulario
  void _onReset(
    CrearFechaResetEvent event,
    Emitter<CrearFechaState> emit,
  ) {
    emit(const CrearFechaInitial());
  }
}
