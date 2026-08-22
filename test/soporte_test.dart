import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/config/soporte.dart';
import 'package:hogarsos/l10n/app_localizations.dart';
import 'package:hogarsos/widgets/soporte_sheet.dart';

/// Centro de ayuda y soporte (auditoría 2026-08-22): un único centro,
/// email operativo desde el primer día, WhatsApp oculto hasta que exista
/// número oficial, contexto invisible, y jamás datos personales en los
/// enlaces preparados.
void main() {
  group('config/soporte — constructores de enlaces', () {
    test('mailto apunta al buzón oficial con el asunto codificado', () {
      final uri = construirMailtoSoporte('Ayuda con HogarSOS');
      expect(uri.scheme, 'mailto');
      expect(uri.toString(), contains('soporte@hogarsos.es'));
      expect(uri.toString(), contains('subject=Ayuda%20con%20HogarSOS'));
    });

    test('whatsapp: null cuando no hay número configurado (estado actual del proyecto)', () {
      expect(kSoporteWhatsapp, isNull, reason: 'no existe número oficial todavía — no inventar');
      expect(construirWhatsappSoporte('Hola'), isNull);
    });

    test('whatsapp: wa.me con mensaje codificado cuando se configura un número', () {
      final uri = construirWhatsappSoporte('Hola, necesito ayuda con HogarSOS.', numero: '34600000000');
      expect(uri.toString(), 'https://wa.me/34600000000?text=Hola%2C%20necesito%20ayuda%20con%20HogarSOS.');
    });

    test('los enlaces preparados solo llevan texto genérico — jamás datos del usuario', () {
      // El contrato: los constructores solo aceptan el texto que se les
      // pasa, y quienes los llaman (SoporteSheet) solo pasan claves de
      // l10n fijas. Ninguna de ellas interpola datos.
      final mailto = construirMailtoSoporte('Cambio de tipo profesional').toString();
      final wa = construirWhatsappSoporte('Hola, necesito ayuda con HogarSOS.', numero: '34600000000').toString();
      for (final enlace in [mailto, wa]) {
        expect(enlace, isNot(contains('userId')));
        expect(enlace, isNot(contains('stripe')));
        expect(enlace, isNot(contains('acct_')));
      }
    });
  });

  Widget lanzador({ContextoSoporte contexto = ContextoSoporte.general, String? whatsapp}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => SoporteSheet(contexto: contexto, whatsappNumero: whatsapp),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
  }

  group('SoporteSheet', () {
    testWidgets('general: título, pregunta, botón de email y dirección con Copiar; SIN WhatsApp', (tester) async {
      await tester.pumpWidget(lanzador());
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Ayuda y soporte'), findsOneWidget);
      expect(find.text('¿Necesitas ayuda con HogarSOS?'), findsOneWidget);
      expect(find.text('Escríbenos por email'), findsOneWidget);
      expect(find.text('soporte@hogarsos.es'), findsOneWidget);
      expect(find.text('Copiar'), findsOneWidget);
      // Sin número configurado: ni botón, ni "próximamente", nada.
      expect(find.text('Escríbenos por WhatsApp'), findsNothing);
    });

    testWidgets('con número configurado, el botón de WhatsApp aparece solo', (tester) async {
      await tester.pumpWidget(lanzador(whatsapp: '34600000000'));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Escríbenos por WhatsApp'), findsOneWidget);
    });

    testWidgets('contexto tipo_profesional: muestra el motivo para que el usuario sepa por qué contacta', (tester) async {
      await tester.pumpWidget(lanzador(contexto: ContextoSoporte.tipoProfesional));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Motivo: cambio de tipo profesional'), findsOneWidget);
      expect(find.text('Escríbenos por email'), findsOneWidget);
    });

    testWidgets('cerrar la hoja no deja nada roto y puede reabrirse', (tester) async {
      await tester.pumpWidget(lanzador());
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10)); // fuera de la hoja
      await tester.pumpAndSettle();
      expect(find.text('Ayuda y soporte'), findsNothing);

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Ayuda y soporte'), findsOneWidget);
    });
  });

  group('FilaAyudaSoporte (fila compartida de los perfiles)', () {
    testWidgets('fila con icono + texto, y al tocarla abre la hoja de soporte', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: const Scaffold(body: FilaAyudaSoporte()),
      ));

      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.text('Ayuda y soporte'), findsOneWidget);

      await tester.tap(find.text('Ayuda y soporte'));
      await tester.pumpAndSettle();

      // La hoja está abierta (título + pregunta + email).
      expect(find.text('¿Necesitas ayuda con HogarSOS?'), findsOneWidget);
      expect(find.text('Escríbenos por email'), findsOneWidget);
    });
  });
}
