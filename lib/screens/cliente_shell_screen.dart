import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'cliente/home_cliente_screen.dart';
import 'cliente/buscar_screen.dart';
import 'cliente/mensajes_screen.dart';
import 'cliente/perfil_screen.dart';

/// Contenedor de navegación inferior del cliente. Usa [IndexedStack] en
/// vez de reconstruir la pantalla cada vez que se cambia de pestaña —
/// así "Inicio" no pierde el scroll ni vuelve a pedir la ubicación cada
/// vez que el usuario mira "Perfil" y vuelve.
class ClienteShellScreen extends StatefulWidget {
  const ClienteShellScreen({super.key});

  @override
  State<ClienteShellScreen> createState() => _ClienteShellScreenState();
}

class _ClienteShellScreenState extends State<ClienteShellScreen> {
  int _indiceActual = 0;

  static const _pantallas = [
    HomeClienteScreen(),
    BuscarScreen(),
    MensajesScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(index: _indiceActual, children: _pantallas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceActual,
        onDestinationSelected: (i) => setState(() => _indiceActual = i),
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
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: t.navMensajes,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: t.navPerfil,
          ),
        ],
      ),
    );
  }
}
