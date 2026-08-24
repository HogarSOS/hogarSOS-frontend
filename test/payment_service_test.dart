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
    // totalCliente ya NO existe a propósito: desde el modelo por tramos
    // (10% hasta 500 € acumulados por solicitud + 5% del exceso) el total
    // del cliente depende de lo ya autorizado en la solicitud, así que lo
    // sirve el backend (DesglosePago) y la app solo lo pinta. Reintroducir
    // un cálculo lineal aquí volvería a abrir la puerta a mostrar un
    // número distinto del que se cobra.
    test('totalProfesional resta el porcentaje de comisión del montoBase', () {
      final comisiones = ComisionesInfo(comisionClientePorcentaje: 0, comisionProfesionalPorcentaje: 10);

      expect(comisiones.totalProfesional(100), 90);
    });

    test('con 0% el profesional recibe el montoBase íntegro', () {
      final comisiones = ComisionesInfo(comisionClientePorcentaje: 0, comisionProfesionalPorcentaje: 0);

      expect(comisiones.totalProfesional(37.5), 37.5);
    });

    test('esPromoLanzamiento solo es true cuando AMBOS porcentajes son 0', () {
      expect(ComisionesInfo(comisionClientePorcentaje: 0, comisionProfesionalPorcentaje: 0).esPromoLanzamiento, isTrue);
      expect(ComisionesInfo(comisionClientePorcentaje: 5, comisionProfesionalPorcentaje: 0).esPromoLanzamiento, isFalse);
      expect(ComisionesInfo(comisionClientePorcentaje: 0, comisionProfesionalPorcentaje: 3).esPromoLanzamiento, isFalse);
    });
  });

  group('DesglosePago.fromJson — desglose servido por el backend', () {
    test('parsea el desglose completo', () {
      final desglose = DesglosePago.fromJson({
        'montoBase': 500,
        'comision': 25,
        'total': 525,
        'baseAcumulada': 500,
      });

      expect(desglose.montoBase, 500.0);
      expect(desglose.comision, 25.0);
      expect(desglose.total, 525.0);
      expect(desglose.baseAcumulada, 500.0);
    });

    // Mismo caso real que CobroHistorial: el backend serializa Decimal
    // como num entero cuando no hay decimales — el .toDouble() evita el
    // cast error.
    test('acepta números con y sin decimales, y baseAcumulada ausente', () {
      final desglose = DesglosePago.fromJson({
        'montoBase': 750.5,
        'comision': 62.55,
        'total': 813.05,
      });

      expect(desglose.comision, 62.55);
      expect(desglose.baseAcumulada, 0.0);
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
