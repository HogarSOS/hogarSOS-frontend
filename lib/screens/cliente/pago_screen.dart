import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import '../../l10n/app_localizations.dart';
import '../../services/payment_service.dart';
import '../../widgets/entrada_animada.dart';

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
      await _paymentService.crearIntencionDePago(widget.serviceRequestId);
      if (!mounted) return;

      // El pago queda AUTORIZADO (no capturado) — se le explica al
      // cliente para que no espere un cargo inmediato en su resumen.
      Navigator.of(context).pop(true);
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.pagoExito)),
      );
    } on StripeException catch (e) {
      // El usuario canceló la hoja de pago o la tarjeta fue rechazada.
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      setState(() => _error = e.error.localizedMessage ?? t.pagoErrorStripeDefault);
    } catch (e) {
      debugPrint('[PagoScreen] Error al procesar el pago: $e');
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      setState(() => _error = t.pagoErrorGenerico);
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
