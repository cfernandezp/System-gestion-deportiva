import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../data/models/jugador_perfil_model.dart';
import '../bloc/perfil_jugador/perfil_jugador.dart';

/// Pagina de perfil publico de un jugador
/// E002-HU-004: Ver Perfil de Otro Jugador
/// CA-002: Datos publicos visibles (foto, apodo, posicion, fecha ingreso)
/// CA-003: Datos privados ocultos (NO email, NO telefono)
/// CA-004: Estadisticas basicas (goles, partidos, puntos)
///
/// Usa ResponsiveLayout con transicion instantanea:
/// - Layout SIEMPRE visible
/// - Loading/Error DENTRO del contenido
class JugadorPerfilPage extends StatelessWidget {
  final String jugadorId;

  const JugadorPerfilPage({
    super.key,
    required this.jugadorId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PerfilJugadorBloc, PerfilJugadorState>(
      builder: (context, state) {
        // Extraer datos del estado (transicion instantanea)
        final perfil = _obtenerPerfil(state);
        final isLoading = state is PerfilJugadorLoading;
        final hasError = state is PerfilJugadorError;
        final errorMessage = hasError ? state.message : null;

        // SIEMPRE mostrar el layout, loading/error va dentro del contenido
        return ResponsiveLayout(
          mobileBody: _MobilePerfilView(
            jugadorId: jugadorId,
            perfil: perfil,
            isLoading: isLoading,
            hasError: hasError,
            errorMessage: errorMessage,
          ),
          desktopBody: _DesktopPerfilView(
            jugadorId: jugadorId,
            perfil: perfil,
            isLoading: isLoading,
            hasError: hasError,
            errorMessage: errorMessage,
          ),
        );
      },
    );
  }

  JugadorPerfilModel? _obtenerPerfil(PerfilJugadorState state) {
    if (state is PerfilJugadorLoaded) return state.perfil;
    return null;
  }
}

// ============================================
// VISTA MOBILE - App Style
// ============================================

class _MobilePerfilView extends StatelessWidget {
  final String jugadorId;
  final JugadorPerfilModel? perfil;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  const _MobilePerfilView({
    required this.jugadorId,
    this.perfil,
    required this.isLoading,
    required this.hasError,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Jugador'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (perfil != null)
            IconButton(
              onPressed: () {
                context.read<PerfilJugadorBloc>().add(const RefrescarPerfilJugadorEvent());
              },
              icon: const Icon(Icons.refresh),
              tooltip: 'Refrescar',
            ),
        ],
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Estado de carga inicial
    if (isLoading && perfil == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de error
    if (hasError && perfil == null) {
      return _buildErrorContent(context);
    }

    // Sin datos
    if (perfil == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Contenido con datos
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PerfilJugadorBloc>().add(const RefrescarPerfilJugadorEvent());
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Header con foto y datos principales
                _buildHeader(context, colorScheme, textTheme),

                const SizedBox(height: DesignTokens.spacingL),

                // Informacion publica
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
                  child: _buildInfoSection(context, colorScheme, textTheme),
                ),

                const SizedBox(height: DesignTokens.spacingL),

                // Estadisticas
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
                  child: _buildEstadisticas(context, colorScheme, textTheme),
                ),

                const SizedBox(height: DesignTokens.spacingXl),
              ],
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
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              errorMessage ?? 'Error al cargar perfil',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            FilledButton.icon(
              onPressed: () {
                context.read<PerfilJugadorBloc>().add(CargarPerfilJugadorEvent(jugadorId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.5),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Avatar (CA-002: foto)
          _buildAvatar(colorScheme, textTheme, 80),
          const SizedBox(height: DesignTokens.spacingM),

          // Apodo (CA-002)
          Text(
            perfil!.apodo,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXs),

          // Nombre completo
          Text(
            perfil!.nombreCompleto,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme, TextTheme textTheme, double size) {
    if (perfil!.tieneFoto) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(perfil!.fotoUrl!),
        backgroundColor: colorScheme.primaryContainer,
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colorScheme.primary,
      child: Text(
        perfil!.iniciales,
        style: textTheme.headlineMedium?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: DesignTokens.fontWeightBold,
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informacion',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingM),

            // Posicion preferida (CA-002, RN-001)
            _buildInfoRow(
              Icons.sports_soccer,
              'Posicion',
              perfil!.posicionDisplay,
              colorScheme,
              textTheme,
            ),
            const Divider(height: DesignTokens.spacingL),

            // Fecha de ingreso (CA-002, RN-001)
            _buildInfoRow(
              Icons.calendar_today,
              'Miembro desde',
              perfil!.fechaIngresoFormato,
              colorScheme,
              textTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: DesignTokens.iconSizeM, color: colorScheme.primary),
        const SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: DesignTokens.spacingXxs),
              Text(
                value,
                style: textTheme.bodyLarge?.copyWith(fontWeight: DesignTokens.fontWeightMedium),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticas(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadisticas',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingM),

            // Grid de estadisticas (CA-004, RN-003)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    Icons.sports_soccer,
                    perfil!.estadisticas.golesTotales.toString(),
                    'Goles',
                    colorScheme,
                    textTheme,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: _buildStatCard(
                    Icons.emoji_events,
                    perfil!.estadisticas.partidosJugados.toString(),
                    'Partidos',
                    colorScheme,
                    textTheme,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: _buildStatCard(
                    Icons.star,
                    perfil!.estadisticas.puntosAcumulados.toString(),
                    'Puntos',
                    colorScheme,
                    textTheme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Column(
        children: [
          Icon(icon, size: DesignTokens.iconSizeL, color: colorScheme.primary),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXxs),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ============================================
// VISTA DESKTOP - Dashboard Style con DashboardShell
// ============================================

class _DesktopPerfilView extends StatelessWidget {
  final String jugadorId;
  final JugadorPerfilModel? perfil;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  const _DesktopPerfilView({
    required this.jugadorId,
    this.perfil,
    required this.isLoading,
    required this.hasError,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      currentRoute: '/jugadores',
      title: 'Perfil del Jugador',
      breadcrumbs: const ['Inicio', 'Jugadores', 'Perfil'],
      actions: [
        if (perfil != null)
          IconButton(
            onPressed: () {
              context.read<PerfilJugadorBloc>().add(const RefrescarPerfilJugadorEvent());
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
          ),
      ],
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Estado de carga inicial
    if (isLoading && perfil == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de error
    if (hasError && perfil == null) {
      return _buildErrorContent(context);
    }

    // Sin datos
    if (perfil == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Contenido con datos - Layout 2 columnas expandido
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna izquierda: Avatar y datos principales (ancho fijo)
              SizedBox(
                width: 300,
                child: _buildLeftColumn(colorScheme, textTheme),
              ),

              const SizedBox(width: DesignTokens.spacingL),

              // Columna derecha: Info y estadisticas (expandida)
              Expanded(
                child: _buildRightColumn(context, colorScheme, textTheme),
              ),
            ],
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

  Widget _buildErrorContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            errorMessage ?? 'Error al cargar perfil',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          FilledButton.icon(
            onPressed: () {
              context.read<PerfilJugadorBloc>().add(CargarPerfilJugadorEvent(jugadorId));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          children: [
            // Avatar grande
            _buildAvatar(colorScheme, textTheme, 120),
            const SizedBox(height: DesignTokens.spacingL),

            // Apodo
            Text(
              perfil!.apodo,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightBold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingS),

            // Nombre completo
            Text(
              perfil!.nombreCompleto,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingM),

            // Posicion badge
            if (perfil!.tienePosicion)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingS,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sports_soccer,
                      size: DesignTokens.iconSizeS,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Text(
                      perfil!.posicionDisplay,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme, TextTheme textTheme, double size) {
    if (perfil!.tieneFoto) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(perfil!.fotoUrl!),
        backgroundColor: colorScheme.primaryContainer,
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colorScheme.primary,
      child: Text(
        perfil!.iniciales,
        style: textTheme.displaySmall?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: DesignTokens.fontWeightBold,
        ),
      ),
    );
  }

  Widget _buildRightColumn(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      children: [
        // Card de informacion
        Card(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informacion del Jugador',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingL),

                // Fecha de ingreso
                _buildInfoRow(
                  Icons.calendar_today,
                  'Miembro desde',
                  perfil!.fechaIngresoFormato,
                  colorScheme,
                  textTheme,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: DesignTokens.spacingL),

        // Card de estadisticas
        Card(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estadisticas',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingL),

                // Grid de estadisticas
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.sports_soccer,
                        perfil!.estadisticas.golesTotales.toString(),
                        'Goles totales',
                        colorScheme,
                        textTheme,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingM),
                    Expanded(
                      child: _buildStatCard(
                        Icons.emoji_events,
                        perfil!.estadisticas.partidosJugados.toString(),
                        'Partidos jugados',
                        colorScheme,
                        textTheme,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingM),
                    Expanded(
                      child: _buildStatCard(
                        Icons.star,
                        perfil!.estadisticas.puntosAcumulados.toString(),
                        'Puntos acumulados',
                        colorScheme,
                        textTheme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingS),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Icon(
            icon,
            size: DesignTokens.iconSizeM,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingXxs),
              Text(
                value,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Column(
        children: [
          Icon(icon, size: DesignTokens.iconSizeXl, color: colorScheme.primary),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            value,
            style: textTheme.displaySmall?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Text(
            label,
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
