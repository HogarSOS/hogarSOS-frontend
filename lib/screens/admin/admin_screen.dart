import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/admin_models.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../theme/brand_mark.dart';
import '../../utils/category_display.dart';
import '../../widgets/entrada_animada.dart';
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
    final t = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HogarSosMark(size: 28),
              const SizedBox(width: 10),
              Text(t.adminTituloPanel),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: t.perfilCerrarSesion,
              onPressed: _cerrarSesion,
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: t.adminTabVerificaciones),
              Tab(text: t.adminTabDisputas),
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

/// Diálogo de texto obligatorio con un mínimo de caracteres — mismo
/// patrón para "motivo del rechazo" y "notas de la resolución". Antes
/// cada uno tenía un TextField desnudo (sin label ni pista de qué
/// escribir) y, si el texto quedaba demasiado corto, el diálogo se
/// cerraba y la acción se descartaba en silencio — el admin nunca se
/// enteraba de que no había pasado nada. Ahora el botón de confirmar
/// permanece deshabilitado hasta que el texto es válido, con una ayuda
/// visible explicando el mínimo.
Future<String?> _pedirTextoObligatorio(
  BuildContext context, {
  required String titulo,
  required String hint,
  required String ayuda,
  required String confirmar,
  required String cancelar,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final valido = controller.text.trim().length >= 5;
        return AlertDialog(
          title: Text(titulo),
          // SingleChildScrollView + viewInsets.bottom: mismo fix que en
          // home_profesional_screen.dart — sin esto, con el teclado
          // abierto en un móvil pequeño (maxLines: 3 más el helperText
          // ocupan bastante alto) el diálogo puede desbordar por abajo.
          content: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(hintText: hint, helperText: ayuda),
              onChanged: (_) => setState(() {}),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(cancelar),
            ),
            FilledButton(
              onPressed: valido ? () => Navigator.of(context).pop(controller.text.trim()) : null,
              child: Text(confirmar),
            ),
          ],
        );
      },
    ),
  );
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

  Future<void> _recargar() async {
    setState(() => _futuro = widget.adminService.listarVerificacionesPendientes());
    await _futuro.catchError((_) => <PendingVerification>[]);
  }

  Future<void> _decidir(PendingVerification v, bool aprobar) async {
    final t = AppLocalizations.of(context);
    String? motivo;
    if (!aprobar) {
      motivo = await _pedirTextoObligatorio(
        context,
        titulo: t.adminMotivoRechazoTitulo,
        hint: t.adminMotivoRechazoHint,
        ayuda: t.adminMotivoRechazoAyuda,
        confirmar: t.adminConfirmar,
        cancelar: t.perfilCancelar,
      );
      if (motivo == null) return; // cancelado
    }

    try {
      await widget.adminService.decidirVerificacion(
        professionalId: v.userId,
        aprobar: aprobar,
        motivoRechazo: motivo,
      );
      if (!mounted) return;
      await _recargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.adminDecisionError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return FutureBuilder<List<PendingVerification>>(
      future: _futuro,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _EstadoLista(
            icono: Icons.error_outline,
            mensaje: t.adminVerificacionesError,
            onRefresh: _recargar,
          );
        }
        final verificaciones = snapshot.data!;
        if (verificaciones.isEmpty) {
          return _EstadoLista(
            icono: Icons.verified_outlined,
            mensaje: t.adminVerificacionesVacio,
            onRefresh: _recargar,
          );
        }
        return RefreshIndicator(
          onRefresh: _recargar,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: verificaciones.length,
            itemBuilder: (context, index) {
              final v = verificaciones[index];
              final categorias = v.categorias.map((c) => nombreLocalizadoCategoria(context, c)).join(', ');
              return EntradaAnimada(
                retraso: Duration(milliseconds: 30 * index),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                          const SizedBox(height: 2),
                          Text(v.email, style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 8),
                          Text(t.adminCategoriasLabel(categorias), style: const TextStyle(fontSize: 13.5)),
                          const SizedBox(height: 10),
                          // Antes esta tarjeta no mostraba el documento de
                          // identidad en ningún sitio — el admin aprobaba o
                          // rechazaba sin poder ver lo que se supone que
                          // está revisando.
                          _DocumentoIdentidadPreview(url: v.documentoIdentidadUrl),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _decidir(v, false),
                                  child: Text(t.adminRechazar),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _decidir(v, true),
                                  child: Text(t.adminAprobar),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
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

  Future<void> _recargar() async {
    setState(() => _futuro = widget.adminService.listarDisputas());
    await _futuro.catchError((_) => <DisputeSummary>[]);
  }

  Future<void> _resolver(DisputeSummary d, bool favorProfesional) async {
    final t = AppLocalizations.of(context);
    final notas = await _pedirTextoObligatorio(
      context,
      titulo: t.adminNotasResolucionTitulo,
      hint: t.adminNotasResolucionHint,
      ayuda: t.adminNotasResolucionAyuda,
      confirmar: t.adminConfirmar,
      cancelar: t.perfilCancelar,
    );
    if (notas == null) return; // cancelado

    try {
      await widget.adminService.resolverDisputa(
        disputeId: d.id,
        favorProfesional: favorProfesional,
        notas: notas,
      );
      if (!mounted) return;
      await _recargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.adminResolucionError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return FutureBuilder<List<DisputeSummary>>(
      future: _futuro,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _EstadoLista(
            icono: Icons.error_outline,
            mensaje: t.adminDisputasError,
            onRefresh: _recargar,
          );
        }
        final disputas = snapshot.data!;
        if (disputas.isEmpty) {
          return _EstadoLista(
            icono: Icons.gavel_outlined,
            mensaje: t.adminDisputasVacio,
            onRefresh: _recargar,
          );
        }
        return RefreshIndicator(
          onRefresh: _recargar,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: disputas.length,
            itemBuilder: (context, index) {
              final d = disputas[index];
              return EntradaAnimada(
                retraso: Duration(milliseconds: 30 * index),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.motivo, style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _resolver(d, false),
                                  // "In favor of the customer" es bastante
                                  // más largo que "A favor del cliente" —
                                  // sin esto, el botón en inglés envolvía
                                  // a 2 líneas mientras el de al lado se
                                  // quedaba en 1, descuadrando el par.
                                  child: Text(
                                    t.adminFavorCliente,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _resolver(d, true),
                                  child: Text(
                                    t.adminFavorProfesional,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Estado vacío/error de una lista del panel admin — mismo lenguaje
/// visual que el resto de la app (icono + texto centrado, ver
/// home_profesional_screen.dart) en vez del `Text` suelto que había
/// antes. Envuelto en un `ListView` + `RefreshIndicator` (no un
/// `Center` a secas) para que "tirar hacia abajo para reintentar"
/// funcione también cuando la lista está vacía o falló la carga —
/// antes, un fallo de red dejaba al admin sin ninguna forma de
/// reintentar salvo salir y volver a entrar a la pantalla.
class _EstadoLista extends StatelessWidget {
  const _EstadoLista({required this.icono, required this.mensaje, required this.onRefresh});

  final IconData icono;
  final String mensaje;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Icon(icono, size: 48, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}

/// Miniatura del documento de identidad enviado por el profesional, con
/// zoom a pantalla completa al tocarla. Antes de esto el admin
/// aprobaba/rechazaba solo con nombre + email + categorías, sin ver
/// nunca el documento que se supone que está verificando — el propio
/// modelo (`PendingVerification.documentoIdentidadUrl`) ya traía el
/// dato desde el backend, solo no se pintaba en ningún sitio.
class _DocumentoIdentidadPreview extends StatelessWidget {
  const _DocumentoIdentidadPreview({required this.url});

  final String? url;

  void _verEnGrande(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton.filledTonal(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    // Registros de antes de que existiera el envío real de
    // documentación (o en los que el profesional aún no ha completado
    // el flujo) tienen documentoIdentidadUrl vacío — no hay nada que
    // previsualizar, así que se avisa en vez de intentar cargar una
    // imagen inexistente.
    final docUrl = url;
    if (docUrl == null || docUrl.isEmpty) {
      return Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: colorScheme.error),
          const SizedBox(width: 6),
          Text(
            t.adminDocumentoSinEnviar,
            style: TextStyle(fontSize: 12.5, color: colorScheme.error, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _verEnGrande(context, docUrl),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              docUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 48,
                height: 48,
                color: colorScheme.surfaceContainerHighest,
                child: Icon(Icons.broken_image_outlined, size: 20, color: colorScheme.onSurfaceVariant),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                        : null),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t.adminVerDocumento,
              style: TextStyle(fontSize: 12.5, color: colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
