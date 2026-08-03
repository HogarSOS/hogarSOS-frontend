import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_keys.dart';
import '../l10n/app_localizations.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/disponibilidad_provider.dart';
import '../providers/stripe_return_provider.dart';
import '../screens/profesional_shell_screen.dart';

/// Envuelve el `home` de la app para escuchar el deep link propio de
/// retorno del onboarding de Stripe Connect (`hogarsos://stripe-return/
/// completado` o `/refresh`, ver return_url/refresh_url en
/// professional.controller.ts y AndroidManifest.xml). Sin esto, Stripe
/// devolvía al usuario a una página web suelta y el estado real
/// (`estadoCuentaStripe`) solo se refrescaba la próxima vez que se
/// abriera el perfil por casualidad.
class DeepLinkListener extends ConsumerStatefulWidget {
  const DeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends ConsumerState<DeepLinkListener> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscripcion;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    try {
      final linkInicial = await _appLinks.getInitialLink();
      if (linkInicial != null) _procesar(linkInicial);
    } catch (e) {
      debugPrint('[DeepLinkListener] Error leyendo el link inicial: $e');
    }

    _subscripcion = _appLinks.uriLinkStream.listen(
      _procesar,
      onError: (e) => debugPrint('[DeepLinkListener] Error en uriLinkStream: $e'),
    );
  }

  void _procesar(Uri uri) {
    if (uri.scheme != 'hogarsos' || uri.host != 'stripe-return') return;

    // Este deep link solo tiene sentido para un profesional que venía de
    // configurar su cuenta de cobro — si por lo que sea nadie ha
    // iniciado sesión todavía o es un cliente, no hay nada que refrescar.
    final usuario = ref.read(authProvider).usuario;
    if (usuario?.role != UserRole.profesional) return;

    ref.read(stripeReturnEventProvider.notifier).state++;
    ref.read(disponibilidadProvider.notifier).cargar();
    ref.read(profesionalTabIndexProvider.notifier).state = 3;

    final context = navigatorKey.currentContext;
    if (context == null) return;
    final t = AppLocalizations.of(context);
    final esRefresh = uri.path.contains('refresh');
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(esRefresh ? t.cuentaCobroStripeCaducado : t.cuentaCobroStripeActualizando)),
    );
  }

  @override
  void dispose() {
    _subscripcion?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
