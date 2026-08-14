import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/service_request_model.dart';
import '../providers/chat_read_provider.dart';
import '../providers/service_request_provider.dart';
import '../providers/trabajos_vistos_provider.dart';
import '../services/app_badge_service.dart';
import 'profesional/home_profesional_screen.dart';
import 'profesional/mi_perfil_profesional_screen.dart';
import 'profesional/trabajos_activos_profesional_screen.dart';
import 'profesional/centro_pagos_screen.dart';

/// Pestaña activa del shell del profesional — en un provider (no
/// estado local del shell) para que otras pantallas dentro de una
/// pestaña puedan cambiar de pestaña sin necesidad de un callback
/// pasado a mano por todo el árbol de widgets. Ej.: el botón
/// "Completar perfil" en Disponibilidad salta a la pestaña Perfil.
final profesionalTabIndexProvider = StateProvider<int>((ref) => 0);

/// Contenedor de navegación inferior del profesional — el mismo patrón
/// que ClienteShellScreen (IndexedStack + NavigationBar), para que la
/// navegación se sienta igual sea cual sea el rol con el que se entró.
/// Antes "Mi perfil" se alcanzaba con un botón suelto en el AppBar de
/// Inicio, una forma de navegar distinta a la del cliente; ahora es una
/// pestaña más, consistente con el resto de la app.
class ProfesionalShellScreen extends ConsumerStatefulWidget {
  const ProfesionalShellScreen({super.key, this.pestanaInicial = 0});

  /// Tras REGISTRARSE (no en un login normal) se pasa 3 (Perfil) desde
  /// login_screen.dart — lo primero que debe ver un profesional recién
  /// creado es su propio perfil, para completarlo, no la lista de
  /// solicitudes cercanas (que además estará vacía: sin categoría
  /// todavía no puede aparecer en ninguna).
  final int pestanaInicial;

  @override
  ConsumerState<ProfesionalShellScreen> createState() => _ProfesionalShellScreenState();
}

class _ProfesionalShellScreenState extends ConsumerState<ProfesionalShellScreen> {
  DateTime? _ultimaPulsacionAtras;

  // Orden pedido por el usuario tras probar la beta: Perfil primero (es
  // lo primero que se ve al entrar, en vez de tener que ir a buscarlo a
  // la derecha), y "Inicio" renombrado a "Solicitudes" porque eso es
  // literalmente lo que muestra esa pantalla (solicitudes cercanas sin
  // aceptar) — "Inicio" no decía nada sobre su contenido real.
  //
  // Disponibilidad ya no es una pestaña propia (roadmap económico,
  // punto 2): se movió dentro de "Mi perfil", con acceso rápido a "No
  // disponible" desde Solicitudes cercanas — ver disponibilidad_provider.dart.
  static const _pantallas = [
    MiPerfilProfesionalScreen(),
    HomeProfesionalScreen(),
    TrabajosActivosProfesionalScreen(),
    CentroPagosScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profesionalTabIndexProvider.notifier).state = widget.pestanaInicial;
    });
  }

  // Este shell es la raíz de la navegación tras el login/registro
  // (pushReplacement) o al restaurar sesión (widget directo de
  // AuthGateScreen) — no hay nada debajo a lo que volver. Sin este
  // PopScope, el botón atrás físico de Android cerraba la app de golpe;
  // ahora exige una segunda pulsación en menos de 2s.
  Future<void> _onPopInvoked(bool didPop) async {
    if (didPop) return;
    final t = AppLocalizations.of(context);
    final ahora = DateTime.now();
    final reciente = _ultimaPulsacionAtras != null &&
        ahora.difference(_ultimaPulsacionAtras!) < const Duration(seconds: 2);

    if (reciente) {
      SystemNavigator.pop();
      return;
    }

    _ultimaPulsacionAtras = ahora;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.salirPulsaOtraVez), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final indiceActual = ref.watch(profesionalTabIndexProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _onPopInvoked(didPop),
      child: Scaffold(
        body: IndexedStack(index: indiceActual, children: _pantallas),
        bottomNavigationBar: NavigationBar(
          selectedIndex: indiceActual,
          onDestinationSelected: (i) => ref.read(profesionalTabIndexProvider.notifier).state = i,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: t.navPerfil,
            ),
            NavigationDestination(
              icon: const Icon(Icons.home_repair_service_outlined),
              selectedIcon: const Icon(Icons.home_repair_service),
              label: t.navSolicitudesCercanas,
            ),
            NavigationDestination(
              icon: const _BadgeMensajesProfesional(child: Icon(Icons.chat_bubble_outline)),
              selectedIcon: const _BadgeMensajesProfesional(child: Icon(Icons.chat_bubble)),
              label: t.navMensajes,
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: const Icon(Icons.account_balance_wallet),
              label: t.navCentroPagos,
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge de la pestaña Mensajes/Trabajos activos, aislado en su propio
/// [ConsumerWidget] (rendimiento, auditoría pre-lanzamiento) — mismo
/// motivo que _BadgeMensajesCliente en cliente_shell_screen.dart: antes
/// este cálculo vivía en el build() del shell entero, así que cualquier
/// cambio de unreadChatProvider o trabajosVistosProvider reconstruía
/// todo el Scaffold/NavigationBar, no solo el punto rojo.
class _BadgeMensajesProfesional extends ConsumerWidget {
  const _BadgeMensajesProfesional({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Punto rojo si algún trabajo asignado tiene un mensaje nuevo sin
    // abrir, O si hay un trabajo recién aceptado que el profesional
    // todavía no ha abierto — antes, si se ignoraba el push "¡Te han
    // elegido!", no quedaba ninguna señal dentro de la app y el trabajo
    // podía pasar desapercibido indefinidamente.
    final trabajosAsync = ref.watch(assignedRequestsProvider);
    final trabajos = trabajosAsync.maybeWhen(
      data: (lista) => lista,
      orElse: () => const <AssignedRequest>[],
    );
    final idsTrabajos = trabajos.map((t) => t.id);
    final numConversacionesNoLeidas = idsTrabajos.where((id) => ref.watch(unreadChatProvider(id))).length;
    final hayMensajesNoLeidos = numConversacionesNoLeidas > 0;
    final trabajosVistos = ref.watch(trabajosVistosProvider);
    final numTrabajosNuevosSinVer =
        trabajos.where((t) => t.estado == EstadoSolicitud.aceptada && !trabajosVistos.contains(t.id)).length;
    final hayTrabajoNuevoSinVer = numTrabajosNuevosSinVer > 0;
    // Suma de ambas señales para el número del badge: si solo se contaran
    // los mensajes, un trabajo nuevo sin mensajes mostraría un badge
    // visible con "0" dentro, más confuso que el punto ciego anterior.
    final numBadgeMensajes = numConversacionesNoLeidas + numTrabajosNuevosSinVer;

    // Badge del icono de la app (UX#6) — booleano (0/1), no la cuenta
    // exacta: iOS no tiene un "punto sin número" a nivel de sistema (su
    // API nativa es siempre un entero), así que 1 es lo más parecido a
    // un punto que permite la plataforma — y, a diferencia de un
    // número real, no puede quedar "mintiendo" si el conteo exacto se
    // desfasa por la limitación de que esto se calcula solo con la app
    // en marcha (ver app_badge_service.dart).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppBadgeService.instance.actualizar((hayMensajesNoLeidos || hayTrabajoNuevoSinVer) ? 1 : 0);
    });

    return Badge(
      isLabelVisible: hayMensajesNoLeidos || hayTrabajoNuevoSinVer,
      label: Text('$numBadgeMensajes'),
      child: child,
    );
  }
}
