import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'admin/admin_screen.dart';
import 'auth/login_screen.dart';
import 'cliente_shell_screen.dart';
import 'profesional_shell_screen.dart';
import 'splash_screen.dart';

/// Qué pantalla mostrar para un [AuthState] dado — pura, sin
/// `BuildContext`/`ref`, para poder probar el contrato exacto sin
/// necesidad de un `authProvider` real (que en su primer uso construye
/// `AuthNotifier`, cuyo constructor toca `FirebaseAuth.instance` —
/// fuera del alcance de esta suite de tests, ver
/// deep_link_stripe_pendiente_test.dart).
///
/// Revisión arquitectónica 2026-08-16: ESTA función, llamada desde
/// AuthGateScreen (la raíz de la app), es la ÚNICA fuente de verdad
/// sobre qué pantalla mostrar tras autenticarse — LoginScreen y
/// VerificarCodigoScreen ya NO construyen ellas mismas
/// ProfesionalShellScreen/ClienteShellScreen/AdminScreen; solo
/// actualizan authProvider y dejan que este switch reaccione solo.
/// Antes existían dos caminos construyendo la misma pantalla para el
/// mismo evento de login — la causa real del crash "Cannot use ref
/// after the widget was disposed" en el profesional (una instancia
/// quedaba con su listener/temporizador huérfano). Ver
/// test/auth_single_source_of_truth_test.dart, que además comprueba por
/// inspección del código fuente que ningún otro archivo construye estas
/// tres pantallas.
Widget construirPantallaSegunAuth(AuthState authState) {
  if (authState.restaurando) {
    return const HogarSosSplashScreen();
  }

  final usuario = authState.usuario;
  if (usuario == null) {
    return const LoginScreen();
  }

  return switch (usuario.role) {
    UserRole.profesional => const ProfesionalShellScreen(),
    UserRole.admin => const AdminScreen(),
    UserRole.cliente => const ClienteShellScreen(),
  };
}

/// Punto de entrada real de la app. Mientras se intenta restaurar la
/// sesión guardada (`restaurando == true`), muestra un loader — nunca
/// salta directamente al login sin comprobar antes si ya hay una
/// sesión válida guardada en el dispositivo.
class AuthGateScreen extends ConsumerWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return construirPantallaSegunAuth(ref.watch(authProvider));
  }
}