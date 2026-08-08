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
}
