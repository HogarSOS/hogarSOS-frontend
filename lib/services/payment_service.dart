import 'package:flutter_stripe/flutter_stripe.dart';
import 'api_service.dart';

class PaymentIntentResult {
  final String paymentId;
  final double montoTotal;
  final double comisionPlataforma;

  PaymentIntentResult({
    required this.paymentId,
    required this.montoTotal,
    required this.comisionPlataforma,
  });
}

class PaymentService {
  final _api = ApiService.instance.client;

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
      montoTotal: (respuesta.data['montoTotal'] as num).toDouble(),
      comisionPlataforma: (respuesta.data['comisionPlataforma'] as num).toDouble(),
    );
  }
}
