import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../fechas/data/models/color_equipo.dart';
import '../../data/models/estado_partido.dart';
import '../../data/models/jugador_partido_model.dart';
import '../../data/models/partido_model.dart';
import '../bloc/goles/goles.dart';
import 'registrar_gol_dialog.dart';

/// Widget con botones para registrar goles por equipo
/// E004-HU-003: Registrar Gol
/// CA-001: Boton de gol por equipo
/// RN-001: Solo admin registra goles
/// RN-002: Partido en curso obligatorio
/// RN-007: No goles durante pausa
class BotonesGolWidget extends StatelessWidget {
  /// Modelo del partido
  final PartidoModel partido;

  /// Indica si el usuario es admin
  final bool esAdmin;

  /// Indica si mostrar en modo compacto
  final bool compacto;

  /// Indica si mostrar en layout horizontal (lado a lado)
  final bool horizontal;

  const BotonesGolWidget({
    super.key,
    required this.partido,
    required this.esAdmin,
    this.compacto = false,
    this.horizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    // RN-001: Solo admin ve los botones
    if (!esAdmin) {
      return const SizedBox.shrink();
    }

    // RN-002, RN-007: Solo si partido esta en curso (no pausado)
    final puedeRegistrar = partido.estado == EstadoPartido.enCurso;

    return BlocBuilder<GolesBloc, GolesState>(
      builder: (context, state) {
        final isProcesando = state is GolesProcesando;

        if (horizontal) {
          return Row(
            children: [
              // Boton equipo local
              Expanded(
                child: _BotonGol(
                  equipo: partido.equipoLocal.color,
                  partido: partido,
                  esLocal: true,
                  habilitado: puedeRegistrar && !isProcesando,
                  compacto: compacto,
                  isProcesando: isProcesando,
                ),
              ),
              SizedBox(
                width: compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
              ),
              // Boton equipo visitante
              Expanded(
                child: _BotonGol(
                  equipo: partido.equipoVisitante.color,
                  partido: partido,
                  esLocal: false,
                  habilitado: puedeRegistrar && !isProcesando,
                  compacto: compacto,
                  isProcesando: isProcesando,
                ),
              ),
            ],
          );
        }

        // Layout vertical
        return Column(
          children: [
            _BotonGol(
              equipo: partido.equipoLocal.color,
              partido: partido,
              esLocal: true,
              habilitado: puedeRegistrar && !isProcesando,
              compacto: compacto,
              isProcesando: isProcesando,
            ),
            SizedBox(
              height: compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
            ),
            _BotonGol(
              equipo: partido.equipoVisitante.color,
              partido: partido,
              esLocal: false,
              habilitado: puedeRegistrar && !isProcesando,
              compacto: compacto,
              isProcesando: isProcesando,
            ),
          ],
        );
      },
    );
  }
}

/// Boton individual para registrar gol de un equipo
class _BotonGol extends StatelessWidget {
  final ColorEquipo equipo;
  final PartidoModel partido;
  final bool esLocal;
  final bool habilitado;
  final bool compacto;
  final bool isProcesando;

  const _BotonGol({
    required this.equipo,
    required this.partido,
    required this.esLocal,
    required this.habilitado,
    required this.compacto,
    required this.isProcesando,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Determinar equipo que anota y contrario (para autogol)
    final equipoQueAnota = esLocal
        ? partido.equipoLocal.color
        : partido.equipoVisitante.color;
    final equipoContrario = esLocal
        ? partido.equipoVisitante.color
        : partido.equipoLocal.color;

    // Obtener jugadores del equipo
    final jugadores = esLocal
        ? partido.equipoLocal.jugadores
        : partido.equipoVisitante.jugadores;

    return AnimatedContainer(
      duration: DesignTokens.animFast,
      child: Material(
        color: habilitado
            ? equipo.color
            : equipo.color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        elevation: habilitado ? DesignTokens.elevationS : 0,
        child: InkWell(
          onTap: habilitado
              ? () => _mostrarDialogGol(
                    context,
                    equipoQueAnota: equipoQueAnota,
                    equipoContrario: equipoContrario,
                    jugadores: jugadores,
                    esLocal: esLocal,
                  )
              : null,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          splashColor: Colors.white.withValues(alpha: 0.3),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compacto ? DesignTokens.spacingM : DesignTokens.spacingL,
              vertical: compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isProcesando)
                  SizedBox(
                    width: compacto ? 16 : 20,
                    height: compacto ? 16 : 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: equipo.textColor.withValues(alpha: 0.7),
                    ),
                  )
                else
                  Icon(
                    Icons.sports_soccer,
                    color: habilitado
                        ? equipo.textColor
                        : equipo.textColor.withValues(alpha: 0.5),
                    size: compacto ? 20 : 24,
                  ),
                SizedBox(width: compacto ? DesignTokens.spacingXs : DesignTokens.spacingS),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '+GOL',
                        style: (compacto ? textTheme.labelMedium : textTheme.titleSmall)
                            ?.copyWith(
                          color: habilitado
                              ? equipo.textColor
                              : equipo.textColor.withValues(alpha: 0.5),
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                      Text(
                        equipo.displayName.toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: habilitado
                              ? equipo.textColor.withValues(alpha: 0.8)
                              : equipo.textColor.withValues(alpha: 0.4),
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDialogGol(
    BuildContext context, {
    required ColorEquipo equipoQueAnota,
    required ColorEquipo equipoContrario,
    required List<JugadorPartidoModel> jugadores,
    required bool esLocal,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => RegistrarGolDialog(
        partidoId: partido.id,
        equipoAnotador: equipoQueAnota,
        equipoContrario: equipoContrario,
        jugadores: jugadores,
        esEquipoLocal: esLocal,
        golesBloc: context.read<GolesBloc>(),
      ),
    );
  }
}

/// Widget con botones de gol para layout de pantalla completa
/// Posiciona botones a los lados del marcador
class BotonesGolFullscreenWidget extends StatelessWidget {
  /// Modelo del partido
  final PartidoModel partido;

  /// Indica si el usuario es admin
  final bool esAdmin;

  const BotonesGolFullscreenWidget({
    super.key,
    required this.partido,
    required this.esAdmin,
  });

  @override
  Widget build(BuildContext context) {
    // RN-001: Solo admin ve los botones
    if (!esAdmin) {
      return const SizedBox.shrink();
    }

    // RN-002, RN-007: Solo si partido esta en curso
    final puedeRegistrar = partido.estado == EstadoPartido.enCurso;

    return BlocBuilder<GolesBloc, GolesState>(
      builder: (context, state) {
        final isProcesando = state is GolesProcesando;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Boton grande equipo local (izquierda)
            _BotonGolGrande(
              equipo: partido.equipoLocal.color,
              partido: partido,
              esLocal: true,
              habilitado: puedeRegistrar && !isProcesando,
              isProcesando: isProcesando,
            ),

            // Boton grande equipo visitante (derecha)
            _BotonGolGrande(
              equipo: partido.equipoVisitante.color,
              partido: partido,
              esLocal: false,
              habilitado: puedeRegistrar && !isProcesando,
              isProcesando: isProcesando,
            ),
          ],
        );
      },
    );
  }
}

/// Boton grande para pantalla completa
class _BotonGolGrande extends StatelessWidget {
  final ColorEquipo equipo;
  final PartidoModel partido;
  final bool esLocal;
  final bool habilitado;
  final bool isProcesando;

  const _BotonGolGrande({
    required this.equipo,
    required this.partido,
    required this.esLocal,
    required this.habilitado,
    required this.isProcesando,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: habilitado
          ? equipo.color
          : equipo.color.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      elevation: habilitado ? DesignTokens.elevationM : 0,
      child: InkWell(
        onTap: habilitado
            ? () => _mostrarDialogGol(context)
            : null,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        splashColor: Colors.white.withValues(alpha: 0.3),
        child: Container(
          width: 120,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingL,
            vertical: DesignTokens.spacingM,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isProcesando)
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: equipo.textColor.withValues(alpha: 0.7),
                  ),
                )
              else
                Icon(
                  Icons.sports_soccer,
                  color: habilitado
                      ? equipo.textColor
                      : equipo.textColor.withValues(alpha: 0.5),
                  size: 32,
                ),
              const SizedBox(height: DesignTokens.spacingS),
              Text(
                '+GOL',
                style: textTheme.titleMedium?.copyWith(
                  color: habilitado
                      ? equipo.textColor
                      : equipo.textColor.withValues(alpha: 0.5),
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
              Text(
                equipo.displayName.toUpperCase(),
                style: textTheme.labelMedium?.copyWith(
                  color: habilitado
                      ? equipo.textColor.withValues(alpha: 0.8)
                      : equipo.textColor.withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogGol(BuildContext context) {
    final equipoQueAnota = esLocal
        ? partido.equipoLocal.color
        : partido.equipoVisitante.color;
    final equipoContrario = esLocal
        ? partido.equipoVisitante.color
        : partido.equipoLocal.color;
    final jugadores = esLocal
        ? partido.equipoLocal.jugadores
        : partido.equipoVisitante.jugadores;

    showDialog(
      context: context,
      builder: (dialogContext) => RegistrarGolDialog(
        partidoId: partido.id,
        equipoAnotador: equipoQueAnota,
        equipoContrario: equipoContrario,
        jugadores: jugadores,
        esEquipoLocal: esLocal,
        golesBloc: context.read<GolesBloc>(),
      ),
    );
  }
}
