import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart'; // Para CrearFechaBloc en dialog
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/fecha_model.dart';
import '../../data/models/listar_fechas_por_rol_response_model.dart';
import '../bloc/crear_fecha/crear_fecha.dart';
import '../bloc/fechas_por_rol/fechas_por_rol.dart';
import '../bloc/inscripcion/inscripcion.dart';
import '../widgets/widgets.dart';

/// Pagina de lista de fechas con tabs segun rol del usuario
/// E003-HU-009: Listar Fechas por Rol
///
/// JUGADOR - Tabs:
/// - Proximas: Fechas abiertas para inscribirse
/// - Inscrito: Fechas cerradas/en_juego donde esta inscrito
/// - Historial: Fechas finalizadas donde participo
///
/// ADMIN - Tabs:
/// - Proximas: Fechas abiertas
/// - En Curso: Fechas cerradas/en_juego
/// - Historial: Fechas finalizadas
/// - Todas: Todas las fechas con filtros
class FechasDisponiblesPage extends StatelessWidget {
  const FechasDisponiblesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // El BlocProvider viene del router (app_router.dart)
    // NO crear uno nuevo aqui para evitar duplicacion y problemas de estado
    return BlocBuilder<FechasPorRolBloc, FechasPorRolState>(
      builder: (context, state) {
        // Determinar si es admin desde el estado
        final esAdmin = _esAdminDesdeEstado(state);

        // Siempre mostrar el layout, el loading/error va dentro del contenido
        return ResponsiveLayout(
          mobileBody: _MobileFechasView(esAdmin: esAdmin),
          desktopBody: _DesktopFechasView(esAdmin: esAdmin),
        );
      },
    );
  }

  bool _esAdminDesdeEstado(FechasPorRolState state) {
    if (state is FechasPorRolLoaded) return state.esAdmin;
    if (state is FechasPorRolEmpty) return state.esAdmin;
    if (state is FechasPorRolRefreshing) return state.esAdmin;
    return false;
  }
}

// ============================================
// VISTA MOBILE - App Style con Tabs
// ============================================

class _MobileFechasView extends StatefulWidget {
  final bool esAdmin;

  const _MobileFechasView({required this.esAdmin});

  @override
  State<_MobileFechasView> createState() => _MobileFechasViewState();
}

class _MobileFechasViewState extends State<_MobileFechasView>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Obtener el index inicial desde el bloc
    final bloc = context.read<FechasPorRolBloc>();
    final initialIndex = _getIndexPorSeccion(bloc.seccionActual);
    _tabController = TabController(
      length: widget.esAdmin ? 4 : 3,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(covariant _MobileFechasView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambia el rol, recrear el tab controller
    if (oldWidget.esAdmin != widget.esAdmin) {
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();
      final bloc = context.read<FechasPorRolBloc>();
      final currentIndex = _getIndexPorSeccion(bloc.seccionActual);
      _tabController = TabController(
        length: widget.esAdmin ? 4 : 3,
        vsync: this,
        initialIndex: currentIndex.clamp(0, (widget.esAdmin ? 4 : 3) - 1),
      );
      _tabController.addListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final seccion = _getSeccionPorIndex(_tabController.index);
    context.read<FechasPorRolBloc>().add(CambiarSeccionEvent(seccion: seccion));
  }

  int _getIndexPorSeccion(String seccion) {
    if (widget.esAdmin) {
      switch (seccion) {
        case 'proximas':
          return 0;
        case 'en_curso':
          return 1;
        case 'historial':
          return 2;
        case 'todas':
          return 3;
        default:
          return 0;
      }
    } else {
      switch (seccion) {
        case 'proximas':
          return 0;
        case 'inscrito':
          return 1;
        case 'historial':
          return 2;
        default:
          return 0;
      }
    }
  }

  String _getSeccionPorIndex(int index) {
    if (widget.esAdmin) {
      switch (index) {
        case 0:
          return 'proximas';
        case 1:
          return 'en_curso';
        case 2:
          return 'historial';
        case 3:
          return 'todas';
        default:
          return 'proximas';
      }
    } else {
      switch (index) {
        case 0:
          return 'proximas';
        case 1:
          return 'inscrito';
        case 2:
          return 'historial';
        default:
          return 'proximas';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pichangas'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              context.read<FechasPorRolBloc>().add(const RefrescarFechasEvent());
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: widget.esAdmin,
          tabs: _buildTabs(),
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _buildTabViews(),
      ),
      floatingActionButton: widget.esAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _mostrarDialogCrearFecha(context),
              icon: const Icon(Icons.add),
              label: const Text('Nueva'),
            )
          : null,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  List<Widget> _buildTabs() {
    if (widget.esAdmin) {
      return const [
        Tab(text: 'Proximas'),
        Tab(text: 'En Curso'),
        Tab(text: 'Historial'),
        Tab(text: 'Todas'),
      ];
    } else {
      return const [
        Tab(text: 'Proximas'),
        Tab(text: 'Inscrito'),
        Tab(text: 'Historial'),
      ];
    }
  }

  List<Widget> _buildTabViews() {
    if (widget.esAdmin) {
      return [
        _FechasTabContent(seccion: 'proximas', esAdmin: true),
        _FechasTabContent(seccion: 'en_curso', esAdmin: true),
        _FechasTabContent(seccion: 'historial', esAdmin: true),
        _FechasTabContent(seccion: 'todas', esAdmin: true, mostrarFiltros: true),
      ];
    } else {
      return [
        _FechasTabContent(seccion: 'proximas', esAdmin: false),
        _FechasTabContent(seccion: 'inscrito', esAdmin: false),
        _FechasTabContent(seccion: 'historial', esAdmin: false),
      ];
    }
  }
}

// ============================================
// VISTA DESKTOP - CRM Style con Panel Lateral (sin Tabs arriba)
// Layout: Panel Filtros con Secciones (320px) | Contenido
// ============================================

class _DesktopFechasView extends StatefulWidget {
  final bool esAdmin;

  const _DesktopFechasView({required this.esAdmin});

  @override
  State<_DesktopFechasView> createState() => _DesktopFechasViewState();
}

class _DesktopFechasViewState extends State<_DesktopFechasView> {
  // Filtros locales
  String? _estadoSeleccionado;
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  void _onCambiarEstado(String? estado) {
    setState(() => _estadoSeleccionado = estado);
  }

  void _onCambiarFechaDesde(DateTime? fecha) {
    setState(() => _fechaDesde = fecha);
  }

  void _onCambiarFechaHasta(DateTime? fecha) {
    setState(() => _fechaHasta = fecha);
  }

  void _aplicarFiltros() {
    context.read<FechasPorRolBloc>().add(AplicarFiltrosEvent(
          filtroEstado: _estadoSeleccionado,
          fechaDesde: _fechaDesde,
          fechaHasta: _fechaHasta,
        ));
  }

  void _limpiarFiltros() {
    setState(() {
      _estadoSeleccionado = null;
      _fechaDesde = null;
      _fechaHasta = null;
    });
    context.read<FechasPorRolBloc>().add(const LimpiarFiltrosEvent());
  }

  bool get _hayFiltrosActivos =>
      _estadoSeleccionado != null ||
      _fechaDesde != null ||
      _fechaHasta != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DashboardShell(
      currentRoute: '/fechas',
      title: 'Pichangas',
      breadcrumbs: const ['Inicio', 'Fechas'],
      actions: [
        IconButton(
          onPressed: () {
            context.read<FechasPorRolBloc>().add(const RefrescarFechasEvent());
          },
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar lista',
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel de filtros lateral (320px fijo) - CON SECCIONES
          SizedBox(
            width: 320,
            child: BlocBuilder<FechasPorRolBloc, FechasPorRolState>(
              builder: (context, state) {
                final seccionActual =
                    context.read<FechasPorRolBloc>().seccionActual;
                return _FilterPanel(
                  esAdmin: widget.esAdmin,
                  state: state,
                  seccionActual: seccionActual,
                  onCambiarSeccion: (seccion) {
                    context
                        .read<FechasPorRolBloc>()
                        .add(CambiarSeccionEvent(seccion: seccion));
                  },
                  estadoSeleccionado: _estadoSeleccionado,
                  fechaDesde: _fechaDesde,
                  fechaHasta: _fechaHasta,
                  hayFiltrosActivos: _hayFiltrosActivos,
                  onCambiarEstado: _onCambiarEstado,
                  onCambiarFechaDesde: _onCambiarFechaDesde,
                  onCambiarFechaHasta: _onCambiarFechaHasta,
                  onAplicarFiltros: _aplicarFiltros,
                  onLimpiarFiltros: _limpiarFiltros,
                  onCrearFecha: () => _mostrarDialogCrearFecha(context),
                );
              },
            ),
          ),

          // Separador vertical
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant,
          ),

          // Contenido principal (muestra seccion actual)
          Expanded(
            child: BlocBuilder<FechasPorRolBloc, FechasPorRolState>(
              builder: (context, state) {
                final seccionActual =
                    context.read<FechasPorRolBloc>().seccionActual;
                return _FechasTabContentDesktop(
                  seccion: seccionActual,
                  esAdmin: widget.esAdmin,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// PANEL DE FILTROS LATERAL (320px) - SIEMPRE VISIBLE
// ============================================

class _FilterPanel extends StatelessWidget {
  final bool esAdmin;
  final FechasPorRolState state;
  final String seccionActual;
  final void Function(String) onCambiarSeccion;
  final String? estadoSeleccionado;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;
  final bool hayFiltrosActivos;
  final void Function(String?) onCambiarEstado;
  final void Function(DateTime?) onCambiarFechaDesde;
  final void Function(DateTime?) onCambiarFechaHasta;
  final VoidCallback onAplicarFiltros;
  final VoidCallback onLimpiarFiltros;
  final VoidCallback onCrearFecha;

  const _FilterPanel({
    required this.esAdmin,
    required this.state,
    required this.seccionActual,
    required this.onCambiarSeccion,
    required this.estadoSeleccionado,
    required this.fechaDesde,
    required this.fechaHasta,
    required this.hayFiltrosActivos,
    required this.onCambiarEstado,
    required this.onCambiarFechaDesde,
    required this.onCambiarFechaHasta,
    required this.onAplicarFiltros,
    required this.onLimpiarFiltros,
    required this.onCrearFecha,
  });

  final List<String> _estados = const [
    'abierta',
    'cerrada',
    'en_juego',
    'finalizada',
    'cancelada',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calcular metricas
    final metricas = _calcularMetricas();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del panel
          Text(
            'Lista de Pichangas',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Text(
            'Consulta las fechas programadas',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: DesignTokens.spacingL),

          // Boton crear nueva fecha (solo admin)
          if (esAdmin) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCrearFecha,
                icon: const Icon(Icons.add),
                label: const Text('Nueva Fecha'),
              ),
            ),
            const SizedBox(height: DesignTokens.spacingL),
          ],

          // Card de resumen con metricas
          AppCard(
            variant: AppCardVariant.outlined,
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: DesignTokens.iconSizeS,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Text(
                      'RESUMEN',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingM),

                // Metricas en grid 2x2
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Total',
                        value: metricas['total'] ?? 0,
                        icon: Icons.calendar_month,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: _MetricTile(
                        label: 'Abiertas',
                        value: metricas['abiertas'] ?? 0,
                        icon: Icons.event_available,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingS),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'En Curso',
                        value: metricas['en_curso'] ?? 0,
                        icon: Icons.sports_soccer,
                        color: const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: _MetricTile(
                        label: 'Finalizadas',
                        value: metricas['finalizadas'] ?? 0,
                        icon: Icons.check_circle,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.spacingL),

          // Seccion SECCION (selector de tabs)
          Text(
            'SECCION',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: DesignTokens.fontWeightSemiBold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),

          // Opciones de seccion como lista seleccionable
          _SeccionSelector(
            esAdmin: esAdmin,
            seccionActual: seccionActual,
            onCambiarSeccion: onCambiarSeccion,
          ),

          const SizedBox(height: DesignTokens.spacingL),

          // Seccion FILTROS
          Text(
            'FILTROS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: DesignTokens.fontWeightSemiBold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),

          // Filtro por estado
          Text(
            'Estado',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          DropdownButtonFormField<String>(
            value: estadoSeleccionado,
            decoration: const InputDecoration(
              hintText: 'Todos los estados',
              prefixIcon: Icon(Icons.filter_list),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Todos los estados'),
              ),
              ..._estados.map((e) => DropdownMenuItem(
                    value: e,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getColorEstado(e),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spacingS),
                        Text(_formatEstado(e)),
                      ],
                    ),
                  )),
            ],
            onChanged: onCambiarEstado,
          ),

          const SizedBox(height: DesignTokens.spacingM),

          // Filtro por rango de fechas
          Text(
            'Rango de fechas',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),

          // Fecha desde
          _DatePickerField(
            label: 'Desde',
            value: fechaDesde,
            onChanged: onCambiarFechaDesde,
          ),
          const SizedBox(height: DesignTokens.spacingS),

          // Fecha hasta
          _DatePickerField(
            label: 'Hasta',
            value: fechaHasta,
            onChanged: onCambiarFechaHasta,
          ),

          const SizedBox(height: DesignTokens.spacingL),

          // Botones de accion
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAplicarFiltros,
              icon: const Icon(Icons.filter_alt),
              label: const Text('Aplicar Filtros'),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          if (hayFiltrosActivos)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLimpiarFiltros,
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar Filtros'),
              ),
            ),

          const SizedBox(height: DesignTokens.spacingL),

          // Leyenda de estados
          Text(
            'LEYENDA',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: DesignTokens.fontWeightSemiBold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          _EstadoLegend(),
        ],
      ),
    );
  }

  Map<String, int> _calcularMetricas() {
    if (state is FechasPorRolLoaded) {
      final fechas = (state as FechasPorRolLoaded).fechas;
      return {
        'total': fechas.length,
        'abiertas':
            fechas.where((f) => f.estado == EstadoFecha.abierta).length,
        'en_curso': fechas
            .where((f) =>
                f.estado == EstadoFecha.enJuego ||
                f.estado == EstadoFecha.cerrada)
            .length,
        'finalizadas':
            fechas.where((f) => f.estado == EstadoFecha.finalizada).length,
      };
    }
    if (state is FechasPorRolRefreshing) {
      final fechas = (state as FechasPorRolRefreshing).fechasActuales;
      return {
        'total': fechas.length,
        'abiertas':
            fechas.where((f) => f.estado == EstadoFecha.abierta).length,
        'en_curso': fechas
            .where((f) =>
                f.estado == EstadoFecha.enJuego ||
                f.estado == EstadoFecha.cerrada)
            .length,
        'finalizadas':
            fechas.where((f) => f.estado == EstadoFecha.finalizada).length,
      };
    }
    return {'total': 0, 'abiertas': 0, 'en_curso': 0, 'finalizadas': 0};
  }

  String _formatEstado(String estado) {
    switch (estado) {
      case 'abierta':
        return 'Abierta';
      case 'cerrada':
        return 'Cerrada';
      case 'en_juego':
        return 'En juego';
      case 'finalizada':
        return 'Finalizada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return estado;
    }
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'abierta':
        return const Color(0xFF4CAF50);
      case 'cerrada':
        return const Color(0xFFFFC107);
      case 'en_juego':
        return const Color(0xFF2196F3);
      case 'finalizada':
        return const Color(0xFF9E9E9E);
      case 'cancelada':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}

// ============================================
// CONTENIDO DE TAB - MOBILE
// ============================================

class _FechasTabContent extends StatelessWidget {
  final String seccion;
  final bool esAdmin;
  final bool mostrarFiltros;

  const _FechasTabContent({
    required this.seccion,
    required this.esAdmin,
    this.mostrarFiltros = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FechasPorRolBloc, FechasPorRolState>(
      builder: (context, state) {
        // Obtener datos segun estado
        final fechas = _obtenerFechas(state);
        final isLoading =
            state is FechasPorRolLoading || state is FechasPorRolRefreshing;
        final isEmpty = state is FechasPorRolEmpty;
        final hasError = state is FechasPorRolError;
        final errorMessage = hasError ? state.message : null;

        return _buildContent(
          context,
          fechas: fechas,
          isLoading: isLoading,
          isEmpty: isEmpty,
          hasError: hasError,
          errorMessage: errorMessage,
        );
      },
    );
  }

  List<FechaPorRolModel> _obtenerFechas(FechasPorRolState state) {
    if (state is FechasPorRolLoaded) return state.fechas;
    if (state is FechasPorRolRefreshing) return state.fechasActuales;
    if (state is FechasPorRolError && state.fechasAnteriores != null) {
      return state.fechasAnteriores!;
    }
    return [];
  }

  Widget _buildContent(
    BuildContext context, {
    required List<FechaPorRolModel> fechas,
    required bool isLoading,
    required bool isEmpty,
    required bool hasError,
    String? errorMessage,
  }) {
    // Estado de carga inicial
    if (isLoading && fechas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de error
    if (hasError && fechas.isEmpty) {
      return _buildErrorContent(context, errorMessage);
    }

    // Estado vacio
    if (isEmpty || fechas.isEmpty) {
      return _buildEmptyContent(context);
    }

    // Lista con datos
    return RefreshIndicator(
      onRefresh: () async {
        context.read<FechasPorRolBloc>().add(const RefrescarFechasEvent());
      },
      child: Stack(
        children: [
          Column(
            children: [
              // Filtros para admin en tab "Todas"
              if (mostrarFiltros) _FiltrosPanel(esAdmin: esAdmin),

              // Lista de fechas
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(DesignTokens.spacingM),
                  itemCount: fechas.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: DesignTokens.spacingM),
                  itemBuilder: (context, index) {
                    final fecha = fechas[index];
                    return _FechaPorRolCard(
                      fecha: fecha,
                      compacta: true,
                      onTap: () => context.push('/fechas/${fecha.id}'),
                      esAdmin: esAdmin,
                      onRefresh: () {
                        context
                            .read<FechasPorRolBloc>()
                            .add(const RefrescarFechasEvent());
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          if (isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, String? errorMessage) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              errorMessage ?? 'Error al cargar fechas',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingL),
            FilledButton.icon(
              onPressed: () {
                context
                    .read<FechasPorRolBloc>()
                    .add(CargarFechasPorRolEvent(seccion: seccion));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (icon, titulo, descripcion) = _getMensajeVacio();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingL),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              ),
              child: Icon(
                icon,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingL),
            Text(
              titulo,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingS),
            Text(
              descripcion,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingL),
            OutlinedButton.icon(
              onPressed: () {
                context
                    .read<FechasPorRolBloc>()
                    .add(const RefrescarFechasEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, String, String) _getMensajeVacio() {
    switch (seccion) {
      case 'proximas':
        return (
          Icons.event_available,
          'No hay pichangas proximas',
          'Aun no se ha programado ninguna fecha.\nVuelve a revisar mas tarde.'
        );
      case 'inscrito':
        return (
          Icons.sports_soccer,
          'No estas inscrito en ninguna fecha',
          'Inscribete en una pichanga proxima\npara verla aqui.'
        );
      case 'en_curso':
        return (
          Icons.sports_soccer,
          'No hay fechas en curso',
          'Las fechas cerradas o en juego\naparecen aqui.'
        );
      case 'historial':
        return (
          Icons.history,
          'No hay historial',
          'Tus pichangas finalizadas\naparecen aqui.'
        );
      case 'todas':
        return (
          Icons.list_alt,
          'No hay fechas registradas',
          'Crea una nueva fecha para comenzar.'
        );
      default:
        return (
          Icons.calendar_month_outlined,
          'No hay fechas disponibles',
          'Vuelve a revisar mas tarde.'
        );
    }
  }
}

// ============================================
// CONTENIDO DE TAB - DESKTOP (Solo tabla, sin panel lateral)
// ============================================

class _FechasTabContentDesktop extends StatelessWidget {
  final String seccion;
  final bool esAdmin;

  const _FechasTabContentDesktop({
    required this.seccion,
    required this.esAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FechasPorRolBloc, FechasPorRolState>(
      builder: (context, state) {
        final fechas = _obtenerFechas(state);
        final isLoading =
            state is FechasPorRolLoading || state is FechasPorRolRefreshing;
        final isEmpty = state is FechasPorRolEmpty;
        final hasError = state is FechasPorRolError;
        final errorMessage = hasError ? state.message : null;

        // Solo la tabla, el panel de filtros esta siempre visible a la izquierda
        return _DataTablePanel(
          fechas: fechas,
          isLoading: isLoading,
          isEmpty: isEmpty,
          hasError: hasError,
          errorMessage: errorMessage,
          seccion: seccion,
          esAdmin: esAdmin,
        );
      },
    );
  }

  List<FechaPorRolModel> _obtenerFechas(FechasPorRolState state) {
    if (state is FechasPorRolLoaded) return state.fechas;
    if (state is FechasPorRolRefreshing) return state.fechasActuales;
    if (state is FechasPorRolError && state.fechasAnteriores != null) {
      return state.fechasAnteriores!;
    }
    return [];
  }
}

// ============================================
// PANEL DE FILTROS - MOBILE
// ============================================

class _FiltrosPanel extends StatefulWidget {
  final bool esAdmin;

  const _FiltrosPanel({required this.esAdmin});

  @override
  State<_FiltrosPanel> createState() => _FiltrosPanelState();
}

class _FiltrosPanelState extends State<_FiltrosPanel> {
  String? _estadoSeleccionado;
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  final List<String> _estados = [
    'abierta',
    'cerrada',
    'en_juego',
    'finalizada',
    'cancelada',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila de filtros
          Wrap(
            spacing: DesignTokens.spacingS,
            runSpacing: DesignTokens.spacingS,
            children: [
              // Dropdown de estado
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  value: _estadoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingS,
                      vertical: DesignTokens.spacingS,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ..._estados.map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(_formatEstado(e)),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _estadoSeleccionado = value);
                  },
                ),
              ),

              // Boton aplicar filtros
              FilledButton.tonal(
                onPressed: _aplicarFiltros,
                child: const Text('Filtrar'),
              ),

              // Boton limpiar filtros
              if (_hayFiltrosActivos)
                TextButton(
                  onPressed: _limpiarFiltros,
                  child: const Text('Limpiar'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _hayFiltrosActivos =>
      _estadoSeleccionado != null ||
      _fechaDesde != null ||
      _fechaHasta != null;

  String _formatEstado(String estado) {
    switch (estado) {
      case 'abierta':
        return 'Abierta';
      case 'cerrada':
        return 'Cerrada';
      case 'en_juego':
        return 'En juego';
      case 'finalizada':
        return 'Finalizada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return estado;
    }
  }

  void _aplicarFiltros() {
    context.read<FechasPorRolBloc>().add(AplicarFiltrosEvent(
          filtroEstado: _estadoSeleccionado,
          fechaDesde: _fechaDesde,
          fechaHasta: _fechaHasta,
        ));
  }

  void _limpiarFiltros() {
    setState(() {
      _estadoSeleccionado = null;
      _fechaDesde = null;
      _fechaHasta = null;
    });
    context.read<FechasPorRolBloc>().add(const LimpiarFiltrosEvent());
  }
}

// ============================================
// DATE PICKER FIELD
// ============================================

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formatoFecha = DateFormat("dd/MM/yyyy", 'es_PE');

    return InkWell(
      onTap: () async {
        final fecha = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('es', 'PE'),
        );
        onChanged(fecha);
      },
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingM,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: DesignTokens.iconSizeS,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                value != null ? formatoFecha.format(value!) : label,
                style: TextStyle(
                  color: value != null
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(
                  Icons.clear,
                  size: DesignTokens.iconSizeS,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// PANEL DE DATOS (Tabla) - DESKTOP
// ============================================

class _DataTablePanel extends StatelessWidget {
  final List<FechaPorRolModel> fechas;
  final bool isLoading;
  final bool isEmpty;
  final bool hasError;
  final String? errorMessage;
  final String seccion;
  final bool esAdmin;

  const _DataTablePanel({
    required this.fechas,
    required this.isLoading,
    required this.isEmpty,
    required this.hasError,
    required this.errorMessage,
    required this.seccion,
    required this.esAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la tabla
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTituloSeccion(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingXxs),
                    Text(
                      _getSubtituloSeccion(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Contador de registros
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingS,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: DesignTokens.iconSizeS,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: DesignTokens.spacingXs),
                    Text(
                      '${fechas.length} fecha${fechas.length != 1 ? 's' : ''}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Contenido de la tabla
        Expanded(
          child: _buildTableContent(context),
        ),
      ],
    );
  }

  String _getTituloSeccion() {
    switch (seccion) {
      case 'proximas':
        return 'Proximas Pichangas';
      case 'inscrito':
        return 'Mis Inscripciones';
      case 'en_curso':
        return 'Fechas en Curso';
      case 'historial':
        return 'Historial de Pichangas';
      case 'todas':
        return 'Todas las Fechas';
      default:
        return 'Fechas';
    }
  }

  String _getSubtituloSeccion() {
    switch (seccion) {
      case 'proximas':
        return 'Fechas abiertas para inscripcion';
      case 'inscrito':
        return 'Fechas donde estas inscrito';
      case 'en_curso':
        return 'Fechas cerradas o en juego';
      case 'historial':
        return 'Pichangas finalizadas';
      case 'todas':
        return 'Administra todas las fechas';
      default:
        return 'Lista de fechas';
    }
  }

  Widget _buildTableContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Estado de carga inicial
    if (isLoading && fechas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error sin datos previos
    if (hasError && fechas.isEmpty) {
      return Center(
        child: EmptyStateWidget.error(
          title: 'Error al cargar fechas',
          description: errorMessage ?? 'Ocurrio un error inesperado',
          actionLabel: 'Reintentar',
          onAction: () {
            context
                .read<FechasPorRolBloc>()
                .add(CargarFechasPorRolEvent(seccion: seccion));
          },
        ),
      );
    }

    // Estado vacio
    if (isEmpty || fechas.isEmpty) {
      final (icon, titulo, descripcion) = _getMensajeVacio();
      return Center(
        child: EmptyStateWidget.noData(
          title: titulo,
          description: descripcion,
          icon: icon,
        ),
      );
    }

    // Tabla con datos
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          child: AppCard(
            variant: AppCardVariant.outlined,
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Ancho minimo para mostrar todas las columnas
                  const double minWidth = 900;
                  // Usar el mayor entre el espacio disponible y el minimo
                  // Esto hace que la tabla sea RESPONSIVA (se expande) pero con scroll si es necesario
                  final tableWidth = constraints.maxWidth > minWidth
                      ? constraints.maxWidth
                      : minWidth;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                        ),
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(label: Text('Fecha/Hora')),
                          DataColumn(label: Text('Lugar')),
                          DataColumn(label: Text('Duracion')),
                          DataColumn(label: Text('Costo')),
                          DataColumn(label: Text('Inscritos')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: fechas.map((fecha) {
                          return DataRow(
                            // Hacer toda la fila clickeable para navegar al detalle
                            onSelectChanged: (_) =>
                                context.push('/fechas/${fecha.id}'),
                            cells: [
                              DataCell(_buildFechaHoraCell(context, fecha)),
                              DataCell(_buildLugarCell(context, fecha)),
                              DataCell(Text('${fecha.duracionHoras}h')),
                              DataCell(_buildCostoCell(context, fecha)),
                              DataCell(_buildInscritosCell(context, fecha)),
                              DataCell(_buildEstadoBadge(context, fecha)),
                              DataCell(_buildAcciones(context, fecha)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  (IconData, String, String) _getMensajeVacio() {
    switch (seccion) {
      case 'proximas':
        return (
          Icons.event_available,
          'No hay pichangas proximas',
          'Aun no se ha programado ninguna fecha'
        );
      case 'inscrito':
        return (
          Icons.sports_soccer,
          'No estas inscrito',
          'Inscribete en una pichanga proxima'
        );
      case 'en_curso':
        return (
          Icons.sports_soccer,
          'No hay fechas en curso',
          'Las fechas cerradas o en juego aparecen aqui'
        );
      case 'historial':
        return (
          Icons.history,
          'No hay historial',
          'Tus pichangas finalizadas aparecen aqui'
        );
      case 'todas':
        return (
          Icons.list_alt,
          'No hay fechas registradas',
          'Crea una nueva fecha para comenzar'
        );
      default:
        return (
          Icons.calendar_month_outlined,
          'No hay fechas disponibles',
          'Vuelve a revisar mas tarde'
        );
    }
  }

  Widget _buildFechaHoraCell(BuildContext context, FechaPorRolModel fecha) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: DesignTokens.iconSizeS - 2,
              color: colorScheme.primary,
            ),
            const SizedBox(width: DesignTokens.spacingXs),
            Text(
              fecha.fechaFormato,
              style: const TextStyle(
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingXxs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time,
              size: DesignTokens.iconSizeS - 2,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: DesignTokens.spacingXs),
            Text(
              fecha.horaFormato,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXs,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLugarCell(BuildContext context, FechaPorRolModel fecha) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: DesignTokens.iconSizeS,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignTokens.spacingXs),
          Flexible(
            child: Text(
              fecha.lugar,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostoCell(BuildContext context, FechaPorRolModel fecha) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      fecha.costoFormato,
      style: TextStyle(
        fontWeight: DesignTokens.fontWeightMedium,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildInscritosCell(BuildContext context, FechaPorRolModel fecha) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.people_outline,
          size: DesignTokens.iconSizeS,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: DesignTokens.spacingXs),
        Text('${fecha.totalInscritos}'),
      ],
    );
  }

  Widget _buildEstadoBadge(BuildContext context, FechaPorRolModel fecha) {
    // Obtener color e icono del indicador
    final color = _hexToColor(fecha.indicador.color);
    final icono = _getIconoDesdeNombre(fecha.indicador.icono);

    // Si el usuario esta inscrito, mostrar badge adicional (apilados verticalmente)
    if (fecha.usuarioInscrito) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingS,
              vertical: DesignTokens.spacingXxs,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  fecha.indicador.texto,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXxs),
          const StatusBadge(
            label: 'Inscrito',
            type: StatusBadgeType.activo,
            size: StatusBadgeSize.small,
            icon: Icons.check_circle,
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            fecha.indicador.texto,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcciones(BuildContext context, FechaPorRolModel fecha) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Boton Ver detalle (siempre visible)
        Tooltip(
          message: 'Ver detalle',
          child: IconButton(
            onPressed: () => context.push('/fechas/${fecha.id}'),
            icon: Icon(
              Icons.visibility_outlined,
              color: colorScheme.primary,
            ),
            iconSize: DesignTokens.iconSizeS + 2,
          ),
        ),
        // Menu de acciones adicionales
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: colorScheme.onSurfaceVariant,
          ),
          tooltip: 'Mas acciones',
          onSelected: (value) => _ejecutarAccion(context, value, fecha),
          itemBuilder: (context) => _buildMenuItems(context, fecha),
        ),
      ],
    );
  }

  /// Construye los items del menu segun el estado y el rol
  List<PopupMenuEntry<String>> _buildMenuItems(
      BuildContext context, FechaPorRolModel fecha) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = <PopupMenuEntry<String>>[];

    // Editar fecha (solo admin y fecha abierta)
    if (esAdmin && fecha.estado == EstadoFecha.abierta) {
      items.add(PopupMenuItem(
        value: 'editar',
        child: Row(
          children: [
            Icon(Icons.edit_outlined, color: DesignTokens.accentColor, size: 20),
            const SizedBox(width: DesignTokens.spacingS),
            const Text('Editar fecha'),
          ],
        ),
      ));
    }

    // Cerrar inscripciones (solo admin y fecha abierta)
    if (esAdmin && fecha.estado == EstadoFecha.abierta) {
      items.add(PopupMenuItem(
        value: 'cerrar_inscripciones',
        child: Row(
          children: [
            Icon(Icons.lock, color: colorScheme.secondary, size: 20),
            const SizedBox(width: DesignTokens.spacingS),
            const Text('Cerrar inscripciones'),
          ],
        ),
      ));
    }

    // Reabrir inscripciones (solo admin y fecha cerrada)
    if (esAdmin && fecha.estado == EstadoFecha.cerrada) {
      items.add(PopupMenuItem(
        value: 'reabrir_inscripciones',
        child: Row(
          children: [
            Icon(Icons.lock_open, color: colorScheme.primary, size: 20),
            const SizedBox(width: DesignTokens.spacingS),
            const Text('Reabrir inscripciones'),
          ],
        ),
      ));
    }

    // Asignar equipos (solo admin y fecha cerrada)
    if (esAdmin && fecha.estado == EstadoFecha.cerrada) {
      items.add(PopupMenuItem(
        value: 'asignar_equipos',
        child: Row(
          children: [
            Icon(Icons.groups, color: colorScheme.primary, size: 20),
            const SizedBox(width: DesignTokens.spacingS),
            const Text('Asignar equipos'),
          ],
        ),
      ));
    }

    // Finalizar fecha (solo admin y fecha cerrada o en_juego)
    if (esAdmin &&
        (fecha.estado == EstadoFecha.cerrada ||
            fecha.estado == EstadoFecha.enJuego)) {
      items.add(PopupMenuItem(
        value: 'finalizar',
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF9E9E9E), size: 20),
            const SizedBox(width: DesignTokens.spacingS),
            const Text('Finalizar pichanga'),
          ],
        ),
      ));
    }

    // Si no hay acciones disponibles, mostrar mensaje
    if (items.isEmpty) {
      items.add(const PopupMenuItem(
        enabled: false,
        child: Text(
          'Sin acciones disponibles',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ));
    }

    return items;
  }

  /// Ejecuta la accion seleccionada del menu
  void _ejecutarAccion(
      BuildContext context, String accion, FechaPorRolModel fecha) {
    switch (accion) {
      case 'editar':
        _mostrarDialogEditar(context, fecha);
        break;
      case 'cerrar_inscripciones':
        _mostrarDialogCerrarInscripciones(context, fecha);
        break;
      case 'reabrir_inscripciones':
        _mostrarDialogReabrirInscripciones(context, fecha);
        break;
      case 'asignar_equipos':
        context.push('/fechas/${fecha.id}/equipos');
        break;
      case 'finalizar':
        _mostrarDialogFinalizar(context, fecha);
        break;
    }
  }

  /// Muestra el dialog para cerrar inscripciones
  void _mostrarDialogCerrarInscripciones(
      BuildContext context, FechaPorRolModel fecha) {
    // Cargamos el detalle de la fecha y luego mostramos el dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider(
        create: (_) => sl<InscripcionBloc>()
          ..add(CargarFechaDetalleEvent(fechaId: fecha.id)),
        child: _CerrarInscripcionesLoaderDialog(
          fechaId: fecha.id,
          onSuccess: () {
            context.read<FechasPorRolBloc>().add(const RefrescarFechasEvent());
          },
        ),
      ),
    );
  }

  /// Muestra el dialog para reabrir inscripciones
  void _mostrarDialogReabrirInscripciones(
      BuildContext context, FechaPorRolModel fecha) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider(
        create: (_) => sl<InscripcionBloc>()
          ..add(CargarFechaDetalleEvent(fechaId: fecha.id)),
        child: _ReabrirInscripcionesLoaderDialog(
          fechaId: fecha.id,
          onSuccess: () {
            context.read<FechasPorRolBloc>().add(const RefrescarFechasEvent());
          },
        ),
      ),
    );
  }

  /// Muestra el dialog para finalizar fecha
  void _mostrarDialogFinalizar(BuildContext context, FechaPorRolModel fecha) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider(
        create: (_) => sl<InscripcionBloc>()
          ..add(CargarFechaDetalleEvent(fechaId: fecha.id)),
        child: _FinalizarFechaLoaderDialog(
          fechaId: fecha.id,
          onSuccess: () {
            context.read<FechasPorRolBloc>().add(const RefrescarFechasEvent());
          },
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  IconData _getIconoDesdeNombre(String nombre) {
    switch (nombre) {
      case 'group':
        return Icons.group;
      case 'lock':
        return Icons.lock;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'check_circle':
        return Icons.check_circle;
      case 'cancel':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  void _mostrarDialogEditar(BuildContext context, FechaPorRolModel fecha) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider(
        create: (_) => sl<InscripcionBloc>()
          ..add(CargarFechaDetalleEvent(fechaId: fecha.id)),
        child: _EditarFechaLoaderDialog(
          fechaId: fecha.id,
          onSuccess: () {
            context.read<FechasPorRolBloc>().add(const RefrescarFechasEvent());
          },
        ),
      ),
    );
  }
}

// ============================================
// CARD DE FECHA POR ROL - MOBILE
// ============================================

class _FechaPorRolCard extends StatelessWidget {
  final FechaPorRolModel fecha;
  final bool compacta;
  final VoidCallback? onTap;
  final bool esAdmin;
  final VoidCallback? onRefresh;

  const _FechaPorRolCard({
    required this.fecha,
    this.compacta = false,
    this.onTap,
    this.esAdmin = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Obtener color del indicador
    final indicadorColor = _hexToColor(fecha.indicador.color);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(
          color: fecha.usuarioInscrito
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: fecha.usuarioInscrito ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Fecha y estado
              Row(
                children: [
                  // Icono con color de estado
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spacingS),
                    decoration: BoxDecoration(
                      color: indicadorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: Icon(
                      _getIconoDesdeNombre(fecha.indicador.icono),
                      size: DesignTokens.iconSizeS,
                      color: indicadorColor,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingS),

                  // Fecha y hora
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fecha.fechaFormato,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: DesignTokens.fontWeightSemiBold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${fecha.horaFormato} - ${fecha.duracionHoras}h',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge de estado
                  _buildEstadoBadge(context, indicadorColor),

                  // Menu de acciones (solo si es admin)
                  if (esAdmin) _buildMenuAcciones(context, colorScheme),
                ],
              ),

              const SizedBox(height: DesignTokens.spacingM),

              // Info: lugar, costo, inscritos
              Row(
                children: [
                  // Lugar
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: DesignTokens.iconSizeS,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: DesignTokens.spacingXs),
                        Expanded(
                          child: Text(
                            fecha.lugar,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: DesignTokens.spacingM),

                  // Costo
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: DesignTokens.iconSizeS,
                        color: colorScheme.primary,
                      ),
                      Text(
                        fecha.costoFormato,
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: DesignTokens.fontWeightMedium,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: DesignTokens.spacingM),

                  // Inscritos
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: DesignTokens.iconSizeS,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: DesignTokens.spacingXxs),
                      Text(
                        '${fecha.totalInscritos}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Equipo asignado (si aplica)
              if (fecha.usuarioInscrito && fecha.equipoAsignado != null) ...[
                const SizedBox(height: DesignTokens.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: _getColorEquipo(fecha.equipoAsignado!)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getColorEquipo(fecha.equipoAsignado!),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingXs),
                      Text(
                        'Equipo ${fecha.equipoAsignado}',
                        style: textTheme.labelSmall?.copyWith(
                          color: _getColorEquipo(fecha.equipoAsignado!),
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(BuildContext context, Color indicadorColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Si el usuario esta inscrito, mostrar badge "Inscrito"
    if (fecha.usuarioInscrito) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingS,
          vertical: DesignTokens.spacingXs,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: DesignTokens.iconSizeS,
              color: colorScheme.primary,
            ),
            const SizedBox(width: DesignTokens.spacingXxs),
            Text(
              'Inscrito',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ],
        ),
      );
    }

    // Mostrar estado de la fecha
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXs,
      ),
      decoration: BoxDecoration(
        color: indicadorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Text(
        fecha.indicador.texto,
        style: textTheme.labelSmall?.copyWith(
          color: indicadorColor,
          fontWeight: DesignTokens.fontWeightMedium,
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  IconData _getIconoDesdeNombre(String nombre) {
    switch (nombre) {
      case 'group':
        return Icons.group;
      case 'lock':
        return Icons.lock;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'check_circle':
        return Icons.check_circle;
      case 'cancel':
        return Icons.cancel;
      default:
        return Icons.calendar_today;
    }
  }

  Color _getColorEquipo(String equipo) {
    switch (equipo.toLowerCase()) {
      case 'azul':
        return const Color(0xFF2196F3);
      case 'rojo':
        return const Color(0xFFF44336);
      case 'amarillo':
        return const Color(0xFFFFC107);
      case 'verde':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  /// Menu de acciones contextual para administradores (Mobile)
  Widget _buildMenuAcciones(BuildContext context, ColorScheme colorScheme) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.onSurfaceVariant,
        size: DesignTokens.iconSizeM,
      ),
      padding: EdgeInsets.zero,
      tooltip: 'Acciones',
      onSelected: (value) => _ejecutarAccion(context, value),
      itemBuilder: (context) => _buildMenuItems(context),
    );
  }

  /// Construye los items del menu segun el estado de la fecha
  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = <PopupMenuEntry<String>>[];

    // Editar fecha (solo fecha abierta)
    if (fecha.estado == EstadoFecha.abierta) {
      items.add(PopupMenuItem(
        value: 'editar',
        child: Row(
          children: [
            Icon(Icons.edit_outlined, color: DesignTokens.accentColor, size: 20),
            const SizedBox(width: DesignTokens.spacingS),
            const Text('Editar'),
          ],
        ),
      ));
    }

    // Cerrar inscripciones (solo fecha abierta)
    if (fecha.estado == EstadoFecha.abierta) {
      items.add(PopupMenuItem(
        value: 'cerrar_inscripciones',
        child: Row(
          children: [
            Icon(Icons.lock, color: colorScheme.secondary, size: 20),
            const SizedBox(width: DesignTokens.spacingS),
            const Text('Cerrar inscripciones'),
          ],
        ),
      ));
    }

    // Reabrir inscripciones (solo fecha cerrada)
    if (fecha.estado == EstadoFecha.cerrada) {
      items.add(PopupMenuItem(
        value: 'reabrir_inscripciones',
        child: Row(
          children: [
            Icon(Icons.lock_open, color: colorScheme.primary, size: 20),
            const SizedBox(width: DesignTokens.spacingS),
            const Text('Reabrir inscripciones'),
          ],
        ),
      ));
    }

    // Asignar equipos (solo fecha cerrada)
    if (fecha.estado == EstadoFecha.cerrada) {
      items.add(PopupMenuItem(
        value: 'asignar_equipos',
        child: Row(
          children: [
            Icon(Icons.groups, color: colorScheme.primary, size: 20),
            const SizedBox(width: DesignTokens.spacingS),
            const Text('Asignar equipos'),
          ],
        ),
      ));
    }

    // Finalizar fecha (fecha cerrada o en_juego)
    if (fecha.estado == EstadoFecha.cerrada ||
        fecha.estado == EstadoFecha.enJuego) {
      items.add(PopupMenuItem(
        value: 'finalizar',
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF9E9E9E), size: 20),
            const SizedBox(width: DesignTokens.spacingS),
            const Text('Finalizar'),
          ],
        ),
      ));
    }

    // Si no hay acciones disponibles
    if (items.isEmpty) {
      items.add(const PopupMenuItem(
        enabled: false,
        child: Text(
          'Sin acciones',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ));
    }

    return items;
  }

  /// Ejecuta la accion seleccionada del menu
  void _ejecutarAccion(BuildContext context, String accion) {
    switch (accion) {
      case 'editar':
        _mostrarDialogEditar(context);
        break;
      case 'cerrar_inscripciones':
        _mostrarDialogCerrarInscripciones(context);
        break;
      case 'reabrir_inscripciones':
        _mostrarDialogReabrirInscripciones(context);
        break;
      case 'asignar_equipos':
        context.push('/fechas/${fecha.id}/equipos');
        break;
      case 'finalizar':
        _mostrarDialogFinalizar(context);
        break;
    }
  }

  void _mostrarDialogEditar(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider(
        create: (_) => sl<InscripcionBloc>()
          ..add(CargarFechaDetalleEvent(fechaId: fecha.id)),
        child: _EditarFechaLoaderDialogGeneric(
          fechaId: fecha.id,
          onSuccess: onRefresh,
        ),
      ),
    );
  }

  void _mostrarDialogCerrarInscripciones(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider(
        create: (_) => sl<InscripcionBloc>()
          ..add(CargarFechaDetalleEvent(fechaId: fecha.id)),
        child: _CerrarInscripcionesLoaderDialogGeneric(
          fechaId: fecha.id,
          onSuccess: onRefresh,
        ),
      ),
    );
  }

  void _mostrarDialogReabrirInscripciones(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider(
        create: (_) => sl<InscripcionBloc>()
          ..add(CargarFechaDetalleEvent(fechaId: fecha.id)),
        child: _ReabrirInscripcionesLoaderDialogGeneric(
          fechaId: fecha.id,
          onSuccess: onRefresh,
        ),
      ),
    );
  }

  void _mostrarDialogFinalizar(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider(
        create: (_) => sl<InscripcionBloc>()
          ..add(CargarFechaDetalleEvent(fechaId: fecha.id)),
        child: _FinalizarFechaLoaderDialogGeneric(
          fechaId: fecha.id,
          onSuccess: onRefresh,
        ),
      ),
    );
  }
}

// ============================================
// WIDGETS AUXILIARES
// ============================================

/// Tile de metrica para el panel de filtros
class _MetricTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: DesignTokens.iconSizeS, color: color),
              const Spacer(),
              Text(
                value.toString(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingXxs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Leyenda de estados
class _EstadoLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _EstadoLegendItem(
          icon: Icons.group,
          label: 'Abierta',
          description: 'Inscripciones abiertas',
          color: Color(0xFF4CAF50),
        ),
        SizedBox(height: DesignTokens.spacingS),
        _EstadoLegendItem(
          icon: Icons.lock,
          label: 'Cerrada',
          description: 'Inscripciones cerradas',
          color: Color(0xFFFFC107),
        ),
        SizedBox(height: DesignTokens.spacingS),
        _EstadoLegendItem(
          icon: Icons.sports_soccer,
          label: 'En juego',
          description: 'Partido en curso',
          color: Color(0xFF2196F3),
        ),
        SizedBox(height: DesignTokens.spacingS),
        _EstadoLegendItem(
          icon: Icons.check_circle,
          label: 'Finalizada',
          description: 'Partido terminado',
          color: Color(0xFF9E9E9E),
        ),
        SizedBox(height: DesignTokens.spacingS),
        _EstadoLegendItem(
          icon: Icons.cancel,
          label: 'Cancelada',
          description: 'Fecha cancelada',
          color: Color(0xFFF44336),
        ),
      ],
    );
  }
}

class _EstadoLegendItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  const _EstadoLegendItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Icon(icon, size: DesignTokens.iconSizeS, color: color),
        const SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================
// SELECTOR DE SECCION (para panel lateral desktop)
// ============================================

class _SeccionSelector extends StatelessWidget {
  final bool esAdmin;
  final String seccionActual;
  final void Function(String) onCambiarSeccion;

  const _SeccionSelector({
    required this.esAdmin,
    required this.seccionActual,
    required this.onCambiarSeccion,
  });

  @override
  Widget build(BuildContext context) {
    final secciones = esAdmin
        ? [
            _SeccionOption(
              id: 'proximas',
              label: 'Proximas',
              icon: Icons.event_available,
              descripcion: 'Fechas abiertas',
            ),
            _SeccionOption(
              id: 'en_curso',
              label: 'En Curso',
              icon: Icons.sports_soccer,
              descripcion: 'Fechas cerradas o en juego',
            ),
            _SeccionOption(
              id: 'historial',
              label: 'Historial',
              icon: Icons.history,
              descripcion: 'Fechas finalizadas',
            ),
            _SeccionOption(
              id: 'todas',
              label: 'Todas',
              icon: Icons.list_alt,
              descripcion: 'Todas las fechas',
            ),
          ]
        : [
            _SeccionOption(
              id: 'proximas',
              label: 'Proximas',
              icon: Icons.event_available,
              descripcion: 'Fechas disponibles',
            ),
            _SeccionOption(
              id: 'inscrito',
              label: 'Inscrito',
              icon: Icons.check_circle,
              descripcion: 'Mis inscripciones',
            ),
            _SeccionOption(
              id: 'historial',
              label: 'Historial',
              icon: Icons.history,
              descripcion: 'Fechas finalizadas',
            ),
          ];

    return Column(
      children: secciones.map((seccion) {
        final isSelected = seccionActual == seccion.id;
        return _SeccionTile(
          seccion: seccion,
          isSelected: isSelected,
          onTap: () => onCambiarSeccion(seccion.id),
        );
      }).toList(),
    );
  }
}

class _SeccionOption {
  final String id;
  final String label;
  final IconData icon;
  final String descripcion;

  _SeccionOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.descripcion,
  });
}

class _SeccionTile extends StatelessWidget {
  final _SeccionOption seccion;
  final bool isSelected;
  final VoidCallback onTap;

  const _SeccionTile({
    required this.seccion,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingXs),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: isSelected
                  ? Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.5),
                      width: 1.5,
                    )
                  : Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
            ),
            child: Row(
              children: [
                // Radio indicator
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primary,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: DesignTokens.spacingM),
                // Icon
                Icon(
                  seccion.icon,
                  size: DesignTokens.iconSizeS,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: DesignTokens.spacingS),
                // Label y descripcion
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seccion.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected
                              ? DesignTokens.fontWeightSemiBold
                              : DesignTokens.fontWeightMedium,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        seccion.descripcion,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
}

// ============================================
// DIALOG PARA CREAR FECHA
// ============================================

/// Muestra el dialog modal para crear una nueva fecha
void _mostrarDialogCrearFecha(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => BlocProvider(
      create: (_) => sl<CrearFechaBloc>(),
      child: _CrearFechaDialog(
        onFechaCreada: () {
          context.read<FechasPorRolBloc>().add(const RefrescarFechasEvent());
        },
      ),
    ),
  );
}

/// Dialog modal para crear una nueva fecha de pichanga
class _CrearFechaDialog extends StatefulWidget {
  final VoidCallback onFechaCreada;

  const _CrearFechaDialog({
    required this.onFechaCreada,
  });

  @override
  State<_CrearFechaDialog> createState() => _CrearFechaDialogState();
}

class _CrearFechaDialogState extends State<_CrearFechaDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _lugarController;
  late TextEditingController _costoController;

  DateTime _fechaSeleccionada = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _horaSeleccionada = const TimeOfDay(hour: 20, minute: 0);
  int _duracionHoras = 2;
  int _numEquipos = 2;

  @override
  void initState() {
    super.initState();
    _lugarController = TextEditingController();
    _costoController = TextEditingController(text: '8.00');
  }

  @override
  void dispose() {
    _lugarController.dispose();
    _costoController.dispose();
    super.dispose();
  }

  DateTime get _fechaHoraInicio {
    return DateTime(
      _fechaSeleccionada.year,
      _fechaSeleccionada.month,
      _fechaSeleccionada.day,
      _horaSeleccionada.hour,
      _horaSeleccionada.minute,
    );
  }

  bool get _esFechaFutura {
    return _fechaHoraInicio.isAfter(DateTime.now());
  }

  double get _costoPorJugador {
    return double.tryParse(_costoController.text) ?? 8.00;
  }

  String get _fechaFormateada {
    final meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return '${_fechaSeleccionada.day} de ${meses[_fechaSeleccionada.month - 1]} de ${_fechaSeleccionada.year}';
  }

  String get _horaFormateada {
    return '${_horaSeleccionada.hour.toString().padLeft(2, '0')}:${_horaSeleccionada.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'PE'),
    );
    if (fecha != null) {
      setState(() => _fechaSeleccionada = fecha);
    }
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (hora != null) {
      setState(() => _horaSeleccionada = hora);
    }
  }

  bool get _formularioValido {
    final lugar = _lugarController.text.trim();
    final costo = double.tryParse(_costoController.text) ?? 0;
    return _esFechaFutura && lugar.length >= 3 && costo > 0;
  }

  void _crearFecha() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_esFechaFutura) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La fecha y hora deben ser futuras'),
            backgroundColor: DesignTokens.errorColor,
          ),
        );
        return;
      }

      context.read<CrearFechaBloc>().add(CrearFechaSubmitEvent(
            fechaHoraInicio: _fechaHoraInicio,
            duracionHoras: _duracionHoras,
            lugar: _lugarController.text.trim(),
            numEquipos: _numEquipos,
            costoPorJugador: _costoPorJugador,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<CrearFechaBloc, CrearFechaState>(
      listener: (context, state) {
        if (state is CrearFechaSuccess) {
          Navigator.of(context).pop();
          widget.onFechaCreada();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: DesignTokens.successColor,
            ),
          );
        }

        if (state is CrearFechaError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: DesignTokens.errorColor,
            ),
          );
        }
      },
      child: BlocBuilder<CrearFechaBloc, CrearFechaState>(
        builder: (context, state) {
          final isLoading = state is CrearFechaLoading;

          return Dialog(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spacingM),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sports_soccer, color: colorScheme.primary),
                        const SizedBox(width: DesignTokens.spacingS),
                        Expanded(
                          child: Text(
                            'Nueva Fecha',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: DesignTokens.fontWeightSemiBold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed:
                              isLoading ? null : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          tooltip: 'Cerrar',
                        ),
                      ],
                    ),
                  ),

                  // Contenido
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(DesignTokens.spacingL),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Fecha *', colorScheme),
                            const SizedBox(height: DesignTokens.spacingS),
                            _buildSelectorField(
                              icon: Icons.calendar_today,
                              value: _fechaFormateada,
                              onTap: _seleccionarFecha,
                              hasError: !_esFechaFutura,
                              colorScheme: colorScheme,
                            ),
                            if (!_esFechaFutura) ...[
                              const SizedBox(height: DesignTokens.spacingXs),
                              Text(
                                'La fecha debe ser futura',
                                style: TextStyle(
                                  fontSize: DesignTokens.fontSizeS,
                                  color: colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: DesignTokens.spacingM),

                            _buildLabel('Hora de inicio *', colorScheme),
                            const SizedBox(height: DesignTokens.spacingS),
                            _buildSelectorField(
                              icon: Icons.access_time,
                              value: _horaFormateada,
                              onTap: _seleccionarHora,
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: DesignTokens.spacingM),

                            _buildLabel('Duracion *', colorScheme),
                            const SizedBox(height: DesignTokens.spacingS),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<int>(
                                segments: const [
                                  ButtonSegment(
                                    value: 1,
                                    label: Text('1 hora'),
                                    icon: Icon(Icons.timer),
                                  ),
                                  ButtonSegment(
                                    value: 2,
                                    label: Text('2 horas'),
                                    icon: Icon(Icons.timer),
                                  ),
                                ],
                                selected: {_duracionHoras},
                                onSelectionChanged: (values) {
                                  setState(() => _duracionHoras = values.first);
                                },
                              ),
                            ),
                            const SizedBox(height: DesignTokens.spacingM),

                            _buildLabel('Cantidad de equipos *', colorScheme),
                            const SizedBox(height: DesignTokens.spacingS),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<int>(
                                segments: const [
                                  ButtonSegment(
                                    value: 2,
                                    label: Text('2'),
                                    icon: Icon(Icons.group),
                                  ),
                                  ButtonSegment(
                                    value: 3,
                                    label: Text('3'),
                                    icon: Icon(Icons.groups),
                                  ),
                                  ButtonSegment(
                                    value: 4,
                                    label: Text('4'),
                                    icon: Icon(Icons.groups),
                                  ),
                                ],
                                selected: {_numEquipos},
                                onSelectionChanged: (values) {
                                  setState(() => _numEquipos = values.first);
                                },
                              ),
                            ),
                            const SizedBox(height: DesignTokens.spacingM),

                            TextFormField(
                              controller: _costoController,
                              decoration: const InputDecoration(
                                labelText: 'Costo por jugador (S/) *',
                                hintText: 'Ej: 8.00',
                                prefixIcon: Icon(Icons.attach_money),
                                helperText: 'Monto que pagara cada jugador',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              validator: (value) {
                                final costo = double.tryParse(value ?? '');
                                if (costo == null || costo <= 0) {
                                  return 'Ingrese un monto valido mayor a 0';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: DesignTokens.spacingM),

                            TextFormField(
                              controller: _lugarController,
                              decoration: const InputDecoration(
                                labelText: 'Lugar de la cancha *',
                                hintText: 'Ej: Cancha Los Olivos, Av. Principal 123',
                                prefixIcon: Icon(Icons.location_on),
                                helperText: 'Minimo 3 caracteres',
                              ),
                              maxLength: 200,
                              validator: (value) {
                                final trimmed = value?.trim() ?? '';
                                if (trimmed.isEmpty) {
                                  return 'El lugar es obligatorio';
                                }
                                if (trimmed.length < 3) {
                                  return 'El lugar debe tener al menos 3 caracteres';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Footer
                  Container(
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
                          onPressed:
                              isLoading ? null : () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: DesignTokens.spacingM),
                        FilledButton.icon(
                          onPressed:
                              isLoading || !_formularioValido ? null : _crearFecha,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: const Text('Guardar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text, ColorScheme colorScheme) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: DesignTokens.fontWeightMedium,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSelectorField({
    required IconData icon,
    required String value,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    bool hasError = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasError ? colorScheme.error : colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: hasError ? colorScheme.error : colorScheme.primary,
            ),
            const SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: DesignTokens.fontSizeM),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// DIALOG LOADER PARA EDITAR FECHA
// ============================================

class _EditarFechaLoaderDialog extends StatelessWidget {
  final String fechaId;
  final VoidCallback onSuccess;

  const _EditarFechaLoaderDialog({
    required this.fechaId,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<InscripcionBloc, InscripcionState>(
      listener: (context, state) {
        if (state is InscripcionFechaDetalleCargado) {
          Navigator.of(context).pop();
          EditarFechaDialog.show(
            context,
            fechaDetalle: state.fechaDetalle,
            onSuccess: onSuccess,
          );
        }

        if (state is InscripcionError) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: DesignTokens.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: DesignTokens.spacingM),
                Text(
                  'Cargando fecha...',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget loader para cerrar inscripciones desde la lista
/// Carga el detalle de la fecha y luego abre el dialog de cerrar inscripciones
class _CerrarInscripcionesLoaderDialog extends StatelessWidget {
  final String fechaId;
  final VoidCallback onSuccess;

  const _CerrarInscripcionesLoaderDialog({
    required this.fechaId,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<InscripcionBloc, InscripcionState>(
      listener: (context, state) {
        if (state is InscripcionFechaDetalleCargado) {
          Navigator.of(context).pop();
          CerrarInscripcionesDialog.show(
            context,
            fechaDetalle: state.fechaDetalle,
            onSuccess: onSuccess,
          );
        }

        if (state is InscripcionError) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: DesignTokens.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: DesignTokens.spacingM),
                Text(
                  'Cargando fecha...',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget loader para reabrir inscripciones desde la lista
/// Carga el detalle de la fecha y luego abre el dialog de reabrir inscripciones
class _ReabrirInscripcionesLoaderDialog extends StatelessWidget {
  final String fechaId;
  final VoidCallback onSuccess;

  const _ReabrirInscripcionesLoaderDialog({
    required this.fechaId,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<InscripcionBloc, InscripcionState>(
      listener: (context, state) {
        if (state is InscripcionFechaDetalleCargado) {
          Navigator.of(context).pop();
          ReabrirInscripcionesDialog.show(
            context,
            fechaDetalle: state.fechaDetalle,
            onSuccess: onSuccess,
          );
        }

        if (state is InscripcionError) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: DesignTokens.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: DesignTokens.spacingM),
                Text(
                  'Cargando fecha...',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget loader para finalizar fecha desde la lista
/// Carga el detalle de la fecha y luego abre el dialog de finalizar
class _FinalizarFechaLoaderDialog extends StatelessWidget {
  final String fechaId;
  final VoidCallback onSuccess;

  const _FinalizarFechaLoaderDialog({
    required this.fechaId,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<InscripcionBloc, InscripcionState>(
      listener: (context, state) {
        if (state is InscripcionFechaDetalleCargado) {
          Navigator.of(context).pop();
          FinalizarFechaDialog.show(
            context,
            fechaDetalle: state.fechaDetalle,
            onSuccess: onSuccess,
          );
        }

        if (state is InscripcionError) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: DesignTokens.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: DesignTokens.spacingM),
                Text(
                  'Cargando fecha...',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================
// WIDGETS LOADER GENERICOS (para uso desde cards mobile)
// ============================================

/// Widget loader generico para editar fecha (acepta onSuccess nullable)
class _EditarFechaLoaderDialogGeneric extends StatelessWidget {
  final String fechaId;
  final VoidCallback? onSuccess;

  const _EditarFechaLoaderDialogGeneric({
    required this.fechaId,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<InscripcionBloc, InscripcionState>(
      listener: (context, state) {
        if (state is InscripcionFechaDetalleCargado) {
          Navigator.of(context).pop();
          EditarFechaDialog.show(
            context,
            fechaDetalle: state.fechaDetalle,
            onSuccess: onSuccess,
          );
        }

        if (state is InscripcionError) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: DesignTokens.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: DesignTokens.spacingM),
                Text(
                  'Cargando fecha...',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget loader generico para cerrar inscripciones (acepta onSuccess nullable)
class _CerrarInscripcionesLoaderDialogGeneric extends StatelessWidget {
  final String fechaId;
  final VoidCallback? onSuccess;

  const _CerrarInscripcionesLoaderDialogGeneric({
    required this.fechaId,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<InscripcionBloc, InscripcionState>(
      listener: (context, state) {
        if (state is InscripcionFechaDetalleCargado) {
          Navigator.of(context).pop();
          CerrarInscripcionesDialog.show(
            context,
            fechaDetalle: state.fechaDetalle,
            onSuccess: onSuccess,
          );
        }

        if (state is InscripcionError) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: DesignTokens.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: DesignTokens.spacingM),
                Text(
                  'Cargando fecha...',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget loader generico para reabrir inscripciones (acepta onSuccess nullable)
class _ReabrirInscripcionesLoaderDialogGeneric extends StatelessWidget {
  final String fechaId;
  final VoidCallback? onSuccess;

  const _ReabrirInscripcionesLoaderDialogGeneric({
    required this.fechaId,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<InscripcionBloc, InscripcionState>(
      listener: (context, state) {
        if (state is InscripcionFechaDetalleCargado) {
          Navigator.of(context).pop();
          ReabrirInscripcionesDialog.show(
            context,
            fechaDetalle: state.fechaDetalle,
            onSuccess: onSuccess,
          );
        }

        if (state is InscripcionError) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: DesignTokens.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: DesignTokens.spacingM),
                Text(
                  'Cargando fecha...',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget loader generico para finalizar fecha (acepta onSuccess nullable)
class _FinalizarFechaLoaderDialogGeneric extends StatelessWidget {
  final String fechaId;
  final VoidCallback? onSuccess;

  const _FinalizarFechaLoaderDialogGeneric({
    required this.fechaId,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<InscripcionBloc, InscripcionState>(
      listener: (context, state) {
        if (state is InscripcionFechaDetalleCargado) {
          Navigator.of(context).pop();
          FinalizarFechaDialog.show(
            context,
            fechaDetalle: state.fechaDetalle,
            onSuccess: onSuccess,
          );
        }

        if (state is InscripcionError) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: DesignTokens.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: DesignTokens.spacingM),
                Text(
                  'Cargando fecha...',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
