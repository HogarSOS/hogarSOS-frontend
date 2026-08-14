import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/service_request_model.dart';
import '../providers/chat_read_provider.dart';
import '../providers/service_request_provider.dart';
import '../services/app_badge_service.dart';
import 'cliente/home_cliente_screen.dart';
import 'cliente/mensajes_screen.dart';
import 'cliente/perfil_screen.dart';

/// Pestaña activa del shell del cliente — mismo patrón que
/// profesionalTabIndexProvider en profesional_shell_screen.dart: en un
/// provider (no estado local del shell) para que una pantalla dentro de
/// una pestaña sepa si es la pestaña visible sin que el shell tenga que
/// pasarle esa información a mano. Útil para pantallas que no deben
/// disparar su carga inicial (p. ej. permisos, red) hasta que el
/// usuario las visita de verdad — IndexedStack construye todas las
/// pestañas de golpe aunque solo una esté visible.
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

  // "Buscar" se quitó de la navegación (ver home_cliente_screen.dart) —
  // buscar_screen.dart sigue intacto, solo no está en esta lista ni en
  // los destinos de la barra de abajo.
  static const _pantallas = [
    HomeClienteScreen(),
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
            icon: const _BadgeMensajesCliente(child: Icon(Icons.chat_bubble_outline)),
            selectedIcon: const _BadgeMensajesCliente(child: Icon(Icons.chat_bubble)),
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

/// Badge de la pestaña Mensajes, aislado en su propio [ConsumerWidget]
/// (rendimiento, auditoría pre-lanzamiento): antes este cálculo vivía en
/// el build() del shell entero, así que CUALQUIER cambio de
/// unreadChatProvider reconstruía todo el Scaffold/NavigationBar, no
/// solo el punto rojo. Aquí solo se reconstruye este icono pequeño.
class _BadgeMensajesCliente extends ConsumerWidget {
  const _BadgeMensajesCliente({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reutiliza resumenActividadClienteProvider (ya compartido con
    // Inicio y Mensajes, sin llamada de red adicional) para saber qué
    // conversaciones existen, y unreadChatProvider por cada una.
    final resumenAsync = ref.watch(resumenActividadClienteProvider);
    final idsActivos = resumenAsync.maybeWhen(
      data: (lista) => lista
          .where((s) => s.estado == EstadoSolicitud.aceptada || s.estado == EstadoSolicitud.en_progreso)
          .map((s) => s.id),
      orElse: () => const Iterable<String>.empty(),
    );
    final numConversacionesNoLeidas = idsActivos.where((id) => ref.watch(unreadChatProvider(id))).length;
    final hayMensajesNoLeidos = numConversacionesNoLeidas > 0;

    // Badge del icono de la app (UX#6) — booleano (0/1), no la cuenta
    // exacta: ver el razonamiento completo en profesional_shell_screen.dart
    // (mismo cambio, iOS no soporta un "punto sin número" a nivel de
    // sistema).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppBadgeService.instance.actualizar(hayMensajesNoLeidos ? 1 : 0);
    });

    return Badge(
      isLabelVisible: hayMensajesNoLeidos,
      label: Text('$numConversacionesNoLeidas'),
      child: child,
    );
  }
}
