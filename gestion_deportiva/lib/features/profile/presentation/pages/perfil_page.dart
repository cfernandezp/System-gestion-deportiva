import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/perfil_model.dart';
import '../bloc/perfil/perfil.dart';
import '../widgets/widgets.dart';

/// Pagina de perfil del usuario
/// E002-HU-001: Ver Perfil Propio
/// CA-001: Acceso al perfil desde seccion "Mi Perfil"
class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
      ),
      body: BlocBuilder<PerfilBloc, PerfilState>(
        builder: (context, state) {
          if (state is PerfilLoading) {
            return const _LoadingView();
          }

          if (state is PerfilError) {
            return _ErrorView(
              message: state.message,
              onRetry: () {
                context.read<PerfilBloc>().add(const CargarPerfilEvent());
              },
            );
          }

          if (state is PerfilLoaded) {
            return _PerfilContent(perfil: state.perfil);
          }

          if (state is PerfilRefreshing) {
            return _PerfilContent(
              perfil: state.perfilActual,
              isRefreshing: true,
            );
          }

          // Estado inicial - cargar perfil
          return const _LoadingView();
        },
      ),
    );
  }
}

/// Vista de carga
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

/// Vista de error
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: DesignTokens.iconSizeXxl,
              color: colorScheme.error,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'Error al cargar el perfil',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingS),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingL),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contenido principal del perfil
/// CA-002: Muestra todos los datos visibles
class _PerfilContent extends StatelessWidget {
  final PerfilModel perfil;
  final bool isRefreshing;

  const _PerfilContent({
    required this.perfil,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= DesignTokens.breakpointMobile;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<PerfilBloc>().add(const RefrescarPerfilEvent());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header con avatar y nombre
            _buildHeader(context, colorScheme, textTheme),

            // Estadisticas (antiguedad y rol)
            _buildStats(context, isTablet),

            // Informacion del perfil
            _buildInfoSection(context, colorScheme, textTheme, isTablet),

            const SizedBox(height: DesignTokens.spacingXl),
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
      decoration: BoxDecoration(
        gradient: DesignTokens.primaryGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          child: Column(
            children: [
              // Avatar
              PerfilAvatar(
                fotoUrl: perfil.fotoUrl,
                nombreCompleto: perfil.nombreCompleto,
                size: 100,
              ),
              const SizedBox(height: DesignTokens.spacingM),
              // Nombre completo
              Text(
                perfil.nombreCompleto,
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spacingXs),
              // Apodo
              Text(
                '@${perfil.apodo}',
                style: textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spacingS),
              // Badge de rol
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Text(
                  perfil.rolDisplay,
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      child: Row(
        children: [
          Expanded(
            child: PerfilStatsCard(
              icon: Icons.calendar_today,
              label: 'Miembro desde',
              value: perfil.antiguedad,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: PerfilStatsCard(
              icon: Icons.sports_soccer,
              label: 'Posicion',
              value: perfil.posicionDisplay,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isTablet,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informacion Personal',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          const Divider(),

          // CA-002: Datos visibles
          // Email (obligatorio - RN-002)
          PerfilInfoItem(
            icon: Icons.email_outlined,
            label: 'Correo electronico',
            value: perfil.email,
          ),

          // Telefono (opcional - RN-003)
          PerfilInfoItem(
            icon: Icons.phone_outlined,
            label: 'Telefono',
            value: perfil.telefonoDisplay,
            isOptional: true,
          ),

          // Posicion preferida (opcional - RN-003, RN-004)
          PerfilInfoItem(
            icon: Icons.sports_soccer_outlined,
            label: 'Posicion preferida',
            value: perfil.posicionDisplay,
            isOptional: true,
          ),

          // Fecha de ingreso (obligatorio - RN-002, RN-005)
          PerfilInfoItem(
            icon: Icons.event_outlined,
            label: 'Fecha de ingreso',
            value: perfil.fechaIngresoFormato,
          ),
        ],
      ),
    );
  }
}
