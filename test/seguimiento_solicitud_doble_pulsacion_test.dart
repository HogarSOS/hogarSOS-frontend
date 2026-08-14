// Auditoría 2026-08-14, P1: doble pulsación sin protección en las
// tarjetas de "Aceptar presupuesto/ampliación/horas" del cliente
// (seguimiento_solicitud_screen.dart). El backend ya protege estas tres
// acciones con un updateMany condicionado a estado:'pendiente' (no hay
// riesgo real de doble aceptación en los datos), pero el frontend no
// deshabilitaba el botón mientras la petición estaba en curso — un
// doble tap rápido disparaba una segunda petición innecesaria que
// siempre volvía como un 409 confuso.
//
// Estos tests demuestran, para las tres tarjetas, que: un solo tap hace
// una única operación; dos taps rápidos hacen una única operación
// efectiva (el segundo queda bloqueado mientras la primera está en
// curso); si la operación falla, el usuario puede reintentar; y el
// estado de "procesando" siempre vuelve a false al terminar.
//
// PresupuestoPendienteCard/AmpliacionPendienteCard/CierreHorasPendienteCard
// se hicieron públicas (antes privadas, `_Xxx`) y se les añadió un
// parámetro `servicio` inyectable SOLO para poder sustituir el backend
// real aquí — en la app real siempre es null (ver el propio widget).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/l10n/app_localizations.dart';
import 'package:hogarsos/models/presupuesto_model.dart';
import 'package:hogarsos/providers/payment_provider.dart';
import 'package:hogarsos/screens/cliente/seguimiento_solicitud_screen.dart';
import 'package:hogarsos/services/payment_service.dart';
import 'package:hogarsos/services/service_request_service.dart';

/// Sustituye la llamada real al backend. `gate`, si no es null, deja la
/// llamada pendiente hasta que el propio test complete ese Completer —
/// así se puede comprobar el estado "a mitad de la petición" (botón
/// deshabilitado, spinner) de forma determinista, sin depender de
/// timings reales de red.
class _FakeServiceRequestService extends ServiceRequestService {
  int llamadasPresupuesto = 0;
  int llamadasAmpliacion = 0;
  int llamadasCierreHoras = 0;
  Completer<void>? gate;
  bool lanzarError = false;

  Future<void> _esperarGateYFallarSiToca() async {
    if (gate != null) await gate!.future;
    if (lanzarError) throw Exception('fallo simulado');
  }

  @override
  Future<void> responderPresupuesto(String id, String presupuestoId, {required bool aceptar}) async {
    llamadasPresupuesto++;
    await _esperarGateYFallarSiToca();
  }

  @override
  Future<void> responderAmpliacion(String id, String ampliacionId, {required bool aceptar}) async {
    llamadasAmpliacion++;
    await _esperarGateYFallarSiToca();
  }

  @override
  Future<void> responderCierreHoras(
    String id,
    String cierreId, {
    required bool aceptar,
    bool confirmarReduccionGrande = false,
  }) async {
    llamadasCierreHoras++;
    await _esperarGateYFallarSiToca();
  }
}

Widget _envolver(Widget child) {
  return ProviderScope(
    overrides: [
      // Evita que la tarjeta dispare una petición HTTP real (vía
      // ApiService/TokenStorage) solo para pintar el desglose de
      // comisión — no es lo que se está probando aquí.
      comisionesProvider.overrideWith(
        (ref) async => ComisionesInfo(comisionClientePorcentaje: 5, comisionProfesionalPorcentaje: 0),
      ),
    ],
    child: MaterialApp(
      // Fijo a propósito: sin esto, flutter test puede resolver el
      // locale por defecto del entorno (inglés) en vez de español, y los
      // find.text(...) de este archivo (en español) fallarían.
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('PresupuestoPendienteCard — doble pulsación', () {
    late _FakeServiceRequestService fake;
    late int llamadasOnRespondido;

    PresupuestoInfo presupuesto() => PresupuestoInfo(
          id: 'pres-1',
          tipo: TipoPresupuesto.cerrado,
          monto: 100,
          estado: EstadoPresupuesto.pendiente,
          createdAt: DateTime(2026, 8, 14),
        );

    setUp(() {
      fake = _FakeServiceRequestService();
      llamadasOnRespondido = 0;
    });

    Widget widget() => _envolver(
          PresupuestoPendienteCard(
            serviceRequestId: 'sr-1',
            presupuesto: presupuesto(),
            servicio: fake,
            onRespondido: ({bool silencioso = false}) async {
              llamadasOnRespondido++;
            },
          ),
        );

    testWidgets('1. un solo tap en Aceptar hace una única llamada al backend', (tester) async {
      await tester.pumpWidget(widget());
      await tester.tap(find.widgetWithText(FilledButton, 'Aceptar'));
      await tester.pumpAndSettle();

      expect(fake.llamadasPresupuesto, 1);
      expect(llamadasOnRespondido, 1);
    });

    testWidgets('2+3. dos taps rápidos mientras la petición sigue pendiente hacen una única llamada; el segundo tap queda bloqueado',
        (tester) async {
      fake.gate = Completer<void>();
      await tester.pumpWidget(widget());

      await tester.tap(find.widgetWithText(FilledButton, 'Aceptar'));
      await tester.pump(); // deja que arranque _responder() y se repinte con _procesando = true

      // El botón ya está deshabilitado — un segundo tap no debe hacer nada.
      final filledButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(filledButton.onPressed, isNull, reason: 'el botón debe estar deshabilitado mientras la petición está en curso');

      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      expect(fake.llamadasPresupuesto, 1, reason: 'el segundo tap no debe disparar una segunda petición');

      // Se completa la petición pendiente para no dejar timers colgados.
      fake.gate!.complete();
      await tester.pumpAndSettle();
      expect(fake.llamadasPresupuesto, 1);
    });

    testWidgets('4. si la petición falla, el usuario puede reintentar', (tester) async {
      fake.lanzarError = true;
      await tester.pumpWidget(widget());

      await tester.tap(find.widgetWithText(FilledButton, 'Aceptar'));
      await tester.pumpAndSettle();
      expect(fake.llamadasPresupuesto, 1);

      // El botón debe haber vuelto a estar habilitado tras el fallo.
      final filledButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(filledButton.onPressed, isNotNull);

      fake.lanzarError = false;
      await tester.tap(find.widgetWithText(FilledButton, 'Aceptar'));
      await tester.pumpAndSettle();
      expect(fake.llamadasPresupuesto, 2, reason: 'un reintento tras el fallo debe poder completarse');
    });

    testWidgets('5. el estado de "procesando" vuelve a false al terminar (éxito y fallo)', (tester) async {
      await tester.pumpWidget(widget());
      await tester.tap(find.widgetWithText(FilledButton, 'Aceptar'));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      final filledButton = tester.widget<FilledButton>(find.byType(FilledButton));
      final outlinedButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(filledButton.onPressed, isNotNull);
      expect(outlinedButton.onPressed, isNotNull);
    });

    testWidgets('6. comportamiento normal: rechazar sigue pidiendo confirmación en un diálogo antes de llamar al backend',
        (tester) async {
      await tester.pumpWidget(widget());

      await tester.tap(find.widgetWithText(OutlinedButton, 'Rechazar'));
      await tester.pumpAndSettle();

      // El diálogo de confirmación se sigue mostrando — comportamiento sin cambios.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(fake.llamadasPresupuesto, 0, reason: 'no debe llamar al backend hasta confirmar el diálogo');

      await tester.tap(find.widgetWithText(FilledButton, 'Rechazar'));
      await tester.pumpAndSettle();

      expect(fake.llamadasPresupuesto, 1);
      expect(llamadasOnRespondido, 1);
    });
  });

  group('AmpliacionPendienteCard — doble pulsación', () {
    late _FakeServiceRequestService fake;

    AmpliacionInfo ampliacion() => AmpliacionInfo(
          id: 'amp-1',
          montoAdicional: 40,
          estado: EstadoPresupuesto.pendiente,
          createdAt: DateTime(2026, 8, 14),
        );

    setUp(() => fake = _FakeServiceRequestService());

    Widget widget() => _envolver(
          AmpliacionPendienteCard(
            serviceRequestId: 'sr-1',
            ampliacion: ampliacion(),
            tarifaHora: null,
            servicio: fake,
            onRespondido: ({bool silencioso = false}) async {},
          ),
        );

    testWidgets('1. un solo tap en Aceptar hace una única llamada', (tester) async {
      await tester.pumpWidget(widget());
      await tester.tap(find.widgetWithText(FilledButton, 'Aceptar'));
      await tester.pumpAndSettle();
      expect(fake.llamadasAmpliacion, 1);
    });

    testWidgets('2+3. doble tap durante la petición pendiente: una sola llamada, botón deshabilitado', (tester) async {
      fake.gate = Completer<void>();
      await tester.pumpWidget(widget());

      await tester.tap(find.widgetWithText(FilledButton, 'Aceptar'));
      await tester.pump();

      final filledButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(filledButton.onPressed, isNull);

      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      expect(fake.llamadasAmpliacion, 1);

      fake.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('4+5. tras un fallo, el botón se reactiva y permite reintentar', (tester) async {
      fake.lanzarError = true;
      await tester.pumpWidget(widget());
      await tester.tap(find.widgetWithText(FilledButton, 'Aceptar'));
      await tester.pumpAndSettle();

      final filledButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(filledButton.onPressed, isNotNull);

      fake.lanzarError = false;
      await tester.tap(find.widgetWithText(FilledButton, 'Aceptar'));
      await tester.pumpAndSettle();
      expect(fake.llamadasAmpliacion, 2);
    });
  });

  group('CierreHorasPendienteCard — doble pulsación', () {
    late _FakeServiceRequestService fake;

    CierreHorasInfo cierre() => CierreHorasInfo(
          id: 'cierre-1',
          horasReales: 4,
          horasEstimadas: 4,
          estado: EstadoPresupuesto.pendiente,
          createdAt: DateTime(2026, 8, 14),
        );

    setUp(() => fake = _FakeServiceRequestService());

    Widget widget() => _envolver(
          CierreHorasPendienteCard(
            serviceRequestId: 'sr-1',
            cierreHoras: cierre(),
            tarifaHora: 20,
            horasEstimadas: 4,
            servicio: fake,
            onRespondido: ({bool silencioso = false}) async {},
          ),
        );

    testWidgets('1. un solo tap en Confirmar hace una única llamada', (tester) async {
      await tester.pumpWidget(widget());
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
      await tester.pumpAndSettle();
      expect(fake.llamadasCierreHoras, 1);
    });

    testWidgets('2+3. doble tap durante la petición pendiente: una sola llamada; también bloquea "Reclamar"', (tester) async {
      fake.gate = Completer<void>();
      await tester.pumpWidget(widget());

      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
      await tester.pump();

      final filledButton = tester.widget<FilledButton>(find.byType(FilledButton));
      final outlinedButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(filledButton.onPressed, isNull);
      expect(outlinedButton.onPressed, isNull, reason: 'Reclamar también debe bloquearse mientras Confirmar está en curso');

      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      expect(fake.llamadasCierreHoras, 1);

      fake.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('4+5. tras un fallo, el botón se reactiva y permite reintentar', (tester) async {
      fake.lanzarError = true;
      await tester.pumpWidget(widget());
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
      await tester.pumpAndSettle();

      final filledButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(filledButton.onPressed, isNotNull);

      fake.lanzarError = false;
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
      await tester.pumpAndSettle();
      expect(fake.llamadasCierreHoras, 2);
    });
  });
}
