// UX candidatura no elegida (2026-08-25): cuando el cliente elige a OTRO
// profesional, la tarjeta de "Solicitudes cerca" deja de decir
// "Candidatura enviada" y pasa a "Solicitud cerrada — El cliente ha
// elegido a otro profesional." con "Eliminar de mis solicitudes".
//
// Tres capas, cada una con su contrato:
//   - modelo: `candidatura_estado` del backend → CandidaturaEstado, con
//     fallback para un backend anterior (sin el campo);
//   - provider: ocultarNoElegida() es optimista, persistente vía backend,
//     y no toca el resto de la lista;
//   - tarjeta (TarjetaSolicitudCercana, pública a propósito): los tres
//     estados pintan lo que deben y solo lo que deben — y nunca
//     "rechazado", que suena a valoración negativa.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/l10n/app_localizations.dart';
import 'package:hogarsos/models/service_request_model.dart';
import 'package:hogarsos/providers/service_request_provider.dart';
import 'package:hogarsos/screens/profesional/home_profesional_screen.dart';
import 'package:hogarsos/services/service_request_service.dart';

Map<String, dynamic> _json({String? candidaturaEstado, bool yaPostulado = false, Object? distancia = 850, bool conCampo = true}) {
  return {
    'id': 'sr-1',
    'descripcion': 'Grifo que gotea',
    'distancia_metros': distancia,
    'created_at': '2026-08-25T10:00:00Z',
    'urgencia': 'lo_antes_posible',
    'cliente_nombre': 'Ana',
    'cliente_foto_url': null,
    'ya_postulado': yaPostulado,
    if (conCampo) 'candidatura_estado': candidaturaEstado,
  };
}

NearbyRequest _solicitud(String id, {CandidaturaEstado estado = CandidaturaEstado.ninguna, double? distancia = 850}) {
  return NearbyRequest(
    id: id,
    descripcion: 'Solicitud $id',
    distanciaMetros: distancia,
    createdAt: DateTime(2026, 8, 25),
    clienteNombre: 'Cliente $id',
    yaPostulado: estado != CandidaturaEstado.ninguna,
    candidaturaEstado: estado,
  );
}

class _FakeServiceRequestService extends ServiceRequestService {
  int llamadasOcultar = 0;
  String? ultimoIdOcultado;
  bool lanzarError = false;

  @override
  Future<void> ocultarCandidatura(String id) async {
    llamadasOcultar++;
    ultimoIdOcultado = id;
    if (lanzarError) throw Exception('fallo simulado de red');
  }

  @override
  Future<List<NearbyRequest>> listarCercanas() async => const [];
}

Future<NearbyRequestsNotifier> _notifierCon(ServiceRequestService servicio, List<NearbyRequest> lista) async {
  final notifier = NearbyRequestsNotifier(servicio);
  await Future<void>.delayed(Duration.zero);
  notifier.state = AsyncValue.data(lista);
  return notifier;
}

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: child))),
  );
}

void main() {
  group('NearbyRequest.fromJson — candidatura_estado', () {
    test('"no_elegida" → noElegida (el cliente eligió a otro)', () {
      final s = NearbyRequest.fromJson(_json(candidaturaEstado: 'no_elegida', yaPostulado: true));
      expect(s.candidaturaEstado, CandidaturaEstado.noElegida);
      expect(s.yaPostulado, isTrue);
    });

    test('"pendiente" → pendiente', () {
      expect(NearbyRequest.fromJson(_json(candidaturaEstado: 'pendiente', yaPostulado: true)).candidaturaEstado,
          CandidaturaEstado.pendiente);
    });

    test('null → ninguna', () {
      expect(NearbyRequest.fromJson(_json(candidaturaEstado: null)).candidaturaEstado, CandidaturaEstado.ninguna);
    });

    test('backend anterior (sin el campo): ya_postulado=true → pendiente, false → ninguna', () {
      expect(NearbyRequest.fromJson(_json(conCampo: false, yaPostulado: true)).candidaturaEstado, CandidaturaEstado.pendiente);
      expect(NearbyRequest.fromJson(_json(conCampo: false, yaPostulado: false)).candidaturaEstado, CandidaturaEstado.ninguna);
    });

    test('un valor desconocido nunca se pinta como cerrada', () {
      expect(NearbyRequest.fromJson(_json(candidaturaEstado: 'algo_nuevo', yaPostulado: true)).candidaturaEstado,
          CandidaturaEstado.ninguna);
    });

    test('distancia_metros null (no elegida sin ubicación actual) no rompe el parseo', () {
      final s = NearbyRequest.fromJson(_json(candidaturaEstado: 'no_elegida', yaPostulado: true, distancia: null));
      expect(s.distanciaMetros, isNull);
    });
  });

  group('NearbyRequestsNotifier.ocultarNoElegida', () {
    test('quita SOLO esa solicitud de la lista y llama al backend con su id', () async {
      final servicio = _FakeServiceRequestService();
      final notifier = await _notifierCon(servicio, [
        _solicitud('A', estado: CandidaturaEstado.noElegida),
        _solicitud('B', estado: CandidaturaEstado.pendiente),
        _solicitud('C'),
      ]);

      await notifier.ocultarNoElegida('A');

      expect(notifier.state.value!.map((s) => s.id), ['B', 'C']);
      // La pendiente (B) y la sin postular (C) siguen exactamente igual.
      expect(notifier.state.value![0].candidaturaEstado, CandidaturaEstado.pendiente);
      expect(notifier.state.value![1].candidaturaEstado, CandidaturaEstado.ninguna);
      expect(servicio.llamadasOcultar, 1);
      expect(servicio.ultimoIdOcultado, 'A');
    });

    test('si el backend falla, la devuelve a la lista y relanza (la pantalla avisa)', () async {
      final servicio = _FakeServiceRequestService()..lanzarError = true;
      final notifier = await _notifierCon(servicio, [
        _solicitud('A', estado: CandidaturaEstado.noElegida),
        _solicitud('B'),
      ]);

      await expectLater(notifier.ocultarNoElegida('A'), throwsException);

      expect(notifier.state.value!.map((s) => s.id), ['A', 'B']);
      expect(notifier.state.value!.first.candidaturaEstado, CandidaturaEstado.noElegida);
    });

    test('postularse marca pendiente sin perder los demás campos', () async {
      final servicio = _FakeServiceRequestService();
      final notifier = await _notifierCon(servicio, [_solicitud('A')]);
      // postularse() llama al backend real del fake padre; aquí solo
      // interesa la transformación local, así que se prueba copyWith.
      final actualizada = notifier.state.value!.first.copyWith(yaPostulado: true, candidaturaEstado: CandidaturaEstado.pendiente);
      expect(actualizada.candidaturaEstado, CandidaturaEstado.pendiente);
      expect(actualizada.id, 'A');
      expect(actualizada.clienteNombre, 'Cliente A');
      expect(actualizada.distanciaMetros, 850);
    });
  });

  group('TarjetaSolicitudCercana — tres estados', () {
    Widget tarjeta(NearbyRequest s, {VoidCallback? onEliminar}) {
      return _app(TarjetaSolicitudCercana(
        solicitud: s,
        onIgnorar: () {},
        onPostularse: () {},
        onEliminarNoElegida: onEliminar ?? () {},
      ));
    }

    testWidgets('sin candidatura → Ignorar + Enviar candidatura, nada de cerrada', (tester) async {
      await tester.pumpWidget(tarjeta(_solicitud('A')));
      await tester.pumpAndSettle();

      expect(find.text('Enviar candidatura'), findsOneWidget);
      expect(find.text('Ignorar'), findsOneWidget);
      expect(find.text('Candidatura enviada'), findsNothing);
      expect(find.text('Solicitud cerrada'), findsNothing);
      expect(find.text('Eliminar de mis solicitudes'), findsNothing);
    });

    testWidgets('pendiente → "Candidatura enviada", sin botones ni texto de cerrada', (tester) async {
      await tester.pumpWidget(tarjeta(_solicitud('A', estado: CandidaturaEstado.pendiente)));
      await tester.pumpAndSettle();

      expect(find.text('Candidatura enviada'), findsOneWidget);
      expect(find.text('Enviar candidatura'), findsNothing);
      expect(find.text('Ignorar'), findsNothing);
      expect(find.text('Solicitud cerrada'), findsNothing);
      expect(find.text('Eliminar de mis solicitudes'), findsNothing);
    });

    testWidgets('no elegida → "Solicitud cerrada" + motivo + "Eliminar de mis solicitudes"; ya no "Candidatura enviada"',
        (tester) async {
      await tester.pumpWidget(tarjeta(_solicitud('A', estado: CandidaturaEstado.noElegida)));
      await tester.pumpAndSettle();

      expect(find.text('Solicitud cerrada'), findsOneWidget);
      expect(find.text('El cliente ha elegido a otro profesional.'), findsOneWidget);
      expect(find.text('Eliminar de mis solicitudes'), findsOneWidget);
      expect(find.text('Candidatura enviada'), findsNothing);
      expect(find.text('Enviar candidatura'), findsNothing);
      expect(find.text('Ignorar'), findsNothing);
      // La descripción y el cliente siguen visibles: se entiende de qué
      // solicitud se trata.
      expect(find.text('Solicitud A'), findsOneWidget);
      expect(find.text('Cliente A'), findsOneWidget);
      // Nunca "rechazado/a": no es una valoración del profesional.
      expect(find.textContaining('echaz'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('"Eliminar de mis solicitudes" dispara el callback de ocultar (y solo ese)', (tester) async {
      var eliminadas = 0;
      await tester.pumpWidget(tarjeta(_solicitud('A', estado: CandidaturaEstado.noElegida), onEliminar: () => eliminadas++));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar de mis solicitudes'));
      await tester.pump();

      expect(eliminadas, 1);
    });

    testWidgets('no elegida sin distancia (sin ubicación actual) oculta el chip de km y no falla', (tester) async {
      await tester.pumpWidget(tarjeta(_solicitud('A', estado: CandidaturaEstado.noElegida, distancia: null)));
      await tester.pumpAndSettle();

      expect(find.textContaining('km'), findsNothing);
      expect(find.text('Solicitud cerrada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('con distancia se sigue mostrando el chip de km (comportamiento previo intacto)', (tester) async {
      await tester.pumpWidget(tarjeta(_solicitud('A', estado: CandidaturaEstado.pendiente, distancia: 1500)));
      await tester.pumpAndSettle();

      expect(find.textContaining('1.5'), findsOneWidget);
    });
  });
}
