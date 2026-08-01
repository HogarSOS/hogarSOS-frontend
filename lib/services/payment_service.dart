import 'package:flutter_stripe/flutter_stripe.dart';
import 'api_service.dart';

class PaymentIntentResult {
  final String paymentId;
  final double montoBase;
  final double montoTotal;
  final double comisionPlataforma;

  PaymentIntentResult({
    required this.paymentId,
    required this.montoBase,
    required this.montoTotal,
    required this.comisionPlataforma,
  });
}

/// Porcentajes de comisión vigentes ahora mismo (`GET /payments/comisiones`).
/// Puramente informativo — el backend es quien fija los importes reales
/// al crear cada autorización.
class ComisionesInfo {
  final double comisionClientePorcentaje;
  final double comisionProfesionalPorcentaje;

  ComisionesInfo({
    required this.comisionClientePorcentaje,
    required this.comisionProfesionalPorcentaje,
  });

  /// Deriva si hay que mostrar el distintivo de "promoción de lanzamiento"
  /// — no es una fecha ni un flag aparte, solo el hecho de que ahora
  /// mismo ninguna de las dos partes paga comisión.
  bool get esPromoLanzamiento => comisionClientePorcentaje == 0 && comisionProfesionalPorcentaje == 0;

  /// Importe que pagaría el cliente por un `montoBase` dado, con la
  /// comisión vigente.
  double totalCliente(double montoBase) => montoBase * (1 + comisionClientePorcentaje / 100);

  /// Importe que recibiría el profesional por un `montoBase` dado, con
  /// la comisión vigente.
  double totalProfesional(double montoBase) => montoBase * (1 - comisionProfesionalPorcentaje / 100);
}

class PaymentService {
  final _api = ApiService.instance.client;

  Future<ComisionesInfo> obtenerComisiones() async {
    final respuesta = await _api.get('/payments/comisiones');
    return ComisionesInfo(
      comisionClientePorcentaje: (respuesta.data['comisionClientePorcentaje'] as num).toDouble(),
      comisionProfesionalPorcentaje: (respuesta.data['comisionProfesionalPorcentaje'] as num).toDouble(),
    );
  }

  /// Pide al backend que autorice el cargo (modelo escrow — no se
  /// captura todavía) y devuelve los datos para mostrar el desglose
  /// al cliente antes de confirmar.
  Future<PaymentIntentResult> crearIntencionDePago(String serviceRequestId) async {
    final respuesta = await _api.post('/payments/intent', data: {
      'serviceRequestId': serviceRequestId,
    });

    final clientSecret = respuesta.data['clientSecret'] as String;

    // Presenta la hoja de pago nativa de Stripe (tarjeta, Apple Pay, Google Pay).
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'hogarSOS',
      ),
    );
    await Stripe.instance.presentPaymentSheet();

    // Si presentPaymentSheet() no lanzó excepción, el cliente completó
    // la autorización. El cargo queda retenido hasta que el profesional
    // complete el servicio (ver payment.service.ts en el backend).
    return PaymentIntentResult(
      paymentId: respuesta.data['paymentId'] as String,
      montoBase: (respuesta.data['montoBase'] as num).toDouble(),
      montoTotal: (respuesta.data['montoTotal'] as num).toDouble(),
      comisionPlataforma: (respuesta.data['comisionPlataforma'] as num).toDouble(),
    );
  }
}
