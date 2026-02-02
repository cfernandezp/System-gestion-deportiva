import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/fecha_detalle_model.dart';
import '../../domain/repositories/fechas_repository.dart';
import '../bloc/iniciar_fecha/iniciar_fecha.dart';

/// Dialog/BottomSheet para iniciar una fecha de pichanga
/// E003-HU-012: Iniciar Fecha
///
/// CA-002: Confirmacion con resumen
/// CA-003: Warning si no hay equipos asignados
/// CA-004: Estado cambia a en_juego
class IniciarFechaDialog extends StatefulWidget {
  /// Detalle de la fecha a iniciar
  final FechaDetalleModel fechaDetalle;

  /// Callback cuando se inicia exitosamente
  final VoidCallback? onSuccess;

  const IniciarFechaDialog({
    super.key,
    required this.fechaDetalle,
    this.onSuccess,
  });

  @override
  State<IniciarFechaDialog> createState() => _IniciarFechaDialogState();

  /// Muestra el dialog adaptado segun el dispositivo
  /// Mobile: BottomSheet
  /// Desktop: Dialog centrado
  static Future<void> show(
    BuildContext context, {
    required FechaDetalleModel fechaDetalle,
    VoidCallback? onSuccess,
  }) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    if (isDesktop) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => BlocProvider(
          create: (_) => IniciarFechaBloc(repository: sl()),
          child: IniciarFechaDialog(
            fechaDetalle: fechaDetalle,
            onSuccess: onSuccess,
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => BlocProvider(
          create: (_) => IniciarFechaBloc(repository: sl()),
          child: DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) => Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(DesignTokens.radiusL),
                ),
              ),
              child: IniciarFechaDialog(
                fechaDetalle: fechaDetalle,
                onSuccess: onSuccess,
              ),
            ),
          ),
        ),
      );
    }
  }
}

class _IniciarFechaDialogState extends State<IniciarFechaDialog> {
  /// Cantidad de equipos asignados (cargado automaticamente)
  int _totalEquipos = 0;

  /// Lista de equipos con jugadores
  List<EquipoResumen> _equiposResumen = [];

  /// Estado de carga de equipos
  bool _cargandoEquipos = true;

  @override
  void initState() {
    super.initState();
    _cargarEquipos();
  }

  /// Carga los datos de equipos desde el repositorio
  Future<void> _cargarEquipos() async {
    final repository = sl<FechasRepository>();
    final fechaId = widget.fechaDetalle.fecha.fechaId;

    final result = await repository.obtenerEquiposFecha(fechaId);

    if (!mounted) return;

    result.fold(
      (failure) {
        // En caso de error, mantener valores por defecto
        setState(() {
          _cargandoEquipos = false;
        });
      },
      (response) {
        if (response.success && response.data != null) {
          final data = response.data!;
          setState(() {
            _totalEquipos = data.totalEquipos;
            _equiposResumen = data.equipos
                .map((e) => EquipoResumen(
                      nombre: e.nombreEquipo,
                      color: _hexToColor(e.colorHex),
                      jugadores: e.totalJugadores,
                    ))
                .toList();
            _cargandoEquipos = false;
          });
        } else {
          setState(() {
            _cargandoEquipos = false;
          });
        }
      },
    );
  }

  /// Convierte un color hex a Color
  Color _hexToColor(String hex) {
    final hexCode = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  /// Verifica si hay warning por falta de equipos
  /// Solo muestra warning cuando ya terminó de cargar los equipos
  bool get _tieneWarningSinEquipos => !_cargandoEquipos && _totalEquipos < 2;

  void _confirmarInicio(BuildContext context) {
    context.read<IniciarFechaBloc>().add(IniciarFechaSubmitEvent(
          fechaId: widget.fechaDetalle.fecha.fechaId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return BlocListener<IniciarFechaBloc, IniciarFechaState>(
      listener: (context, state) {
        if (state is IniciarFechaSuccess) {
          Navigator.of(context).pop();
          widget.onSuccess?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.play_circle, color: Colors.white),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: DesignTokens.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (state is IniciarFechaError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: DesignTokens.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<IniciarFechaBloc, IniciarFechaState>(
        builder: (context, state) {
          final isLoading = state is IniciarFechaLoading;

          if (isDesktop) {
            return _buildDesktopDialog(
              context,
              colorScheme,
              textTheme,
              isLoading,
            );
          } else {
            return _buildMobileContent(
              context,
              colorScheme,
              textTheme,
              isLoading,
            );
          }
        },
      ),
    );
  }

  Widget _buildDesktopDialog(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isLoading,
  ) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, colorScheme, textTheme, isLoading),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DesignTokens.spacingL),
                child: _buildContent(context, colorScheme, textTheme),
              ),
            ),
            _buildFooter(context, colorScheme, isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileContent(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isLoading,
  ) {
    return Column(
      children: [
        // Handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: DesignTokens.spacingM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        _buildHeader(context, colorScheme, textTheme, isLoading),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: _buildContent(context, colorScheme, textTheme),
          ),
        ),
        _buildFooter(context, colorScheme, isLoading),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isLoading,
  ) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingS),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Icon(
              Icons.play_circle,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Iniciar Pichanga',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                Text(
                  'Esta accion no se puede deshacer',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CA-003: Warning si no hay equipos
        if (_tieneWarningSinEquipos) ...[
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: DesignTokens.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: DesignTokens.accentColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: DesignTokens.accentColor,
                  size: 24,
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ATENCION',
                        style: textTheme.labelMedium?.copyWith(
                          color: DesignTokens.accentColor,
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingXs),
                      Text(
                        'No hay equipos asignados. Se recomienda asignar equipos antes de iniciar.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),
        ],

        // Info de la fecha
        Text(
          'DETALLES DE LA PICHANGA',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: DesignTokens.fontWeightSemiBold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                Icons.calendar_today,
                'Fecha',
                widget.fechaDetalle.fecha.fechaFormato,
                colorScheme,
                textTheme,
              ),
              const SizedBox(height: DesignTokens.spacingS),
              _buildInfoRow(
                Icons.access_time,
                'Hora pactada',
                widget.fechaDetalle.fecha.horaFormato.isNotEmpty
                    ? widget.fechaDetalle.fecha.horaFormato
                    : 'No definida',
                colorScheme,
                textTheme,
              ),
              const SizedBox(height: DesignTokens.spacingS),
              _buildInfoRow(
                Icons.location_on,
                'Lugar',
                widget.fechaDetalle.fecha.lugar,
                colorScheme,
                textTheme,
              ),
              const SizedBox(height: DesignTokens.spacingS),
              _buildInfoRow(
                Icons.people,
                'Inscritos',
                '${widget.fechaDetalle.totalInscritos} jugadores',
                colorScheme,
                textTheme,
              ),
              const SizedBox(height: DesignTokens.spacingS),
              _buildInfoRow(
                Icons.groups,
                'Equipos',
                _cargandoEquipos
                    ? 'Cargando...'
                    : _totalEquipos > 0
                        ? '$_totalEquipos equipos asignados'
                        : 'Sin asignar',
                colorScheme,
                textTheme,
                isWarning: !_cargandoEquipos && _totalEquipos < 2,
              ),
            ],
          ),
        ),

        // Resumen de equipos si hay
        if (_equiposResumen.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.spacingL),
          Text(
            'EQUIPOS',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: DesignTokens.fontWeightSemiBold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          ..._equiposResumen.map((equipo) => Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.spacingXs),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: equipo.color,
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusXs),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Text(
                      equipo.nombre,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${equipo.jugadores} jugadores',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )),
        ],

        const SizedBox(height: DesignTokens.spacingL),

        // Mensaje informativo
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: Text(
                  'Al iniciar, se notificara a todos los jugadores inscritos y se registrara la hora real de inicio.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    bool isWarning = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isWarning
              ? DesignTokens.accentColor
              : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: DesignTokens.spacingS),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightMedium,
              color: isWarning ? DesignTokens.accentColor : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(
    BuildContext context,
    ColorScheme colorScheme,
    bool isLoading,
  ) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: DesignTokens.spacingM),
          FilledButton.icon(
            onPressed: isLoading ? null : () => _confirmarInicio(context),
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_circle),
            label: Text(
              _tieneWarningSinEquipos
                  ? 'Iniciar de Todas Formas'
                  : 'Iniciar Pichanga',
            ),
          ),
        ],
      ),
    );
  }
}

/// Clase auxiliar para resumen de equipo
class EquipoResumen {
  final String nombre;
  final Color color;
  final int jugadores;

  const EquipoResumen({
    required this.nombre,
    required this.color,
    required this.jugadores,
  });
}
