// Test mínimo de sanidad del proyecto.
//
// El test generado por defecto de Flutter (`flutter create`) hacía
// pumpWidget(const MyApp()) y probaba un contador — esa clase no existe
// en este proyecto (la app se llama HogarSOSApp) y no hay ningún
// contador. Se sustituye por un smoke test simple que no depende de
// Firebase ni de los providers de Riverpod estar inicializados, ya que
// levantar la app real requiere Firebase.initializeApp() (llamado en
// main(), no en el widget) y credenciales que no existen en el entorno
// de test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test: un widget básico se construye sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('hogarSOS'))),
      ),
    );

    expect(find.text('hogarSOS'), findsOneWidget);
  });
}

