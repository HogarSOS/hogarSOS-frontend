// VerificarCodigoScreen (revisión arquitectónica 2026-08-16) — caso
// delicado del fix de fuente única de verdad de navegación: a
// diferencia de LoginScreen (que vive en la MISMA posición del árbol
// que AuthGateScreen y por tanto le basta con no navegar), esta
// pantalla está empujada ENCIMA de esa ruta base
// (Navigator.push(VerificarCodigoScreen) desde login_screen.dart) — si
// tras verificar el código simplemente se dejara de navegar del todo,
// el usuario se quedaría atascado mirando el campo de código para
// siempre, aunque AuthGateScreen ya hubiera construido el Shell correcto
// por debajo, sin ninguna forma de llegar a verlo.
//
// El fix real es Navigator.popUntil((route) => route.isFirst) — vuelve
// a la ruta base (donde vive AuthGateScreen) SIN construir ningún Shell
// aquí. Este test prueba el MECANISMO de navegación en sí (pop hasta la
// primera ruta revela lo que hay debajo) de forma aislada, con un
// Navigator real de 2 rutas y widgets marcadores simples — sin
// necesidad de AuthProvider/Firebase real (bloqueado en esta suite, ver
// auth_single_source_of_truth_test.dart), porque el mecanismo de
// Navigator no depende de qué construye cada ruta.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'popUntil((route) => route.isFirst) desde una ruta empujada revela la ruta base, sin construir nada nuevo',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('empujar'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        body: Center(
                          child: ElevatedButton(
                            key: const Key('confirmar'),
                            // Mismo mecanismo que VerificarCodigoScreen._confirmar():
                            // NO construye una pantalla nueva, solo vuelve a la base.
                            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                            child: const Text('Confirmar código'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Ruta base (AuthGateScreen)'),
                ),
              ),
            );
          },
        ),
      ),
    );

    // Ruta base visible al arrancar.
    expect(find.text('Ruta base (AuthGateScreen)'), findsOneWidget);

    // Empuja la "pantalla de verificar código" — mismo Navigator.push()
    // que login_screen.dart usa para llegar a VerificarCodigoScreen.
    await tester.tap(find.byKey(const Key('empujar')));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar código'), findsOneWidget);
    expect(find.text('Ruta base (AuthGateScreen)'), findsNothing);

    // "Verificar código" con éxito — popUntil, no construye nada nuevo.
    await tester.tap(find.byKey(const Key('confirmar')));
    await tester.pumpAndSettle();

    // La ruta base vuelve a verse — en la app real, para entonces
    // AuthGateScreen ya reaccionó a authProvider.usuario actualizado y
    // construyó el Shell correcto ahí mismo, sin que esta pantalla
    // tuviera que construir nada.
    expect(find.text('Ruta base (AuthGateScreen)'), findsOneWidget);
    expect(find.text('Confirmar código'), findsNothing);
  });

  testWidgets('popUntil no hace nada si ya se está en la ruta base (idempotente, sin excepción)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Base'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Base'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Base'), findsOneWidget);
  });
}
