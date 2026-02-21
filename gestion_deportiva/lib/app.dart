import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injection_container.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/responsive_layout.dart';
import 'features/auth/presentation/bloc/session/session.dart';
import 'features/settings/presentation/bloc/theme/theme.dart';

/// Widget raiz de la aplicacion
/// Configura tema, routing y providers globales
///
/// E000-HU-001: Sistema de Temas (Dark/Light)
/// - CA-001: Detectar preferencia del SO al abrir
/// - CA-002: Cambio inmediato sin reinicio
/// - CA-005: Pantallas de auth respetan el tema
/// - CA-007: Transicion suave (themeAnimationDuration)
///
/// HU-004: Cierre de Sesion
/// - CA-004: Sesion no persistente -> CheckSessionEvent al iniciar
/// - RN-004: No persistencia de credenciales post-cierre
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // HU-004: SessionBloc global para manejo de sesion
        // CA-004: Verificar sesion al iniciar app
        BlocProvider<SessionBloc>(
          create: (context) => sl<SessionBloc>()..add(const CheckSessionEvent()),
        ),
        // E000-HU-001: ThemeBloc global para tema dark/light
        // CA-001, CA-004: Cargar preferencia guardada al iniciar
        BlocProvider<ThemeBloc>(
          create: (context) => sl<ThemeBloc>()..add(const LoadThemeEvent()),
        ),
      ],
      // E000-HU-001: BlocBuilder escucha cambios de tema y los aplica
      // CA-002: themeMode cambia en caliente sin reiniciar la app
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: 'Gestion Deportiva',
            debugShowCheckedModeBanner: false,

            // Localizaciones (requerido para DatePicker/TimePicker en espanol)
            locale: const Locale('es', 'PE'),
            supportedLocales: const [
              Locale('es', 'PE'),
              Locale('es', ''),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // E000-HU-001: Tema controlado por ThemeBloc
            // CA-007: themeAnimationDuration para transicion suave
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.themeMode,
            themeAnimationDuration: const Duration(milliseconds: 300),
            themeAnimationCurve: Curves.easeInOut,

            // Routing
            routerConfig: AppRouter.router,

            // E000-HU-004 CA-011/RN-003: Configurar orientaciones
            // segun tipo de dispositivo despues del primer build
            builder: (context, child) {
              // Configurar orientaciones: celular=portrait, tablet=portrait+landscape
              ResponsiveLayout.configureOrientations(context);
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
