// Bug real (aprobado tras causa confirmada por código, auditoría
// 2026-08-15): un profesional podía tocar el push "nueva_solicitud"
// (nuevo trabajo cercano al que puede enviar candidatura) y aterrizar en
// "Trabajos activos" en vez de "Solicitudes" (pestaña 1, donde vive de
// verdad) — deep_link_listener.dart mandaba TODA notificación
// profesional no-chat a la pestaña 2. Confirmado con grep del backend:
// 'nueva_solicitud' es el ÚNICO tipo enviado a un profesional sobre una
// solicitud a la que todavía no está vinculado (nada aceptado, nada
// postulado); el resto (postulacion_aceptada, presupuesto_aceptado,
// cierre_horas_*, ampliacion_*...) sí son sobre un trabajo en el que ya
// está metido.
//
// Revisión UX 2026-08-16: la pestaña 2 dejó de ser "Trabajos activos"
// (ahora es Mensajes, solo conversaciones) — resolverPestanaDeNotificacionProfesional
// (que devolvía un índice de pestaña) se sustituyó por
// resolverDestinoNotificacionProfesional (que devuelve un DESTINO: la
// pestaña Solicitudes, o un push real a TrabajosActivosProfesionalScreen
// para todo lo demás — ver deep_link_listener.dart). El contrato de
// "nueva_solicitud → Solicitudes, resto → Trabajos" no cambia, solo CÓMO
// se llega a "Trabajos" (antes índice de pestaña, ahora push).
//
// Además, "Solicitudes" no tenía ningún indicador persistente dentro de
// la app (a diferencia de "Mensajes", que sí tiene
// _BadgeMensajesProfesional) — ni entrando por casualidad era obvio que
// hubiera algo nuevo.
//
// Fix (2026-08-15): 'nueva_solicitud' se enruta a Solicitudes (resto
// intacto, sigue yendo a Trabajos activos) + badge simple en la pestaña,
// contando solicitudes cercanas sin postular. Sin estado "visto"
// persistente ni notifier nuevo: una solicitud sale sola de la lista al
// postularse, ignorarse o expirar (ver NearbyRequestsNotifier en
// service_request_provider.dart), así que "cuántas hay sin postular
// ahora mismo" ya es la señal correcta.
//
// 'chat_mensaje' (tercer tipo pedido en la revisión) no se prueba aquí
// aparte: ese bloque de deep_link_listener.dart (empuja ChatScreen,
// nunca pasa por resolverDestinoNotificacionProfesional) no se tocó en
// absoluto en ninguno de los dos cambios.

import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/models/service_request_model.dart';
import 'package:hogarsos/screens/profesional_shell_screen.dart';

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
  group('resolverDestinoNotificacionProfesional (función pura de decisión)', () {
    test('nueva_solicitud → Solicitudes', () {
      expect(resolverDestinoNotificacionProfesional('nueva_solicitud'), DestinoNotificacionProfesional.solicitudes);
    });

    test('postulacion_aceptada → Trabajos activos (push, ya no es pestaña)', () {
      expect(
          resolverDestinoNotificacionProfesional('postulacion_aceptada'), DestinoNotificacionProfesional.trabajosActivos);
    });

    test('presupuesto_aceptado → Trabajos activos (comportamiento previo intacto)', () {
      expect(
          resolverDestinoNotificacionProfesional('presupuesto_aceptado'), DestinoNotificacionProfesional.trabajosActivos);
    });

    test('cierre_horas_aceptado / pendiente / rechazado → Trabajos activos', () {
      expect(resolverDestinoNotificacionProfesional('cierre_horas_aceptado'), DestinoNotificacionProfesional.trabajosActivos);
      expect(resolverDestinoNotificacionProfesional('cierre_horas_pendiente'), DestinoNotificacionProfesional.trabajosActivos);
      expect(
          resolverDestinoNotificacionProfesional('cierre_horas_rechazado'), DestinoNotificacionProfesional.trabajosActivos);
    });

    test('ampliacion_aceptada / rechazada → Trabajos activos', () {
      expect(resolverDestinoNotificacionProfesional('ampliacion_aceptada'), DestinoNotificacionProfesional.trabajosActivos);
      expect(resolverDestinoNotificacionProfesional('ampliacion_rechazada'), DestinoNotificacionProfesional.trabajosActivos);
    });

    test('pago_autorizado → Centro de Pagos (E2E 2026-08-18: habla de dinero, no de tarea)', () {
      expect(resolverDestinoNotificacionProfesional('pago_autorizado'), DestinoNotificacionProfesional.centroPagos);
    });

    test('tipo desconocido o null → Trabajos activos por defecto (comportamiento previo intacto)', () {
      expect(resolverDestinoNotificacionProfesional(null), DestinoNotificacionProfesional.trabajosActivos);
      expect(resolverDestinoNotificacionProfesional('algo_no_mapeado'), DestinoNotificacionProfesional.trabajosActivos);
    });
  });

  group('contarTrabajosNuevosSinVer (indicador de la tarjeta "Tienes X trabajos activos")', () {
    AssignedRequest trabajo({required String id, required EstadoSolicitud estado}) {
      return AssignedRequest(
        id: id,
        categoria: 'fontaneria',
        descripcion: 'Grifo que gotea',
        estado: estado,
        clienteNombre: 'Cliente $id',
        createdAt: DateTime(2026, 8, 16),
        tienePago: false,
        tieneValoracion: false,
      );
    }

    test('lista vacía → 0', () {
      expect(contarTrabajosNuevosSinVer(const [], const {}), 0);
    });

    test('trabajo aceptado no visto → cuenta 1', () {
      final trabajos = [trabajo(id: 'a', estado: EstadoSolicitud.aceptada)];
      expect(contarTrabajosNuevosSinVer(trabajos, const {}), 1);
    });

    test('trabajo aceptado ya visto → 0', () {
      final trabajos = [trabajo(id: 'a', estado: EstadoSolicitud.aceptada)];
      expect(contarTrabajosNuevosSinVer(trabajos, {'a'}), 0);
    });

    test('trabajo en_progreso o completado no cuenta, aunque no esté en vistos (solo "aceptada" es "recién elegido")', () {
      final trabajos = [
        trabajo(id: 'a', estado: EstadoSolicitud.en_progreso),
        trabajo(id: 'b', estado: EstadoSolicitud.completada),
      ];
      expect(contarTrabajosNuevosSinVer(trabajos, const {}), 0);
    });

    test('varios trabajos, mezcla de vistos/no vistos → cuenta exacta', () {
      final trabajos = [
        trabajo(id: 'a', estado: EstadoSolicitud.aceptada),
        trabajo(id: 'b', estado: EstadoSolicitud.aceptada),
        trabajo(id: 'c', estado: EstadoSolicitud.aceptada),
      ];
      expect(contarTrabajosNuevosSinVer(trabajos, {'b'}), 2);
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
