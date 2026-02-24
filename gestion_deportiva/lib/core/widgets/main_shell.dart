import 'package:flutter/material.dart';

import 'app_bottom_nav_bar.dart';
import 'app_navigation_rail.dart';
import 'responsive_layout.dart';

/// Shell principal que envuelve las paginas de tabs principales
/// En mobile: Scaffold con AppBottomNavBar (sin cambios, RN-002)
/// En tablet: Scaffold con Row[NavigationRail, Expanded(child)] sin BottomNavBar
///
/// Uso: Cada page principal (Home, Perfil, Jugadores, Pichangas) debe
/// devolver MainShell en vez de Scaffold con AppBottomNavBar directamente.
///
/// RN-002: La experiencia mobile NO debe cambiar en absoluto
/// RN-008: Fondo respeta scaffoldBackgroundColor (sin areas negras)
class MainShell extends StatelessWidget {
  /// El contenido de la pagina (ya con su propio Scaffold)
  /// En mobile se pasa tal cual.
  /// En tablet se envuelve con NavigationRail.
  final int currentIndex;

  /// AppBar para el Scaffold
  final PreferredSizeWidget? appBar;

  /// Body content (NO un Scaffold completo, solo el body)
  final Widget body;

  /// FloatingActionButton opcional
  final Widget? floatingActionButton;

  /// FloatingActionButtonLocation opcional
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const MainShell({
    super.key,
    required this.currentIndex,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobile(context),
      tablet: _buildTablet(context),
    );
  }

  /// Mobile: Scaffold normal con AppBottomNavBar (sin cambios)
  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: AppBottomNavBar(currentIndex: currentIndex),
    );
  }

  /// Tablet: Scaffold con Row[NavigationRail, contenido] sin BottomNavBar
  /// RN-008: scaffoldBackgroundColor para evitar areas negras
  Widget _buildTablet(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Row(
          children: [
            // NavigationRail a la izquierda
            AppNavigationRail(currentIndex: currentIndex),

            // Contenido principal expandido
            Expanded(child: body),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      // Sin bottomNavigationBar en tablet
    );
  }
}
