import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../bloc/theme/theme.dart';

/// Pagina de configuracion con selector de tema
/// CA-003: Selector con opciones "Sistema", "Oscuro", "Claro"
/// CA-007: Transicion suave al cambiar tema
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuracion')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          children: [
            // Seccion: Apariencia
            Text(
              'Apariencia',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingS),
            _ThemeSelectorCard(),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelectorCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: DesignTokens.spacingS,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingM,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: DesignTokens.spacingS),
                      Text('Tema', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                // RN-002: Tres opciones de tema
                _ThemeOption(
                  icon: Icons.brightness_auto,
                  title: 'Sistema',
                  subtitle: 'Sigue la configuracion del dispositivo',
                  isSelected: state.themeMode == ThemeMode.system,
                  onTap: () => context
                      .read<ThemeBloc>()
                      .add(const ChangeThemeEvent(ThemeMode.system)),
                ),
                _ThemeOption(
                  icon: Icons.light_mode,
                  title: 'Claro',
                  subtitle: 'Siempre modo claro',
                  isSelected: state.themeMode == ThemeMode.light,
                  onTap: () => context
                      .read<ThemeBloc>()
                      .add(const ChangeThemeEvent(ThemeMode.light)),
                ),
                _ThemeOption(
                  icon: Icons.dark_mode,
                  title: 'Oscuro',
                  subtitle: 'Siempre modo oscuro',
                  isSelected: state.themeMode == ThemeMode.dark,
                  onTap: () => context
                      .read<ThemeBloc>()
                      .add(const ChangeThemeEvent(ThemeMode.dark)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight:
              isSelected ? DesignTokens.fontWeightSemiBold : null,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
