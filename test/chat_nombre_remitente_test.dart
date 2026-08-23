// Nombre del remitente en el chat (Build 43, UX): etiqueta con el nombre
// público de la contraparte SOLO en la primera burbuja de cada racha de
// sus mensajes — nunca en las burbujas propias, nunca repetida en
// mensajes consecutivos. Resolución dinámica desde nombreContraparte (el
// mismo nombre que ya muestran el AppBar y las listas), jamás guardada
// dentro del mensaje: un cambio de nombre o la anonimización RGPD
// ("Usuario eliminado") se reflejan también en los mensajes antiguos.

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

/// Fake mínimo de solo lectura: sirve una lista fija de mensajes por el
/// stream (como haría Firestore al abrir la conversación) — aquí no se
/// prueba el envío, eso vive en chat_screen_duplicacion_test.dart.
class _FakeChatLectura implements ChatServiceBase {
  _FakeChatLectura(this._mensajes);

  final List<ChatMessage> _mensajes;

  @override
  Stream<List<ChatMessage>> observarMensajes(String serviceRequestId) =>
      Stream.value(List.unmodifiable(_mensajes));

  @override
  Stream<ChatMessage?> observarUltimoMensaje(String serviceRequestId) =>
      Stream.value(_mensajes.isEmpty ? null : _mensajes.last);

  @override
  Stream<EstadoLecturaChat> observarEstadoLectura(String serviceRequestId) =>
      Stream.value(EstadoLecturaChat.vacio);

  @override
  String nuevoIdIntento(String serviceRequestId) => 'intento-x';

  @override
  Future<void> enviarMensaje({
    required String serviceRequestId,
    required String intentoId,
    required String texto,
    required String autorId,
  }) async {}
}

ChatMessage _msg(String id, String autorId, String texto) =>
    ChatMessage(id: id, texto: texto, autorId: autorId, enviadoEn: DateTime(2026, 8, 23, 12));

Future<void> _abrir(
  WidgetTester tester,
  List<ChatMessage> mensajes, {
  String? nombreContraparte,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [chatServiceProvider.overrideWithValue(_FakeChatLectura(mensajes))],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChatScreen(
          serviceRequestId: 'sr-1',
          servicioSolicitud: _FakeServicioSolicitud(),
          miUidOverride: 'uid-yo',
          nombreContraparte: nombreContraparte,
        ),
      ),
    ),
  );
  await tester.pump(); // _prepararChat() con fakes
  await tester.pump(); // primera emisión del stream
}

void main() {
  testWidgets('el nombre aparece solo al inicio de cada racha de la contraparte', (tester) async {
    await _abrir(
      tester,
      [
        _msg('m1', 'uid-otro', 'Hola'),
        _msg('m2', 'uid-otro', '¿Puedes venir mañana?'),
        _msg('m3', 'uid-yo', 'Sí, a las 18:00'),
        _msg('m4', 'uid-otro', 'Perfecto'),
      ],
      nombreContraparte: 'Ana',
    );

    // 'Ana' está en el AppBar (1) + inicio de las DOS rachas de la
    // contraparte (m1 y m4) — nunca sobre m2 (racha ya empezada) ni
    // sobre el mensaje propio m3.
    expect(find.text('Ana'), findsNWidgets(3));
  });

  testWidgets('las burbujas propias nunca llevan nombre, aunque abran la conversación', (tester) async {
    await _abrir(
      tester,
      [
        _msg('m1', 'uid-yo', 'Hola, ¿está disponible?'),
        _msg('m2', 'uid-yo', '¿Me confirma?'),
      ],
      nombreContraparte: 'Ana',
    );

    // Solo el AppBar: ninguna etiqueta sobre mensajes propios.
    expect(find.text('Ana'), findsOneWidget);
  });

  testWidgets('sin nombre disponible no hay etiqueta ni error (fallback silencioso)', (tester) async {
    await _abrir(
      tester,
      [
        _msg('m1', 'uid-otro', 'Hola'),
        _msg('m2', 'uid-yo', 'Hola, dime'),
      ],
      nombreContraparte: null,
    );

    expect(find.text('Hola'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
