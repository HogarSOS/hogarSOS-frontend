// BUG real confirmado en dispositivo (Android release minificado, 2/2
// veces): abrir hogarsos://stripe-return/completado con la app cerrada
// del todo se quedaba en "Mi perfil" en vez de saltar a "Centro de
// Pagos". Con la app ya abierta (caliente) el mismo link funcionaba bien.
//
// Causa confirmada (dos partes, encontradas y arregladas en el mismo
// bloque de trabajo):
//
// 1. deep_link_listener.dart::_procesar() leía
// `ref.read(authProvider).usuario` de forma SÍNCRONA. En un arranque en
// frío, getInitialLink() puede resolver antes de que
// AuthNotifier._restaurarSesionInicial() termine — `restaurando` seguía
// `true`, `usuario` era `null`, y el guard de rol descartaba el link
// para siempre, sin ningún reintento (a diferencia del path de
// notificaciones push, que sí tenía ese mecanismo desde antes).
//
// 2. Arreglada la parte 1, seguía fallando en real: logging temporal
// confirmó que la decisión SÍ llegaba a "procesar" y fijaba
// profesionalTabIndexProvider=3 correctamente — pero ProfesionalShellScreen
// también está montándose en ese mismo cold start, y su propio
// initState() resetea profesionalTabIndexProvider a pestanaInicial (0)
// en su postFrameCallback. Sin escribir también
// pendingProfesionalTabRequestProvider (exactamente la misma carrera de
// BUG 1 de ayer, pero en esta ruta hermana que aquel fix no cubría), ese
// reset se ejecutaba DESPUÉS y pisaba el índice 3.
//
// Fix: mismo patrón que _notificacionPendiente/pendingProfesionalTabRequestProvider
// — un provider a nivel de módulo guarda el URI pendiente y build() lo
// reintenta exactamente una vez, cuando authProvider.restaurando pasa a
// false; al procesar, escribe TANTO profesionalTabIndexProvider (gana si
// el shell ya está estable) COMO pendingProfesionalTabRequestProvider
// (red de seguridad si el shell sigue montándose). Sin Future.delayed,
// sin polling.
//
// Estos tests prueban el contrato de los providers y la función pura de
// decisión directamente (sin montar DeepLinkListener entero, que
// arrastra app_links/FirebaseMessaging/NotificationService, ni
// AuthNotifier real, que en su constructor llama a Firebase — fuera del
// alcance de este bug). Los "hechos" de auth (restaurando/rol) se pasan
// como parámetros explícitos en vez de a través de un AuthNotifier de
// mentira, para no depender del tipo concreto que exige
// authProvider.overrideWith.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/models/user_model.dart';
import 'package:hogarsos/providers/stripe_return_provider.dart';
import 'package:hogarsos/screens/profesional_shell_screen.dart';
import 'package:hogarsos/services/deep_link_listener.dart';

/// Replica EXACTAMENTE lo que hace
/// _DeepLinkListenerState._intentarProcesarDeepLinkPendiente(): lee el
/// URI pendiente, decide con la misma función pura que usa el widget
/// (resolverDeepLinkStripePendiente, importada de verdad, no
/// reimplementada aquí), y aplica los mismos efectos sobre los mismos
/// providers reales. `restaurando`/`rolUsuario` representan el
/// AuthState de authProvider en el instante del reintento.
void _reintentarDeepLinkPendiente(
  ProviderContainer container, {
  required bool restaurando,
  required UserRole? rolUsuario,
}) {
  final uri = container.read(pendingStripeReturnLinkProvider);
  if (uri == null) return;

  final decision = resolverDeepLinkStripePendiente(restaurando: restaurando, rolUsuario: rolUsuario);
  if (decision == DecisionDeepLinkStripe.esperar) return;

  container.read(pendingStripeReturnLinkProvider.notifier).state = null;
  if (decision == DecisionDeepLinkStripe.descartar) return;

  container.read(stripeReturnEventProvider.notifier).state++;
  // disponibilidadProvider.cargar() toca red real (ProfessionalService) —
  // se omite aquí a propósito: lo relevante para este bug es la
  // navegación de pestaña y el contador de evento, no ese side-effect
  // (que además se traga sus propios errores, ver disponibilidad_provider.dart).
  container.read(pendingProfesionalTabRequestProvider.notifier).state = 3;
  container.read(profesionalTabIndexProvider.notifier).state = 3;
}

/// Replica exactamente lo que hace ProfesionalShellScreen.initState() en
/// su postFrameCallback (ver profesional_shell_tab_navigation_test.dart)
/// — necesario aquí para probar la carrera real con el montaje del
/// shell en el mismo cold start (parte 2 de la causa, ver cabecera).
void _aplicarMontajeDelShell(ProviderContainer container, {required int pestanaInicial}) {
  final pendiente = container.read(pendingProfesionalTabRequestProvider);
  container.read(profesionalTabIndexProvider.notifier).state =
      resolverPestanaAlMontar(pendiente: pendiente, pestanaInicial: pestanaInicial);
  if (pendiente != null) {
    container.read(pendingProfesionalTabRequestProvider.notifier).state = null;
  }
}

/// Replica _procesar(): deja el URI pendiente y reintenta de inmediato
/// con el AuthState "actual" pasado a mano (mismo valor que tendría
/// ref.read(authProvider) en ese instante).
void _recibirDeepLink(
  ProviderContainer container,
  Uri uri, {
  required bool restaurando,
  required UserRole? rolUsuario,
}) {
  container.read(pendingStripeReturnLinkProvider.notifier).state = uri;
  _reintentarDeepLinkPendiente(container, restaurando: restaurando, rolUsuario: rolUsuario);
}

final _uriCompletado = Uri.parse('hogarsos://stripe-return/completado');
final _uriRefresh = Uri.parse('hogarsos://stripe-return/refresh');

void main() {
  group('resolverDeepLinkStripePendiente (función pura de decisión)', () {
    test('restaurando=true → esperar, sea cual sea el rol', () {
      expect(
        resolverDeepLinkStripePendiente(restaurando: true, rolUsuario: UserRole.profesional),
        DecisionDeepLinkStripe.esperar,
      );
      expect(
        resolverDeepLinkStripePendiente(restaurando: true, rolUsuario: null),
        DecisionDeepLinkStripe.esperar,
      );
    });

    test('restaurando=false y profesional → procesar', () {
      expect(
        resolverDeepLinkStripePendiente(restaurando: false, rolUsuario: UserRole.profesional),
        DecisionDeepLinkStripe.procesar,
      );
    });

    test('restaurando=false y cliente → descartar', () {
      expect(
        resolverDeepLinkStripePendiente(restaurando: false, rolUsuario: UserRole.cliente),
        DecisionDeepLinkStripe.descartar,
      );
    });

    test('restaurando=false y sin sesión (null) → descartar', () {
      expect(
        resolverDeepLinkStripePendiente(restaurando: false, rolUsuario: null),
        DecisionDeepLinkStripe.descartar,
      );
    });
  });

  group('pendingStripeReturnLinkProvider (contrato end-to-end, cold start real)', () {
    test('app caliente (restaurando ya en false, profesional logueado) → navega en el acto', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      _recibirDeepLink(container, _uriCompletado, restaurando: false, rolUsuario: UserRole.profesional);

      expect(container.read(profesionalTabIndexProvider), 3);
      expect(container.read(stripeReturnEventProvider), 1);
      expect(container.read(pendingStripeReturnLinkProvider), isNull);
    });

    test('cold start: el link llega con restaurando=true → queda pendiente, NO navega todavía', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // authProvider aún restaurando la sesión — todavía no se sabe ni
      // siquiera si hay usuario.
      _recibirDeepLink(container, _uriCompletado, restaurando: true, rolUsuario: null);

      expect(container.read(profesionalTabIndexProvider), 0, reason: 'no debe tocar la pestaña mientras restaurando siga true');
      expect(container.read(stripeReturnEventProvider), 0);
      expect(container.read(pendingStripeReturnLinkProvider), _uriCompletado, reason: 'debe quedar guardado para el reintento');
    });

    test('auth restaurado (profesional) → build() reintenta y AHORA sí navega a Centro de Pagos', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      _recibirDeepLink(container, _uriCompletado, restaurando: true, rolUsuario: null);
      expect(container.read(pendingStripeReturnLinkProvider), isNotNull);

      // authProvider termina de restaurar la sesión con un profesional —
      // build() vería restaurando pasar a false y llamaría al reintento.
      _reintentarDeepLinkPendiente(container, restaurando: false, rolUsuario: UserRole.profesional);

      expect(container.read(profesionalTabIndexProvider), 3);
      expect(container.read(stripeReturnEventProvider), 1);
      expect(container.read(pendingStripeReturnLinkProvider), isNull);
    });

    test(
        'revisión adversarial: ProfesionalShellScreen montándose en el MISMO cold start no pisa el índice 3 (parte 2 de la causa real)',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // El deep link llega en frío y queda pendiente.
      _recibirDeepLink(container, _uriCompletado, restaurando: true, rolUsuario: null);

      // authProvider termina de restaurar — el reintento navega y deja
      // pendingProfesionalTabRequestProvider=3 como red de seguridad.
      _reintentarDeepLinkPendiente(container, restaurando: false, rolUsuario: UserRole.profesional);
      expect(container.read(profesionalTabIndexProvider), 3);

      // Justo después (mismo cold start), ProfesionalShellScreen termina
      // de montarse y aplica SU propio postFrameCallback — sin la red de
      // seguridad, este reset a pestanaInicial (0) pisaría el índice 3
      // que se acababa de fijar.
      _aplicarMontajeDelShell(container, pestanaInicial: 0);

      expect(container.read(profesionalTabIndexProvider), 3, reason: 'la pendiente debe ganar sobre el reset del shell');
      expect(container.read(pendingProfesionalTabRequestProvider), isNull);
    });

    test('usuario no profesional (cliente) restaurado → NO navega, pero limpia la pendiente', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      _recibirDeepLink(container, _uriCompletado, restaurando: true, rolUsuario: null);
      _reintentarDeepLinkPendiente(container, restaurando: false, rolUsuario: UserRole.cliente);

      expect(container.read(profesionalTabIndexProvider), 0);
      expect(container.read(stripeReturnEventProvider), 0);
      expect(container.read(pendingStripeReturnLinkProvider), isNull, reason: 'se descarta, no debe quedar colgado para un login posterior');
    });

    test('sin sesión (logout) al restaurar → no navega, y un login posterior NO hereda el link viejo', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // El link llega en frío, pero cuando termina de restaurar resulta
      // que no había ninguna sesión activa (usuario nunca llegó a
      // loguearse, o cerró sesión justo antes de que Stripe devolviera).
      _recibirDeepLink(container, _uriCompletado, restaurando: true, rolUsuario: null);
      _reintentarDeepLinkPendiente(container, restaurando: false, rolUsuario: null);

      expect(container.read(pendingStripeReturnLinkProvider), isNull);
      expect(container.read(profesionalTabIndexProvider), 0);

      // Más tarde, en la MISMA ejecución de la app, un profesional inicia
      // sesión (login normal, sin ningún deep link nuevo de por medio).
      // Sin la limpieza incondicional de arriba, el link de Stripe de
      // hace un rato podría reaplicarse aquí y mandar a este usuario
      // distinto a Centro de Pagos sin que haya pasado nada de Stripe.
      _reintentarDeepLinkPendiente(container, restaurando: false, rolUsuario: UserRole.profesional); // no-op: no hay nada pendiente

      expect(container.read(profesionalTabIndexProvider), 0);
      expect(container.read(stripeReturnEventProvider), 0);
    });

    test('deep link duplicado (dos llegan antes de resolver) → determinista, el último gana, una sola vez', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Dos retornos de Stripe casi seguidos (p.ej. el usuario tocó
      // "actualizar" dos veces en el navegador) mientras la app seguía
      // restaurando la sesión.
      _recibirDeepLink(container, _uriCompletado, restaurando: true, rolUsuario: null);
      _recibirDeepLink(container, _uriRefresh, restaurando: true, rolUsuario: null);
      expect(container.read(pendingStripeReturnLinkProvider), _uriRefresh, reason: 'sin cola: el segundo reemplaza al primero');

      _reintentarDeepLinkPendiente(container, restaurando: false, rolUsuario: UserRole.profesional);

      expect(container.read(profesionalTabIndexProvider), 3);
      expect(container.read(stripeReturnEventProvider), 1, reason: 'una sola aplicación, no dos');
      expect(container.read(pendingStripeReturnLinkProvider), isNull);
    });
  });
}
