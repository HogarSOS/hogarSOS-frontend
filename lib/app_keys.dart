import 'package:flutter/material.dart';

/// Claves globales de navegación, usadas por código que necesita
/// mostrar un SnackBar o navegar sin tener un BuildContext de pantalla
/// a mano — hoy solo DeepLinkListener (ver services/deep_link_listener.dart),
/// que reacciona a un deep link o una notificación push, no a una acción
/// del usuario dentro de una pantalla concreta.
final navigatorKey = GlobalKey<NavigatorState>();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Nombre de la ruta visible ahora mismo — solo de las rutas que se dan
/// explícitamente un `RouteSettings.name` al empujarlas (la mayoría de
/// pushes de la app no lo hace, y quedan como null). Pensado para que
/// código sin BuildContext propio (DeepLinkListener) pueda comprobar "ya
/// estoy en esa pantalla" antes de volver a empujarla — más fiable que
/// `ModalRoute.of()` con un context que no es el de la ruta en sí.
final routeObserver = _RutaActualObserver();
String? get rutaActual => routeObserver.nombreActual;

class _RutaActualObserver extends NavigatorObserver {
  String? nombreActual;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    nombreActual = route.settings.name;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    nombreActual = previousRoute?.settings.name;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    nombreActual = newRoute?.settings.name;
  }
}
