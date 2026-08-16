// Header "Solicitudes cerca de ti" (revisión UX 2026-08-16): antes
// logo + título + chip de disponibilidad vivían en un único Row del
// AppBar — el título era el único elemento Flexible y perdía espacio
// primero en pantallas normales, cortándose. Se sustituyó por un Column
// de 2 líneas (título completo arriba, "Tu estado · X" pequeño y
// discreto debajo, sin onTap/InkWell/GestureDetector).
//
// Este test reproduce la MISMA composición de widgets que ahora usa
// home_profesional_screen.dart (Row con HogarSosMark+título, Text de
// estado debajo) en vez de montar HomeProfesionalScreen entero — esa
// pantalla arrastra nearbyRequestsProvider/assignedRequestsProvider/
// disponibilidadProvider (red real sin mock), nada de eso relacionado
// con este cambio puramente visual. Mismo patrón que
// test/eliminar_cuenta_ux_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/l10n/app_localizations.dart';
import 'package:hogarsos/theme/brand_mark.dart';

Widget _header({required String estado, required double anchoDisponible}) {
  return MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) {
        final t = AppLocalizations.of(context);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(size: Size(anchoDisponible, 640)),
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 64,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HogarSosMark(size: 24),
                      const SizedBox(width: 8),
                      Flexible(child: Text(t.profesionalTituloSolicitudes, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(t.profesionalEstadoLinea(estado)),
                ],
              ),
            ),
            body: const SizedBox.shrink(),
          ),
        );
      },
    ),
  );
}

void main() {
  // Ancho de referencia de "teléfono normal" — más estrecho que el
  // Galaxy S9 de 360dp de referencia (moderadamente pequeño), lo
  // suficiente para reproducir el corte real reportado.
  const anchoTelefonoNormal = 360.0;

  testWidgets('el título "Solicitudes cerca de ti" se ve completo, sin overflow, en un teléfono normal', (tester) async {
    await tester.pumpWidget(_header(estado: 'Disponible', anchoDisponible: anchoTelefonoNormal));
    await tester.pumpAndSettle();

    // flutter_test convierte cualquier RenderFlex overflow (el bug
    // original: logo+título+chip en un único Row, sin espacio en
    // pantallas normales) en una excepción capturada durante el pump —
    // si el título se cortara de verdad, tester.takeException() no sería
    // null. Esta es la prueba real de "no se corta", no una comparación
    // de anchos por separado.
    expect(tester.takeException(), isNull);
    expect(find.text('Solicitudes cerca de ti'), findsOneWidget);

    // La línea de estado, en su propia línea debajo, tampoco se corta ni
    // desaparece por falta de espacio compartido.
    expect(find.text('Tu estado · Disponible'), findsOneWidget);
  });

  testWidgets('línea de estado: "Tu estado · Disponible"', (tester) async {
    await tester.pumpWidget(_header(estado: 'Disponible', anchoDisponible: anchoTelefonoNormal));
    await tester.pumpAndSettle();

    expect(find.text('Tu estado · Disponible'), findsOneWidget);
  });

  testWidgets('línea de estado: "Tu estado · No disponible"', (tester) async {
    await tester.pumpWidget(_header(estado: 'No disponible', anchoDisponible: anchoTelefonoNormal));
    await tester.pumpAndSettle();

    expect(find.text('Tu estado · No disponible'), findsOneWidget);
  });

  testWidgets('el indicador de estado no tiene ninguna interacción (sin GestureDetector/InkWell que lo envuelva)', (tester) async {
    await tester.pumpWidget(_header(estado: 'Disponible', anchoDisponible: anchoTelefonoNormal));
    await tester.pumpAndSettle();

    final estadoFinder = find.text('Tu estado · Disponible');
    expect(estadoFinder, findsOneWidget);

    // Ningún ancestro entre el AppBar y este Text es un GestureDetector,
    // InkWell ni InkResponse — el indicador es puramente informativo.
    final ancestrosClicables = find.ancestor(
      of: estadoFinder,
      matching: find.byWidgetPredicate((w) => w is GestureDetector || w is InkWell || w is InkResponse),
    );
    expect(ancestrosClicables, findsNothing);
  });
}
