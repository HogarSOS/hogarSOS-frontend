import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/l10n/app_localizations.dart';
import 'package:hogarsos/models/tipo_profesional.dart';
import 'package:hogarsos/widgets/selector_tipo_profesional.dart';

/// Selector de tipo profesional rediseñado (2026-08-22): tarjetas
/// seleccionables + Continuar, y declaración de responsabilidad
/// obligatoria para "Particular". Estos tests fijan el contrato completo
/// aprobado en la revisión adversarial, incluida la regla de oro: NUNCA
/// se puede continuar como Particular sin marcar la casilla, y la
/// casilla jamás aparece marcada por sí sola.
void main() {
  const declaracion =
      'Entiendo y acepto que soy responsable de cumplir las obligaciones legales, fiscales y de Seguridad Social que correspondan a mi actividad.';

  Widget lanzador({TipoProfesional? seleccionInicial, required void Function(TipoProfesional?) alCerrar}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              final r = await showDialog<TipoProfesional>(
                context: context,
                builder: (_) => SelectorTipoProfesional(seleccionInicial: seleccionInicial),
              );
              alCerrar(r);
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );
  }

  Future<void> abrir(WidgetTester tester, {TipoProfesional? inicial, void Function(TipoProfesional?)? alCerrar}) async {
    await tester.pumpWidget(lanzador(seleccionInicial: inicial, alCerrar: alCerrar ?? (_) {}));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  bool continuarHabilitado(WidgetTester tester) {
    final boton = tester.widget<FilledButton>(
      find.ancestor(of: find.text('Continuar'), matching: find.byType(FilledButton)),
    );
    return boton.onPressed != null;
  }

  testWidgets('1. aparecen las tres opciones y el aviso general', (tester) async {
    await abrir(tester);
    expect(find.text('Autónomo'), findsOneWidget);
    expect(find.text('Empresa'), findsOneWidget);
    expect(find.text('Particular'), findsOneWidget);
    expect(find.textContaining('plataforma de intermediación'), findsOneWidget);
  });

  testWidgets('2-5. cada opción se selecciona y queda marcada visualmente (check_circle)', (tester) async {
    await abrir(tester);
    expect(find.byIcon(Icons.check_circle), findsNothing);

    for (final etiqueta in ['Autónomo', 'Empresa', 'Particular']) {
      await tester.tap(find.text(etiqueta));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle), findsOneWidget, reason: 'solo $etiqueta marcada');
    }
  });

  testWidgets('6. Autónomo → Continuar habilitado y devuelve el valor correcto', (tester) async {
    TipoProfesional? resultado;
    await abrir(tester, alCerrar: (r) => resultado = r);

    expect(continuarHabilitado(tester), isFalse, reason: 'sin selección no se puede continuar');
    await tester.ensureVisible(find.text('Autónomo'));
    await tester.tap(find.text('Autónomo'));
    await tester.pumpAndSettle();
    expect(continuarHabilitado(tester), isTrue);

    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(resultado, TipoProfesional.autonomo);
  });

  testWidgets('7. Empresa → Continuar habilitado inmediatamente', (tester) async {
    TipoProfesional? resultado;
    await abrir(tester, alCerrar: (r) => resultado = r);

    await tester.ensureVisible(find.text('Empresa'));
    await tester.tap(find.text('Empresa'));
    await tester.pumpAndSettle();
    expect(continuarHabilitado(tester), isTrue);
    expect(find.text(declaracion), findsNothing, reason: 'la declaración es solo de Particular');

    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(resultado, TipoProfesional.empresa);
  });

  testWidgets('8-9. Particular bloquea Continuar sin casilla; con casilla, continúa', (tester) async {
    TipoProfesional? resultado;
    await abrir(tester, alCerrar: (r) => resultado = r);

    await tester.ensureVisible(find.text('Particular'));
    await tester.tap(find.text('Particular'));
    await tester.pumpAndSettle();

    // Casilla visible, desmarcada, y Continuar bloqueado.
    expect(find.text(declaracion), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(continuarHabilitado(tester), isFalse);

    // La fila completa es pulsable, no solo el cuadradito.
    await tester.ensureVisible(find.text(declaracion));
    await tester.tap(find.text(declaracion));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    expect(continuarHabilitado(tester), isTrue);

    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(resultado, TipoProfesional.personaFisica);
  });

  testWidgets('10. Particular con casilla marcada → cambiar a Autónomo oculta la casilla y Continuar sigue habilitado', (tester) async {
    await abrir(tester);

    await tester.ensureVisible(find.text('Particular'));
    await tester.tap(find.text('Particular'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(declaracion));
    await tester.tap(find.text(declaracion));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Autónomo'));
    await tester.tap(find.text('Autónomo'));
    await tester.pumpAndSettle();

    expect(find.text(declaracion), findsNothing);
    expect(continuarHabilitado(tester), isTrue, reason: 'cambiar de tipo nunca deja bloqueado');
  });

  testWidgets('11. volver a Particular tras marcarla → la casilla reaparece DESMARCADA (sin consentimiento fantasma)', (tester) async {
    await abrir(tester);

    await tester.ensureVisible(find.text('Particular'));
    await tester.tap(find.text('Particular'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(declaracion));
    await tester.tap(find.text(declaracion));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    await tester.ensureVisible(find.text('Autónomo'));
    await tester.tap(find.text('Autónomo'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Particular'));
    await tester.tap(find.text('Particular'));
    await tester.pumpAndSettle();

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(continuarHabilitado(tester), isFalse);
  });

  testWidgets('12. Particular → Empresa funciona y devuelve empresa', (tester) async {
    TipoProfesional? resultado;
    await abrir(tester, alCerrar: (r) => resultado = r);

    await tester.ensureVisible(find.text('Particular'));
    await tester.tap(find.text('Particular'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Empresa'));
    await tester.tap(find.text('Empresa'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(resultado, TipoProfesional.empresa);
  });

  testWidgets('13-14. cancelar no devuelve nada y una apertura nueva nace limpia (sin herencias)', (tester) async {
    TipoProfesional? resultado = TipoProfesional.autonomo; // centinela
    await abrir(tester, alCerrar: (r) => resultado = r);

    await tester.ensureVisible(find.text('Particular'));
    await tester.tap(find.text('Particular'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(declaracion));
    await tester.tap(find.text(declaracion));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cancelar'));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(resultado, isNull, reason: 'cancelar no guarda ningún consentimiento ni selección');

    // Reapertura (equivale a otra sesión/cuenta: cada diálogo es una
    // instancia nueva de State): nada marcado, nada seleccionado.
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.text(declaracion), findsNothing);
    expect(continuarHabilitado(tester), isFalse);
  });

  testWidgets('preselección: se abre con el tipo ya persistido marcado; confirmar Particular re-exige casilla', (tester) async {
    await abrir(tester, inicial: TipoProfesional.personaFisica);

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text(declaracion), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(continuarHabilitado(tester), isFalse, reason: 'continuar es re-confirmar: exige la casilla');
  });

  test('15. los valores enviados al backend no cambian (contrato del enum)', () {
    expect(TipoProfesional.autonomo.toJson(), 'autonomo');
    expect(TipoProfesional.empresa.toJson(), 'empresa');
    expect(TipoProfesional.personaFisica.toJson(), 'persona_fisica');
  });
}
