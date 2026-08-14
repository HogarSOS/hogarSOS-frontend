// Auditoría 2026-08-14, P1: posible duplicación de mensajes de chat con
// red intermitente (chat_screen.dart / chat_service.dart).
//
// Diagnóstico previo (solo lectura) confirmó: Firestore no duplica sus
// propias escrituras al reconectar, y añadir timeout() sería
// contraproducente (el escrito local ya es durable, un timeout solo
// haría creer a la app que falló). El riesgo real es que el USUARIO,
// sin ninguna señal de "enviando", reintente manualmente creyendo que
// falló — dos llamadas independientes a enviarMensaje() con dos IDs
// distintos si no hay idempotencia real.
//
// Solución: ID de INTENTO generado en el cliente (no de contenido — dos
// mensajes iguales enviados por separado son intentos distintos, dos
// documentos), enviarMensaje() idempotente sobre ese ID, y estado local
// "pendiente"/"error" visible y reconciliado por ID contra el stream
// real.
//
// Estos tests usan un ChatService y un ServiceRequestService falsos
// (nunca tocan Firestore/Firebase Auth/red real) para poder controlar
// con precisión el timing ("red lenta", "conexión perdida") y demostrar
// el contrato de idempotencia a nivel de aplicación. La verificación de
// que firestore.rules impide editar un mensaje ya existente (la pieza
// que hace SEGURA esa idempotencia) se prueba aparte, contra el
// emulador de Firestore — ver el informe adjunto.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/l10n/app_localizations.dart';
import 'package:hogarsos/providers/chat_read_provider.dart';
import 'package:hogarsos/screens/chat_screen.dart';
import 'package:hogarsos/services/chat_service.dart';
import 'package:hogarsos/services/service_request_service.dart';

class _FakeServicioSolicitud extends ServiceRequestService {
  @override
  Future<void> sincronizarChat(String id) async {}

  @override
  Future<void> marcarChatLeido(String id) async {}
}

/// Simula el comportamiento observable de ChatService.enviarMensaje()
/// real: idempotente por intentoId (un reintento del mismo intento ya
/// confirmado es un no-op, sin duplicar el mensaje ni la notificación),
/// con la posibilidad de dejar una llamada "pendiente" (gate) o forzarla
/// a fallar, para simular red lenta/perdida de forma determinista.
class _FakeChatService implements ChatServiceBase {
  final _controller = StreamController<List<ChatMessage>>.broadcast();
  List<ChatMessage> _mensajes = [];
  int _contador = 0;

  /// Todas las llamadas reales a "Firestore" (nunca las que el propio
  /// método detecta como reintento ya confirmado y descarta antes).
  final List<String> intentosEscritos = [];
  int notificaciones = 0;

  final Map<String, Completer<void>> _puertas = {};
  final Set<String> _fallarIntento = {};

  List<ChatMessage> get mensajesReales => List.unmodifiable(_mensajes);

  void _emitir() => _controller.add(List.unmodifiable(_mensajes));

  /// Deja la próxima llamada a enviarMensaje() con este intentoId
  /// pendiente hasta que se complete el Completer devuelto — simula red
  /// lenta o conexión perdida de forma determinista, sin depender de
  /// timings reales.
  Completer<void> abrirPuerta(String intentoId) {
    final puerta = Completer<void>();
    _puertas[intentoId] = puerta;
    return puerta;
  }

  void forzarFallo(String intentoId) => _fallarIntento.add(intentoId);

  @override
  Stream<List<ChatMessage>> observarMensajes(String serviceRequestId) async* {
    // Firestore SIEMPRE emite el estado actual (aunque esté vacío) en
    // cuanto un listener se suscribe, no solo los cambios futuros — sin
    // esto, snapshot.hasData se queda en false para siempre si nadie ha
    // llamado a _emitir() todavía, y el StreamBuilder no sale nunca del
    // spinner genérico de carga.
    yield List.unmodifiable(_mensajes);
    yield* _controller.stream;
  }

  @override
  Stream<ChatMessage?> observarUltimoMensaje(String serviceRequestId) async* {
    yield _mensajes.isEmpty ? null : _mensajes.last;
    yield* _controller.stream.map((lista) => lista.isEmpty ? null : lista.last);
  }

  @override
  Stream<EstadoLecturaChat> observarEstadoLectura(String serviceRequestId) => Stream.value(EstadoLecturaChat.vacio);

  @override
  String nuevoIdIntento(String serviceRequestId) => 'intento-${_contador++}';

  @override
  Future<void> enviarMensaje({
    required String serviceRequestId,
    required String intentoId,
    required String texto,
    required String autorId,
  }) async {
    // Mismo contrato que el ChatService real: un reintento de un intento
    // que YA está confirmado es un éxito silencioso, sin repetir nada.
    if (_mensajes.any((m) => m.id == intentoId)) {
      return;
    }

    intentosEscritos.add(intentoId);

    final puerta = _puertas.remove(intentoId);
    if (puerta != null) await puerta.future;

    if (_fallarIntento.remove(intentoId)) {
      throw Exception('fallo simulado');
    }

    _mensajes = [..._mensajes, ChatMessage(id: intentoId, texto: texto, autorId: autorId, enviadoEn: DateTime.now())];
    _emitir();
    notificaciones++;
  }

  void cerrar() => _controller.close();
}

Widget _envolver(_FakeChatService fake, {Key? key}) {
  return ProviderScope(
    overrides: [chatServiceProvider.overrideWithValue(fake)],
    child: MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChatScreen(
        key: key,
        serviceRequestId: 'sr-1',
        servicioSolicitud: _FakeServicioSolicitud(),
        miUidOverride: 'uid-yo',
      ),
    ),
  );
}

Future<void> _abrirChat(WidgetTester tester, _FakeChatService fake, {Key? key}) async {
  await tester.pumpWidget(_envolver(fake, key: key));
  await tester.pump(); // deja resolver _prepararChat() (fakes, sin red real) y suscribirse al stream
}

Future<void> _escribir(WidgetTester tester, String texto) async {
  await tester.enterText(find.byType(TextField), texto);
}

Future<void> _tocarEnviar(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.send));
}

/// Sustituye a pumpAndSettle() en este archivo a propósito: el spinner
/// de "pendiente" es un CircularProgressIndicator indeterminado, que
/// anima para siempre — pumpAndSettle() nunca converge mientras esté en
/// pantalla (no es un bug de la lógica, es cómo funciona esa animación).
/// Unos pocos pumps bastan para dejar resolver los Futures/microtasks en
/// vuelo de los fakes, que no usan temporizadores reales.
Future<void> _asentar(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  late _FakeChatService fake;

  setUp(() => fake = _FakeChatService());
  tearDown(() => fake.cerrar());

  testWidgets('1. envío normal: un mensaje escrito y confirmado crea un único documento', (tester) async {
    await _abrirChat(tester, fake);
    await _escribir(tester, 'Hola');
    await _tocarEnviar(tester);
    await _asentar(tester);

    expect(fake.mensajesReales, hasLength(1));
    expect(fake.mensajesReales.single.texto, 'Hola');
    expect(fake.notificaciones, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing, reason: 'ya confirmado, no debe quedar pendiente');
  });

  testWidgets('2. doble tap sobre enviar (sin retype) no duplica — el campo ya se limpió tras el primer tap',
      (tester) async {
    await _abrirChat(tester, fake);
    await _escribir(tester, 'Hola');

    // Dos taps "a la vez": el primero limpia el campo de forma síncrona
    // antes del primer await, así que el segundo lee el campo vacío.
    await tester.tap(find.byIcon(Icons.send));
    await tester.tap(find.byIcon(Icons.send), warnIfMissed: false);
    await _asentar(tester);

    expect(fake.mensajesReales, hasLength(1));
    expect(fake.intentosEscritos, hasLength(1));
  });

  testWidgets('3. red lenta: el mensaje queda visible como pendiente hasta que se confirma', (tester) async {
    await _abrirChat(tester, fake);
    await _escribir(tester, 'Hola');

    // Generará 'intento-0' (primer nuevoIdIntento de este test).
    final puerta = fake.abrirPuerta('intento-0');
    await _tocarEnviar(tester);
    await tester.pump();

    expect(find.text('Hola'), findsOneWidget, reason: 'el mensaje ya se pinta optimistamente');
    expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'debe verse como pendiente, no confirmado');
    expect(fake.mensajesReales, isEmpty, reason: 'todavía no ha "llegado a Firestore"');

    puerta.complete();
    await _asentar(tester);

    expect(fake.mensajesReales, hasLength(1));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('4. conexión perdida tras la escritura local: un reintento del mismo intento no duplica', (tester) async {
    await _abrirChat(tester, fake);
    await _escribir(tester, 'Hola');
    fake.forzarFallo('intento-0');
    await _tocarEnviar(tester);
    await _asentar(tester);

    expect(fake.mensajesReales, isEmpty);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    // Reintento del USUARIO tocando el aviso de error — reutiliza el
    // mismo intentoId, no genera uno nuevo.
    await tester.tap(find.byIcon(Icons.error_outline));
    await _asentar(tester);

    expect(fake.mensajesReales, hasLength(1));
    expect(fake.intentosEscritos, ['intento-0', 'intento-0'], reason: 'dos intentos de red, mismo intentoId');
  });

  testWidgets('5. reintento del mismo intento produce el mismo documento (mismo id), no uno nuevo', (tester) async {
    await _abrirChat(tester, fake);
    await _escribir(tester, 'Hola');
    fake.forzarFallo('intento-0');
    await _tocarEnviar(tester);
    await _asentar(tester);

    await tester.tap(find.byIcon(Icons.error_outline));
    await _asentar(tester);

    expect(fake.mensajesReales, hasLength(1));
    expect(fake.mensajesReales.single.id, 'intento-0');
  });

  testWidgets('6. el mismo texto enviado legítimamente dos veces por separado crea dos documentos distintos',
      (tester) async {
    await _abrirChat(tester, fake);

    await _escribir(tester, 'Hola');
    await _tocarEnviar(tester);
    await _asentar(tester);

    await _escribir(tester, 'Hola');
    await _tocarEnviar(tester);
    await _asentar(tester);

    expect(fake.mensajesReales, hasLength(2), reason: 'dos intentos legítimos deben existir, no fusionarse');
    expect(fake.mensajesReales.map((m) => m.id).toSet(), hasLength(2), reason: 'IDs distintos entre sí');
    expect(fake.mensajesReales.every((m) => m.texto == 'Hola'), isTrue);
  });

  testWidgets('7. dos mensajes distintos enviados rápidamente crean dos documentos, sin colisión', (tester) async {
    await _abrirChat(tester, fake);

    await _escribir(tester, 'Hola');
    await _tocarEnviar(tester);
    await _escribir(tester, 'Adiós');
    await _tocarEnviar(tester);
    await _asentar(tester);

    expect(fake.mensajesReales, hasLength(2));
    expect(fake.mensajesReales.map((m) => m.texto).toList(), ['Hola', 'Adiós']);
  });

  testWidgets('8. al confirmarse, el estado "pendiente" desaparece y no queda mensaje duplicado visualmente',
      (tester) async {
    await _abrirChat(tester, fake);
    await _escribir(tester, 'Hola');
    final puerta = fake.abrirPuerta('intento-0');
    await _tocarEnviar(tester);
    await tester.pump();

    expect(find.text('Hola'), findsOneWidget);
    puerta.complete();
    await _asentar(tester);

    // Sigue habiendo solo UNA burbuja con "Hola" — el optimista se
    // retiró al reconciliar por id con el mensaje real del stream.
    expect(find.text('Hola'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('9. salir y volver a entrar no deja un mensaje fantasma pendiente', (tester) async {
    final key1 = UniqueKey();
    await _abrirChat(tester, fake, key: key1);
    await _escribir(tester, 'Hola');
    fake.abrirPuerta('intento-0'); // nunca se completa: simula que la pantalla se cierra antes de confirmar
    await _tocarEnviar(tester);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Sale del chat (se destruye _ChatScreenState y su _pendientes local).
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    // Vuelve a entrar: instancia nueva, sin rastro del intento anterior.
    final key2 = UniqueKey();
    await _abrirChat(tester, fake, key: key2);
    await _asentar(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing, reason: 'no debe reaparecer un pendiente fantasma');
    expect(fake.mensajesReales, isEmpty, reason: 'el intento anterior nunca llegó a confirmarse');
  });

  testWidgets('10. un error real deja el mensaje en estado recuperable, reintentable por el usuario', (tester) async {
    await _abrirChat(tester, fake);
    await _escribir(tester, 'Hola');
    fake.forzarFallo('intento-0');
    await _tocarEnviar(tester);
    await _asentar(tester);

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Hola'), findsOneWidget, reason: 'el mensaje fallido sigue visible, no se pierde');

    await tester.tap(find.byIcon(Icons.error_outline));
    await _asentar(tester);

    expect(fake.mensajesReales, hasLength(1));
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });
}
