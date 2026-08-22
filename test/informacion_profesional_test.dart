import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/l10n/app_localizations.dart';
import 'package:hogarsos/widgets/informacion_profesional.dart';

/// Sección "Información profesional" (simplificación de Mi perfil,
/// 2026-08-22): plan de guardado por-campo (cada endpoint recibe SOLO lo
/// que cambió), composición del mensaje específico de fallo parcial, y
/// los dos widgets (resumen de 2 líneas y hoja de edición).
void main() {
  const resultadoBase = InformacionProfesionalResultado(
    descripcion: 'Fontanero con experiencia',
    telefono: '+34611222333',
    tarifa: 25,
  );

  group('planGuardadoInfoProfesional — solo se envía lo que cambió', () {
    test('guardar solo teléfono: descripción y tarifa iguales no viajan', () {
      final plan = planGuardadoInfoProfesional(
        descripcionActual: 'Fontanero con experiencia',
        telefonoActual: '+34600000000',
        tarifaActual: 25,
        resultado: resultadoBase,
      );
      expect(plan.guardarTelefono, isTrue);
      expect(plan.guardarDescripcion, isFalse);
      expect(plan.guardarTarifa, isFalse);
      expect(plan.guardarDatosProfesionales, isFalse);
    });

    test('guardar solo descripción', () {
      final plan = planGuardadoInfoProfesional(
        descripcionActual: 'Otra cosa',
        telefonoActual: '+34611222333',
        tarifaActual: 25,
        resultado: resultadoBase,
      );
      expect(plan.guardarDescripcion, isTrue);
      expect(plan.guardarTelefono, isFalse);
      expect(plan.guardarTarifa, isFalse);
    });

    test('guardar solo precio', () {
      final plan = planGuardadoInfoProfesional(
        descripcionActual: 'Fontanero con experiencia',
        telefonoActual: '+34611222333',
        tarifaActual: 20,
        resultado: resultadoBase,
      );
      expect(plan.guardarTarifa, isTrue);
      expect(plan.guardarDescripcion, isFalse);
      expect(plan.guardarTelefono, isFalse);
      expect(plan.guardarDatosProfesionales, isTrue);
    });

    test('guardar los tres a la vez', () {
      final plan = planGuardadoInfoProfesional(
        descripcionActual: '',
        telefonoActual: '',
        tarifaActual: 0,
        resultado: resultadoBase,
      );
      expect(plan.guardarDescripcion, isTrue);
      expect(plan.guardarTelefono, isTrue);
      expect(plan.guardarTarifa, isTrue);
    });

    test('sin cambios → no hay nada que guardar', () {
      final plan = planGuardadoInfoProfesional(
        descripcionActual: 'Fontanero con experiencia',
        telefonoActual: '+34611222333',
        tarifaActual: 25,
        resultado: resultadoBase,
      );
      expect(plan.hayCambios, isFalse);
    });

    test('campo vacío = sin cambio (paridad con los diálogos anteriores: vaciar nunca borra)', () {
      final plan = planGuardadoInfoProfesional(
        descripcionActual: 'Algo escrito',
        telefonoActual: '+34611222333',
        tarifaActual: 25,
        resultado: const InformacionProfesionalResultado(descripcion: '', telefono: '', tarifa: null),
      );
      expect(plan.hayCambios, isFalse);
    });
  });

  group('componerMensajeGuardadoInfoProfesional — fallos específicos, nunca genéricos', () {
    const falloDatos = 'FALLO_DATOS.';
    const falloTelefono = 'FALLO_TELEFONO.';
    const resto = 'RESTO_OK.';

    String? componer({
      required bool intentoDatos,
      required bool okDatos,
      required bool intentoTelefono,
      required bool okTelefono,
    }) =>
        componerMensajeGuardadoInfoProfesional(
          intentoDatos: intentoDatos,
          okDatos: okDatos,
          intentoTelefono: intentoTelefono,
          okTelefono: okTelefono,
          falloDatos: falloDatos,
          falloTelefono: falloTelefono,
          restoGuardado: resto,
        );

    test('todo bien → null (el llamador muestra su éxito)', () {
      expect(componer(intentoDatos: true, okDatos: true, intentoTelefono: true, okTelefono: true), isNull);
    });

    test('falla el teléfono y los datos sí se guardaron → mensaje específico + "el resto sí"', () {
      expect(
        componer(intentoDatos: true, okDatos: true, intentoTelefono: true, okTelefono: false),
        '$falloTelefono $resto',
      );
    });

    test('fallan descripción/tarifa y el teléfono sí se guardó → específico + "el resto sí"', () {
      expect(
        componer(intentoDatos: true, okDatos: false, intentoTelefono: true, okTelefono: true),
        '$falloDatos $resto',
      );
    });

    test('solo se intentó el teléfono y falló → sin coletilla de "el resto"', () {
      expect(
        componer(intentoDatos: false, okDatos: true, intentoTelefono: true, okTelefono: false),
        falloTelefono,
      );
    });

    test('fallan los dos → se nombran los dos', () {
      expect(
        componer(intentoDatos: true, okDatos: false, intentoTelefono: true, okTelefono: false),
        '$falloDatos $falloTelefono',
      );
    });
  });

  Widget envolver(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(body: child),
      );

  group('contieneContactoExterno — la descripción pública no admite contactos', () {
    for (final texto in [
      'Puedes llamarme al 612 345 678',
      'Tel 612-34-56-78',
      '+34612345678',
      'Escríbeme por WhatsApp',
      'estoy en telegram',
      'wa.me/34612345678',
      'mi correo es paco@example.com',
    ]) {
      test('detecta: $texto', () => expect(contieneContactoExterno(texto), isTrue));
    }

    for (final texto in [
      'Fontanero con 10 años de experiencia en calderas.',
      'Servicio 24h, presupuestos desde 15€.',
      'Trabajo en la zona centro desde 1998, Calle Mayor 123.',
    ]) {
      test('sin falso positivo: $texto', () => expect(contieneContactoExterno(texto), isFalse));
    }
  });

  group('InformacionProfesionalResumen', () {
    testWidgets('muestra tipo, descripción, teléfono SIN número y precio', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: const Scaffold(
          body: InformacionProfesionalResumen(
            tipoEtiqueta: 'Autónomo',
            descripcion: 'Fontanero con experiencia',
            tarifaBase: 25,
          ),
        ),
      ));

      expect(find.textContaining('Autónomo'), findsOneWidget);
      expect(find.textContaining('Fontanero con experiencia'), findsOneWidget);
      expect(find.text('Teléfono: solo uso interno'), findsOneWidget);
      expect(find.textContaining('25.00 €/h'), findsOneWidget);
      // Jamás un número de teléfono en la vista principal.
      expect(find.textContaining('6'), findsNothing);
    });

    testWidgets('sin datos → Sin indicar / CTA de descripción / opcional', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: const Scaffold(
          body: InformacionProfesionalResumen(tipoEtiqueta: null, descripcion: '', tarifaBase: 0),
        ),
      ));

      expect(find.textContaining('Sin indicar'), findsOneWidget);
      expect(find.textContaining('Añade una breve descripción'), findsOneWidget);
      expect(find.textContaining('opcional'), findsOneWidget);
    });
  });

  group('DescripcionResumen', () {
    testWidgets('descripción vacía → llamada a completarla', (tester) async {
      await tester.pumpWidget(envolver(const DescripcionResumen(descripcion: '')));
      expect(find.text('Añade una breve descripción para que los clientes te conozcan mejor'), findsOneWidget);
    });

    testWidgets('descripción existente → texto con máximo 2 líneas y elipsis', (tester) async {
      const larga = 'Fontanero con experiencia en instalaciones, reparaciones, calderas, '
          'termos, radiadores, desatascos y urgencias de todo tipo a domicilio.';
      await tester.pumpWidget(envolver(const DescripcionResumen(descripcion: larga)));

      final texto = tester.widget<Text>(find.text(larga));
      expect(texto.maxLines, 2);
      expect(texto.overflow, TextOverflow.ellipsis);
    });
  });

  group('EditorInformacionProfesional', () {
    testWidgets('abre con los valores actuales y devuelve lo editado al guardar', (tester) async {
      InformacionProfesionalResultado? resultado;

      await tester.pumpWidget(envolver(Builder(
        builder: (context) => FilledButton(
          onPressed: () async {
            resultado = await showModalBottomSheet<InformacionProfesionalResultado>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const EditorInformacionProfesional(
                descripcionInicial: 'Desc previa',
                telefonoInicial: '+34600111222',
                tarifaInicial: 30,
              ),
            );
          },
          child: const Text('abrir'),
        ),
      )));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      // Los tres campos llegan con sus valores actuales.
      expect(find.text('Información profesional'), findsOneWidget);
      expect(find.text('Desc previa'), findsOneWidget);
      expect(find.text('+34600111222'), findsOneWidget);
      expect(find.text('30.00'), findsOneWidget);
      // La nota de uso interno del teléfono vive dentro del editor.
      expect(find.text('Solo para uso interno de HogarSOS. Los clientes no lo ven.'), findsOneWidget);

      // Editar los tres y guardar.
      await tester.enterText(find.widgetWithText(TextField, 'Desc previa'), 'Desc nueva');
      await tester.enterText(find.widgetWithText(TextField, '+34600111222'), '+34699888777');
      await tester.enterText(find.widgetWithText(TextField, '30.00'), '45,50');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(resultado, isNotNull);
      expect(resultado!.descripcion, 'Desc nueva');
      expect(resultado!.telefono, '+34699888777');
      expect(resultado!.tarifa, 45.50);
    });

    testWidgets('descripción con teléfono → error en línea, la hoja NO se cierra y el texto NO se borra', (tester) async {
      await tester.pumpWidget(envolver(Builder(
        builder: (context) => FilledButton(
          onPressed: () => showModalBottomSheet<InformacionProfesionalResultado>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const EditorInformacionProfesional(
              descripcionInicial: '',
              telefonoInicial: '',
              tarifaInicial: null,
            ),
          ),
          child: const Text('abrir'),
        ),
      )));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Llámame al 612 345 678');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(find.text('Información profesional'), findsOneWidget); // sigue abierta
      expect(find.textContaining('No puedes incluir teléfonos'), findsOneWidget);
      expect(find.text('Llámame al 612 345 678'), findsOneWidget); // el texto no se borra
    });

    testWidgets('tipo bloqueado (aprobado + Stripe) → fila informativa con la vía de soporte', (tester) async {
      await tester.pumpWidget(envolver(Builder(
        builder: (context) => FilledButton(
          onPressed: () => showModalBottomSheet<InformacionProfesionalResultado>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const EditorInformacionProfesional(
              descripcionInicial: '',
              telefonoInicial: '',
              tarifaInicial: null,
              tipoEtiqueta: 'Autónomo',
              tipoBloqueado: true,
            ),
          ),
          child: const Text('abrir'),
        ),
      )));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Cómo trabajas'), findsOneWidget);
      expect(find.text('Autónomo'), findsOneWidget);
      expect(find.text('Para cambiar tu tipo profesional, contacta con soporte.'), findsOneWidget);
    });

    testWidgets('tarifa no numérica → error en línea y la hoja NO se cierra', (tester) async {
      await tester.pumpWidget(envolver(Builder(
        builder: (context) => FilledButton(
          onPressed: () => showModalBottomSheet<InformacionProfesionalResultado>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const EditorInformacionProfesional(
              descripcionInicial: '',
              telefonoInicial: '',
              tarifaInicial: null,
            ),
          ),
          child: const Text('abrir'),
        ),
      )));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'abc');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(find.text('Información profesional'), findsOneWidget); // sigue abierta
      expect(find.text('Indica una tarifa base válida'), findsOneWidget);
    });
  });
}
