import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_keys.dart';
import '../l10n/app_localizations.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/disponibilidad_provider.dart';
import '../providers/stripe_return_provider.dart';
import '../screens/chat_screen.dart';
import '../screens/cliente/seguimiento_solicitud_screen.dart';
import '../screens/profesional/trabajos_activos_profesional_screen.dart';
import '../screens/profesional_shell_screen.dart';
import 'notification_service.dart';

/// Deep link de Stripe Connect recibido antes de que authProvider
/// terminara de restaurar la sesión (posible con getInitialLink() en un
/// arranque en frío) — se reintenta en build() en cuanto restaurando pase
/// a false. Provider a nivel de módulo (no campo privado del State) para
/// poder probar el contrato exacto con un ProviderContainer, mismo
/// patrón que pendingProfesionalTabRequestProvider en
/// profesional_shell_screen.dart. Un segundo link mientras el primero
/// sigue pendiente simplemente sobrescribe este valor: el último gana,
/// sin encolar.
final pendingStripeReturnLinkProvider = StateProvider<Uri?>((ref) => null);

/// Qué hacer con el deep link de Stripe pendiente — pura, sin
/// BuildContext/ref/temporizadores de por medio, para poder probar el
/// contrato exacto sin montar DeepLinkListener (solo se llama cuando ya
/// se sabe que hay un URI pendiente). Mismo patrón que
/// resolverPestanaAlMontar en profesional_shell_screen.dart.
enum DecisionDeepLinkStripe { esperar, descartar, procesar }

DecisionDeepLinkStripe resolverDeepLinkStripePendiente({
  required bool restaurando,
  required UserRole? rolUsuario,
}) {
  if (restaurando) return DecisionDeepLinkStripe.esperar;
  if (rolUsuario != UserRole.profesional) return DecisionDeepLinkStripe.descartar;
  return DecisionDeepLinkStripe.procesar;
}

/// Envuelve el `home` de la app para escuchar dos cosas que llegan desde
/// fuera de una pantalla concreta, sin BuildContext propio:
///
/// 1. El deep link propio de retorno del onboarding de Stripe Connect
/// (`hogarsos://stripe-return/completado` o `/refresh`, ver
/// return_url/refresh_url en professional.controller.ts y
/// AndroidManifest.xml). Sin esto, Stripe devolvía al usuario a una
/// página web suelta y el estado real (`estadoCuentaStripe`) solo se
/// refrescaba la próxima vez que se abriera el perfil por casualidad.
///
/// 2. La notificación push que el usuario pulsó para abrir la app (ver
/// NotificationService.aperturasPorNotificacion) — antes de esto, tocar
/// una notificación no llevaba a ningún sitio, solo abría la app a su
/// pantalla por defecto, aunque el backend ya manda `solicitudId` (y
/// `tipo: 'chat_mensaje'` para el chat) en el payload `data` desde hace
/// meses. El backend sí sabe a dónde debería ir cada notificación; este
/// listener es lo que por fin lo aprovecha.
class DeepLinkListener extends ConsumerStatefulWidget {
  const DeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends ConsumerState<DeepLinkListener> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscripcion;
  StreamSubscription<RemoteMessage>? _aperturasSub;

  // Notificación recibida antes de que authProvider terminara de
  // restaurar la sesión (posible con getInitialMessage() en un arranque
  // en frío) — se reintenta en build() en cuanto restaurando pase a
  // false. Mismo problema y mismo mecanismo aplican al deep link de
  // Stripe, ver pendingStripeReturnLinkProvider arriba del todo.
  RemoteMessage? _notificacionPendiente;
  String? _ultimaNotificacionProcesadaId;

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

    unawaited(NotificationService.instance.iniciarListenersTemprano());
    unawaited(NotificationService.instance.comprobarMensajeInicial());
    unawaited(NotificationService.instance.comprobarNotificacionInicialNativa());
    _aperturasSub = NotificationService.instance.aperturasPorNotificacion.listen(_recibirNotificacion);
  }

  void _procesar(Uri uri) {
    if (uri.scheme != 'hogarsos' || uri.host != 'stripe-return') return;

    // No se procesa aquí mismo: se deja pendiente y se intenta de
    // inmediato — si authProvider ya terminó de restaurar (caso normal,
    // app caliente), _intentarProcesarDeepLinkPendiente() lo consume en
    // el acto, mismo comportamiento que antes. Si todavía no terminó
    // (arranque en frío), se reintenta solo una vez, cuando build() vea
    // `restaurando` pasar a false (ver más abajo) — nunca con un timer.
    ref.read(pendingStripeReturnLinkProvider.notifier).state = uri;
    _intentarProcesarDeepLinkPendiente();
  }

  void _intentarProcesarDeepLinkPendiente() {
    final uri = ref.read(pendingStripeReturnLinkProvider);
    if (uri == null) return;

    final authState = ref.read(authProvider);
    final decision = resolverDeepLinkStripePendiente(
      restaurando: authState.restaurando,
      rolUsuario: authState.usuario?.role,
    );
    if (decision == DecisionDeepLinkStripe.esperar) {
      return; // build() reintenta cuando restaurando pase a false
    }

    // Se limpia AQUÍ, tanto si se va a procesar como si se descarta —
    // restaurando solo pasa de true a false una vez en toda la vida de
    // la app (ver AuthNotifier._restaurarSesionInicial), así que esta es
    // la única ventana de reintento real. Limpiarlo incondicionalmente
    // evita que un login posterior (de la misma sesión de la app, con
    // restaurando ya en false para siempre) reciba un deep link de una
    // cuenta distinta que quedó sin consumir.
    ref.read(pendingStripeReturnLinkProvider.notifier).state = null;

    if (decision == DecisionDeepLinkStripe.descartar) return;

    ref.read(stripeReturnEventProvider.notifier).state++;
    ref.read(disponibilidadProvider.notifier).cargar();

    // Mismo patrón que _navegarPorNotificacionAsync (BUG 1, ayer): en un
    // arranque en frío, ProfesionalShellScreen puede estar montándose
    // justo ahora, y su propio initState() resetea profesionalTabIndexProvider
    // a pestanaInicial en un postFrameCallback — sin escribir también
    // pendingProfesionalTabRequestProvider, ese reset podía ejecutarse
    // DESPUÉS de esta línea y pisar el índice 3, dejando al profesional
    // en "Mi perfil". Confirmado en real con logging temporal: la
    // decisión llegaba a "procesar" y fijaba profesionalTabIndexProvider
    // correctamente, pero el shell lo sobrescribía justo después.
    // Escribir ambos, sin delay, hace que el resultado final sea el
    // mismo sea cual sea el orden real de ejecución — ver
    // profesional_shell_screen.dart.
    ref.read(pendingProfesionalTabRequestProvider.notifier).state = 3;
    ref.read(profesionalTabIndexProvider.notifier).state = 3;

    final context = navigatorKey.currentContext;
    if (context == null) return;
    final t = AppLocalizations.of(context);
    final esRefresh = uri.path.contains('refresh');
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(esRefresh ? t.cuentaCobroStripeCaducado : t.cuentaCobroStripeActualizando)),
    );
  }

  // getInitialMessage() y onMessageOpenedApp (ver NotificationService)
  // pueden entregar el mismo mensaje dos veces en un arranque en frío —
  // FCM no lo garantiza mutuamente excluyente. `messageId` es estable
  // por mensaje, así que basta con recordar el último ya procesado.
  void _recibirNotificacion(RemoteMessage mensaje) {
    final id = mensaje.messageId;
    if (id != null && id == _ultimaNotificacionProcesadaId) {
      return;
    }
    _notificacionPendiente = mensaje;
    _intentarProcesarNotificacionPendiente();
  }

  void _intentarProcesarNotificacionPendiente() {
    final mensaje = _notificacionPendiente;
    if (mensaje == null) {
      return;
    }

    final authState = ref.read(authProvider);
    if (authState.restaurando) {
      return; // build() reintenta cuando termine
    }

    _notificacionPendiente = null;
    _ultimaNotificacionProcesadaId = mensaje.messageId;

    // Sin sesión no hay ninguna pantalla privada a la que navegar — se
    // descarta sin más (quien tocó la notificación la recibió porque
    // tenía sesión cuando llegó; no merece la pena "recordarla" hasta
    // después de un login manual posterior).
    final usuario = authState.usuario;
    if (usuario == null) {
      return;
    }

    _navegarPorNotificacion(mensaje, usuario.role);
  }

  void _navegarPorNotificacion(RemoteMessage mensaje, UserRole role) {
    unawaited(_navegarPorNotificacionAsync(mensaje, role));
  }

  Future<void> _navegarPorNotificacionAsync(RemoteMessage mensaje, UserRole role) async {
    final solicitudId = mensaje.data['solicitudId'] as String?;
    final tipo = mensaje.data['tipo'] as String?;
    final navigator = navigatorKey.currentState;

    if (solicitudId == null) {
      return;
    }

    if (navigator == null) {
      return;
    }

    if (tipo == 'chat_mensaje') {
      final ruta = 'chat/$solicitudId';
      if (rutaActual == ruta) {
        return; // ya está viendo ese chat
      }
      // El título de la notificación de chat ES el nombre de quien
      // escribe (ver notifyChatMessage en el backend), es decir, la
      // contraparte desde el punto de vista de quien recibe — así el
      // AppBar del chat abierto desde la notificación muestra el nombre
      // en vez del genérico "Chat". `notification` puede ser null en la
      // vía nativa de iOS (solo data), y ahí ChatScreen cae con gracia
      // al título genérico, igual que antes.
      navigator.push(MaterialPageRoute(
        settings: RouteSettings(name: ruta),
        builder: (_) => ChatScreen(
          serviceRequestId: solicitudId,
          nombreContraparte: mensaje.notification?.title,
        ),
      ));
      return;
    }

    // Resto de tipos (nueva_postulacion, presupuesto_aceptado,
    // postulacion_aceptada...): el cliente tiene una pantalla de
    // seguimiento por solicitud; el profesional no (su pantalla de
    // Trabajos activos es una lista con las acciones en cada tarjeta,
    // sin ruta propia por trabajo) — llevarlo a esa pestaña es lo más
    // preciso que se puede hacer hoy sin construir una pantalla nueva.
    if (role == UserRole.cliente) {
      final ruta = 'solicitud/$solicitudId';
      if (rutaActual == ruta) {
        return;
      }
      navigator.push(MaterialPageRoute(
        settings: RouteSettings(name: ruta),
        builder: (_) => SeguimientoSolicitudScreen(solicitudId: solicitudId),
      ));
    } else if (role == UserRole.profesional) {
      // A diferencia del caso cliente de arriba (que empuja una pantalla
      // nueva, visible pase lo que pase), el caso "Solicitudes" de abajo
      // solo cambia un provider que pinta el shell del profesional — si
      // el usuario ya tenía otra pantalla empujada encima (p. ej. un chat
      // abierto de otro trabajo), el cambio de pestaña ocurría en
      // silencio detrás sin que se viera. Confirmado en real: tocar una
      // notificación de "presupuesto rechazado" con el chat abierto no
      // hacía nada visible hasta volver atrás — la pestaña correcta ya
      // estaba seleccionada debajo. popUntil primero cubre ambos casos.
      navigator.popUntil((route) => route.isFirst);

      final destino = resolverDestinoNotificacionProfesional(tipo);

      switch (destino) {
        case DestinoNotificacionProfesional.solicitudes:
          // Sin delay ni carrera de tiempos: se escriben los DOS
          // providers de forma síncrona.
          // - profesionalTabIndexProvider directo: gana cuando el shell
          //   ya está estable (caso normal — la app llevaba un rato
          //   abierta).
          // - pendingProfesionalTabRequestProvider: red de seguridad
          //   para el caso de arranque en frío, donde
          //   ProfesionalShellScreen puede estar montándose justo ahora
          //   — su propio initState() consulta este valor en su
          //   postFrameCallback y lo hace ganar sobre `pestanaInicial`
          //   si lo encuentra (ver profesional_shell_screen.dart). Cuál
          //   de los dos escribe "el último" ya no importa: el
          //   resultado final es el mismo sea cual sea el orden real de
          //   ejecución.
          ref.read(pendingProfesionalTabRequestProvider.notifier).state = 1;
          ref.read(profesionalTabIndexProvider.notifier).state = 1;
          break;
        case DestinoNotificacionProfesional.trabajosActivos:
          // Revisión UX 2026-08-16: Trabajos activos dejó de ser una
          // pestaña (el índice 2 ahora es Mensajes, solo conversaciones)
          // — postulacion_aceptada, presupuesto_aceptado, cierre_horas_*
          // y ampliacion_* ya no pueden resolverse con un simple cambio
          // de índice, hace falta un push real, mismo camino que ya usa
          // la tarjeta "Tienes X trabajos activos" de Solicitudes.
          navigator.push(MaterialPageRoute(builder: (_) => const TrabajosActivosProfesionalScreen()));
          break;
        case DestinoNotificacionProfesional.centroPagos:
          // pago_autorizado → pestaña Pagos (índice 3). Mismo doble
          // write que el caso "solicitudes" de arriba y que el retorno
          // de Stripe Connect: directo para el shell ya estable,
          // pendiente como red de seguridad del arranque en frío.
          ref.read(pendingProfesionalTabRequestProvider.notifier).state = 3;
          ref.read(profesionalTabIndexProvider.notifier).state = 3;
          break;
      }
    }
  }

  @override
  void dispose() {
    _subscripcion?.cancel();
    _aperturasSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reintenta la notificación y/o el deep link de Stripe que hayan
    // llegado antes de que restaurando terminara — ver los comentarios
    // de _notificacionPendiente y pendingStripeReturnLinkProvider arriba.
    ref.listen(authProvider, (previo, actual) {
      if (!actual.restaurando) {
        _intentarProcesarNotificacionPendiente();
        _intentarProcesarDeepLinkPendiente();
      }
    });
    // Build 34 — mecanismo de recuperación, no solución definitiva: ver
    // comprobarToquePendienteTrasInteraccion en NotificationService. Solo
    // observa (no intercepta) el primer toque en pantalla tras un mensaje
    // en primer plano; no hace nada si no hay ningún mensaje pendiente por
    // messageId.
    return Listener(
      onPointerDown: (_) => unawaited(NotificationService.instance.comprobarToquePendienteTrasInteraccion()),
      child: widget.child,
    );
  }
}
