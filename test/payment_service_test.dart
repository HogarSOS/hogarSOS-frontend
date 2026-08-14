import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/services/payment_service.dart';

// PaymentService.crearIntencionDePago() orquesta el SDK nativo de Stripe
// (canal de plataforma) y no es testeable como unidad sin un arnés de
// integración completo — fuera de alcance aquí ("no reabrir Apple
// Pay/Google Pay"). Lo que SÍ es puro, crítico y seguro de testear es el
// cálculo de comisiones que ve el usuario y el parseo de las respuestas
// del backend: un bug de redondeo o de parseo aquí muestra un importe
// incorrecto de dinero real, sin que ningún error visible lo delate.
void main() {
  group('ComisionesInfo — cálculo de importes mostrados al usuario', () {
    test('totalCliente añade el porcentaje de comisión sobre el montoBase', () {
      final comisiones = ComisionesInfo(comisionClientePorcentaje: 5, comisionProfesionalPorcentaje: 0);

      expect(comisiones.totalCliente(100), 105);
    });

    test('totalProfesional resta el porcentaje de comisión del montoBase', () {
      final comisiones = ComisionesInfo(comisionClientePorcentaje: 0, comisionProfesionalPorcentaje: 10);

      expect(comisiones.totalProfesional(100), 90);
    });

    test('con 0%/0% el cliente paga exactamente el montoBase y el profesional lo recibe íntegro', () {
      final comisiones = ComisionesInfo(comisionClientePorcentaje: 0, comisionProfesionalPorcentaje: 0);

      expect(comisiones.totalCliente(37.5), 37.5);
      expect(comisiones.totalProfesional(37.5), 37.5);
    });

    test('esPromoLanzamiento solo es true cuando AMBOS porcentajes son 0', () {
      expect(ComisionesInfo(comisionClientePorcentaje: 0, comisionProfesionalPorcentaje: 0).esPromoLanzamiento, isTrue);
      expect(ComisionesInfo(comisionClientePorcentaje: 5, comisionProfesionalPorcentaje: 0).esPromoLanzamiento, isFalse);
      expect(ComisionesInfo(comisionClientePorcentaje: 0, comisionProfesionalPorcentaje: 3).esPromoLanzamiento, isFalse);
    });
  });

  group('CobroHistorial.fromJson', () {
    test('parsea una fila de historial completa', () {
      final cobro = CobroHistorial.fromJson({
        'id': 'pay-1',
        'monto': 45.5,
        'fecha': '2026-08-10T12:00:00.000Z',
        'categoria': 'fontanero',
        'descripcion': 'Reparación de grifo',
        'nombreCliente': 'Ana',
      });

      expect(cobro.id, 'pay-1');
      expect(cobro.monto, 45.5);
      expect(cobro.categoria, 'fontanero');
      expect(cobro.nombreCliente, 'Ana');
    });

    // El backend serializa Decimal como num entero cuando no hay
    // decimales (100 en vez de 100.0) — sin el .toDouble() esto rompe
    // con un cast error real, ya pasó con otros campos Decimal del
    // backend en este proyecto.
    test('acepta un monto entero sin decimales sin reventar', () {
      final cobro = CobroHistorial.fromJson({
        'id': 'pay-2',
        'monto': 100,
        'fecha': '2026-08-10T12:00:00.000Z',
        'categoria': 'electricista',
        'descripcion': 'Instalación',
        'nombreCliente': 'Bea',
      });

      expect(cobro.monto, 100.0);
    });
  });

  group('PaymentsSummary.fromJson', () {
    test('parsea el resumen completo con historial', () {
      final resumen = PaymentsSummary.fromJson({
        'estadoCuentaStripe': 'configurada',
        'pendiente': 20.0,
        'disponible': 150.0,
        'historial': [
          {
            'id': 'pay-1',
            'monto': 30.0,
            'fecha': '2026-08-10T12:00:00.000Z',
            'categoria': 'limpieza',
            'descripcion': 'Limpieza general',
            'nombreCliente': 'Carlos',
          },
        ],
      });

      expect(resumen.pendiente, 20.0);
      expect(resumen.disponible, 150.0);
      expect(resumen.historial, hasLength(1));
      expect(resumen.historial.first.nombreCliente, 'Carlos');
    });

    test('historial ausente se trata como lista vacía, no como error', () {
      final resumen = PaymentsSummary.fromJson({
        'estadoCuentaStripe': 'pendiente',
        'pendiente': 0.0,
        'disponible': 0.0,
      });

      expect(resumen.historial, isEmpty);
    });
  });
}
