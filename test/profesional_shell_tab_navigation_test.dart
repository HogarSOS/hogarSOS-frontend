// BUG 1 (auditoría 2026-08-15, confirmado en dispositivo real): tocar la
// notificación "¡Te han elegido!" a veces aterrizaba en "Mi perfil" en
// vez de "Trabajos activos".
//
// Causa confirmada: ProfesionalShellScreen.initState() resetea la
// pestaña a `pestanaInicial` en un addPostFrameCallback al montar;
// deep_link_listener.dart intentaba fijar la pestaña a Trabajos con un
// `Future.delayed(400ms)` para "ganarle" a ese reset — una carrera de
// tiempos que en la reproducción real se perdió.
//
// Fix: sin delay ni temporizador de ningún tipo. `pendingProfesionalTabRequestProvider`
// es la fuente de verdad que ProfesionalShellScreen.initState() consulta
// en el único momento en que de verdad importa (su propio
// postFrameCallback) — determinista pase lo que pase antes, porque la
// decisión no depende de CUÁNDO llega cada escritura, solo de QUÉ estado
// hay en el momento de leer.
//
// Estos tests prueban el contrato de los providers y la función pura de
// decisión directamente (sin montar ProfesionalShellScreen entero, que
// arrastra sondeo de trabajos, badges de chat, AppBadgeService, etc. —
// fuera del alcance de este bug).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/screens/profesional_shell_screen.dart';

/// Replica exactamente lo que hace ProfesionalShellScreen.initState() en
/// su postFrameCallback: consultar la pestaña pendiente, resolver el
/// destino final, y limpiar la pendiente si la consumió.
void _aplicarMontajeDelShell(ProviderContainer container, {required int pestanaInicial}) {
  final pendiente = container.read(pendingProfesionalTabRequestProvider);
  container.read(profesionalTabIndexProvider.notifier).state =
      resolverPestanaAlMontar(pendiente: pendiente, pestanaInicial: pestanaInicial);
  if (pendiente != null) {
    container.read(pendingProfesionalTabRequestProvider.notifier).state = null;
  }
}

/// Replica exactamente lo que hace deep_link_listener.dart al navegar
/// por una notificación de rol profesional: escribe los dos providers de
/// forma síncrona, sin delay.
void _aplicarNotificacion(ProviderContainer container, int pestanaDestino) {
  container.read(pendingProfesionalTabRequestProvider.notifier).state = pestanaDestino;
  container.read(profesionalTabIndexProvider.notifier).state = pestanaDestino;
}

/// Replica exactamente lo que hace ProfesionalShellScreen.dispose(): si
/// quedó una pendiente sin consumir (la notificación llegó con el shell
/// ya estable, así que solo hizo falta el write directo), se limpia al
/// destruirse — para que un logout/login posterior en la MISMA ejecución
/// de la app no la herede. Y desde el bug real del 2026-08-22, también
/// restablece la pestaña activa a 0: sin eso, una sesión que terminó en
/// Pagos (índice 3) hacía que el PRIMER FOTOGRAMA del shell de la cuenta
/// siguiente pintara Pagos heredado (y el Centro de Pagos disparara su
/// carga) antes de que el reset del postFrameCallback llegara.
void _destruirElShell(ProviderContainer container) {
  container.read(pendingProfesionalTabRequestProvider.notifier).state = null;
  container.read(profesionalTabIndexProvider.notifier).state = 0;
}

void main() {
  group('resolverPestanaAlMontar (función pura de decisión)', () {
    test('sin pendiente, usa pestanaInicial', () {
      expect(resolverPestanaAlMontar(pendiente: null, pestanaInicial: 0), 0);
    });

    test('con pendiente, la pendiente gana sobre pestanaInicial', () {
      expect(resolverPestanaAlMontar(pendiente: 2, pestanaInicial: 0), 2);
    });

    test('la pendiente gana incluso si pestanaInicial no es el default (p.ej. tras registrarse)', () {
      // Si coincidieran una notificación con un registro recién hecho
      // (pestanaInicial: 3 en login_screen.dart), la notificación —algo
      // que el usuario acaba de tocar— debe ganar.
      expect(resolverPestanaAlMontar(pendiente: 2, pestanaInicial: 3), 2);
    });
  });

  group('profesionalTabIndexProvider + pendingProfesionalTabRequestProvider (contrato end-to-end, sin carrera de tiempos)', () {
    test('arranque normal, sin notificación → Perfil (no cambia de pestaña)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      _aplicarMontajeDelShell(container, pestanaInicial: 0);

      expect(container.read(profesionalTabIndexProvider), 0);
      expect(container.read(pendingProfesionalTabRequestProvider), isNull);
    });

    test('cold start desde notificación / deep link mientras monta el shell: la notificación llega ANTES de que el shell aplique su reset → Trabajos', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      _aplicarNotificacion(container, 2); // deep_link_listener corre primero
      _aplicarMontajeDelShell(container, pestanaInicial: 0); // el shell monta después

      expect(container.read(profesionalTabIndexProvider), 2);
      // La pendiente se consume y se limpia — no queda colgada para la
      // próxima vez que el shell monte.
      expect(container.read(pendingProfesionalTabRequestProvider), isNull);
    });

    test('notificación con la app ya abierta (el shell ya montó hace rato) → Trabajos', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      _aplicarMontajeDelShell(container, pestanaInicial: 0); // shell monta primero, aplica Perfil
      expect(container.read(profesionalTabIndexProvider), 0);

      _aplicarNotificacion(container, 2); // notificación llega después, con la app ya en marcha

      expect(container.read(profesionalTabIndexProvider), 2);
    });

    test('dos eventos consecutivos → estado final determinista (el último gana, sin encolado)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      _aplicarNotificacion(container, 2);
      _aplicarNotificacion(container, 3);

      expect(container.read(profesionalTabIndexProvider), 3);
    });

    test('un segundo montaje del shell sin notificación nueva no reaplica una pendiente ya consumida', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      _aplicarNotificacion(container, 2);
      _aplicarMontajeDelShell(container, pestanaInicial: 0); // consume la pendiente → Trabajos
      expect(container.read(profesionalTabIndexProvider), 2);

      // Un remontaje posterior del shell (p.ej. otra navegación interna)
      // sin ninguna notificación nueva de por medio debe aplicar
      // pestanaInicial normalmente, no seguir "recordando" la anterior.
      _aplicarMontajeDelShell(container, pestanaInicial: 0);
      expect(container.read(profesionalTabIndexProvider), 0);
    });

    test(
        'revisión adversarial: una pendiente que llegó con el shell YA montado (nunca la consumió nadie) no sobrevive a un logout/login posterior',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Sesión 1: el shell ya está montado y estable.
      _aplicarMontajeDelShell(container, pestanaInicial: 0);
      expect(container.read(profesionalTabIndexProvider), 0);

      // Llega una notificación con la app ya abierta — el write directo
      // basta para navegar, pero `pending` también queda escrito (por si
      // el shell no hubiera montado todavía) y aquí NADIE lo consume.
      _aplicarNotificacion(container, 2);
      expect(container.read(pendingProfesionalTabRequestProvider), 2, reason: 'queda sin consumir a propósito, como pasaría en real');

      // El usuario cierra sesión: el shell de la sesión 1 se destruye.
      _destruirElShell(container);
      expect(container.read(pendingProfesionalTabRequestProvider), isNull);

      // Sesión 2: un profesional (el mismo u otro) inicia sesión — un
      // ProfesionalShellScreen NUEVO monta, sin ninguna notificación
      // propia. Sin el dispose(), heredaría la pendiente=2 de la sesión
      // 1 y saltaría a Trabajos sin motivo.
      _aplicarMontajeDelShell(container, pestanaInicial: 0);
      expect(container.read(profesionalTabIndexProvider), 0);
    });

    test(
        'bug real 2026-08-22: cuenta A termina en Pagos → logout → cuenta B monta directamente en Perfil, sin heredar Pagos ni un fotograma',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Cuenta A: monta y navega a Pagos (índice 3) — p.ej. mirando su
      // Centro de Pagos, o tras el retorno de Stripe.
      _aplicarMontajeDelShell(container, pestanaInicial: 0);
      container.read(profesionalTabIndexProvider.notifier).state = 3;
      expect(container.read(profesionalTabIndexProvider), 3);

      // Logout: el shell de A se destruye.
      _destruirElShell(container);

      // CLAVE del bug: el índice debe estar YA en 0 ANTES de que el
      // shell de B monte — el primer fotograma del IndexedStack usa este
      // valor tal cual, y con 3 heredado pintaba Pagos y el Centro de
      // Pagos lanzaba /payments/me/summary para la cuenta nueva.
      expect(container.read(profesionalTabIndexProvider), 0);

      // Cuenta B monta con normalidad → Perfil.
      _aplicarMontajeDelShell(container, pestanaInicial: 0);
      expect(container.read(profesionalTabIndexProvider), 0);
      expect(container.read(pendingProfesionalTabRequestProvider), isNull);
    });

    test('el retorno de Stripe DENTRO de una sesión sigue aterrizando en Pagos (el reset solo aplica al cierre de sesión)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      _aplicarMontajeDelShell(container, pestanaInicial: 0);
      // deep_link_listener al procesar hogarsos://stripe-return escribe
      // ambos providers con 3 — idéntico a _aplicarNotificacion(3).
      _aplicarNotificacion(container, 3);

      expect(container.read(profesionalTabIndexProvider), 3);
    });
  });
}
