import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/partido_model.dart';
import '../bloc/goles/goles.dart';
import '../bloc/partido/partido.dart';
import 'botones_gol_widget.dart';
import 'lista_goles_admin_widget.dart';
import 'marcador_widget.dart';

/// Widget integrado que muestra partido en vivo con marcador y botones de gol
/// E004-HU-003: Registrar Gol
/// Combina:
/// - Temporizador (del PartidoBloc)
/// - Marcador (del GolesBloc)
/// - Botones de gol (para admin)
/// - Lista de goles (para admin)
class PartidoConGolesWidget extends StatelessWidget {
  /// Indica si el usuario es admin
  final bool esAdmin;

  /// Callback para pantalla completa
  final void Function(PartidoModel partido)? onPantallaCompleta;

  /// Indica si mostrar la lista de goles
  final bool mostrarListaGoles;

  /// Indica si mostrar en modo compacto
  final bool compacto;

  const PartidoConGolesWidget({
    super.key,
    required this.esAdmin,
    this.onPantallaCompleta,
    this.mostrarListaGoles = true,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PartidoBloc, PartidoState>(
      builder: (context, state) {
        // Obtener partido activo
        PartidoModel? partido;
        if (state is PartidoEnCurso) {
          partido = state.partido;
        } else if (state is PartidoPausado) {
          partido = state.partido;
        } else if (state is PartidoProcesando && state.partido != null) {
          partido = state.partido;
        } else if (state is PartidoError && state.partido != null) {
          partido = state.partido;
        }

        if (partido == null) {
          return const SizedBox.shrink();
        }

        // Proveer GolesBloc para este partido
        return BlocProvider(
          create: (_) => sl<GolesBloc>()
            ..add(CargarGolesEvent(partidoId: partido!.id)),
          child: _PartidoConGolesContent(
            partido: partido,
            esAdmin: esAdmin,
            isPausado: state is PartidoPausado,
            onPantallaCompleta: onPantallaCompleta,
            mostrarListaGoles: mostrarListaGoles,
            compacto: compacto,
          ),
        );
      },
    );
  }
}

class _PartidoConGolesContent extends StatelessWidget {
  final PartidoModel partido;
  final bool esAdmin;
  final bool isPausado;
  final void Function(PartidoModel partido)? onPantallaCompleta;
  final bool mostrarListaGoles;
  final bool compacto;

  const _PartidoConGolesContent({
    required this.partido,
    required this.esAdmin,
    required this.isPausado,
    this.onPantallaCompleta,
    required this.mostrarListaGoles,
    required this.compacto,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Escuchar estados de GolesBloc para snackbars
    return BlocListener<GolesBloc, GolesState>(
      listener: (context, state) {
        if (state is GolEliminado) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.undo, color: Colors.white),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: DesignTokens.accentColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is GolesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: DesignTokens.errorColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          side: BorderSide(
            color: isPausado
                ? DesignTokens.accentColor
                : DesignTokens.successColor,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con estado
            _HeaderEstado(
              isPausado: isPausado,
              tiempoTerminado: partido.tiempoTerminado,
            ),

            // Contenido principal
            Padding(
              padding: EdgeInsets.all(
                compacto ? DesignTokens.spacingM : DesignTokens.spacingL,
              ),
              child: Column(
                children: [
                  // Marcador con colores de equipos
                  MarcadorWidget(
                    partido: partido,
                    compacto: compacto,
                  ),

                  SizedBox(
                    height: compacto
                        ? DesignTokens.spacingM
                        : DesignTokens.spacingL,
                  ),

                  // Temporizador
                  _TemporizadorCompacto(
                    tiempoRestante: partido.tiempoRestanteSegundos,
                    isPausado: isPausado,
                    tiempoTerminado: partido.tiempoTerminado,
                    compacto: compacto,
                  ),

                  // CA-001: Botones de gol (solo admin, solo si en curso)
                  if (esAdmin) ...[
                    SizedBox(
                      height: compacto
                          ? DesignTokens.spacingM
                          : DesignTokens.spacingL,
                    ),
                    BotonesGolWidget(
                      partido: partido,
                      esAdmin: esAdmin,
                      compacto: compacto,
                    ),
                  ],

                  // Boton pantalla completa
                  if (onPantallaCompleta != null) ...[
                    const SizedBox(height: DesignTokens.spacingM),
                    OutlinedButton.icon(
                      onPressed: () => onPantallaCompleta?.call(partido),
                      icon: const Icon(Icons.fullscreen),
                      label: const Text('Pantalla Completa'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                      ),
                    ),
                  ],

                  // CA-004, CA-005: Lista de goles (con deshacer para admin)
                  if (mostrarListaGoles) ...[
                    const SizedBox(height: DesignTokens.spacingL),
                    ListaGolesAdminWidget(
                      partido: partido,
                      esAdmin: esAdmin,
                      compacto: compacto,
                      maxHeight: 200,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header con estado del partido
class _HeaderEstado extends StatelessWidget {
  final bool isPausado;
  final bool tiempoTerminado;

  const _HeaderEstado({
    required this.isPausado,
    required this.tiempoTerminado,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Color bgColor;
    IconData icon;
    String texto;

    if (isPausado) {
      bgColor = DesignTokens.accentColor;
      icon = Icons.pause_circle;
      texto = 'PARTIDO PAUSADO';
    } else if (tiempoTerminado) {
      bgColor = DesignTokens.accentColor;
      icon = Icons.flag;
      texto = 'TIEMPO TERMINADO';
    } else {
      bgColor = DesignTokens.successColor;
      icon = Icons.play_circle;
      texto = 'PARTIDO EN CURSO';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusL - 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: DesignTokens.iconSizeS),
          const SizedBox(width: DesignTokens.spacingXs),
          Text(
            texto,
            style: textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: DesignTokens.fontWeightBold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Temporizador compacto para el widget integrado
class _TemporizadorCompacto extends StatelessWidget {
  final int tiempoRestante;
  final bool isPausado;
  final bool tiempoTerminado;
  final bool compacto;

  const _TemporizadorCompacto({
    required this.tiempoRestante,
    required this.isPausado,
    required this.tiempoTerminado,
    required this.compacto,
  });

  String get _tiempoFormateado {
    final esNegativo = tiempoRestante < 0;
    final segundosAbsolutos = tiempoRestante.abs();
    final minutos = segundosAbsolutos ~/ 60;
    final segs = segundosAbsolutos % 60;
    final tiempo =
        '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
    return esNegativo ? '-$tiempo' : tiempo;
  }

  bool get _esTiempoExtra => tiempoRestante < 0;
  bool get _tiempoCritico => tiempoRestante <= 120 && tiempoRestante > 0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Determinar color
    Color tiempoColor;
    String label;
    if (tiempoTerminado) {
      tiempoColor = DesignTokens.errorColor;
      label = 'FIN DEL TIEMPO';
    } else if (isPausado) {
      tiempoColor = DesignTokens.accentColor;
      label = 'TIEMPO PAUSADO';
    } else if (_esTiempoExtra) {
      tiempoColor = DesignTokens.errorColor;
      label = 'TIEMPO EXTRA';
    } else if (_tiempoCritico) {
      tiempoColor = DesignTokens.errorColor;
      label = 'TIEMPO RESTANTE';
    } else {
      tiempoColor = DesignTokens.successColor;
      label = 'TIEMPO RESTANTE';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? DesignTokens.spacingM : DesignTokens.spacingL,
        vertical: compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
      ),
      decoration: BoxDecoration(
        color: tiempoColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: tiempoColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: tiempoColor,
              fontWeight: DesignTokens.fontWeightMedium,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Text(
            _tiempoFormateado,
            style: TextStyle(
              fontSize: compacto ? 32 : 48,
              fontWeight: DesignTokens.fontWeightBold,
              color: tiempoColor,
              fontFamily: 'monospace',
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }
}
