import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import 'app_button.dart';

/// Widget para mostrar estados vacios con mensaje y accion opcional
/// Usar cuando una lista esta vacia o no hay datos que mostrar
class EmptyStateWidget extends StatelessWidget {
  /// Constructor principal
  const EmptyStateWidget({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.iconWidget,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.compact = false,
  });

  /// Constructor para lista vacia
  const EmptyStateWidget.noData({
    super.key,
    this.title = 'No hay datos',
    this.description = 'Aun no hay informacion para mostrar',
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  })  : iconWidget = null,
        secondaryActionLabel = null,
        onSecondaryAction = null;

  /// Constructor para busqueda sin resultados
  const EmptyStateWidget.noResults({
    super.key,
    this.title = 'Sin resultados',
    this.description = 'No se encontraron coincidencias para tu busqueda',
    this.icon = Icons.search_off_outlined,
    this.actionLabel = 'Limpiar busqueda',
    this.onAction,
    this.compact = false,
  })  : iconWidget = null,
        secondaryActionLabel = null,
        onSecondaryAction = null;

  /// Constructor para error
  const EmptyStateWidget.error({
    super.key,
    this.title = 'Algo salio mal',
    this.description = 'Ocurrio un error al cargar los datos',
    this.icon = Icons.error_outline,
    this.actionLabel = 'Reintentar',
    this.onAction,
    this.compact = false,
  })  : iconWidget = null,
        secondaryActionLabel = null,
        onSecondaryAction = null;

  /// Constructor para sin conexion
  const EmptyStateWidget.offline({
    super.key,
    this.title = 'Sin conexion',
    this.description = 'Verifica tu conexion a internet e intenta de nuevo',
    this.icon = Icons.wifi_off_outlined,
    this.actionLabel = 'Reintentar',
    this.onAction,
    this.compact = false,
  })  : iconWidget = null,
        secondaryActionLabel = null,
        onSecondaryAction = null;

  /// Constructor para partidos
  const EmptyStateWidget.noMatches({
    super.key,
    this.title = 'No hay partidos',
    this.description = 'Aun no se han programado partidos',
    this.icon = Icons.sports_soccer_outlined,
    this.actionLabel = 'Crear partido',
    this.onAction,
    this.compact = false,
  })  : iconWidget = null,
        secondaryActionLabel = null,
        onSecondaryAction = null;

  /// Constructor para equipos
  const EmptyStateWidget.noTeams({
    super.key,
    this.title = 'No hay equipos',
    this.description = 'Aun no se han registrado equipos',
    this.icon = Icons.groups_outlined,
    this.actionLabel = 'Crear equipo',
    this.onAction,
    this.compact = false,
  })  : iconWidget = null,
        secondaryActionLabel = null,
        onSecondaryAction = null;

  /// Constructor para jugadores
  const EmptyStateWidget.noPlayers({
    super.key,
    this.title = 'No hay jugadores',
    this.description = 'Aun no se han registrado jugadores',
    this.icon = Icons.person_outline,
    this.actionLabel = 'Agregar jugador',
    this.onAction,
    this.compact = false,
  })  : iconWidget = null,
        secondaryActionLabel = null,
        onSecondaryAction = null;

  /// Titulo principal
  final String title;

  /// Descripcion opcional
  final String? description;

  /// Icono a mostrar
  final IconData? icon;

  /// Widget de icono personalizado (reemplaza icon)
  final Widget? iconWidget;

  /// Texto del boton de accion principal
  final String? actionLabel;

  /// Callback de accion principal
  final VoidCallback? onAction;

  /// Texto del boton de accion secundaria
  final String? secondaryActionLabel;

  /// Callback de accion secundaria
  final VoidCallback? onSecondaryAction;

  /// Si debe mostrarse en version compacta
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final iconSize =
        compact ? DesignTokens.iconSizeXl : DesignTokens.iconSizeXxl;
    final spacing = compact ? DesignTokens.spacingS : DesignTokens.spacingM;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? DesignTokens.spacingM : DesignTokens.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono
            if (iconWidget != null)
              iconWidget!
            else if (icon != null)
              Container(
                padding: EdgeInsets.all(compact ? DesignTokens.spacingM : DesignTokens.spacingL),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

            SizedBox(height: spacing * 1.5),

            // Titulo
            Text(
              title,
              style: (compact ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)
                  ?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            // Descripcion
            if (description != null) ...[
              SizedBox(height: spacing / 2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // Acciones
            if (actionLabel != null || secondaryActionLabel != null) ...[
              SizedBox(height: spacing * 1.5),
              Wrap(
                spacing: DesignTokens.spacingS,
                runSpacing: DesignTokens.spacingS,
                alignment: WrapAlignment.center,
                children: [
                  if (actionLabel != null)
                    AppButton(
                      label: actionLabel!,
                      onPressed: onAction,
                      size: compact ? AppButtonSize.small : AppButtonSize.medium,
                    ),
                  if (secondaryActionLabel != null)
                    AppButton(
                      label: secondaryActionLabel!,
                      onPressed: onSecondaryAction,
                      variant: AppButtonVariant.secondary,
                      size: compact ? AppButtonSize.small : AppButtonSize.medium,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado vacio animado con ilustracion
class AnimatedEmptyState extends StatefulWidget {
  const AnimatedEmptyState({
    super.key,
    required this.title,
    this.description,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<AnimatedEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignTokens.animSlow,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: EmptyStateWidget(
              title: widget.title,
              description: widget.description,
              icon: widget.icon,
              actionLabel: widget.actionLabel,
              onAction: widget.onAction,
            ),
          ),
        );
      },
    );
  }
}
