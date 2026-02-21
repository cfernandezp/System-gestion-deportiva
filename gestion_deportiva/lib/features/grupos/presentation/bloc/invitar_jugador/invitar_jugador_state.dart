import 'package:equatable/equatable.dart';

import '../../../data/models/invitar_jugador_response_model.dart';

/// Estados del Bloc InvitarJugador
/// E001-HU-004: Invitar Jugador al Grupo
abstract class InvitarJugadorState extends Equatable {
  const InvitarJugadorState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class InvitarJugadorInitial extends InvitarJugadorState {}

/// Enviando invitacion
class InvitarJugadorLoading extends InvitarJugadorState {}

/// CA-001 a CA-004, CA-007: Invitacion exitosa
class InvitarJugadorSuccess extends InvitarJugadorState {
  final InvitarJugadorResponseModel response;

  const InvitarJugadorSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

/// Error al invitar (CA-003, CA-004, CA-006, RN-001, etc.)
class InvitarJugadorError extends InvitarJugadorState {
  final String message;
  final String? hint;

  const InvitarJugadorError(this.message, {this.hint});

  @override
  List<Object?> get props => [message, hint];
}
