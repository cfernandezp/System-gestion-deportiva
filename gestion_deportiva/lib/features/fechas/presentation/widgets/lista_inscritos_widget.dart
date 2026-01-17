import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/inscrito_model.dart';

/// Widget de lista expandible de jugadores inscritos
/// E003-HU-002: CA-006
/// Muestra header con contador y lista de jugadores anotados
class ListaInscritosWidget extends StatefulWidget {
  /// Lista de jugadores inscritos
  final List<InscritoModel> inscritos;

  /// Total de inscritos (puede diferir de inscritos.length por paginacion)
  final int totalInscritos;

  /// Capacidad maxima de la fecha
  final int capacidadMaxima;

  /// Si iniciar expandido
  final bool expandidoInicial;

  const ListaInscritosWidget({
    super.key,
    required this.inscritos,
    required this.totalInscritos,
    required this.capacidadMaxima,
    this.expandidoInicial = true,
  });

  @override
  State<ListaInscritosWidget> createState() => _ListaInscritosWidgetState();
}

class _ListaInscritosWidgetState extends State<ListaInscritosWidget> {
  late bool _expandido;

  @override
  void initState() {
    super.initState();
    _expandido = widget.expandidoInicial;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con contador (CA-006)
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(DesignTokens.radiusM),
              bottom: _expandido
                  ? Radius.zero
                  : const Radius.circular(DesignTokens.radiusM),
            ),
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingM),
              child: Row(
                children: [
                  // Icono
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spacingS),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: Icon(
                      Icons.group,
                      color: colorScheme.primary,
                      size: DesignTokens.iconSizeM,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingM),

                  // Titulo y contador
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jugadores anotados',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: DesignTokens.fontWeightSemiBold,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacingXxs),
                        Text(
                          '${widget.totalInscritos} de ${widget.capacidadMaxima} lugares',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Indicador de progreso circular
                  _buildProgressIndicator(context),

                  const SizedBox(width: DesignTokens.spacingS),

                  // Icono expandir/colapsar
                  Icon(
                    _expandido ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Lista de inscritos (expandible)
          if (_expandido) ...[
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            _buildListaInscritos(context),
          ],
        ],
      ),
    );
  }

  /// Indicador circular de ocupacion
  Widget _buildProgressIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final porcentaje = widget.capacidadMaxima > 0
        ? widget.totalInscritos / widget.capacidadMaxima
        : 0.0;

    final color = porcentaje >= 1.0
        ? DesignTokens.errorColor
        : porcentaje >= 0.8
            ? DesignTokens.accentColor
            : DesignTokens.successColor;

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: porcentaje.clamp(0.0, 1.0),
            strokeWidth: 4,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: color,
          ),
          Text(
            '${widget.totalInscritos}',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Lista de jugadores inscritos
  Widget _buildListaInscritos(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (widget.inscritos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.person_add_outlined,
                size: DesignTokens.iconSizeL,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: DesignTokens.spacingS),
              Text(
                'Se el primero en anotarte',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
      itemCount: widget.inscritos.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: DesignTokens.spacingM + 40 + DesignTokens.spacingM,
        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
      itemBuilder: (context, index) {
        final inscrito = widget.inscritos[index];
        return _InscritoTile(inscrito: inscrito, index: index);
      },
    );
  }
}

/// Tile individual de un jugador inscrito
class _InscritoTile extends StatelessWidget {
  final InscritoModel inscrito;
  final int index;

  const _InscritoTile({
    required this.inscrito,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      child: Row(
        children: [
          // Avatar con numero
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: DesignTokens.primaryGradient,
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
            child: Center(
              child: Text(
                inscrito.nombreCompleto.isNotEmpty
                    ? inscrito.nombreCompleto[0].toUpperCase()
                    : '?',
                style: textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
            ),
          ),

          const SizedBox(width: DesignTokens.spacingM),

          // Nombre y posicion
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inscrito.nombreDisplay,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (inscrito.posicion != null && inscrito.posicion!.isNotEmpty)
                  Text(
                    inscrito.posicion!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),

          // Fecha de inscripcion
          Text(
            _formatearFechaInscripcion(inscrito.fechaInscripcion),
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Formatea fecha de inscripcion de manera relativa
  String _formatearFechaInscripcion(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours}h';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays}d';
    } else {
      return '${fecha.day}/${fecha.month}';
    }
  }
}
