import 'package:equatable/equatable.dart';

/// Estados del Bloc GenerarCodigo
/// E001-HU-007: Generar codigo de recuperacion para jugador (admin-side)
abstract class GenerarCodigoState extends Equatable {
  const GenerarCodigoState();

  @override
  List<Object?> get props => [];
}

/// Estado: Inicial (formulario vacio)
class GenerarCodigoInitial extends GenerarCodigoState {}

/// Estado: Cargando (generando codigo)
class GenerarCodigoLoading extends GenerarCodigoState {}

/// Estado: Codigo generado exitosamente
class CodigoGenerado extends GenerarCodigoState {
  final String codigo;
  final String celularJugador;
  final int expiraEnMinutos;
  final String mensajeParaJugador;

  const CodigoGenerado({
    required this.codigo,
    required this.celularJugador,
    required this.expiraEnMinutos,
    required this.mensajeParaJugador,
  });

  @override
  List<Object?> get props => [
        codigo,
        celularJugador,
        expiraEnMinutos,
        mensajeParaJugador,
      ];
}

/// Estado: Error al generar codigo
class GenerarCodigoError extends GenerarCodigoState {
  final String mensaje;
  final String? hint;

  const GenerarCodigoError({
    required this.mensaje,
    this.hint,
  });

  @override
  List<Object?> get props => [mensaje, hint];
}
