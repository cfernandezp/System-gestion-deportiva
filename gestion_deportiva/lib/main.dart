import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/di/injection_container.dart';
import 'core/network/supabase_client.dart';

void main() async {
  // Asegurar inicializacion de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar locale para fechas en espanol Peru
  await initializeDateFormatting('es_PE', null);

  // Inicializar Supabase
  await SupabaseConfig.initialize();

  // Inicializar inyeccion de dependencias
  await initializeDependencies();

  // Ejecutar aplicacion
  runApp(const App());
}
