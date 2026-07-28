import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'admin/admin_screen.dart';
import 'auth/login_screen.dart';
import 'cliente_shell_screen.dart';
import 'profesional_shell_screen.dart';
import 'splash_screen.dart';

/// Punto de entrada real de la app. Mientras se intenta restaurar la
/// sesión guardada (`restaurando == true`), muestra un loader — nunca
/// salta directamente al login sin comprobar antes si ya hay una
/// sesión válida guardada en el dispositivo.
class AuthGateScreen extends ConsumerWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

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
}