import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/l10n/app_localizations.dart';
import 'package:hogarsos/models/postulacion_model.dart';
import 'package:hogarsos/models/tipo_profesional.dart';
import 'package:hogarsos/screens/cliente/widgets/postulacion_card.dart';

/// Tipo profesional visible ANTES de elegir (hallazgo C del cierre P0):
/// la tarjeta de candidatura pinta un chip Autónomo/Empresa/Particular
/// separado del nombre, y desaparece sin romper nada cuando el tipo es
/// null (API antigua sin el campo, o valor desconocido).
void main() {
  PostulacionCandidate candidato({TipoProfesional? tipo, String nombre = 'Paco'}) {
    return PostulacionCandidate(
      id: 'post-1',
      profesionalId: 'prof-1',
      nombre: nombre,
      valoracionMedia: 4.5,
      totalValoraciones: 12,
      mensaje: 'Puedo ir esta tarde',
      estaVerificado: true,
      createdAt: DateTime(2026, 8, 23),
      tipoProfesional: tipo,
    );
  }

  Widget lanzador(PostulacionCandidate c, {double escalaTexto = 1.0}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(escalaTexto)),
        child: Scaffold(body: PostulacionCard(candidato: c, onElegir: () {})),
      ),
    );
  }

  testWidgets('autónomo → muestra el chip "Autónomo"', (tester) async {
    await tester.pumpWidget(lanzador(candidato(tipo: TipoProfesional.autonomo)));
    expect(find.text('Autónomo'), findsOneWidget);
  });

  testWidgets('empresa → muestra el chip "Empresa"', (tester) async {
    await tester.pumpWidget(lanzador(candidato(tipo: TipoProfesional.empresa)));
    expect(find.text('Empresa'), findsOneWidget);
  });

  testWidgets('persona física → muestra el chip "Particular"', (tester) async {
    await tester.pumpWidget(lanzador(candidato(tipo: TipoProfesional.personaFisica)));
    expect(find.text('Particular'), findsOneWidget);
  });

  testWidgets('tipo null → no muestra ningún chip de tipo', (tester) async {
    await tester.pumpWidget(lanzador(candidato()));
    expect(find.text('Autónomo'), findsNothing);
    expect(find.text('Empresa'), findsNothing);
    expect(find.text('Particular'), findsNothing);
  });

  testWidgets('nombre largo + fuente grande: la tarjeta no desborda', (tester) async {
    await tester.pumpWidget(lanzador(
      candidato(
        tipo: TipoProfesional.personaFisica,
        nombre: 'Francisco Javier de Todos los Santos Expósito y Fernández de Córdoba',
      ),
      escalaTexto: 1.6,
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('Particular'), findsOneWidget);
  });

  group('PostulacionCandidate.fromJson', () {
    final base = <String, dynamic>{
      'id': 'post-1',
      'profesional_id': 'prof-1',
      'nombre': 'Paco',
      'valoracion_media': 4.5,
      'total_valoraciones': 12,
      'mensaje': 'hola',
      'estado_verificacion': 'aprobado',
      'created_at': '2026-08-23T10:00:00.000Z',
    };

    test('JSON antiguo SIN tipo_profesional no rompe y deja null', () {
      final c = PostulacionCandidate.fromJson(Map.of(base));
      expect(c.tipoProfesional, isNull);
    });

    test('tipo_profesional desconocido → null (enum cerrado, sin excepción)', () {
      final c = PostulacionCandidate.fromJson({...base, 'tipo_profesional': 'cooperativa_marciana'});
      expect(c.tipoProfesional, isNull);
    });

    test('los tres valores reales se parsean', () {
      expect(PostulacionCandidate.fromJson({...base, 'tipo_profesional': 'autonomo'}).tipoProfesional,
          TipoProfesional.autonomo);
      expect(PostulacionCandidate.fromJson({...base, 'tipo_profesional': 'empresa'}).tipoProfesional,
          TipoProfesional.empresa);
      expect(PostulacionCandidate.fromJson({...base, 'tipo_profesional': 'persona_fisica'}).tipoProfesional,
          TipoProfesional.personaFisica);
    });
  });
}
