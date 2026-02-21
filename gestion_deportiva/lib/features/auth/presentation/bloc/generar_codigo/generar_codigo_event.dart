import 'package:equatable/equatable.dart';

/// Eventos del Bloc GenerarCodigo
/// E001-HU-007: Generar codigo de recuperacion para jugador (admin-side)
abstract class GenerarCodigoEvent extends Equatable {
  const GenerarCodigoEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Generar codigo de recuperacion para un jugador
class GenerarCodigoRecuperacionEvent extends GenerarCodigoEvent {
  final String celularJugador;

  const GenerarCodigoRecuperacionEvent({required this.celularJugador});

  @override
  List<Object?> get props => [celularJugador];
}

/// Evento: Resetear estado (limpiar formulario)
class ResetGenerarCodigoEvent extends GenerarCodigoEvent {
  const ResetGenerarCodigoEvent();
}
