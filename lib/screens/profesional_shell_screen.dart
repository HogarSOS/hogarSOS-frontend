import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import 'profesional/home_profesional_screen.dart';
import 'profesional/disponibilidad_profesional_screen.dart';
import 'profesional/mi_perfil_profesional_screen.dart';

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

  /// Tras REGISTRARSE (no en un login normal) se pasa 2 (Perfil) desde
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

  static const _pantallas = [
    HomeProfesionalScreen(),
    DisponibilidadProfesionalScreen(),
    MiPerfilProfesionalScreen(),
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
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: t.navInicio,
            ),
            NavigationDestination(
              icon: const Icon(Icons.bolt_outlined),
              selectedIcon: const Icon(Icons.bolt),
              label: t.navDisponibilidad,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: t.navPerfil,
            ),
          ],
        ),
      ),
    );
  }
}
