// Revisión de producto 2026-08-16: "Ignorar" debía volverse persistente
// (antes era un filtro puramente local — reaparecía en el siguiente
// sondeo de 10s). NearbyRequestsNotifier.ignorar() ahora llama al
// backend (ver ignorarSolicitud, postulacion.controller.ts) y es
// optimista: quita la solicitud de la lista al instante, y si la
// llamada falla la devuelve y relanza el error para que la pantalla
// pueda avisar (mismo patrón que DisponibilidadNotifier.actualizar).
//
// La persistencia real (que no vuelva tras el sondeo, en otro
// dispositivo, tras cerrar/reabrir la app, o para otra cuenta) vive en
// el backend — ver la migración de EstadoPostulacion.ignorada y
// listNearbyRequests. Este test solo prueba el contrato del notifier:
// que llama al backend y que el estado optimista se revierte si falla.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/models/service_request_model.dart';
import 'package:hogarsos/providers/service_request_provider.dart';
import 'package:hogarsos/services/service_request_service.dart';

/// Mismo patrón que _FakeServiceRequestService en
/// seguimiento_solicitud_doble_pulsacion_test.dart — sustituye la
/// llamada real al backend.
class _FakeServiceRequestService extends ServiceRequestService {
  int llamadasIgnorar = 0;
  String? ultimoIdIgnorado;
  bool lanzarError = false;

  @override
  Future<void> ignorar(String id) async {
    llamadasIgnorar++;
    ultimoIdIgnorado = id;
    if (lanzarError) throw Exception('fallo simulado de red');
  }

  // NearbyRequestsNotifier llama a cargar() -> listarCercanas() en su
  // propio constructor — sin este override, el constructor dispararía
  // una llamada HTTP real (ApiService) en cada test. Cada test fija
  // `notifier.state` a mano justo después, así que el resultado de esta
  // carga inicial no importa, solo que no toque la red de verdad.
  @override
  Future<List<NearbyRequest>> listarCercanas() async => const [];
}

NearbyRequest _solicitud(String id) {
  return NearbyRequest(
    id: id,
    descripcion: 'Grifo que gotea',
    distanciaMetros: 850,
    createdAt: DateTime(2026, 8, 16),
    clienteNombre: 'Cliente $id',
  );
}

/// El constructor de NearbyRequestsNotifier dispara su propia
/// cargar() (fire-and-forget) — sin esperar a que esa carga inicial
/// asiente antes de fijar el estado que cada test quiere probar, esa
/// carga de fondo puede resolver DESPUÉS y pisar el estado a mitad del
/// test (carrera real, no hipotética: así se descubrió). Un flush de
/// microtask (Future.delayed(Duration.zero) espera al menos un ciclo
/// completo del event loop, suficiente para un fake sin I/O real) deja
/// la carga inicial ya resuelta antes de que el test tome el control.
Future<NearbyRequestsNotifier> _crearNotifierConEstado(
  ServiceRequestService servicio,
  List<NearbyRequest> solicitudesIniciales,
) async {
  final notifier = NearbyRequestsNotifier(servicio);
  await Future<void>.delayed(Duration.zero);
  notifier.state = AsyncValue.data(solicitudesIniciales);
  return notifier;
}

void main() {
  group('NearbyRequestsNotifier.ignorar (persistencia real, no solo filtro local)', () {
    test('quita la solicitud de la lista y llama al backend', () async {
      final fake = _FakeServiceRequestService();
      final notifier = await _crearNotifierConEstado(fake, [_solicitud('a'), _solicitud('b')]);

      await notifier.ignorar('a');

      expect(notifier.state.value!.map((s) => s.id), ['b']);
      expect(fake.llamadasIgnorar, 1);
      expect(fake.ultimoIdIgnorado, 'a');

      notifier.dispose();
    });

    test('si la llamada al backend falla, la solicitud vuelve a la lista (revert optimista)', () async {
      final fake = _FakeServiceRequestService()..lanzarError = true;
      final notifier = await _crearNotifierConEstado(fake, [_solicitud('a'), _solicitud('b')]);

      await expectLater(notifier.ignorar('a'), throwsException);

      expect(notifier.state.value!.map((s) => s.id).toSet(), {'a', 'b'}, reason: 'debe revertir, no quedarse a medias');

      notifier.dispose();
    });

    test('un sondeo posterior (cargar) que ya no trae la solicitud ignorada confirma que no reaparece', () async {
      // Simula lo que hace el backend real: tras ignorar, listarCercanas()
      // ya no incluye esa solicitud (excluida por el WHERE de
      // listNearbyRequests). El notifier no necesita ningún estado propio
      // para esto — simplemente refleja lo que el backend devuelva.
      final fake = _FakeServiceRequestServiceConLista(['b']);
      final notifier = await _crearNotifierConEstado(fake, [_solicitud('a'), _solicitud('b')]);

      await notifier.ignorar('a');
      await notifier.cargar(); // sondeo de 10s simulado

      expect(notifier.state.value!.map((s) => s.id), ['b']);

      notifier.dispose();
    });

    test('ignorar una solicitud no afecta a otra distinta del mismo cliente', () async {
      final fake = _FakeServiceRequestService();
      final notifier = await _crearNotifierConEstado(fake, [_solicitud('a'), _solicitud('b')]);

      await notifier.ignorar('a');

      expect(notifier.state.value!.any((s) => s.id == 'b'), isTrue, reason: 'B no debe verse afectada por ignorar A');

      notifier.dispose();
    });
  });
}

class _FakeServiceRequestServiceConLista extends ServiceRequestService {
  _FakeServiceRequestServiceConLista(this._idsRestantes);
  final List<String> _idsRestantes;

  @override
  Future<void> ignorar(String id) async {}

  @override
  Future<List<NearbyRequest>> listarCercanas() async {
    return _idsRestantes.map(_solicitud).toList();
  }
}
