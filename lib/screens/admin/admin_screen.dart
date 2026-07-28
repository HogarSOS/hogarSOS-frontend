import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/admin_models.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../auth/login_screen.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _adminService = AdminService();

  // El panel admin, igual que el de profesional, no tenía ningún punto
  // de la UI para cerrar sesión — solo la pantalla de perfil del cliente
  // lo tenía. Sin confirmación: el admin es un rol de confianza y esta
  // acción es fácilmente reversible (solo cierra la sesión local).
  Future<void> _cerrarSesion() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel admin'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: _cerrarSesion,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Verificaciones'),
              Tab(text: 'Disputas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _VerificacionesTab(adminService: _adminService),
            _DisputasTab(adminService: _adminService),
          ],
        ),
      ),
    );
  }
}

class _VerificacionesTab extends StatefulWidget {
  const _VerificacionesTab({required this.adminService});
  final AdminService adminService;

  @override
  State<_VerificacionesTab> createState() => _VerificacionesTabState();
}

class _VerificacionesTabState extends State<_VerificacionesTab> {
  late Future<List<PendingVerification>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = widget.adminService.listarVerificacionesPendientes();
  }

  void _recargar() {
    setState(() => _futuro = widget.adminService.listarVerificacionesPendientes());
  }

  Future<void> _decidir(PendingVerification v, bool aprobar) async {
    String? motivo;
    if (!aprobar) {
      motivo = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Motivo del rechazo'),
            content: TextField(controller: controller, autofocus: true),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      );
      if (motivo == null || motivo.length < 5) return; // cancelado o demasiado corto
    }

    await widget.adminService.decidirVerificacion(
      professionalId: v.userId,
      aprobar: aprobar,
      motivoRechazo: motivo,
    );
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PendingVerification>>(
      future: _futuro,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final verificaciones = snapshot.data!;
        if (verificaciones.isEmpty) {
          return const Center(child: Text('No hay verificaciones pendientes'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: verificaciones.length,
          itemBuilder: (context, index) {
            final v = verificaciones[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(v.email, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text('Categorías: ${v.categorias.join(", ")}'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _decidir(v, false),
                            child: const Text('Rechazar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _decidir(v, true),
                            child: const Text('Aprobar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DisputasTab extends StatefulWidget {
  const _DisputasTab({required this.adminService});
  final AdminService adminService;

  @override
  State<_DisputasTab> createState() => _DisputasTabState();
}

class _DisputasTabState extends State<_DisputasTab> {
  late Future<List<DisputeSummary>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = widget.adminService.listarDisputas();
  }

  void _recargar() {
    setState(() => _futuro = widget.adminService.listarDisputas());
  }

  Future<void> _resolver(DisputeSummary d, bool favorProfesional) async {
    final notas = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Notas de la resolución'),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
    if (notas == null || notas.length < 5) return;

    await widget.adminService.resolverDisputa(
      disputeId: d.id,
      favorProfesional: favorProfesional,
      notas: notas,
    );
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DisputeSummary>>(
      future: _futuro,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final disputas = snapshot.data!;
        if (disputas.isEmpty) {
          return const Center(child: Text('No hay disputas abiertas'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: disputas.length,
          itemBuilder: (context, index) {
            final d = disputas[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.motivo),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _resolver(d, false),
                            child: const Text('A favor del cliente'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _resolver(d, true),
                            child: const Text('A favor del profesional'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
