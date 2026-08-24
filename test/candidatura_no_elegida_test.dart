// Auditoría UX 2026-08-25 — "candidatura no elegida".
//
// Flujo real hoy (ver selectPostulacion en postulacion.controller.ts y
// listNearbyRequests en serviceRequest.controller.ts, backend):
//   1. El cliente elige a OTRO profesional → la solicitud pasa a
//      'aceptada', la candidatura de este profesional a 'rechazada', y se
//      le envía el push 'postulacion_rechazada' ("Selección finalizada /
//      El cliente ha seleccionado a otro profesional").
//   2. listNearbyRequests solo devuelve solicitudes 'pendiente' → en la
//      siguiente recarga la tarjeta "Candidatura enviada" desaparece.
//
// Dos bugs de app puros que este archivo fija por contrato:
//   - Tocar esa notificación aterrizaba en Trabajos activos (fallback de
//     resolverDestinoNotificacionProfesional), un sitio donde ese
//     profesional no tiene nada — ahora va a "Solicitudes".
//   - Entre el push y el siguiente sondeo de 10s la lista en memoria
//     seguía diciendo "Candidatura enviada"; deep_link_listener.dart
//     ahora recarga al tocar. Aquí se prueba el contrato del notifier
//     del que depende esa recarga: si el backend deja de devolver la
//     solicitud, cargar() la quita de la lista sin tocar las demás.
//
// Lo que NO cubre (y no puede, sin backend): mostrar "Solicitud cerrada
// — El cliente ha elegido a otro profesional" de forma persistente
// después de esa recarga. Hoy la tarjeta simplemente desaparece.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/models/service_request_model.dart';
import 'package:hogarsos/providers/service_request_provider.dart';
import 'package:hogarsos/screens/profesional_shell_screen.dart';
import 'package:hogarsos/services/service_request_service.dart';

/// Mismo patrón que nearby_requests_ignorar_test.dart: sustituye la
/// llamada real al backend y devuelve lo que "el servidor" devolvería.
class _FakeServiceRequestService extends ServiceRequestService {
  List<NearbyRequest> respuestaServidor = const [];
  int llamadasListar = 0;

  @override
  Future<List<NearbyRequest>> listarCercanas() async {
    llamadasListar++;
    return respuestaServidor;
  }
}

NearbyRequest _solicitud(String id, {bool yaPostulado = false}) {
  return NearbyRequest(
    id: id,
    descripcion: 'Solicitud $id',
    distanciaMetros: 900,
    createdAt: DateTime(2026, 8, 25),
    clienteNombre: 'Cliente $id',
    yaPostulado: yaPostulado,
  );
}

void main() {
  group('Notificación "Selección finalizada" (postulacion_rechazada)', () {
    test('lleva a Solicitudes, no a Trabajos activos', () {
      expect(
        resolverDestinoNotificacionProfesional('postulacion_rechazada'),
        DestinoNotificacionProfesional.solicitudes,
      );
    });

    test('el elegido ("¡Te han elegido!") sigue yendo a Trabajos activos', () {
      expect(
        resolverDestinoNotificacionProfesional('postulacion_aceptada'),
        DestinoNotificacionProfesional.trabajosActivos,
      );
    });
  });

  group('NearbyRequestsNotifier.cargar tras elegir el cliente a otro profesional', () {
    test('la solicitud con "Candidatura enviada" desaparece y las demás quedan intactas', () async {
      final servicio = _FakeServiceRequestService();
      // Estado antes de que el cliente eligiera: A (con candidatura de
      // este profesional) y B (otra solicitud pendiente, sin postular).
      servicio.respuestaServidor = [_solicitud('A', yaPostulado: true), _solicitud('B')];
      final notifier = NearbyRequestsNotifier(servicio);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.value!.map((s) => s.id), ['A', 'B']);
      expect(notifier.state.value!.first.yaPostulado, isTrue);

      // El cliente elige a otro: el backend deja de devolver A (ya no
      // está 'pendiente'). Es exactamente lo que ve deep_link_listener
      // al recargar tras tocar la notificación, o el sondeo de 10s.
      servicio.respuestaServidor = [_solicitud('B')];
      await notifier.cargar();

      expect(notifier.state.value!.map((s) => s.id), ['B']);
      expect(notifier.state.value!.single.yaPostulado, isFalse);
      expect(servicio.llamadasListar, 2);
    });

    test('la recarga no pasa por loading (la lista visible no parpadea)', () async {
      final servicio = _FakeServiceRequestService();
      servicio.respuestaServidor = [_solicitud('A', yaPostulado: true)];
      final notifier = NearbyRequestsNotifier(servicio);
      await Future<void>.delayed(Duration.zero);

      servicio.respuestaServidor = const [];
      final futuro = notifier.cargar();
      // Justo después de lanzar la recarga, el estado sigue siendo el
      // dato anterior (no AsyncLoading) — contrato ya existente del
      // notifier del que depende que la recarga al tocar sea invisible.
      expect(notifier.state, isA<AsyncData<List<NearbyRequest>>>());
      await futuro;
      expect(notifier.state.value, isEmpty);
    });
  });
}
