import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../fechas/data/models/color_equipo.dart';
import '../../data/models/gol_model.dart';
import '../../data/models/partido_model.dart';
import '../bloc/goles/goles.dart';

/// Widget para mostrar lista de goles con opcion de deshacer
/// E004-HU-003: Registrar Gol
/// CA-005: Deshacer gol (dentro de 30 seg)
/// RN-005: Ventana de deshacer de 30 segundos
class ListaGolesAdminWidget extends StatelessWidget {
  /// Modelo del partido
  final PartidoModel partido;

  /// Indica si el usuario es admin
  final bool esAdmin;

  /// Indica si mostrar en modo compacto
  final bool compacto;

  /// Altura maxima del widget (para scroll)
  final double? maxHeight;

  const ListaGolesAdminWidget({
    super.key,
    required this.partido,
    required this.esAdmin,
    this.compacto = false,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GolesBloc, GolesState>(
      builder: (context, state) {
        // Obtener lista de goles
        List<GolModel> goles = [];
        if (state is GolesLoaded) {
          goles = state.goles;
        } else if (state is GolesLoading && state.golesPrevios != null) {
          goles = state.golesPrevios!;
        } else if (state is GolesProcesando && state.golesPrevios != null) {
          goles = state.golesPrevios!;
        } else if (state is GolesError && state.golesPrevios != null) {
          goles = state.golesPrevios!;
        }

        return _ListaGolesContent(
          goles: goles,
          equipoLocal: partido.equipoLocal.color,
          equipoVisitante: partido.equipoVisitante.color,
          esAdmin: esAdmin,
          compacto: compacto,
          maxHeight: maxHeight,
          isProcesando: state is GolesProcesando,
        );
      },
    );
  }
}

class _ListaGolesContent extends StatelessWidget {
  final List<GolModel> goles;
  final ColorEquipo equipoLocal;
  final ColorEquipo equipoVisitante;
  final bool esAdmin;
  final bool compacto;
  final double? maxHeight;
  final bool isProcesando;

  const _ListaGolesContent({
    required this.goles,
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.esAdmin,
    required this.compacto,
    this.maxHeight,
    required this.isProcesando,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (goles.isEmpty) {
      return _buildEmptyState(context);
    }

    // Ordenar goles por minuto (mas reciente primero para admin)
    final golesOrdenados = List<GolModel>.from(goles)
      ..sort((a, b) => b.minuto.compareTo(a.minuto));

    final content = ListView.separated(
      shrinkWrap: true,
      physics: maxHeight != null
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(
        compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
      ),
      itemCount: golesOrdenados.length,
      separatorBuilder: (_, __) => SizedBox(
        height: compacto ? DesignTokens.spacingXs : DesignTokens.spacingS,
      ),
      itemBuilder: (context, index) {
        final gol = golesOrdenados[index];
        // RN-005: Calcular si puede deshacer (ultimos 30 segundos)
        final puedeDeshacer = esAdmin && _puedeDeshacer(gol);

        return _GolItemAdmin(
          gol: gol,
          equipoLocal: equipoLocal,
          equipoVisitante: equipoVisitante,
          compacto: compacto,
          puedeDeshacer: puedeDeshacer,
          isProcesando: isProcesando,
          onDeshacer: puedeDeshacer
              ? () => _mostrarConfirmacionDeshacer(context, gol)
              : null,
        );
      },
    );

    return Container(
      constraints: maxHeight != null ? BoxConstraints(maxHeight: maxHeight!) : null,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(
              compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports_soccer,
                  size: compacto ? 16 : 20,
                  color: colorScheme.primary,
                ),
                SizedBox(
                    width:
                        compacto ? DesignTokens.spacingXs : DesignTokens.spacingS),
                Text(
                  'GOLES (${goles.length})',
                  style:
                      (compacto ? textTheme.labelSmall : textTheme.labelMedium)
                          ?.copyWith(
                    fontWeight: DesignTokens.fontWeightBold,
                    letterSpacing: 1,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (esAdmin) ...[
                  const Spacer(),
                  Icon(
                    Icons.admin_panel_settings,
                    size: 16,
                    color: colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          // Lista de goles
          maxHeight != null ? Expanded(child: content) : content,
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(
        compacto ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_soccer_outlined,
            size: compacto ? 32 : 48,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(
              height: compacto ? DesignTokens.spacingXs : DesignTokens.spacingS),
          Text(
            'Sin goles aun',
            style:
                (compacto ? textTheme.bodySmall : textTheme.bodyMedium)?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (!compacto)
            Text(
              '0 - 0',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
        ],
      ),
    );
  }

  /// RN-005: Verificar si el gol puede deshacerse (30 segundos)
  bool _puedeDeshacer(GolModel gol) {
    if (gol.createdAt == null) return false;
    final segundosDesdeRegistro =
        DateTime.now().difference(gol.createdAt!).inSeconds;
    return segundosDesdeRegistro <= 30;
  }

  void _mostrarConfirmacionDeshacer(BuildContext context, GolModel gol) {
    final colorEquipo = _getColorEquipo(gol);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.undo, color: DesignTokens.accentColor),
            SizedBox(width: DesignTokens.spacingS),
            Text('Deshacer Gol'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estas seguro de eliminar este gol?'),
            const SizedBox(height: DesignTokens.spacingM),
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: colorEquipo.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                border: Border.all(
                  color: colorEquipo.color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorEquipo.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sports_soccer,
                      color: colorEquipo.textColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gol.jugadorNombre ?? 'Sin asignar',
                          style: const TextStyle(
                            fontWeight: DesignTokens.fontWeightSemiBold,
                          ),
                        ),
                        Text(
                          "Min ${gol.minuto}' - ${colorEquipo.displayName}${gol.esAutogol ? ' (autogol)' : ''}",
                          style: TextStyle(
                            fontSize: 12,
                            color: colorEquipo.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<GolesBloc>().add(EliminarGolEvent(golId: gol.id));
            },
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.errorColor,
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  ColorEquipo _getColorEquipo(GolModel gol) {
    final colorString = gol.equipoAnotador.toLowerCase();
    if (colorString == equipoLocal.name) {
      return equipoLocal;
    } else if (colorString == equipoVisitante.name) {
      return equipoVisitante;
    }
    return ColorEquipo.fromString(gol.equipoAnotador) ?? equipoLocal;
  }
}

/// Item de gol con boton de deshacer para admin
class _GolItemAdmin extends StatelessWidget {
  final GolModel gol;
  final ColorEquipo equipoLocal;
  final ColorEquipo equipoVisitante;
  final bool compacto;
  final bool puedeDeshacer;
  final bool isProcesando;
  final VoidCallback? onDeshacer;

  const _GolItemAdmin({
    required this.gol,
    required this.equipoLocal,
    required this.equipoVisitante,
    required this.compacto,
    required this.puedeDeshacer,
    required this.isProcesando,
    this.onDeshacer,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final colorEquipo = _getColorEquipo();
    final esReciente = gol.createdAt != null &&
        DateTime.now().difference(gol.createdAt!).inSeconds < 5;

    return AnimatedContainer(
      duration: DesignTokens.animNormal,
      padding: EdgeInsets.all(
        compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
      ),
      decoration: BoxDecoration(
        color: esReciente
            ? DesignTokens.successColor.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: esReciente
              ? DesignTokens.successColor.withValues(alpha: 0.5)
              : puedeDeshacer
                  ? DesignTokens.accentColor.withValues(alpha: 0.3)
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: esReciente || puedeDeshacer ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Minuto
          Container(
            width: compacto ? 36 : 44,
            height: compacto ? 36 : 44,
            decoration: BoxDecoration(
              color: colorEquipo.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              border: Border.all(
                color: colorEquipo.color.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                "${gol.minuto}'",
                style: TextStyle(
                  fontSize: compacto ? 12 : 14,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: colorEquipo.color,
                ),
              ),
            ),
          ),

          SizedBox(
              width: compacto ? DesignTokens.spacingS : DesignTokens.spacingM),

          // Icono de balon con color del equipo
          Container(
            width: compacto ? 28 : 36,
            height: compacto ? 28 : 36,
            decoration: BoxDecoration(
              color: colorEquipo.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorEquipo.color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.sports_soccer,
                color: colorEquipo.textColor,
                size: compacto ? 14 : 18,
              ),
            ),
          ),

          SizedBox(
              width: compacto ? DesignTokens.spacingS : DesignTokens.spacingM),

          // Nombre del jugador y equipo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        gol.jugadorNombre ?? 'Sin asignar',
                        style: (compacto
                                ? textTheme.bodySmall
                                : textTheme.bodyMedium)
                            ?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (esReciente)
                      Container(
                        margin:
                            const EdgeInsets.only(left: DesignTokens.spacingXs),
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingXs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.successColor,
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusS),
                        ),
                        child: Text(
                          'NUEVO',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: DesignTokens.fontWeightBold,
                            fontSize: 8,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorEquipo.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      colorEquipo.displayName,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorEquipo.color,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                    if (gol.esAutogol) ...[
                      const SizedBox(width: DesignTokens.spacingS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingXs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.errorColor.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusS),
                          border: Border.all(
                            color:
                                DesignTokens.errorColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'AUTOGOL',
                          style: textTheme.labelSmall?.copyWith(
                            color: DesignTokens.errorColor,
                            fontWeight: DesignTokens.fontWeightBold,
                            fontSize: compacto ? 8 : 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // CA-005, RN-005: Boton deshacer (solo si esta dentro de ventana de 30 seg)
          if (puedeDeshacer)
            IconButton(
              onPressed: isProcesando ? null : onDeshacer,
              icon: isProcesando
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DesignTokens.accentColor,
                      ),
                    )
                  : Icon(
                      Icons.undo,
                      color: DesignTokens.accentColor,
                      size: compacto ? 20 : 24,
                    ),
              tooltip: 'Deshacer gol',
              style: IconButton.styleFrom(
                backgroundColor: DesignTokens.accentColor.withValues(alpha: 0.1),
              ),
            ),
        ],
      ),
    );
  }

  ColorEquipo _getColorEquipo() {
    final colorString = gol.equipoAnotador.toLowerCase();
    if (colorString == equipoLocal.name) {
      return equipoLocal;
    } else if (colorString == equipoVisitante.name) {
      return equipoVisitante;
    }
    return ColorEquipo.fromString(gol.equipoAnotador) ?? equipoLocal;
  }
}
