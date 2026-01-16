import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../theme/design_tokens.dart';
import '../../features/auth/presentation/bloc/session/session.dart';

/// Item de navegacion para el bottom nav
class BottomNavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final List<String>? roles; // Roles que pueden ver este item

  const BottomNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    this.roles,
  });
}

/// Barra de navegacion inferior para mobile
/// Estilo App Nativa - maximo 5 items
class AppBottomNavBar extends StatelessWidget {
  /// Indice actual seleccionado
  final int currentIndex;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  // Items de navegacion (max 5)
  static const List<BottomNavItem> _baseItems = [
    BottomNavItem(
      label: 'Inicio',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      route: '/',
    ),
    BottomNavItem(
      label: 'Perfil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      route: '/perfil',
    ),
    // E002-HU-003: Lista de Jugadores
    BottomNavItem(
      label: 'Jugadores',
      icon: Icons.group_outlined,
      selectedIcon: Icons.group,
      route: '/jugadores',
    ),
    BottomNavItem(
      label: 'Usuarios',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      route: '/admin/usuarios',
      roles: ['admin', 'administrador'],
    ),
  ];

  /// Obtiene los items filtrados por rol del usuario
  static List<BottomNavItem> getItemsForRole(String role) {
    final normalizedRole = role.toLowerCase();
    return _baseItems.where((item) {
      if (item.roles == null) return true;
      return item.roles!.contains(normalizedRole);
    }).toList();
  }

  /// Obtiene el indice correcto basado en la ruta actual
  static int getIndexForRoute(String route, String userRole) {
    final items = getItemsForRole(userRole);
    final index = items.indexWhere((item) => item.route == route);
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        String userRole = 'jugador';
        if (state is SessionAuthenticated) {
          userRole = state.rol.toLowerCase();
        }

        final items = getItemsForRole(userRole);

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingS,
                vertical: DesignTokens.spacingXs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = index == currentIndex;

                  return _NavBarItem(
                    item: item,
                    isSelected: isSelected,
                    onTap: () => context.go(item.route),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final BottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: AnimatedContainer(
          duration: DesignTokens.animFast,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: DesignTokens.iconSizeM,
              ),
              const SizedBox(height: DesignTokens.spacingXxs),
              Text(
                item.label,
                style: textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected
                      ? DesignTokens.fontWeightSemiBold
                      : DesignTokens.fontWeightRegular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
