import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/service_request_model.dart';
import '../providers/chat_read_provider.dart';
import '../providers/service_request_provider.dart';
import 'cliente/home_cliente_screen.dart';
import 'cliente/buscar_screen.dart';
import 'cliente/mensajes_screen.dart';
import 'cliente/perfil_screen.dart';

/// Pestaña activa del shell del cliente — mismo patrón que
/// profesionalTabIndexProvider en profesional_shell_screen.dart: en un
/// provider (no estado local del shell) para que una pantalla dentro de
/// una pestaña (p. ej. BuscarScreen) sepa si es la pestaña visible sin
/// que el shell tenga que pasarle esa información a mano. Se usa para
/// que "Buscar" no dispare su búsqueda inicial (y el permiso de
/// ubicación) hasta que el usuario la visita de verdad — antes se
/// disparaba en cuanto se iniciaba sesión, porque IndexedStack
/// construye las 4 pestañas de golpe aunque solo una esté visible.
final clienteTabIndexProvider = StateProvider<int>((ref) => 0);

/// Contenedor de navegación inferior del cliente. Usa [IndexedStack] en
/// vez de reconstruir la pantalla cada vez que se cambia de pestaña —
/// así "Inicio" no pierde el scroll ni vuelve a pedir la ubicación cada
/// vez que el usuario mira "Perfil" y vuelve.
class ClienteShellScreen extends ConsumerStatefulWidget {
  const ClienteShellScreen({super.key});

  @override
  ConsumerState<ClienteShellScreen> createState() => _ClienteShellScreenState();
}

class _ClienteShellScreenState extends ConsumerState<ClienteShellScreen> {
  DateTime? _ultimaPulsacionAtras;

  static const _pantallas = [
    HomeClienteScreen(),
    BuscarScreen(),
    MensajesScreen(),
    PerfilScreen(),
  ];

  // Este shell es la raíz de la navegación tras el login/registro o al
  // restaurar sesión — no hay nada debajo a lo que volver. Sin este
  // PopScope, el botón atrás físico de Android cerraba la app de golpe
  // desde Inicio (mismo problema ya resuelto en ProfesionalShellScreen,
  // aquí faltaba igualarlo).
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
    final indiceActual = ref.watch(clienteTabIndexProvider);

    // Punto rojo en la pestaña "Mensajes" si alguna conversación activa
    // tiene un mensaje nuevo sin abrir — reutiliza
    // resumenActividadClienteProvider (ya compartido con Inicio y
    // Mensajes, sin llamada de red adicional) para saber qué
    // conversaciones existen, y unreadChatProvider por cada una.
    final resumenAsync = ref.watch(resumenActividadClienteProvider);
    final idsActivos = resumenAsync.maybeWhen(
      data: (lista) => lista
          .where((s) => s.estado == EstadoSolicitud.aceptada || s.estado == EstadoSolicitud.en_progreso)
          .map((s) => s.id),
      orElse: () => const Iterable<String>.empty(),
    );
    final hayMensajesNoLeidos = idsActivos.any((id) => ref.watch(unreadChatProvider(id)));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _onPopInvoked(didPop),
      child: Scaffold(
      body: IndexedStack(index: indiceActual, children: _pantallas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indiceActual,
        onDestinationSelected: (i) => ref.read(clienteTabIndexProvider.notifier).state = i,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: t.navInicio,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search),
            label: t.navBuscar,
          ),
          NavigationDestination(
            icon: Badge(isLabelVisible: hayMensajesNoLeidos, child: const Icon(Icons.chat_bubble_outline)),
            selectedIcon: Badge(isLabelVisible: hayMensajesNoLeidos, child: const Icon(Icons.chat_bubble)),
            label: t.navMensajes,
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
