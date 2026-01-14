// Test basico de widget para Sistema de Gestion Deportiva
// Actualizado para soportar GetIt y nueva arquitectura

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gestion_deportiva/features/auth/domain/repositories/auth_repository.dart';
import 'package:gestion_deportiva/features/auth/presentation/bloc/login/login_bloc.dart';
import 'package:gestion_deportiva/features/auth/presentation/bloc/registro/registro_bloc.dart';
import 'package:gestion_deportiva/app.dart';

// Mocks
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    final sl = GetIt.instance;
    
    // Limpiar registros anteriores
    if (sl.isRegistered<AuthRepository>()) {
      sl.unregister<AuthRepository>();
    }
    if (sl.isRegistered<LoginBloc>()) {
      sl.unregister<LoginBloc>();
    }
    if (sl.isRegistered<RegistroBloc>()) {
      sl.unregister<RegistroBloc>();
    }
    
    // Registrar mocks
    sl.registerFactory<LoginBloc>(() => LoginBloc(repository: mockAuthRepository));
    sl.registerFactory<RegistroBloc>(() => RegistroBloc(repository: mockAuthRepository));
    sl.registerLazySingleton<AuthRepository>(() => mockAuthRepository);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  testWidgets('App renders LoginPage correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // Verify that the login page title is displayed (app name in header)
    expect(find.text('Gestion Deportiva'), findsOneWidget);
    
    // Verify login form elements exist (finds at least one - titulo o boton)
    expect(find.text('Iniciar sesion'), findsAtLeast(1));
    
    // Verify email and password fields exist
    expect(find.text('Correo electronico'), findsOneWidget);
    expect(find.text('Contrasena'), findsOneWidget);
    
    // Verify register link exists (CA-005)
    expect(find.text('Registrate'), findsOneWidget);
  });
}
