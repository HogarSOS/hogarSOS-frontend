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
import '../screens/profesional_shell_screen.dart';
import 'notification_service.dart';

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
  // false, en vez de perderla como hace _procesar() con el link de
  // Stripe (ahí no hace falta: un deep link solo llega con la app ya en
  // marcha y, en la práctica, con sesión ya restaurada).
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

  // getInitialMessage() y onMessageOpenedApp (ver NotificationService)
  // pueden entregar el mismo mensaje dos veces en un arranque en frío —
  // FCM no lo garantiza mutuamente excluyente. `messageId` es estable
  // por mensaje, así que basta con recordar el último ya procesado.
  void _recibirNotificacion(RemoteMessage mensaje) {
    final id = mensaje.messageId;
    if (id != null && id == _ultimaNotificacionProcesadaId) {
      // [DIAG-NOTIF-IOS] temporal.
      debugPrint(
        '[DIAG-NOTIF-IOS] descartada en _recibirNotificacion: '
        'motivo=duplicado (mismo messageId ya procesado) messageId=$id',
      );
      return;
    }
    _notificacionPendiente = mensaje;
    _intentarProcesarNotificacionPendiente();
  }

  void _intentarProcesarNotificacionPendiente() {
    final mensaje = _notificacionPendiente;
    if (mensaje == null) {
      // [DIAG-NOTIF-IOS] temporal.
      debugPrint('[DIAG-NOTIF-IOS] _intentarProcesarNotificacionPendiente: nada pendiente, no hace nada');
      return;
    }

    final authState = ref.read(authProvider);
    if (authState.restaurando) {
      // [DIAG-NOTIF-IOS] temporal.
      debugPrint(
        '[DIAG-NOTIF-IOS] descartada en _intentarProcesarNotificacionPendiente: '
        'motivo=authState.restaurando=true (se reintentará cuando termine) '
        'messageId=${mensaje.messageId}',
      );
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
      // [DIAG-NOTIF-IOS] temporal.
      debugPrint(
        '[DIAG-NOTIF-IOS] descartada en _intentarProcesarNotificacionPendiente: '
        'motivo=sin usuario en sesión messageId=${mensaje.messageId}',
      );
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
    // [DIAG-NOTIF-IOS] temporal — punto de entrada, antes de cualquier
    // descarte posible, para saber siempre en qué estado llegó aquí.
    final authStateEntrada = ref.read(authProvider);
    debugPrint(
      '[DIAG-NOTIF-IOS] entrando en _navegarPorNotificacionAsync '
      'ts=${DateTime.now().toIso8601String()} '
      'navigatorNoNulo=${navigator != null} '
      'restaurando=${authStateEntrada.restaurando} '
      'tipo=$tipo solicitudId=$solicitudId rutaActual=$rutaActual',
    );

    if (solicitudId == null) {
      debugPrint('[DIAG-NOTIF-IOS] descartada en _navegarPorNotificacionAsync: motivo=solicitudId nulo en el payload');
      return;
    }

    if (navigator == null) {
      debugPrint('[DIAG-NOTIF-IOS] descartada en _navegarPorNotificacionAsync: motivo=navigatorKey.currentState es null');
      return;
    }

    if (tipo == 'chat_mensaje') {
      final ruta = 'chat/$solicitudId';
      if (rutaActual == ruta) {
        debugPrint('[DIAG-NOTIF-IOS] descartada en rama chat_mensaje: motivo=ya está viendo esa ruta ruta=$ruta');
        return; // ya está viendo ese chat
      }
      navigator.push(MaterialPageRoute(
        settings: RouteSettings(name: ruta),
        builder: (_) => ChatScreen(serviceRequestId: solicitudId),
      ));
      debugPrint(
        '[DIAG-NOTIF-IOS] navegación ejecutada ts=${DateTime.now().toIso8601String()} '
        'destino=$ruta rutaPrevia=$rutaActual resultado=push chat_mensaje ok',
      );
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
        debugPrint('[DIAG-NOTIF-IOS] descartada en rama cliente: motivo=ya está viendo esa ruta ruta=$ruta');
        return;
      }
      navigator.push(MaterialPageRoute(
        settings: RouteSettings(name: ruta),
        builder: (_) => SeguimientoSolicitudScreen(solicitudId: solicitudId),
      ));
      debugPrint(
        '[DIAG-NOTIF-IOS] navegación ejecutada ts=${DateTime.now().toIso8601String()} '
        'destino=$ruta rutaPrevia=$rutaActual resultado=push cliente ok',
      );
    } else if (role == UserRole.profesional) {
      // A diferencia de los dos casos de arriba (que empujan una pantalla
      // nueva, visible pase lo que pase), este solo cambia un provider que
      // pinta el shell del profesional — si el usuario ya tenía otra
      // pantalla empujada encima (p. ej. un chat abierto de otro trabajo),
      // el cambio de pestaña ocurría en silencio detrás sin que se viera.
      // Confirmado en real: tocar una notificación de "presupuesto
      // rechazado" con el chat abierto no hacía nada visible hasta volver
      // atrás — la pestaña correcta ya estaba seleccionada debajo.
      navigator.popUntil((route) => route.isFirst);
      debugPrint('[DIAG-NOTIF-IOS] rama profesional: popUntil ejecutado ts=${DateTime.now().toIso8601String()}');

      // En un arranque en frío, ProfesionalShellScreen acaba de montarse
      // y su propio initState() programa un addPostFrameCallback que
      // RESETEA profesionalTabIndexProvider a su valor por defecto (0) —
      // ver profesional_shell_screen.dart. Si fijamos la pestaña aquí en
      // el mismo instante, esa reset puede ejecutarse después y pisarnos
      // el valor. Confirmado en real: la notificación "postulacion_
      // aceptada" en frío aterrizaba en Perfil en vez de Trabajos activos.
      // Un pequeño margen deja que esa reset ya haya pasado antes de fijar
      // la pestaña de verdad.
      await Future.delayed(const Duration(milliseconds: 400));
      ref.read(profesionalTabIndexProvider.notifier).state = 2;
      debugPrint(
        '[DIAG-NOTIF-IOS] navegación ejecutada ts=${DateTime.now().toIso8601String()} '
        'destino=pestaña Trabajos activos (index 2) resultado=profesionalTabIndexProvider fijado a 2',
      );

      // [DIAG-NOTIF-IOS] temporal — relectura diferida para detectar si
      // algo sobrescribe el valor después de fijarlo aquí (escenario D).
      unawaited(Future.delayed(const Duration(milliseconds: 300), () {
        final valorActual = ref.read(profesionalTabIndexProvider);
        debugPrint(
          '[DIAG-NOTIF-IOS] relectura +300ms tras fijar pestaña: '
          'valorActual=$valorActual (esperado=2) '
          'ts=${DateTime.now().toIso8601String()}',
        );
      }));
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
    // Reintenta la notificación que llegó antes de que restaurando
    // terminara — ver el comentario de _notificacionPendiente arriba.
    ref.listen(authProvider, (previo, actual) {
      if (!actual.restaurando) _intentarProcesarNotificacionPendiente();
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
