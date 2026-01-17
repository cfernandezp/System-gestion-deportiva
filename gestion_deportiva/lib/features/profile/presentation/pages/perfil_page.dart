import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../data/models/perfil_model.dart';
import '../bloc/perfil/perfil.dart';
import '../widgets/widgets.dart';
import 'editar_perfil_page.dart';

/// Pagina de perfil del usuario
/// E002-HU-001: Ver Perfil Propio
/// E002-HU-002: Editar Perfil Propio
/// Usa ResponsiveLayout: Mobile App Style + Desktop Dashboard Style
class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PerfilBloc, PerfilState>(
      builder: (context, state) {
        final perfil = _obtenerPerfil(state);
        final isLoading = state is PerfilLoading;
        final hasError = state is PerfilError;
        final errorMessage = hasError ? state.message : null;
        final isRefreshing = state is PerfilRefreshing;

        // Siempre mostrar el layout, el loading/error va dentro del contenido
        return ResponsiveLayout(
          mobileBody: _MobilePerfilView(
            perfil: perfil,
            isLoading: isLoading,
            isRefreshing: isRefreshing,
            hasError: hasError,
            errorMessage: errorMessage,
          ),
          desktopBody: _DesktopPerfilView(
            perfil: perfil,
            isLoading: isLoading,
            isRefreshing: isRefreshing,
            hasError: hasError,
            errorMessage: errorMessage,
          ),
        );
      },
    );
  }

  /// E002-HU-002: Obtiene el perfil del estado actual
  PerfilModel? _obtenerPerfil(PerfilState state) {
    if (state is PerfilLoaded) return state.perfil;
    if (state is PerfilRefreshing) return state.perfilActual;
    if (state is PerfilSaving) return state.perfilActual;
    if (state is PerfilUpdateSuccess) return state.perfil;
    if (state is PerfilUpdateError) return state.perfilActual;
    return null;
  }
}

// ============================================
// VISTA MOBILE - App Style
// ============================================

class _MobilePerfilView extends StatelessWidget {
  final PerfilModel? perfil;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasError;
  final String? errorMessage;

  const _MobilePerfilView({
    this.perfil,
    this.isLoading = false,
    this.isRefreshing = false,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
        actions: perfil != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar perfil',
                  onPressed: () => _navegarAEdicion(context, perfil!),
                ),
              ]
            : null,
      ),
      body: _buildBody(context),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Estado de carga
    if (isLoading && perfil == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de error
    if (hasError && perfil == null) {
      return _buildErrorContent(context);
    }

    // Sin perfil
    if (perfil == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Contenido normal
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PerfilBloc>().add(const RefrescarPerfilEvent());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header con avatar y nombre
            _buildMobileHeader(context),

            // Estadisticas
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingM),
              child: Row(
                children: [
                  Expanded(
                    child: PerfilStatsCard(
                      icon: Icons.calendar_today,
                      label: 'Miembro desde',
                      value: perfil!.antiguedad,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingM),
                  Expanded(
                    child: PerfilStatsCard(
                      icon: Icons.sports_soccer,
                      label: 'Posicion',
                      value: perfil!.posicionDisplay,
                    ),
                  ),
                ],
              ),
            ),

            // Informacion personal
            _buildInfoSection(context),

            const SizedBox(height: DesignTokens.spacingXl),
          ],
        ),
      ),
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
            errorMessage ?? 'Error al cargar el perfil',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          FilledButton.icon(
            onPressed: () {
              context.read<PerfilBloc>().add(const CargarPerfilEvent());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: DesignTokens.primaryGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          child: Column(
            children: [
              PerfilAvatar(
                fotoUrl: perfil!.fotoUrl,
                nombreCompleto: perfil!.nombreCompleto,
                size: 100,
              ),
              const SizedBox(height: DesignTokens.spacingM),
              Text(
                perfil!.nombreCompleto,
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spacingXs),
              Text(
                '@${perfil!.apodo}',
                style: textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spacingS),
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
                  perfil!.rolDisplay,
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

  Widget _buildInfoSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
          PerfilInfoItem(
            icon: Icons.email_outlined,
            label: 'Correo electronico',
            value: perfil!.email,
          ),
          PerfilInfoItem(
            icon: Icons.phone_outlined,
            label: 'Telefono',
            value: perfil!.telefonoDisplay,
            isOptional: true,
          ),
          PerfilInfoItem(
            icon: Icons.sports_soccer_outlined,
            label: 'Posicion preferida',
            value: perfil!.posicionDisplay,
            isOptional: true,
          ),
          PerfilInfoItem(
            icon: Icons.event_outlined,
            label: 'Fecha de ingreso',
            value: perfil!.fechaIngresoFormato,
          ),
        ],
      ),
    );
  }

  void _navegarAEdicion(BuildContext context, PerfilModel perfil) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<PerfilBloc>(),
          child: EditarPerfilPage(perfilInicial: perfil),
        ),
      ),
    );
  }
}

// ============================================
// VISTA DESKTOP - Dashboard Style
// Layout: Sidebar izquierdo fijo + contenido derecho expandido
// ============================================

class _DesktopPerfilView extends StatelessWidget {
  final PerfilModel? perfil;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasError;
  final String? errorMessage;

  const _DesktopPerfilView({
    this.perfil,
    this.isLoading = false,
    this.isRefreshing = false,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      currentRoute: '/perfil',
      title: 'Mi Perfil',
      breadcrumbs: const ['Inicio', 'Mi Perfil'],
      actions: perfil != null
          ? [
              FilledButton.icon(
                onPressed: () => _navegarAEdicion(context, perfil!),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar Perfil'),
              ),
            ]
          : null,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Estado de carga
    if (isLoading && perfil == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de error
    if (hasError && perfil == null) {
      return _buildErrorContent(context);
    }

    // Sin perfil
    if (perfil == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Contenido normal
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel izquierdo fijo - Avatar y datos basicos (300px)
          SizedBox(
            width: 300,
            child: _buildProfileSidebar(context),
          ),
          const SizedBox(width: DesignTokens.spacingL),

          // Panel derecho expandido - Informacion detallada
          Expanded(
            child: _buildMainContent(context),
          ),
        ],
      ),
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
            errorMessage ?? 'Error al cargar el perfil',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          FilledButton.icon(
            onPressed: () {
              context.read<PerfilBloc>().add(const CargarPerfilEvent());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  /// Panel lateral izquierdo con avatar y datos basicos
  Widget _buildProfileSidebar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Avatar grande
          PerfilAvatar(
            fotoUrl: perfil!.fotoUrl,
            nombreCompleto: perfil!.nombreCompleto,
            size: 120,
          ),
          const SizedBox(height: DesignTokens.spacingM),

          // Nombre
          Text(
            perfil!.nombreCompleto,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingXs),

          // Apodo
          Text(
            '@${perfil!.apodo}',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),

          // Badge de rol
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            decoration: BoxDecoration(
              gradient: DesignTokens.primaryGradient,
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: DesignTokens.iconSizeS,
                  color: Colors.white,
                ),
                const SizedBox(width: DesignTokens.spacingXs),
                Text(
                  perfil!.rolDisplay,
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),
          const Divider(),
          const SizedBox(height: DesignTokens.spacingM),

          // Stats compactos
          _buildCompactStat(
            context,
            icon: Icons.calendar_today,
            label: 'Miembro desde',
            value: perfil!.antiguedad,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          _buildCompactStat(
            context,
            icon: Icons.sports_soccer,
            label: 'Posicion',
            value: perfil!.posicionDisplay,
          ),
        ],
      ),
    );
  }

  /// Stat compacto para el sidebar
  Widget _buildCompactStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Icon(
            icon,
            size: DesignTokens.iconSizeS,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Contenido principal expandido
  Widget _buildMainContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card de informacion de contacto
        _buildInfoCard(
          context,
          title: 'Informacion de Contacto',
          icon: Icons.contact_mail_outlined,
          children: [
            _buildInfoRow(
              context,
              icon: Icons.email_outlined,
              label: 'Correo electronico',
              value: perfil!.email,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            _buildInfoRow(
              context,
              icon: Icons.phone_outlined,
              label: 'Telefono',
              value: perfil!.telefonoDisplay,
              isOptional: perfil!.telefono == null,
            ),
          ],
        ),

        const SizedBox(height: DesignTokens.spacingL),

        // Card de informacion deportiva
        _buildInfoCard(
          context,
          title: 'Informacion Deportiva',
          icon: Icons.sports_soccer_outlined,
          children: [
            _buildInfoRow(
              context,
              icon: Icons.sports,
              label: 'Posicion preferida',
              value: perfil!.posicionDisplay,
              isOptional: perfil!.posicionPreferida == null,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            _buildInfoRow(
              context,
              icon: Icons.event_outlined,
              label: 'Fecha de ingreso',
              value: perfil!.fechaIngresoFormato,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            _buildInfoRow(
              context,
              icon: Icons.access_time,
              label: 'Antiguedad',
              value: perfil!.antiguedad,
            ),
          ],
        ),

        const SizedBox(height: DesignTokens.spacingL),

        // Card de estado de cuenta
        _buildInfoCard(
          context,
          title: 'Estado de Cuenta',
          icon: Icons.verified_user_outlined,
          children: [
            _buildInfoRow(
              context,
              icon: Icons.badge_outlined,
              label: 'Rol en el sistema',
              value: perfil!.rolDisplay,
              valueColor: colorScheme.primary,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            _buildInfoRow(
              context,
              icon: Icons.check_circle_outline,
              label: 'Estado',
              value: 'Cuenta activa',
              valueColor: DesignTokens.successColor,
            ),
          ],
        ),
      ],
    );
  }

  /// Card de informacion generica
  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spacingL),
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
          Row(
            children: [
              Icon(
                icon,
                size: DesignTokens.iconSizeM,
                color: colorScheme.primary,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingM),
          const Divider(),
          const SizedBox(height: DesignTokens.spacingM),
          ...children,
        ],
      ),
    );
  }

  /// Fila de informacion individual
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isOptional = false,
    Color? valueColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Icon(
            icon,
            size: DesignTokens.iconSizeS,
            color: colorScheme.onSurfaceVariant,
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
                  color: valueColor ?? (isOptional && value.contains('No especificado')
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface),
                  fontStyle: isOptional && value.contains('No especificado')
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navegarAEdicion(BuildContext context, PerfilModel perfil) {
    // En desktop, abre un Dialog modal en lugar de navegar a otra pagina
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<PerfilBloc>(),
        child: EditarPerfilDialog(perfilInicial: perfil),
      ),
    );
  }
}
