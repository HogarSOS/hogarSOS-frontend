import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/service_request_model.dart';
import '../providers/chat_read_provider.dart';
import '../providers/service_request_provider.dart';
import '../providers/trabajos_vistos_provider.dart';
import '../services/app_badge_service.dart';
import '../utils/category_display.dart';
import '../utils/polling_lifecycle_mixin.dart';
import 'profesional/home_profesional_screen.dart';
import 'profesional/mensajes_profesional_screen.dart';
import 'profesional/mi_perfil_profesional_screen.dart';
import 'profesional/trabajos_activos_profesional_screen.dart';
import 'profesional/centro_pagos_screen.dart';

/// Pestaña activa del shell del profesional — en un provider (no
/// estado local del shell) para que otras pantallas dentro de una
/// pestaña puedan cambiar de pestaña sin necesidad de un callback
/// pasado a mano por todo el árbol de widgets. Ej.: el botón
/// "Completar perfil" en Disponibilidad salta a la pestaña Perfil.
final profesionalTabIndexProvider = StateProvider<int>((ref) => 0);

/// Petición de pestaña pendiente de aplicar, dejada por quien navega
/// desde FUERA de una pantalla concreta (deep_link_listener.dart) antes
/// de saber si `ProfesionalShellScreen` ya terminó de montar o no.
///
/// Existe para eliminar de raíz la carrera entre esa navegación externa
/// y el reset a `pestanaInicial` que initState() hace abajo — sin esto,
/// cuál de los dos gana dependía de qué llegara primero (ver commit que
/// introdujo el `Future.delayed(400ms)` como parche de tiempos, que
/// seguía perdiendo la carrera en la práctica). En vez de adivinar un
/// tiempo, initState() CONSULTA este valor en el único momento en que de
/// verdad importa (su propio postFrameCallback) y lo deja ganar si
/// existe — determinista pase lo que pase antes.
final pendingProfesionalTabRequestProvider = StateProvider<int?>((ref) => null);

/// La decisión en sí, aparte de dónde se lee/escribe — pura y sin
/// `BuildContext`/`ref`/temporizadores de por medio, para poder probar el
/// contrato exacto ("pendiente gana si existe, si no pestanaInicial") sin
/// tener que montar todo el árbol de `ProfesionalShellScreen`.
int resolverPestanaAlMontar({required int? pendiente, required int pestanaInicial}) {
  return pendiente ?? pestanaInicial;
}

/// Cuántas solicitudes cercanas están sin postular todavía — pura, sin
/// `ref`/`BuildContext`, para poder probar el contrato exacto del badge
/// de "Solicitudes" sin montar el widget. A diferencia de
/// trabajosVistosProvider (trabajos ya asignados, que se quedan para
/// siempre en la lista y necesitan un "visto" persistente para
/// distinguir nuevo de ya visto), una solicitud cercana sale sola de la
/// lista en cuanto se postula, se ignora o expira — "cuántas hay sin
/// postular ahora mismo" ya es la señal correcta sin guardar nada en
/// disco ni inventar un estado "visto" artificial.
int contarSolicitudesSinPostular(List<NearbyRequest> solicitudes) {
  return solicitudes.where((s) => !s.yaPostulado).length;
}

/// Cuántos trabajos aceptados no ha visto todavía el profesional — pura,
/// misma forma que contarSolicitudesSinPostular. Antes esta cuenta vivía
/// mezclada dentro de _BadgeMensajesProfesional (revisión UX
/// 2026-08-16): con Mensajes convertido en una lista de conversaciones,
/// esta señal se separa y pasa a representar el punto de la tarjeta
/// "Tienes X trabajos activos" en Solicitudes — mismo
/// trabajosVistosProvider de siempre (marcarVistos() al entrar a
/// Trabajos activos), sin mecanismo de persistencia nuevo.
int contarTrabajosNuevosSinVer(List<AssignedRequest> trabajos, Set<String> vistos) {
  return trabajos.where((t) => t.estado == EstadoSolicitud.aceptada && !vistos.contains(t.id)).length;
}

/// A qué acción debe llevar una notificación de rol profesional sobre un
/// trabajo (ya descartado el caso 'chat_mensaje' en deep_link_listener.dart,
/// que empuja ChatScreen directo sin pasar por aquí) — pura, para poder
/// probar el contrato exacto sin RemoteMessage/Navigator de por medio.
///
/// 'nueva_solicitud' es la ÚNICA notificación de rol profesional sobre
/// una solicitud a la que todavía no está vinculado (nada aceptado, nada
/// postulado) — vive en "Solicitudes" (pestaña 1). El resto
/// (postulacion_aceptada, presupuesto_aceptado, cierre_horas_*,
/// ampliacion_*...) son sobre un trabajo en el que el profesional ya
/// está metido — antes vivían en la pestaña 2 (entonces Trabajos
/// activos); con Mensajes en el índice 2 (revisión UX 2026-08-16),
/// "trabajo activo" ya no es una pestaña, así que estos tipos pasan a
/// EMPUJAR TrabajosActivosProfesionalScreen en vez de cambiar de índice
/// (ver deep_link_listener.dart, que hace ese push).
/// 'pago_autorizado' (E2E 2026-08-18): habla de dinero, no de tarea — el
/// profesional que lo toca espera ver el importe retenido, y eso vive en
/// el Centro de Pagos (pestaña 3), no en la lista de trabajos. Los
/// avisos de caducidad NO van ahí: su acción es cerrar el trabajo, que
/// sí vive en Trabajos activos.
enum DestinoNotificacionProfesional { solicitudes, trabajosActivos, centroPagos }

DestinoNotificacionProfesional resolverDestinoNotificacionProfesional(String? tipo) {
  if (tipo == 'nueva_solicitud') return DestinoNotificacionProfesional.solicitudes;
  if (tipo == 'pago_autorizado') return DestinoNotificacionProfesional.centroPagos;
  return DestinoNotificacionProfesional.trabajosActivos;
}

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

class _ProfesionalShellScreenState extends ConsumerState<ProfesionalShellScreen>
    with WidgetsBindingObserver, PollingLifecycleMixin {
  DateTime? _ultimaPulsacionAtras;

  // Suscripción de assignedRequestsProvider — se guarda y se cierra
  // explícitamente en dispose(), en vez de confiar en el autocierre que
  // promete la documentación de ref.listenManual ("no hace falta cerrar
  // en dispose(), se cierra solo"). Causa real, confirmada con
  // instrumentación en dispositivo (2026-08-16): esa promesa no se
  // cumplía aquí — tras un logout, dispose() de la instancia vieja se
  // ejecutaba y stopPolling() cancelaba su Timer correctamente, pero
  // ESTA suscripción seguía viva y seguía recibiendo los cargar() de la
  // sesión SIGUIENTE, disparando _avisarDeTrabajosNuevos sobre un ref ya
  // no válido — "Cannot use ref after the widget was disposed" cada 10s,
  // indefinidamente. `mounted` no servía de guarda porque seguía
  // devolviendo true en ese callback huérfano (el chequeo real de
  // Riverpod mira el Element, no el State). Cierre explícito, no un
  // guard adicional.
  late final ProviderSubscription<AsyncValue<List<AssignedRequest>>> _suscripcionTrabajos;

  // IDs de trabajos para los que YA se mostró el SnackBar "te han
  // elegido" en ESTA ejecución de la app — solo en memoria, a propósito
  // (revisión UX 2026-08-16). Distinto de trabajosVistosProvider (que
  // persiste a disco y significa "el profesional entró a Trabajos
  // activos y lo miró"): este set solo evita repetir el mismo aviso en
  // cada sondeo de 10s mientras siga sin visitar la pantalla. Si se
  // reutilizara trabajosVistosProvider para esto, marcar "avisado" sería
  // indistinguible de marcar "visto de verdad", y el punto de la tarjeta
  // de Solicitudes (contarTrabajosNuevosSinVer) desaparecería en cuanto
  // sonara el SnackBar, aunque el profesional lo hubiera ignorado.
  final Set<String> _idsYaAvisados = {};

  // Orden pedido por el usuario tras probar la beta: Perfil primero (es
  // lo primero que se ve al entrar, en vez de tener que ir a buscarlo a
  // la derecha), y "Inicio" renombrado a "Solicitudes" porque eso es
  // literalmente lo que muestra esa pantalla (solicitudes cercanas sin
  // aceptar) — "Inicio" no decía nada sobre su contenido real.
  //
  // Disponibilidad ya no es una pestaña propia (roadmap económico,
  // punto 2): se movió dentro de "Mi perfil", con acceso rápido a "No
  // disponible" desde Solicitudes cercanas — ver disponibilidad_provider.dart.
  //
  // Mensajes (revisión UX 2026-08-16) muestra ahora MensajesProfesionalScreen
  // (lista de conversaciones) en vez de TrabajosActivosProfesionalScreen
  // — Trabajos activos sigue existiendo, pero solo como pantalla
  // independiente accesible desde Solicitudes o desde una notificación
  // de un trabajo ya asignado (ver resolverDestinoNotificacionProfesional
  // y deep_link_listener.dart).
  static const _pantallas = [
    MiPerfilProfesionalScreen(),
    HomeProfesionalScreen(),
    MensajesProfesionalScreen(),
    CentroPagosScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Si una navegación externa (notificación) ya dejó una pestaña
      // pendiente antes de que este callback llegara a ejecutarse, esa
      // pestaña gana sobre `pestanaInicial` — sin esto, este reset podía
      // pisar justo lo que el usuario tocó para llegar aquí.
      final pendiente = ref.read(pendingProfesionalTabRequestProvider);
      ref.read(profesionalTabIndexProvider.notifier).state =
          resolverPestanaAlMontar(pendiente: pendiente, pestanaInicial: widget.pestanaInicial);
      if (pendiente != null) {
        ref.read(pendingProfesionalTabRequestProvider.notifier).state = null;
      }
    });

    // Sondeo de assignedRequestsProvider (revisión UX 2026-08-16): antes
    // vivía dentro de TrabajosActivosProfesionalScreen.initState() —
    // funcionaba porque esa pantalla era una de las 4 mantenidas vivas
    // por el IndexedStack de este shell. Ahora que Trabajos activos ya
    // NO es una pestaña (solo se monta cuando se hace push desde
    // Solicitudes o desde una notificación), ese sondeo tiene que vivir
    // aquí — el shell es lo único que está montado de verdad durante
    // toda la sesión del profesional — para que la tarjeta "Tienes X
    // trabajos activos", el punto de "trabajo nuevo" y el SnackBar de
    // "te han elegido" seguan funcionando aunque el profesional nunca
    // abra esa pantalla.
    startPolling(const Duration(seconds: 10), () {
      ref.read(assignedRequestsProvider.notifier).cargar();
    });
    _suscripcionTrabajos =
        ref.listenManual(assignedRequestsProvider, (_, next) => next.whenData(_avisarDeTrabajosNuevos));
    final actuales = ref.read(assignedRequestsProvider).valueOrNull;
    if (actuales != null) _avisarDeTrabajosNuevos(actuales);
  }

  /// SnackBar "te han elegido" (revisión UX 2026-08-16, movido desde
  /// TrabajosActivosProfesionalScreen) — a diferencia de
  /// trabajosVistosProvider.marcarVistos() (que solo se llama al entrar
  /// de verdad a Trabajos activos, y persiste a disco), este método NO
  /// marca nada como visto: solo evita repetir el aviso dentro de esta
  /// misma ejecución de la app vía `_idsYaAvisados`. El punto de la
  /// tarjeta de Solicitudes sigue encendido hasta que el profesional
  /// entra de verdad a Trabajos activos, sin importar si vio o ignoró
  /// este SnackBar.
  ///
  /// Revisión adversarial (misma sesión, tras la primera pasada): igual
  /// que marcarVistosDe en trabajos_activos_profesional_screen.dart, hay
  /// que esperar `trabajosVistosProvider.notifier.listo` ANTES de leer el
  /// set — si no, en un arranque en frío este método podía correr antes
  /// de que terminara de cargarse el set persistido de disco (arranca en
  /// `{}`) y tratar un trabajo YA visto en una sesión anterior como
  /// nuevo, disparando un SnackBar "te han elegido" para un trabajo que
  /// el profesional ya conocía. Mismo bug, mismo fix, sitio distinto.
  ///
  /// Segundo fallo real — causa raíz encontrada con instrumentación en
  /// dispositivo real (2026-08-16), no una suposición: la promesa de
  /// `ref.listenManual` de cerrarse solo al desmontar el widget no se
  /// cumplía aquí — tras un logout, `dispose()` de la instancia vieja
  /// corría y `stopPolling()` cancelaba su Timer correctamente, pero esa
  /// suscripción concreta seguía viva y recibía los `cargar()` de la
  /// sesión SIGUIENTE, dando lugar a "Cannot use ref after the widget
  /// was disposed" cada 10s, indefinidamente. `mounted` no servía de
  /// nada ahí — en ese callback huérfano seguía devolviendo `true` (el
  /// chequeo real de Riverpod mira el Element, no el State). El fix de
  /// fondo está en `initState()`/`dispose()`: la suscripción se guarda y
  /// se cierra explícitamente, sin depender del autocierre. El guard de
  /// `mounted` de aquí abajo se mantiene solo como defensa adicional
  /// normal (mismo patrón que el resto de la app), no como el fix.
  Future<void> _avisarDeTrabajosNuevos(List<AssignedRequest> trabajos) async {
    if (!mounted) return;
    await ref.read(trabajosVistosProvider.notifier).listo;
    if (!mounted) return;

    final vistos = ref.read(trabajosVistosProvider);
    final nuevos = trabajos
        .where((t) => t.estado == EstadoSolicitud.aceptada && !vistos.contains(t.id) && !_idsYaAvisados.contains(t.id))
        .toList();
    if (nuevos.isEmpty) return;
    _idsYaAvisados.addAll(nuevos.map((t) => t.id));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      // Un único SnackBar, nunca uno por trabajo (revisión 2026-08-16):
      // antes, con varios trabajos nuevos a la vez (ej. tras recuperar el
      // almacenamiento persistido — trabajosVistosProvider vacío),
      // showSnackBar() se llamaba en bucle, una vez por trabajo, sin
      // esperar entre una llamada y otra. Confirmado en dispositivo real
      // con 22 trabajos nuevos simultáneos: el ScaffoldMessenger quedaba
      // con el primer SnackBar completamente congelado — ni avanzaba a
      // la cola, ni respondía al toque, ni desaparecía pasados los 6s
      // previstos. Un solo mensaje combinado evita por completo la
      // situación (nunca hay más de un showSnackBar() por aviso), además
      // de ser mejor UX incluso si la cola hubiera funcionado bien: nadie
      // quiere 22 avisos seguidos.
      final mensaje = nuevos.length == 1
          ? t.trabajosActivosTeEligieron(nombreLocalizadoCategoria(context, nuevos.first.categoria))
          : t.trabajosActivosTeEligieronVarios(nuevos.length);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: t.trabajosActivosVerTrabajo,
            // Antes esto solo cambiaba profesionalTabIndexProvider a 2
            // (Trabajos activos era una pestaña, siempre montada). Ahora
            // que ya no lo es, hace falta un push real — mismo camino
            // que ya usa la tarjeta "Tienes X trabajos activos" de
            // Solicitudes.
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TrabajosActivosProfesionalScreen()),
            ),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    stopPolling();
    // Cierre explícito (causa raíz real del crash "ref after disposed",
    // ver el docstring de _avisarDeTrabajosNuevos) — el autocierre que
    // promete la documentación de ref.listenManual no se cumplía aquí.
    // Sin esto, esta suscripción seguía viva después de dispose() y
    // recibía los cargar() de la sesión SIGUIENTE tras un logout/login,
    // intentando usar un ref ya no válido cada vez que
    // assignedRequestsProvider se actualizaba.
    _suscripcionTrabajos.close();
    // Revisión adversarial: una notificación que llega con el shell YA
    // estable solo necesita el write directo a profesionalTabIndexProvider
    // (ver deep_link_listener.dart) — pero también deja escrito
    // `pending` "por si acaso" el shell no hubiera montado todavía. Si
    // nadie llega a consumirlo (este caso exacto: ya estaba montado), se
    // queda ahí. Sin este dispose(), un logout/login posterior en la
    // MISMA ejecución de la app haría que el siguiente
    // ProfesionalShellScreen que monte lo encuentre y salte a la pestaña
    // de una notificación de la sesión ANTERIOR, que ya no tiene nada
    // que ver con esta.
    ref.read(pendingProfesionalTabRequestProvider.notifier).state = null;
    super.dispose();
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
        body: Stack(
          children: [
            IndexedStack(index: indiceActual, children: _pantallas),
            // Invisible — solo mantiene actualizado el badge del icono de
            // la app combinando las dos señales (ver la clase de arriba).
            const _ActualizadorBadgeAppProfesional(),
          ],
        ),
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
              icon: const _BadgeSolicitudesProfesional(child: Icon(Icons.home_repair_service_outlined)),
              selectedIcon: const _BadgeSolicitudesProfesional(child: Icon(Icons.home_repair_service)),
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

/// Badge de la pestaña Mensajes, aislado en su propio [ConsumerWidget]
/// (rendimiento, auditoría pre-lanzamiento) — mismo motivo que
/// _BadgeMensajesCliente en cliente_shell_screen.dart: antes este
/// cálculo vivía en el build() del shell entero, así que cualquier
/// cambio de unreadChatProvider reconstruía todo el
/// Scaffold/NavigationBar, no solo el punto rojo.
///
/// Revisión UX 2026-08-16: representa SOLO mensajes no leídos. Antes
/// sumaba también "trabajos nuevos sin ver" (para compensar que Mensajes
/// era en realidad Trabajos activos) — esa señal ahora vive aparte, en
/// el punto de la tarjeta "Tienes X trabajos activos" de Solicitudes
/// (ver contarTrabajosNuevosSinVer y _TarjetaTrabajosActivos en
/// home_profesional_screen.dart). El badge del icono de la app (fuera de
/// la propia pestaña) combina ambas señales por separado, ver
/// _ActualizadorBadgeAppProfesional más abajo.
class _BadgeMensajesProfesional extends ConsumerWidget {
  const _BadgeMensajesProfesional({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trabajosAsync = ref.watch(assignedRequestsProvider);
    final trabajos = trabajosAsync.maybeWhen(
      data: (lista) => lista,
      orElse: () => const <AssignedRequest>[],
    );
    final numConversacionesNoLeidas =
        trabajos.map((t) => t.id).where((id) => ref.watch(unreadChatProvider(id))).length;

    return Badge(
      isLabelVisible: numConversacionesNoLeidas > 0,
      label: Text('$numConversacionesNoLeidas'),
      child: child,
    );
  }
}

/// Combina las dos señales del profesional (mensajes no leídos + trabajo
/// nuevo sin ver) en el ÚNICO número que acepta el badge del icono de la
/// app (AppBadgeService.actualizar — un entero, "el último valor gana",
/// sin combinar internamente). Antes esto vivía dentro de
/// _BadgeMensajesProfesional, cuando esa pestaña ERA la mezcla de ambas
/// señales; separarlas en dos badges visuales distintos (revisión UX
/// 2026-08-16) habría dejado dos widgets llamando a `actualizar()` por
/// su cuenta, pisándose el uno al otro según cuál reconstruyera último —
/// este widget invisible es el único punto que lo calcula y lo aplica,
/// para que ningún caller quede "ganando por casualidad".
class _ActualizadorBadgeAppProfesional extends ConsumerWidget {
  const _ActualizadorBadgeAppProfesional();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trabajosAsync = ref.watch(assignedRequestsProvider);
    final trabajos = trabajosAsync.maybeWhen(data: (lista) => lista, orElse: () => const <AssignedRequest>[]);
    final hayMensajesNoLeidos = trabajos.map((t) => t.id).any((id) => ref.watch(unreadChatProvider(id)));
    final trabajosVistos = ref.watch(trabajosVistosProvider);
    final hayTrabajoNuevoSinVer = contarTrabajosNuevosSinVer(trabajos, trabajosVistos) > 0;

    // Booleano (0/1), no la cuenta exacta — iOS no tiene un "punto sin
    // número" a nivel de sistema (ver app_badge_service.dart).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppBadgeService.instance.actualizar((hayMensajesNoLeidos || hayTrabajoNuevoSinVer) ? 1 : 0);
    });

    return const SizedBox.shrink();
  }
}

/// Badge de la pestaña Solicitudes — antes no había ninguna señal dentro
/// de la app de que hubiera una solicitud cercana nueva a la que
/// postularse; un profesional que ignorara o no viera el push "nueva
/// solicitud" podía no enterarse nunca. Sin estado "visto" persistente
/// (ver contarSolicitudesSinPostular más arriba): el número en vivo de
/// solicitudes sin postular ya es la señal correcta.
class _BadgeSolicitudesProfesional extends ConsumerWidget {
  const _BadgeSolicitudesProfesional({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solicitudesAsync = ref.watch(nearbyRequestsProvider);
    final solicitudes = solicitudesAsync.maybeWhen(
      data: (lista) => lista,
      orElse: () => const <NearbyRequest>[],
    );
    final numSinPostular = contarSolicitudesSinPostular(solicitudes);

    return Badge(
      isLabelVisible: numSinPostular > 0,
      label: Text('$numSinPostular'),
      child: child,
    );
  }
}
