// Test basico de widget para Sistema de Gestion Deportiva

import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_deportiva/app.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());

    // Verify that the app title is displayed
    expect(find.text('Sistema de Gestion Deportiva'), findsOneWidget);
  });
}
