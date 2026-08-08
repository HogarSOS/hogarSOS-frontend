import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/models/admin_models.dart';

void main() {
  group('StuckPayment.fromJson', () {
    test('parsea un pago capturado sin transferir, con todos los campos', () {
      final pago = StuckPayment.fromJson({
        'paymentId': 'pago-1',
        'serviceRequestId': 'sr-1',
        'estado': 'capturado',
        'estadoSolicitud': 'completada',
        'categoria': 'Aire acondicionado',
        'clienteNombre': 'Ana Sánchez',
        'profesionalNombre': 'José Fernández',
        'montoProfesional': 95.5,
        'capturadoAt': '2026-08-04T09:00:00.000Z',
        'createdAt': '2026-08-03T09:00:00.000Z',
        'intentosLiberacion': 2,
        'ultimoError': 'Stripe timeout',
        'dineroRetenidoEnPlataforma': true,
      });

      expect(pago.paymentId, 'pago-1');
      expect(pago.clienteNombre, 'Ana Sánchez');
      expect(pago.profesionalNombre, 'José Fernández');
      expect(pago.montoProfesional, 95.5);
      expect(pago.capturadoAt, DateTime.parse('2026-08-04T09:00:00.000Z'));
      expect(pago.intentosLiberacion, 2);
      expect(pago.ultimoError, 'Stripe timeout');
      expect(pago.dineroRetenidoEnPlataforma, true);
    });

    // El backend puede devolver profesionalNombre/capturadoAt/ultimoError
    // como null (ver PagoAtascado en payment.service.ts) — un pago
    // 'retenido' con la solicitud completada nunca llegó a capturarse,
    // así que no tiene fecha de captura ni profesional garantizado.
    test('acepta profesionalNombre, capturadoAt y ultimoError nulos sin reventar', () {
      final pago = StuckPayment.fromJson({
        'paymentId': 'pago-2',
        'serviceRequestId': 'sr-2',
        'estado': 'retenido',
        'estadoSolicitud': 'completada',
        'categoria': 'Fontanería',
        'clienteNombre': 'Luis Pérez',
        'profesionalNombre': null,
        'montoProfesional': 40,
        'capturadoAt': null,
        'createdAt': '2026-08-03T10:00:00.000Z',
        'intentosLiberacion': 0,
        'ultimoError': null,
        'dineroRetenidoEnPlataforma': false,
      });

      expect(pago.profesionalNombre, isNull);
      expect(pago.capturadoAt, isNull);
      expect(pago.ultimoError, isNull);
      expect(pago.dineroRetenidoEnPlataforma, false);
    });
  });

  group('StuckPaymentsSummary.fromJson', () {
    test('parsea el resumen con su lista de pagos', () {
      final resumen = StuckPaymentsSummary.fromJson({
        'total': 2,
        'importeRetenidoEnPlataforma': 95.5,
        'pagos': [
          {
            'paymentId': 'pago-1',
            'serviceRequestId': 'sr-1',
            'estado': 'capturado',
            'estadoSolicitud': 'completada',
            'categoria': 'Aire acondicionado',
            'clienteNombre': 'Ana Sánchez',
            'profesionalNombre': 'José Fernández',
            'montoProfesional': 95.5,
            'capturadoAt': '2026-08-04T09:00:00.000Z',
            'createdAt': '2026-08-03T09:00:00.000Z',
            'intentosLiberacion': 2,
            'ultimoError': null,
            'dineroRetenidoEnPlataforma': true,
          },
        ],
      });

      expect(resumen.total, 2);
      expect(resumen.importeRetenidoEnPlataforma, 95.5);
      expect(resumen.pagos, hasLength(1));
      expect(resumen.pagos.first.paymentId, 'pago-1');
    });

    test('parsea una lista vacía sin errores', () {
      final resumen = StuckPaymentsSummary.fromJson({
        'total': 0,
        'importeRetenidoEnPlataforma': 0,
        'pagos': [],
      });

      expect(resumen.total, 0);
      expect(resumen.pagos, isEmpty);
    });
  });

  group('ScheduledJob.fromJson', () {
    test('parsea una tarea que ya se ejecutó, con resultado', () {
      final tarea = ScheduledJob.fromJson({
        'nombre': 'reintentar-pagos-atascados',
        'descripcion': 'Reintenta capturar/transferir pagos atascados',
        'intervaloMinutos': 10,
        'ultimaEjecucionAt': '2026-08-08T09:00:00.000Z',
        'proximaEjecucionAprox': '2026-08-08T09:10:00.000Z',
        'enCurso': false,
        'ejecuciones': 42,
        'fallosConsecutivos': 0,
        'ultimoResultado': '0 pagos atascados encontrados',
        'ultimoError': null,
      });

      expect(tarea.nombre, 'reintentar-pagos-atascados');
      expect(tarea.intervaloMinutos, 10);
      expect(tarea.ultimaEjecucionAt, DateTime.parse('2026-08-08T09:00:00.000Z'));
      expect(tarea.enCurso, false);
      expect(tarea.ejecuciones, 42);
      expect(tarea.ultimoResultado, '0 pagos atascados encontrados');
      expect(tarea.ultimoError, isNull);
    });

    // Una tarea que nunca se ejecutó (recién desplegada) no tiene
    // ultimaEjecucionAt/proximaEjecucionAprox/ultimoResultado/ultimoError
    // — ver listJobs en admin.controller.ts, todos nullable.
    test('acepta una tarea que nunca se ha ejecutado, con campos nulos', () {
      final tarea = ScheduledJob.fromJson({
        'nombre': 'limpiar-archivos-huerfanos',
        'descripcion': 'Borra archivos subidos que ya no están en uso',
        'intervaloMinutos': 1440,
        'ultimaEjecucionAt': null,
        'proximaEjecucionAprox': null,
        'enCurso': false,
        'ejecuciones': 0,
        'fallosConsecutivos': 0,
        'ultimoResultado': null,
        'ultimoError': null,
      });

      expect(tarea.ultimaEjecucionAt, isNull);
      expect(tarea.proximaEjecucionAprox, isNull);
      expect(tarea.ultimoResultado, isNull);
      expect(tarea.ejecuciones, 0);
    });

    test('parsea una tarea en curso con fallos consecutivos y último error', () {
      final tarea = ScheduledJob.fromJson({
        'nombre': 'autorizaciones-por-caducar',
        'descripcion': 'Avisa de autorizaciones cerca de caducar',
        'intervaloMinutos': 360,
        'ultimaEjecucionAt': '2026-08-08T08:00:00.000Z',
        'proximaEjecucionAprox': '2026-08-08T14:00:00.000Z',
        'enCurso': true,
        'ejecuciones': 5,
        'fallosConsecutivos': 3,
        'ultimoResultado': null,
        'ultimoError': 'Timeout consultando Stripe',
      });

      expect(tarea.enCurso, true);
      expect(tarea.fallosConsecutivos, 3);
      expect(tarea.ultimoError, 'Timeout consultando Stripe');
    });
  });

  group('AdminUserLookup.fromJson', () {
    test('parsea un usuario activo normal', () {
      final usuario = AdminUserLookup.fromJson({
        'id': 'user-1',
        'nombre': 'Ana Cliente',
        'email': 'ana@example.com',
        'telefono': null,
        'role': 'cliente',
        'activo': true,
        'cuentaEliminada': false,
      });

      expect(usuario.id, 'user-1');
      expect(usuario.activo, true);
      expect(usuario.cuentaEliminada, false);
      expect(usuario.telefono, isNull);
    });

    // Ver el comentario de cuentaEliminada en admin.controller.ts: una
    // cuenta autoeliminada (RGPD) también tiene activo:false, pero el
    // panel necesita distinguirla para no ofrecer "Activar" sobre ella.
    test('parsea una cuenta eliminada por el propio usuario (RGPD)', () {
      final usuario = AdminUserLookup.fromJson({
        'id': 'user-2',
        'nombre': 'Usuario eliminado',
        'email': null,
        'telefono': null,
        'role': 'cliente',
        'activo': false,
        'cuentaEliminada': true,
      });

      expect(usuario.activo, false);
      expect(usuario.cuentaEliminada, true);
      expect(usuario.email, isNull);
    });
  });
}
