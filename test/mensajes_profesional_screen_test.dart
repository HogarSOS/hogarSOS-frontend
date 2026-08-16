// MensajesProfesionalScreen (revisión UX 2026-08-16): antes la pestaña
// "Mensajes" del profesional mostraba en realidad TrabajosActivosProfesionalScreen
// (tarjetas con Chat, Enviar presupuesto, Reportar...). Estos tests
// prueban la pantalla nueva — lista limpia de conversaciones, mismo
// patrón que ya usa el cliente en mensajes_screen.dart — de forma
// aislada, sin montar ProfesionalShellScreen entero (que arrastra
// disponibilidad, solicitudes cercanas, trabajosVistosProvider con
// flutter_secure_storage, AppBadgeService...).
//
// unreadChatProvider se sobreescribe directamente por completo (en vez
// de sobreescribir chatServiceProvider y dejar que resuelva el booleano
// de verdad) porque su implementación real lee FirebaseAuth.instance sin
// ningún hook de test — este proyecto evita a propósito requerir
// Firebase.initializeApp() en la suite de tests (ver test/widget_test.dart).
// Sobreescribir el propio provider (soportado por family providers de
// Riverpod) dejó fuera esa dependencia sin tocar el widget de producción.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/l10n/app_localizations.dart';
import 'package:hogarsos/models/service_request_model.dart';
import 'package:hogarsos/providers/chat_read_provider.dart';
import 'package:hogarsos/providers/service_request_provider.dart';
import 'package:hogarsos/screens/chat_screen.dart';
import 'package:hogarsos/screens/profesional/mensajes_profesional_screen.dart';
import 'package:hogarsos/services/service_request_service.dart';

AssignedRequest _trabajo({
  required String id,
  required String clienteNombre,
  EstadoSolicitud estado = EstadoSolicitud.aceptada,
}) {
  return AssignedRequest(
    id: id,
    categoria: 'fontaneria',
    descripcion: 'Grifo que gotea',
    estado: estado,
    clienteNombre: clienteNombre,
    createdAt: DateTime(2026, 8, 16),
    tienePago: false,
    tieneValoracion: false,
  );
}

class _FakeServiceRequestService extends ServiceRequestService {
  _FakeServiceRequestService(this._trabajos);
  final List<AssignedRequest> _trabajos;

  @override
  Future<List<AssignedRequest>> listarTrabajosAsignados() async => _trabajos;
}

/// Captura la última ruta empujada de forma SÍNCRONA (didPush corre
/// dentro del propio Navigator.push, antes de que el frame que
/// construiría de verdad esa pantalla llegue a pintarse) — permite
/// comprobar qué widget exacto se pediría montar sin necesidad de
/// montarlo. Necesario aquí porque ChatScreen real llama a
/// FirebaseFirestore.instance/FirebaseAuth.instance sin ningún hook de
/// test cuando se navega a él tal cual lo hace la producción (sin
/// miUidOverride) — este proyecto evita a propósito requerir
/// Firebase.initializeApp() en la suite de tests (test/widget_test.dart).
class _ObservadorNavegacion extends NavigatorObserver {
  Route<dynamic>? ultimaRutaEmpujada;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    ultimaRutaEmpujada = route;
  }
}

Widget _pantallaDePrueba({
  required List<AssignedRequest> trabajos,
  Map<String, bool> noLeidos = const {},
  NavigatorObserver? observador,
}) {
  return ProviderScope(
    overrides: [
      serviceRequestServiceProvider.overrideWithValue(_FakeServiceRequestService(trabajos)),
      unreadChatProvider.overrideWith((ref, id) => noLeidos[id] ?? false),
    ],
    child: MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: observador != null ? [observador] : const [],
      home: const MensajesProfesionalScreen(),
    ),
  );
}

void main() {
  testWidgets('múltiples conversaciones: se lista una fila por trabajo aceptado/en curso', (tester) async {
    await tester.pumpWidget(_pantallaDePrueba(trabajos: [
      _trabajo(id: 't1', clienteNombre: 'Ana'),
      _trabajo(id: 't2', clienteNombre: 'Luis', estado: EstadoSolicitud.en_progreso),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Luis'), findsOneWidget);
  });

  testWidgets('trabajo completado no aparece en Mensajes (solo Trabajos activos lo sigue mostrando)', (tester) async {
    await tester.pumpWidget(_pantallaDePrueba(trabajos: [
      _trabajo(id: 't1', clienteNombre: 'Ana', estado: EstadoSolicitud.completada),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsNothing);
  });

  testWidgets('sin trabajos activos → estado vacío, sin crashear', (tester) async {
    await tester.pumpWidget(_pantallaDePrueba(trabajos: const []));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
  });

  testWidgets('conversación no leída: negrita + punto rojo, no el icono de chat', (tester) async {
    await tester.pumpWidget(_pantallaDePrueba(
      trabajos: [_trabajo(id: 't1', clienteNombre: 'Ana')],
      noLeidos: {'t1': true},
    ));
    await tester.pumpAndSettle();

    final titulo = tester.widget<Text>(find.text('Ana'));
    expect(titulo.style?.fontWeight, FontWeight.w800);
    expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
  });

  testWidgets('conversación leída: peso normal + icono de chat, sin punto rojo', (tester) async {
    await tester.pumpWidget(_pantallaDePrueba(
      trabajos: [_trabajo(id: 't1', clienteNombre: 'Ana')],
      noLeidos: {'t1': false},
    ));
    await tester.pumpAndSettle();

    final titulo = tester.widget<Text>(find.text('Ana'));
    expect(titulo.style?.fontWeight, FontWeight.w600);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
  });

  testWidgets('tocar una conversación pide navegar a ChatScreen con el serviceRequestId y el nombre correctos', (tester) async {
    final observador = _ObservadorNavegacion();
    await tester.pumpWidget(_pantallaDePrueba(
      trabajos: [
        _trabajo(id: 't1', clienteNombre: 'Ana'),
        _trabajo(id: 't2', clienteNombre: 'Luis'),
      ],
      observador: observador,
    ));
    await tester.pumpAndSettle();

    // Sin pump() después del tap a propósito: Navigator.push() llama a
    // didPush() de forma síncrona dentro del propio manejador onTap, así
    // que la ruta ya queda capturada aquí — un pump() posterior sí
    // llegaría a construir el ChatScreen real (y ahí sí haría falta
    // Firebase, que esta suite evita).
    await tester.tap(find.text('Luis'));

    final ruta = observador.ultimaRutaEmpujada;
    expect(ruta, isA<MaterialPageRoute>());
    // Invoca el MISMO builder que usaría la Navigation real — construye
    // el objeto ChatScreen (una llamada a constructor normal, sin
    // BuildContext real de por medio) sin llegar a montarlo/pintarlo.
    final widgetConstruido = (ruta as MaterialPageRoute).builder(tester.element(find.byType(MensajesProfesionalScreen)));
    expect(widgetConstruido, isA<ChatScreen>());
    final chat = widgetConstruido as ChatScreen;
    expect(chat.serviceRequestId, 't2');
    expect(chat.nombreContraparte, 'Luis');
  });
}
