import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../theme/design_tokens.dart';
import '../../features/auth/presentation/bloc/session/session.dart';
import 'app_bottom_nav_bar.dart';

/// NavigationRail reutilizable para tablet
/// Extraido de home_page.dart _TabletNavigationRail para uso global
/// CA-005/RN-004: Reemplaza BottomNavigationBar en tablet
/// RN-008: Respeta dark/light mode
class AppNavigationRail extends StatelessWidget {
  /// Indice actual seleccionado
  final int currentIndex;

  const AppNavigationRail({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        String userRole = 'jugador';
        if (state is SessionAuthenticated) {
          userRole = state.rol.toLowerCase();
        }

        final items = AppBottomNavBar.getItemsForRole(userRole);

        return NavigationRail(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            if (index < items.length) {
              context.go(items[index].route);
            }
          },
          labelType: NavigationRailLabelType.all,
          backgroundColor: colorScheme.surface,
          selectedIconTheme: IconThemeData(color: colorScheme.primary),
          selectedLabelTextStyle: TextStyle(
            color: colorScheme.primary,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontSize: DesignTokens.fontSizeXs,
          ),
          unselectedIconTheme: IconThemeData(
            color: colorScheme.onSurfaceVariant,
          ),
          unselectedLabelTextStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: DesignTokens.fontSizeXs,
          ),
          leading: Padding(
            padding: const EdgeInsets.only(
              top: DesignTokens.spacingS,
              bottom: DesignTokens.spacingM,
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: DesignTokens.primaryGradient,
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: const Icon(
                Icons.sports_soccer,
                color: Colors.white,
                size: DesignTokens.iconSizeM,
              ),
            ),
          ),
          destinations: items
              .map((item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ))
              .toList(),
        );
      },
    );
  }
}
