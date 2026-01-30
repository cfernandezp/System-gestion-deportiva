import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/inscrito_fecha_model.dart';
import '../bloc/inscritos/inscritos.dart';

/// Widget reutilizable para mostrar lista de jugadores inscritos a una fecha
/// E003-HU-003: Ver Inscritos
///
/// Criterios de Aceptacion implementados:
/// - CA-001: Acceso a lista de inscritos
/// - CA-002: Informacion de cada inscrito (foto/avatar, apodo, posicion)
/// - CA-003: Header con contador "X jugadores anotados"
/// - CA-004: Estado vacio con icono y mensaje
/// - CA-005: Indicador "(Tu)" para usuario actual con fondo diferenciado
/// - CA-006: Actualizacion en tiempo real con feedback visual
///
/// Reglas de Negocio:
/// - RN-003: Orden por fecha de inscripcion
/// - RN-005: Pull-to-refresh para actualizacion manual (fallback)
class InscritosListWidget extends StatefulWidget {
  /// ID de la fecha para cargar inscritos
  final String fechaId;

  /// Si mostrar el widget en modo compacto (para cards)
  final bool compacto;

  /// Si habilitar realtime automaticamente
  final bool habilitarRealtime;

  /// Si iniciar expandido (solo aplica si es expandible)
  final bool expandidoInicial;

  /// Si el widget es expandible/colapsable
  final bool expandible;

  /// Capacidad maxima para mostrar progreso (opcional)
  final int? capacidadMaxima;

  const InscritosListWidget({
    super.key,
    required this.fechaId,
    this.compacto = false,
    this.habilitarRealtime = true,
    this.expandidoInicial = true,
    this.expandible = true,
    this.capacidadMaxima,
  });

  @override
  State<InscritosListWidget> createState() => _InscritosListWidgetState();
}

class _InscritosListWidgetState extends State<InscritosListWidget>
    with SingleTickerProviderStateMixin {
  late bool _expandido;

  /// Controlador para animacion de actualizacion realtime (CA-006)
  late AnimationController _realtimeAnimController;
  late Animation<double> _realtimeAnimation;

  @override
  void initState() {
    super.initState();
    _expandido = widget.expandidoInicial;

    // CA-006: Animacion para feedback de actualizacion realtime
    _realtimeAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _realtimeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _realtimeAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _realtimeAnimController.dispose();
    super.dispose();
  }

  /// CA-006: Mostrar animacion de actualizacion
  void _mostrarAnimacionActualizacion() {
    _realtimeAnimController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _realtimeAnimController.reverse();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = sl<InscritosBloc>();
        // Cargar inscritos
        bloc.add(CargarInscritosEvent(fechaId: widget.fechaId));
        // Iniciar realtime si esta habilitado
        if (widget.habilitarRealtime) {
          bloc.add(IniciarRealtimeEvent(fechaId: widget.fechaId));
        }
        return bloc;
      },
      child: BlocConsumer<InscritosBloc, InscritosState>(
        listener: (context, state) {
          // CA-006: Feedback visual cuando hay actualizacion realtime
          if (state is InscritosLoaded && state.realtimeActivo) {
            _mostrarAnimacionActualizacion();
          }
        },
        builder: (context, state) {
          return _buildContent(context, state);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, InscritosState state) {
    final colorScheme = Theme.of(context).colorScheme;

    // Container principal con borde
    return AnimatedBuilder(
      animation: _realtimeAnimation,
      builder: (context, child) {
        // CA-006: Borde brillante durante actualizacion realtime
        final borderColor = Color.lerp(
          colorScheme.outlineVariant.withValues(alpha: 0.5),
          colorScheme.primary,
          _realtimeAnimation.value,
        )!;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(
              color: borderColor,
              width: 1 + (_realtimeAnimation.value * 1),
            ),
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con contador (CA-003)
          _buildHeader(context, state),

          // Lista de inscritos (expandible)
          if (_expandido || !widget.expandible) ...[
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            _buildListaContent(context, state),
          ],
        ],
      ),
    );
  }

  /// CA-003: Header con contador "X jugadores anotados"
  Widget _buildHeader(BuildContext context, InscritosState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Obtener datos segun estado
    int total = 0;
    String mensaje = 'Cargando...';
    bool isLoading = false;

    if (state is InscritosLoading) {
      isLoading = true;
    } else if (state is InscritosLoaded) {
      total = state.total;
      mensaje = state.message;
    } else if (state is InscritosError) {
      mensaje = 'Error al cargar';
    }

    return InkWell(
      onTap: widget.expandible
          ? () => setState(() => _expandido = !_expandido)
          : null,
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(DesignTokens.radiusM),
        bottom: _expandido || !widget.expandible
            ? Radius.zero
            : const Radius.circular(DesignTokens.radiusM),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          widget.compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
        ),
        child: Row(
          children: [
            // Icono
            Container(
              padding: EdgeInsets.all(
                widget.compacto ? DesignTokens.spacingXs : DesignTokens.spacingS,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Icon(
                Icons.group,
                color: colorScheme.primary,
                size: widget.compacto
                    ? DesignTokens.iconSizeS
                    : DesignTokens.iconSizeM,
              ),
            ),
            SizedBox(
              width: widget.compacto
                  ? DesignTokens.spacingS
                  : DesignTokens.spacingM,
            ),

            // Titulo y contador
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jugadores anotados',
                    style: (widget.compacto
                            ? textTheme.bodyMedium
                            : textTheme.titleSmall)
                        ?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                  if (!widget.compacto) ...[
                    const SizedBox(height: DesignTokens.spacingXxs),
                    Text(
                      mensaje,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Indicador de progreso o contador
            if (isLoading)
              SizedBox(
                width: widget.compacto ? 20 : 24,
                height: widget.compacto ? 20 : 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              )
            else if (widget.capacidadMaxima != null && !widget.compacto)
              _buildProgressIndicator(context, total)
            else
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compacto
                      ? DesignTokens.spacingS
                      : DesignTokens.spacingM,
                  vertical: widget.compacto
                      ? DesignTokens.spacingXs
                      : DesignTokens.spacingS,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Text(
                  '$total',
                  style: (widget.compacto
                          ? textTheme.labelMedium
                          : textTheme.titleMedium)
                      ?.copyWith(
                    fontWeight: DesignTokens.fontWeightBold,
                    color: colorScheme.primary,
                  ),
                ),
              ),

            // Icono expandir/colapsar
            if (widget.expandible) ...[
              const SizedBox(width: DesignTokens.spacingS),
              Icon(
                _expandido ? Icons.expand_less : Icons.expand_more,
                color: colorScheme.onSurfaceVariant,
                size: widget.compacto
                    ? DesignTokens.iconSizeS
                    : DesignTokens.iconSizeM,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Indicador circular de ocupacion (cuando hay capacidad definida)
  Widget _buildProgressIndicator(BuildContext context, int total) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final capacidad = widget.capacidadMaxima ?? 0;
    final porcentaje = capacidad > 0 ? total / capacidad : 0.0;

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
            '$total',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Contenido de la lista segun el estado
  Widget _buildListaContent(BuildContext context, InscritosState state) {
    // Estado de carga
    if (state is InscritosLoading) {
      return _buildLoadingState(context);
    }

    // Estado de error
    if (state is InscritosError) {
      return _buildErrorState(context, state);
    }

    // Estado cargado
    if (state is InscritosLoaded) {
      // CA-004: Lista vacia
      if (state.estaVacia) {
        return _buildEmptyState(context);
      }
      // CA-001, CA-002: Lista con datos
      return _buildListaInscritos(context, state.inscritos);
    }

    // Estado inicial
    return _buildEmptyState(context);
  }

  /// Estado de carga con shimmer/skeleton
  Widget _buildLoadingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
            child: Row(
              children: [
                // Avatar skeleton
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                // Text skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 120,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusXs),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingXs),
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusXs),
                        ),
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

  /// CA-004: Estado vacio con icono y mensaje
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.all(
        widget.compacto ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: widget.compacto
                  ? DesignTokens.iconSizeL
                  : DesignTokens.iconSizeXl,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(
              height:
                  widget.compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
            ),
            Text(
              'Aun no hay jugadores anotados',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (!widget.compacto) ...[
              const SizedBox(height: DesignTokens.spacingS),
              Text(
                'Se el primero en anotarte',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Estado de error con opcion de reintentar
  Widget _buildErrorState(BuildContext context, InscritosError state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.all(
        widget.compacto ? DesignTokens.spacingM : DesignTokens.spacingL,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: widget.compacto
                  ? DesignTokens.iconSizeL
                  : DesignTokens.iconSizeXl,
              color: colorScheme.error,
            ),
            SizedBox(
              height:
                  widget.compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
            ),
            Text(
              state.message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height:
                  widget.compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
            ),
            // RN-005: Boton de reintentar (fallback)
            TextButton.icon(
              onPressed: () {
                context.read<InscritosBloc>().add(
                      CargarInscritosEvent(fechaId: widget.fechaId),
                    );
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  /// CA-001, CA-002: Lista de jugadores inscritos
  Widget _buildListaInscritos(
    BuildContext context,
    List<InscritoFechaModel> inscritos,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // RN-005: Pull-to-refresh para actualizacion manual
    return RefreshIndicator(
      onRefresh: () async {
        context.read<InscritosBloc>().add(const RefrescarInscritosEvent());
        // Esperar un poco para que se vea el indicador
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.separated(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          vertical:
              widget.compacto ? DesignTokens.spacingXs : DesignTokens.spacingS,
        ),
        itemCount: inscritos.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: DesignTokens.spacingM + 40 + DesignTokens.spacingM,
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        itemBuilder: (context, index) {
          final inscrito = inscritos[index];
          return _InscritoTile(
            inscrito: inscrito,
            index: index,
            compacto: widget.compacto,
          );
        },
      ),
    );
  }
}

/// CA-002, CA-005: Tile individual de un jugador inscrito
class _InscritoTile extends StatelessWidget {
  final InscritoFechaModel inscrito;
  final int index;
  final bool compacto;

  const _InscritoTile({
    required this.inscrito,
    required this.index,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // CA-005: Fondo diferenciado para usuario actual
    final backgroundColor = inscrito.esUsuarioActual
        ? colorScheme.primaryContainer.withValues(alpha: 0.2)
        : Colors.transparent;

    return Container(
      color: backgroundColor,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
          vertical: compacto ? DesignTokens.spacingXs : DesignTokens.spacingS,
        ),
        child: Row(
          children: [
            // CA-002: Avatar/foto circular
            _buildAvatar(context),

            SizedBox(
              width: compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
            ),

            // CA-002: Apodo y posicion
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CA-005: Nombre con indicador "(Tu)"
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          inscrito.nombreDisplay,
                          style: (compacto
                                  ? textTheme.bodySmall
                                  : textTheme.bodyMedium)
                              ?.copyWith(
                            fontWeight: inscrito.esUsuarioActual
                                ? DesignTokens.fontWeightSemiBold
                                : DesignTokens.fontWeightMedium,
                            color: inscrito.esUsuarioActual
                                ? colorScheme.primary
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // CA-002: Posicion preferida
                  if (inscrito.posicionPreferida != null &&
                      inscrito.posicionPreferida!.isNotEmpty)
                    Text(
                      inscrito.posicionPreferida!,
                      style: (compacto ? textTheme.labelSmall : textTheme.bodySmall)
                          ?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),

            // Fecha de inscripcion (solo en modo no compacto)
            if (!compacto && inscrito.inscritoAt != null)
              Text(
                _formatearFechaRelativa(inscrito.inscritoAt!),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// CA-002: Avatar circular con foto o inicial
  Widget _buildAvatar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = compacto ? 32.0 : 40.0;

    // Si tiene foto, mostrar imagen
    if (inscrito.fotoUrl != null && inscrito.fotoUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          image: DecorationImage(
            image: NetworkImage(inscrito.fotoUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Sin foto: mostrar inicial con gradiente
    final inicial = inscrito.nombreSinIndicador.isNotEmpty
        ? inscrito.nombreSinIndicador[0].toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: DesignTokens.primaryGradient,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Center(
        child: Text(
          inicial,
          style: (compacto ? textTheme.labelMedium : textTheme.titleSmall)
              ?.copyWith(
            color: Colors.white,
            fontWeight: DesignTokens.fontWeightBold,
          ),
        ),
      ),
    );
  }

  /// Formatea fecha de inscripcion de manera relativa
  String _formatearFechaRelativa(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 1) {
      return 'Ahora';
    } else if (diferencia.inMinutes < 60) {
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
