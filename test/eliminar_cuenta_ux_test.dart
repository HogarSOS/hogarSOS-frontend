// UX (auditoría 2026-08-15): "Eliminar cuenta" estaba pegado a "Cerrar
// sesión" (mismo color rojo de alarma para las dos, sin apenas
// separación, y en la pantalla de profesional sin separación alguna),
// fácil de confundir. Cambio puramente visual en cliente/perfil_screen.dart
// y profesional/mi_perfil_profesional_screen.dart: más espacio + un
// Divider entre ambas + "Cerrar sesión" ya no usa el rojo destructivo
// (queda solo para "Eliminar cuenta"). Ni el diálogo de confirmación ni
// la lógica de deleteMe se tocaron (widgets/eliminar_cuenta.dart, sin
// cambios).
//
// Estos tests reproducen la misma estructura de widgets que ahora usan
// las dos pantallas reales (OutlinedButton/TextButton "Cerrar sesión" +
// Divider + TextButton "Eliminar cuenta" con confirmarYEliminarCuenta),
// en vez de montar las pantallas completas (que arrastran providers de
// auth, perfil de profesional, disponibilidad, Stripe... nada de eso
// relacionado con este cambio). Se prueba la función real
// confirmarYEliminarCuenta (sin reimplementarla) para el diálogo.
//
// A propósito NO se llega a tocar "Confirmar" de verdad: eso dispararía
// una llamada de red real (UserService().eliminarCuenta(), sin mock
// posible sin tocar código de producción) — se verifica en su lugar que
// el botón de confirmar existe, está habilitado y sigue siendo el
// destructivo (fondo de error), sin ejecutarlo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/l10n/app_localizations.dart';
import 'package:hogarsos/widgets/eliminar_cuenta.dart';

Widget _pantallaDePrueba({required VoidCallback onCerrarSesion}) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            final t = AppLocalizations.of(context);
            final colorScheme = Theme.of(context).colorScheme;
            return Consumer(
              builder: (context, ref, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mismo patrón que las dos pantallas reales: "Cerrar
                  // sesión" ya NO usa colorScheme.error (acción normal).
                  OutlinedButton.icon(
                    onPressed: onCerrarSesion,
                    icon: const Icon(Icons.logout),
                    label: Text(t.perfilCerrarSesion),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Divider(color: colorScheme.outlineVariant),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => confirmarYEliminarCuenta(context, ref),
                    style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                    child: Text(t.perfilEliminarCuenta),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('layout no rompe la pantalla: las dos acciones y el divisor se construyen sin error', (tester) async {
    await tester.pumpWidget(_pantallaDePrueba(onCerrarSesion: () {}));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Cerrar sesión'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Eliminar cuenta'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cerrar sesión nunca ejecuta el flujo de eliminar cuenta (no aparece su diálogo)', (tester) async {
    var llamadasCerrarSesion = 0;
    await tester.pumpWidget(_pantallaDePrueba(onCerrarSesion: () => llamadasCerrarSesion++));

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(llamadasCerrarSesion, 1);
    expect(find.text('¿Eliminar tu cuenta?'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('tocar "Eliminar cuenta" NO borra directamente — primero pide confirmación explícita', (tester) async {
    await tester.pumpWidget(_pantallaDePrueba(onCerrarSesion: () {}));

    await tester.tap(find.widgetWithText(TextButton, 'Eliminar cuenta'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('¿Eliminar tu cuenta?'), findsOneWidget);
    expect(
      find.text(
        'Esta acción no se puede deshacer. Perderás el acceso de inmediato y se eliminarán tu nombre, email, teléfono, foto y, si eres profesional, tus documentos de verificación.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('cancelar la confirmación no hace nada — el diálogo se cierra y no pasa nada más', (tester) async {
    await tester.pumpWidget(_pantallaDePrueba(onCerrarSesion: () {}));

    await tester.tap(find.widgetWithText(TextButton, 'Eliminar cuenta'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    // Sigue en la misma pantalla — cancelar no navega ni deja rastro.
    expect(find.widgetWithText(TextButton, 'Eliminar cuenta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmar mantiene el flujo actual: el botón destructivo sigue presente, habilitado y en rojo (sin ejecutarlo — dispararía red real)',
      (tester) async {
    await tester.pumpWidget(_pantallaDePrueba(onCerrarSesion: () {}));

    await tester.tap(find.widgetWithText(TextButton, 'Eliminar cuenta'));
    await tester.pumpAndSettle();

    final botonConfirmar = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Sí, eliminar mi cuenta'),
    );
    expect(botonConfirmar.onPressed, isNotNull);

    final colorScheme = Theme.of(tester.element(find.byType(AlertDialog))).colorScheme;
    final estilo = botonConfirmar.style!.backgroundColor!.resolve({});
    expect(estilo, colorScheme.error);
  });
}
