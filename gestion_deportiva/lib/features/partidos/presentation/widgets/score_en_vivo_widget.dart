import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/score_partido_model.dart';
import '../bloc/score/score.dart';
import 'score_marcador_widget.dart';
import 'lista_goles_widget.dart';

/// Widget para mostrar el score en vivo de un partido
/// E004-HU-004: Ver Score en Vivo
/// Integra ScoreMarcadorWidget y ListaGolesWidget con el ScoreBloc
///
/// CA-001: Marcador visible (Equipo1 [goles] - [goles] Equipo2)
/// CA-002: Colores de equipo (naranja, verde, azul)
/// CA-003: Actualizacion en tiempo real (Supabase realtime en tabla goles)
/// CA-004: Lista de goles (jugador, minuto, equipo)
/// CA-005: Tiempo restante junto al score
/// CA-006: Indicador de equipo ganando (destacar visualmente)
/// CA-007: Empate visible
class ScoreEnVivoWidget extends StatelessWidget {
  /// ID del partido a mostrar
  final String partidoId;

  /// Indica si mostrar la lista de goles
  final bool mostrarListaGoles;

  /// Indica si es vista compacta
  final bool compacto;

  /// Altura maxima para la lista de goles
  final double? maxHeightGoles;

  /// Callback cuando cambia el score
  final void Function(ScorePartidoModel score)? onScoreChanged;

  const ScoreEnVivoWidget({
    super.key,
    required this.partidoId,
    this.mostrarListaGoles = true,
    this.compacto = false,
    this.maxHeightGoles,
    this.onScoreChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ScoreBloc>()
        ..add(CargarScoreEvent(partidoId: partidoId)),
      child: _ScoreEnVivoContent(
        mostrarListaGoles: mostrarListaGoles,
        compacto: compacto,
        maxHeightGoles: maxHeightGoles,
        onScoreChanged: onScoreChanged,
      ),
    );
  }
}

class _ScoreEnVivoContent extends StatelessWidget {
  final bool mostrarListaGoles;
  final bool compacto;
  final double? maxHeightGoles;
  final void Function(ScorePartidoModel score)? onScoreChanged;

  const _ScoreEnVivoContent({
    required this.mostrarListaGoles,
    required this.compacto,
    this.maxHeightGoles,
    this.onScoreChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScoreBloc, ScoreState>(
      listener: (context, state) {
        if (state is ScoreLoaded) {
          onScoreChanged?.call(state.score);
        }

        // Mostrar errores
        if (state is ScoreError) {
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
            ),
          );
        }
      },
      builder: (context, state) {
        // Estado de carga
        if (state is ScoreLoading) {
          return _buildLoadingState(context, state.scorePrevio);
        }

        // Score cargado
        if (state is ScoreLoaded) {
          return _buildScoreContent(context, state.score);
        }

        // Error con score previo
        if (state is ScoreError && state.scorePrevio != null) {
          return _buildScoreContent(context, state.scorePrevio!);
        }

        // Error sin datos
        if (state is ScoreError) {
          return _buildErrorState(context, state);
        }

        // Estado inicial - Loading
        return _buildLoadingState(context, null);
      },
    );
  }

  Widget _buildLoadingState(BuildContext context, ScorePartidoModel? scorePrevio) {
    final colorScheme = Theme.of(context).colorScheme;

    // Si hay score previo, mostrar con indicador de actualizando
    if (scorePrevio != null) {
      return Stack(
        children: [
          _buildScoreContent(context, scorePrevio),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      );
    }

    // Loading sin datos previos
    return Container(
      padding: EdgeInsets.all(
        compacto ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Cargando score...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreContent(BuildContext context, ScorePartidoModel score) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Marcador
        ScoreMarcadorWidget(
          score: score,
          mostrarTiempo: true,
          compacto: compacto,
        ),

        // Lista de goles
        if (mostrarListaGoles) ...[
          SizedBox(
            height: compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
          ),
          ListaGolesWidget(
            goles: score.goles,
            equipoLocal: score.equipoLocal.color,
            equipoVisitante: score.equipoVisitante.color,
            compacto: compacto,
            maxHeight: maxHeightGoles,
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, ScoreError state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(
        compacto ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(color: DesignTokens.errorColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: compacto ? DesignTokens.iconSizeL : DesignTokens.iconSizeXl,
            color: DesignTokens.errorColor,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            state.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          if (state.partidoId != null)
            FilledButton.icon(
              onPressed: () {
                context.read<ScoreBloc>().add(
                      CargarScoreEvent(partidoId: state.partidoId!),
                    );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
        ],
      ),
    );
  }
}
