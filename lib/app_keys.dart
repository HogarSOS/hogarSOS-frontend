import 'package:flutter/material.dart';

/// Claves globales de navegación, usadas por código que necesita
/// mostrar un SnackBar o navegar sin tener un BuildContext de pantalla
/// a mano — hoy solo DeepLinkListener (ver services/deep_link_listener.dart),
/// que reacciona a un deep link, no a una acción del usuario dentro de
/// una pantalla concreta.
final navigatorKey = GlobalKey<NavigatorState>();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
