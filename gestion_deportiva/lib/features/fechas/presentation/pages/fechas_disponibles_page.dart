import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../data/models/fecha_disponible_model.dart';
import '../bloc/fechas_disponibles/fechas_disponibles.dart';
import '../widgets/widgets.dart';

/// Pagina de lista de fechas disponibles para inscripcion
/// E003-HU-002: Inscribirse a Fecha
/// CA-001: Mostrar lista con fecha, hora, lugar, duracion, costo, total inscritos
/// CA-006: Contador de inscritos visible
/// Usa ResponsiveLayout: Mobile App Style + Desktop Dashboard Style
class FechasDisponiblesPage extends StatelessWidget {
  const FechasDisponiblesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FechasDisponiblesBloc, FechasDisponiblesState>(
      builder: (context, state) {
        // Obtener datos del estado
        final fechas = _obtenerFechas(state);
        final isLoading = state is FechasDisponiblesLoading ||
                          state is FechasDisponiblesRefrescando;
        final isEmpty = state is FechasDisponiblesCargadas && state.fechas.isEmpty;
        final hasError = state is FechasDisponiblesError;
        final errorMessage = hasError ? state.message : null;

        // Siempre mostrar el layout, el loading/error va dentro del contenido
        return ResponsiveLayout(
          mobileBody: _MobileFechasView(
            fechas: fechas,
            isLoading: isLoading,
            isEmpty: isEmpty,
            hasError: hasError,
            errorMessage: errorMessage,
          ),
          desktopBody: _DesktopFechasView(
            fechas: fechas,
            isLoading: isLoading,
            isEmpty: isEmpty,
            hasError: hasError,
            errorMessage: errorMessage,
          ),
        );
      },
    );
  }

  List<FechaDisponibleModel> _obtenerFechas(FechasDisponiblesState state) {
    if (state is FechasDisponiblesCargadas) return state.fechas;
    if (state is FechasDisponiblesRefrescando) return state.fechasActuales;
    if (state is FechasDisponiblesError && state.fechasAnteriores != null) {
      return state.fechasAnteriores!;
    }
    return [];
  }
}

// ============================================
// VISTA MOBILE - App Style
// ============================================

class _MobileFechasView extends StatelessWidget {
  final List<FechaDisponibleModel> fechas;
  final bool isLoading;
  final bool isEmpty;
  final bool hasError;
  final String? errorMessage;

  const _MobileFechasView({
    required this.fechas,
    required this.isLoading,
    required this.isEmpty,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proximas Pichangas'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              context.read<FechasDisponiblesBloc>().add(
                const RefrescarFechasDisponiblesEvent(),
              );
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: _buildContent(context),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Estado de carga inicial
    if (isLoading && fechas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de error
    if (hasError && fechas.isEmpty) {
      return _buildErrorContent(context);
    }

    // Estado vacio
    if (isEmpty) {
      return _buildEmptyContent(context);
    }

    // Lista con datos
    return RefreshIndicator(
      onRefresh: () async {
        context.read<FechasDisponiblesBloc>().add(
          const RefrescarFechasDisponiblesEvent(),
        );
      },
      child: Stack(
        children: [
          ListView.separated(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            itemCount: fechas.length,
            separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.spacingM),
            itemBuilder: (context, index) {
              final fecha = fechas[index];
              return FechaCard(
                fecha: fecha,
                compacta: true,
                onTap: () => context.push('/fechas/${fecha.fechaId}'),
              );
            },
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

  Widget _buildErrorContent(BuildContext context) {
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
              errorMessage ?? 'Error al cargar fechas disponibles',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingL),
            FilledButton.icon(
              onPressed: () {
                context.read<FechasDisponiblesBloc>().add(
                  const CargarFechasDisponiblesEvent(),
                );
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
                Icons.calendar_month_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingL),
            Text(
              'No hay pichangas disponibles',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingS),
            Text(
              'Aun no se ha programado ninguna fecha.\nVuelve a revisar mas tarde.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingL),
            OutlinedButton.icon(
              onPressed: () {
                context.read<FechasDisponiblesBloc>().add(
                  const RefrescarFechasDisponiblesEvent(),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// VISTA DESKTOP - Dashboard Style
// ============================================

class _DesktopFechasView extends StatelessWidget {
  final List<FechaDisponibleModel> fechas;
  final bool isLoading;
  final bool isEmpty;
  final bool hasError;
  final String? errorMessage;

  const _DesktopFechasView({
    required this.fechas,
    required this.isLoading,
    required this.isEmpty,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      currentRoute: '/fechas',
      title: 'Proximas Pichangas',
      breadcrumbs: const ['Inicio', 'Fechas'],
      actions: [
        OutlinedButton.icon(
          onPressed: () {
            context.read<FechasDisponiblesBloc>().add(
              const RefrescarFechasDisponiblesEvent(),
            );
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Actualizar'),
        ),
      ],
      child: Column(
        children: [
          // Header con contador
          _buildHeader(context),

          // Contenido
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final totalInscritas = fechas.where((f) => f.usuarioInscrito).length;
    final totalDisponibles = fechas.where((f) => f.puedeInscribirse).length;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingL,
        vertical: DesignTokens.spacingM,
      ),
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
          // Total fechas
          _buildStatChip(
            context,
            icon: Icons.calendar_month,
            label: '${fechas.length} fecha${fechas.length != 1 ? 's' : ''}',
            color: colorScheme.primary,
          ),

          const SizedBox(width: DesignTokens.spacingM),

          // Fechas donde estoy inscrito
          if (totalInscritas > 0) ...[
            _buildStatChip(
              context,
              icon: Icons.check_circle,
              label: '$totalInscritas anotado${totalInscritas != 1 ? 's' : ''}',
              color: DesignTokens.successColor,
            ),
            const SizedBox(width: DesignTokens.spacingM),
          ],

          // Fechas disponibles para inscribirme
          if (totalDisponibles > 0)
            _buildStatChip(
              context,
              icon: Icons.sports_soccer,
              label: '$totalDisponibles disponible${totalDisponibles != 1 ? 's' : ''}',
              color: DesignTokens.accentColor,
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: DesignTokens.iconSizeS, color: color),
          const SizedBox(width: DesignTokens.spacingXs),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Estado de carga inicial
    if (isLoading && fechas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de error
    if (hasError && fechas.isEmpty) {
      return _buildErrorContent(context);
    }

    // Estado vacio
    if (isEmpty) {
      return _buildEmptyContent(context);
    }

    // Grid con datos
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          child: _buildFechasGrid(context),
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

  Widget _buildFechasGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular columnas basado en el ancho disponible
        final columns = (constraints.maxWidth / 500).floor().clamp(1, 2);

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: DesignTokens.spacingM,
            crossAxisSpacing: DesignTokens.spacingM,
            mainAxisExtent: 140, // Altura del card
          ),
          itemCount: fechas.length,
          itemBuilder: (context, index) {
            final fecha = fechas[index];
            return FechaCard(
              fecha: fecha,
              compacta: false,
              onTap: () => context.push('/fechas/${fecha.fechaId}'),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            errorMessage ?? 'Error al cargar fechas disponibles',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingL),
          FilledButton.icon(
            onPressed: () {
              context.read<FechasDisponiblesBloc>().add(
                const CargarFechasDisponiblesEvent(),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
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
              Icons.calendar_month_outlined,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),
          Text(
            'No hay pichangas disponibles',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            'Aun no se ha programado ninguna fecha para inscripcion.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
