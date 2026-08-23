// Hallazgo F3 de la auditoría del build 40 (2026-08-23): los providers
// de solicitudes cercanas y trabajos asignados sobrevivían a un cambio
// de cuenta (logout de A + login de B en el mismo dispositivo) y la
// cuenta B veía los datos de A hasta que el sondeo de 10s recargaba.
// El fix replica el de disponibilidadProvider (2026-08-22): el provider
// observa authProvider y se reconstruye al cambiar el usuario, con dos
// mecanismos que se prueban aquí directamente (sin AuthNotifier real,
// que en su constructor llama a Firebase — mismo criterio que
// deep_link_stripe_pendiente_test.dart):
//
// 1. `autoCargar: false` (sesión de cliente o sin sesión): el notifier
//    no dispara ninguna petición en el constructor.
// 2. Guard `mounted` en cargar(): una respuesta que llega DESPUÉS de
//    que el notifier fuera descartado (porque el usuario cambió y
//    Riverpod lo reconstruyó) no escribe estado ni revienta.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/models/service_request_model.dart';
import 'package:hogarsos/providers/service_request_provider.dart';
import 'package:hogarsos/services/service_request_service.dart';

class _ServicioControlado extends ServiceRequestService {
  int llamadasCercanas = 0;
  int llamadasAsignados = 0;
  final cercanas = Completer<List<NearbyRequest>>();
  final asignados = Completer<List<AssignedRequest>>();

  @override
  Future<List<NearbyRequest>> listarCercanas() {
    llamadasCercanas++;
    return cercanas.future;
  }

  @override
  Future<List<AssignedRequest>> listarTrabajosAsignados() {
    llamadasAsignados++;
    return asignados.future;
  }
}

void main() {
  group('NearbyRequestsNotifier — cambio de cuenta (F3)', () {
    test('autoCargar: false no dispara ninguna petición', () {
      final servicio = _ServicioControlado();
      final notifier = NearbyRequestsNotifier(servicio, autoCargar: false);
      expect(servicio.llamadasCercanas, 0);
      expect(notifier.state.isLoading, isTrue);
      notifier.dispose();
    });

    test('una respuesta tardía tras dispose no escribe ni revienta', () async {
      final servicio = _ServicioControlado();
      final notifier = NearbyRequestsNotifier(servicio, autoCargar: true);
      expect(servicio.llamadasCercanas, 1);

      // El usuario cambia de cuenta: Riverpod descartaría este notifier.
      notifier.dispose();

      // La respuesta de la cuenta ANTERIOR llega después del dispose —
      // sin el guard `mounted`, StateNotifier lanza al asignar state.
      servicio.cercanas.complete(const []);
      await pumpEventQueue();
      // Si llegamos aquí sin excepción, el guard funcionó.
    });

    test('el error tardío tras dispose tampoco escribe ni revienta', () async {
      final servicio = _ServicioControlado();
      final notifier = NearbyRequestsNotifier(servicio, autoCargar: true);
      notifier.dispose();
      servicio.cercanas.completeError(Exception('red caída de la cuenta A'));
      await pumpEventQueue();
    });
  });

  group('AssignedRequestsNotifier — cambio de cuenta (F3)', () {
    test('autoCargar: false no dispara ninguna petición', () {
      final servicio = _ServicioControlado();
      final notifier = AssignedRequestsNotifier(servicio, autoCargar: false);
      expect(servicio.llamadasAsignados, 0);
      expect(notifier.state.isLoading, isTrue);
      notifier.dispose();
    });

    test('una respuesta tardía tras dispose no escribe ni revienta', () async {
      final servicio = _ServicioControlado();
      final notifier = AssignedRequestsNotifier(servicio, autoCargar: true);
      expect(servicio.llamadasAsignados, 1);
      notifier.dispose();
      servicio.asignados.complete(const []);
      await pumpEventQueue();
    });
  });
}
