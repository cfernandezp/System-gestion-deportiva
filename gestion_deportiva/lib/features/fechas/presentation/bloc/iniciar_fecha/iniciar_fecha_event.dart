import 'package:equatable/equatable.dart';

/// Eventos del BLoC de iniciar fecha
/// E003-HU-012: Iniciar Fecha
abstract class IniciarFechaEvent extends Equatable {
  const IniciarFechaEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para iniciar una fecha
/// CA-004: Confirmar inicio y cambiar estado a en_juego
class IniciarFechaSubmitEvent extends IniciarFechaEvent {
  /// UUID de la fecha a iniciar
  final String fechaId;

  const IniciarFechaSubmitEvent({
    required this.fechaId,
  });

  @override
  List<Object?> get props => [fechaId];
}

/// Evento para reiniciar el estado del BLoC
class IniciarFechaResetEvent extends IniciarFechaEvent {
  const IniciarFechaResetEvent();
}
