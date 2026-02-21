import 'package:equatable/equatable.dart';

import '../../../data/models/activacion_cuenta_response_model.dart';
import '../../../data/models/verificar_invitacion_model.dart';

/// Estados del Bloc ActivacionCuenta
/// E001-HU-005: Activacion de Cuenta de Jugador Invitado
abstract class ActivacionCuentaState extends Equatable {
  const ActivacionCuentaState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - Pantalla de ingreso de celular
class ActivacionCuentaInitial extends ActivacionCuentaState {}

/// Cargando (verificando invitacion o activando cuenta)
class ActivacionCuentaLoading extends ActivacionCuentaState {}

/// CA-001: Invitacion verificada exitosamente - mostrar formulario de activacion
class InvitacionVerificada extends ActivacionCuentaState {
  final VerificarInvitacionModel verificacion;
  final String celular;

  const InvitacionVerificada({
    required this.verificacion,
    required this.celular,
  });

  @override
  List<Object?> get props => [verificacion, celular];
}

/// CA-002 / CA-004: No tiene invitacion o ya esta activo
class InvitacionNoEncontrada extends ActivacionCuentaState {
  final String mensaje;
  final bool yaActivo;

  const InvitacionNoEncontrada({
    required this.mensaje,
    required this.yaActivo,
  });

  @override
  List<Object?> get props => [mensaje, yaActivo];
}

/// CA-001 / CA-006: Cuenta activada exitosamente
class ActivacionCuentaSuccess extends ActivacionCuentaState {
  final ActivacionCuentaResponseModel response;

  const ActivacionCuentaSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

/// Error generico
class ActivacionCuentaError extends ActivacionCuentaState {
  final String message;
  final String? hint;

  const ActivacionCuentaError(this.message, {this.hint});

  @override
  List<Object?> get props => [message, hint];
}
