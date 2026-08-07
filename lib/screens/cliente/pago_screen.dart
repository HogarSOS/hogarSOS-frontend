import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import '../../l10n/app_localizations.dart';
import '../../services/payment_service.dart';
import '../../utils/error_extraction.dart';
import '../../widgets/entrada_animada.dart';
import '../legal/terminos_screen.dart';

class PagoScreen extends StatefulWidget {
  const PagoScreen({super.key, required this.serviceRequestId});

  final String serviceRequestId;

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  final _paymentService = PaymentService();
  bool _procesando = false;
  String? _error;

  Future<void> _pagar() async {
    setState(() {
      _procesando = true;
      _error = null;
    });

    try {
      final resultado = await _paymentService.crearIntencionDePago(widget.serviceRequestId);
      if (!mounted) return;

      // El pago queda AUTORIZADO (no capturado) — se le explica al
      // cliente para que no espere un cargo inmediato en su resumen.
      // El desglose ya se mostró al aceptar el presupuesto; aquí es
      // solo un recibo de refuerzo con los importes ya fijados.
      //
      // Devolvemos `resultado` al hacer pop en vez de mostrar aquí
      // mismo el SnackBar de éxito: justo después de pop() este
      // contexto pertenece a una pantalla que ya se está desmontando,
      // así que ScaffoldMessenger.of(context) podía fallar (lookup
      // sobre un widget desactivado) — un pago que SÍ se autorizó
      // correctamente en Stripe/backend acababa mostrando el error
      // genérico igualmente, porque ese fallo caía en el catch de más
      // abajo. Quien empuja esta pantalla (seguimiento_solicitud_screen)
      // muestra el SnackBar con su propio contexto, que sigue vivo.
      Navigator.of(context).pop(resultado);
    } on StripeException catch (e) {
      // El usuario canceló la hoja de pago o la tarjeta fue rechazada.
      // FailureCode.Canceled aparte porque `localizedMessage` para ese
      // caso concreto lo manda Stripe siempre en inglés ("The payment
      // flow has been canceled"), sin traducir aunque el resto de la
      // app esté en español — se detectó al probar en dispositivo real.
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      setState(() => _error = e.error.code == FailureCode.Canceled
          ? t.pagoCancelado
          : e.error.localizedMessage ?? t.pagoErrorStripeDefault);
    } catch (e) {
      debugPrint('[PagoScreen] Error al procesar el pago: $e');
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      // Antes mostraba siempre el mismo texto genérico ("No se pudo
      // procesar el pago"), incluso cuando el backend sí manda un motivo
      // concreto (ej. 409 "No hay nada pendiente de autorizar para esta
      // solicitud" cuando ya se había autorizado antes) — el cliente
      // nunca se enteraba de que en realidad el pago YA estaba hecho, y
      // reintentaba pensando que seguía fallando.
      setState(() => _error = mensajeDeError(e, contexto: t.pagoErrorGenerico, t: t));
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.pagoTitulo)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EntradaAnimada(
              child: Material(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.lock_outline, color: colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          t.pagoInfo,
                          style: TextStyle(fontSize: 13.5, color: colorScheme.onSurfaceVariant, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Enlace real a los términos (incluye cancelación/reembolso)
            // justo antes de pagar — no basta con tenerlos enterrados en
            // el perfil, las tiendas de apps piden que sean visibles en
            // el propio flujo de pago.
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TerminosScreen()),
                ),
                child: Text(
                  t.pagoAceptacionTerminos,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton(
              onPressed: _procesando ? null : _pagar,
              child: _procesando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.pagoBtnAutorizar),
            ),
          ],
        ),
      ),
    );
  }
}
