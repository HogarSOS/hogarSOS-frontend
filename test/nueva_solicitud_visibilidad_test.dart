// Bug real (aprobado tras causa confirmada por código): un profesional
// podía tocar el push "nueva_solicitud" (nuevo trabajo cercano al que
// puede enviar candidatura) y aterrizar en "Trabajos activos" (pestaña
// 2) en vez de "Solicitudes" (pestaña 1, donde vive de verdad) —
// deep_link_listener.dart mandaba TODA notificación profesional no-chat
// a la pestaña 2. Confirmado con grep del backend: 'nueva_solicitud' es
// el ÚNICO tipo enviado a un profesional sobre una solicitud a la que
// todavía no está vinculado (nada aceptado, nada postulado); el resto
// (postulacion_aceptada, presupuesto_aceptado, cierre_horas_*...) sí son
// sobre un trabajo en el que ya está metido, y pertenecen correctamente
// a la pestaña 2.
//
// Además, "Solicitudes" no tenía ningún indicador persistente dentro de
// la app (a diferencia de "Mensajes"/Trabajos activos, que sí tiene
// _BadgeMensajesProfesional) — ni entrando por casualidad era obvio que
// hubiera algo nuevo.
//
// Fix: 'nueva_solicitud' se enruta a la pestaña 1 (resto intacto, sigue
// yendo a la 2) + badge simple en la pestaña, contando solicitudes
// cercanas sin postular. Sin estado "visto" persistente ni notifier
// nuevo: una solicitud sale sola de la lista al postularse, ignorarse o
// expirar (ver NearbyRequestsNotifier en service_request_provider.dart),
// así que "cuántas hay sin postular ahora mismo" ya es la señal correcta.
//
// 'chat_mensaje' (tercer tipo pedido en la revisión) no se prueba aquí
// aparte: ese bloque de deep_link_listener.dart (empuja ChatScreen,
// nunca cambia de pestaña) no se tocó en absoluto en este cambio —
// verificado por inspección del diff, cero líneas modificadas ahí.

import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/models/service_request_model.dart';
import 'package:hogarsos/screens/profesional_shell_screen.dart';
import 'package:hogarsos/services/deep_link_listener.dart';

NearbyRequest _solicitud({required String id, bool yaPostulado = false}) {
  return NearbyRequest(
    id: id,
    descripcion: 'Grifo que gotea',
    distanciaMetros: 850,
    createdAt: DateTime(2026, 8, 16),
    clienteNombre: 'Cliente $id',
    yaPostulado: yaPostulado,
  );
}

void main() {
  group('resolverPestanaDeNotificacionProfesional (función pura de decisión)', () {
    test('nueva_solicitud → pestaña 1 (Solicitudes)', () {
      expect(resolverPestanaDeNotificacionProfesional('nueva_solicitud'), 1);
    });

    test('postulacion_aceptada → sigue yendo a pestaña 2 (Trabajos activos)', () {
      expect(resolverPestanaDeNotificacionProfesional('postulacion_aceptada'), 2);
    });

    test('presupuesto_aceptado → pestaña 2 (comportamiento previo intacto)', () {
      expect(resolverPestanaDeNotificacionProfesional('presupuesto_aceptado'), 2);
    });

    test('cierre_horas_aceptado / pendiente / rechazado → pestaña 2', () {
      expect(resolverPestanaDeNotificacionProfesional('cierre_horas_aceptado'), 2);
      expect(resolverPestanaDeNotificacionProfesional('cierre_horas_pendiente'), 2);
      expect(resolverPestanaDeNotificacionProfesional('cierre_horas_rechazado'), 2);
    });

    test('tipo desconocido o null → pestaña 2 por defecto (comportamiento previo intacto)', () {
      expect(resolverPestanaDeNotificacionProfesional(null), 2);
      expect(resolverPestanaDeNotificacionProfesional('algo_no_mapeado'), 2);
    });
  });

  group('contarSolicitudesSinPostular (badge de la pestaña Solicitudes, sin estado persistente)', () {
    test('lista vacía → 0', () {
      expect(contarSolicitudesSinPostular(const []), 0);
    });

    test('varias solicitudes sin postular → cuenta exacta', () {
      final lista = [_solicitud(id: 'a'), _solicitud(id: 'b'), _solicitud(id: 'c')];
      expect(contarSolicitudesSinPostular(lista), 3);
    });

    test('no cuenta las ya postuladas', () {
      final lista = [_solicitud(id: 'a', yaPostulado: true), _solicitud(id: 'b')];
      expect(contarSolicitudesSinPostular(lista), 1);
    });

    test('todas postuladas → 0 (el badge debe ocultarse, isLabelVisible: numSinPostular > 0)', () {
      final lista = [_solicitud(id: 'a', yaPostulado: true), _solicitud(id: 'b', yaPostulado: true)];
      expect(contarSolicitudesSinPostular(lista), 0);
    });

    test('al postularse a una solicitud, el contador disminuye', () {
      final antes = [_solicitud(id: 'a'), _solicitud(id: 'b')];
      expect(contarSolicitudesSinPostular(antes), 2);

      // El backend devuelve la misma solicitud con ya_postulado=true tras
      // postularse (ver listNearbyRequests, serviceRequest.controller.ts)
      // — no desaparece de la lista hasta que expira o se ignora.
      final despues = [_solicitud(id: 'a', yaPostulado: true), _solicitud(id: 'b')];
      expect(contarSolicitudesSinPostular(despues), 1);
    });

    test('cambio de cuenta (lista completamente distinta) → cuenta correcta para la cuenta nueva, sin arrastrar la anterior', () {
      final cuentaA = [_solicitud(id: 'a1'), _solicitud(id: 'a2', yaPostulado: true)];
      expect(contarSolicitudesSinPostular(cuentaA), 1);

      // Un profesional distinto inicia sesión — nearbyRequestsProvider se
      // recarga con la lista de la cuenta nueva (HomeProfesionalScreen
      // llama a cargar() al montar). El badge es un ConsumerWidget que
      // solo hace ref.watch(nearbyRequestsProvider) — no guarda nada
      // propio que pueda arrastrar la cuenta anterior, recalcula desde
      // cero con cualquier lista que le llegue.
      final cuentaB = [_solicitud(id: 'b1'), _solicitud(id: 'b2'), _solicitud(id: 'b3')];
      expect(contarSolicitudesSinPostular(cuentaB), 3);
    });
  });
}
