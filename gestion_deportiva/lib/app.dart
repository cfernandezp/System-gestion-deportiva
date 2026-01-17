import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injection_container.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/session/session.dart';

/// Widget raiz de la aplicacion
/// Configura tema, routing y providers globales
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
      ],
      child: MaterialApp.router(
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

        // Tema
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,

        // Routing
        routerConfig: AppRouter.router,
      ),
    );
  }
}
