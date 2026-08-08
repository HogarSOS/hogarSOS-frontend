import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/admin_models.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../theme/brand_mark.dart';
import '../../utils/category_display.dart';
import '../../utils/error_extraction.dart';
import '../../widgets/entrada_animada.dart';
import '../auth/login_screen.dart';
import '../../utils/imagen_autenticada.dart';

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
      length: 4,
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
            isScrollable: true,
            tabs: [
              Tab(text: t.adminTabVerificaciones),
              Tab(text: t.adminTabDisputas),
              Tab(text: t.adminTabPagosAtascados),
              Tab(text: t.adminTabTareas),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _VerificacionesTab(adminService: _adminService),
            _DisputasTab(adminService: _adminService),
            _PagosAtascadosTab(adminService: _adminService),
            _TareasProgramadasTab(adminService: _adminService),
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

/// Diálogo de confirmación simple (sí/no), sin texto obligatorio — para
/// acciones donde solo hace falta confirmar la intención, no explicar un
/// motivo (a diferencia de `_pedirTextoObligatorio`, usado para rechazar
/// una verificación o resolver una disputa).
Future<bool> _confirmarAccion(
  BuildContext context, {
  required String titulo,
  required String texto,
  required String confirmar,
  required String cancelar,
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(texto),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelar),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmar),
        ),
      ],
    ),
  );
  return resultado ?? false;
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

/// Cola de pagos atascados (`GET /admin/payments/stuck`) — dinero
/// capturado sin transferir al profesional, o trabajo completado cuya
/// autorización nunca llegó a capturarse. Reutiliza exactamente el mismo
/// `retryPaymentRelease`/`releasePayments` idempotente del flujo normal
/// (ver `payment.service.ts`) — esta pantalla no mueve dinero por su
/// cuenta, solo pide al backend que reintente.
class _PagosAtascadosTab extends StatefulWidget {
  const _PagosAtascadosTab({required this.adminService});
  final AdminService adminService;

  @override
  State<_PagosAtascadosTab> createState() => _PagosAtascadosTabState();
}

class _PagosAtascadosTabState extends State<_PagosAtascadosTab> {
  late Future<StuckPaymentsSummary> _futuro;

  // Bloquea el botón del pago concreto que está en curso — no toda la
  // pantalla — así un reintento en un pago no impide ver/actuar sobre
  // el resto de la lista mientras tanto.
  final Set<String> _procesando = {};

  @override
  void initState() {
    super.initState();
    _futuro = widget.adminService.listarPagosAtascados();
  }

  Future<void> _recargar() async {
    setState(() => _futuro = widget.adminService.listarPagosAtascados());
    await _futuro.catchError(
      (_) => StuckPaymentsSummary(total: 0, importeRetenidoEnPlataforma: 0, pagos: []),
    );
  }

  Future<void> _reintentar(StuckPayment pago) async {
    final t = AppLocalizations.of(context);
    final confirmado = await _confirmarAccion(
      context,
      titulo: t.adminReintentarLiberacionConfirmarTitulo,
      texto: t.adminReintentarLiberacionConfirmarTexto,
      confirmar: t.adminConfirmar,
      cancelar: t.perfilCancelar,
    );
    if (!confirmado) return;
    if (!mounted) return;

    setState(() => _procesando.add(pago.serviceRequestId));
    try {
      await widget.adminService.reintentarLiberacion(pago.serviceRequestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.adminReintentarLiberacionExito)),
      );
      await _recargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.adminPagosAtascadosError, t: t))),
      );
    } finally {
      if (mounted) setState(() => _procesando.remove(pago.serviceRequestId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return FutureBuilder<StuckPaymentsSummary>(
      future: _futuro,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _EstadoLista(
            icono: Icons.error_outline,
            mensaje: t.adminPagosAtascadosError,
            onRefresh: _recargar,
          );
        }
        final resumen = snapshot.data!;
        if (resumen.pagos.isEmpty) {
          return _EstadoLista(
            icono: Icons.task_alt_outlined,
            mensaje: t.adminPagosAtascadosVacio,
            onRefresh: _recargar,
          );
        }
        return RefreshIndicator(
          onRefresh: _recargar,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: resumen.pagos.length + 1, // +1 = cabecera de resumen
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    t.adminPagosAtascadosResumen(
                      resumen.total,
                      resumen.importeRetenidoEnPlataforma.toStringAsFixed(2),
                    ),
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                );
              }
              final pago = resumen.pagos[index - 1];
              return EntradaAnimada(
                retraso: Duration(milliseconds: 30 * (index - 1)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PagoAtascadoCard(
                    pago: pago,
                    procesando: _procesando.contains(pago.serviceRequestId),
                    onReintentar: () => _reintentar(pago),
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

class _PagoAtascadoCard extends StatelessWidget {
  const _PagoAtascadoCard({
    required this.pago,
    required this.procesando,
    required this.onReintentar,
  });

  final StuckPayment pago;
  final bool procesando;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final formatoFecha = DateFormat.yMMMd(t.localeName).add_Hm();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  pago.dineroRetenidoEnPlataforma ? Icons.warning_amber_rounded : Icons.hourglass_bottom_rounded,
                  size: 18,
                  color: pago.dineroRetenidoEnPlataforma ? colorScheme.error : colorScheme.tertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pago.dineroRetenidoEnPlataforma
                        ? t.adminPagoAtascadoCapturadoSinTransferir
                        : t.adminPagoAtascadoCompletadoSinCapturar,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: pago.dineroRetenidoEnPlataforma ? colorScheme.error : colorScheme.tertiary,
                    ),
                  ),
                ),
                Text(
                  '${pago.montoProfesional.toStringAsFixed(2)} €',
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              nombreLocalizadoCategoria(context, pago.categoria),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              '${pago.clienteNombre} → ${pago.profesionalNombre ?? t.adminPagoAtascadoSinProfesional}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              t.adminPagoAtascadoAutorizadoEl(formatoFecha.format(pago.createdAt)),
              style: const TextStyle(fontSize: 12.5),
            ),
            if (pago.capturadoAt != null)
              Text(
                t.adminPagoAtascadoCapturadoEl(formatoFecha.format(pago.capturadoAt!)),
                style: const TextStyle(fontSize: 12.5),
              ),
            if (pago.intentosLiberacion > 0)
              Text(
                t.adminPagoAtascadoIntentos(pago.intentosLiberacion),
                style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
              ),
            if (pago.ultimoError != null) ...[
              const SizedBox(height: 4),
              Text(
                t.adminPagoAtascadoUltimoError(pago.ultimoError!),
                style: TextStyle(fontSize: 12.5, color: colorScheme.error),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: procesando ? null : onReintentar,
                icon: procesando
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.replay, size: 18),
                label: Text(t.adminReintentarLiberacion),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tareas programadas (`GET /admin/jobs`, `POST /admin/jobs/:nombre/run`)
/// — mismo patrón que `_PagosAtascadosTab`: el backend ya gestiona el
/// lock y la idempotencia (`ejecutarTareaAhora` en `scheduler.ts`), esta
/// pantalla solo pide confirmación y muestra el resultado.
class _TareasProgramadasTab extends StatefulWidget {
  const _TareasProgramadasTab({required this.adminService});
  final AdminService adminService;

  @override
  State<_TareasProgramadasTab> createState() => _TareasProgramadasTabState();
}

class _TareasProgramadasTabState extends State<_TareasProgramadasTab> {
  late Future<List<ScheduledJob>> _futuro;

  // Igual que en pagos atascados: bloquea solo el botón de la tarea
  // concreta en curso, no toda la pantalla.
  final Set<String> _procesando = {};

  @override
  void initState() {
    super.initState();
    _futuro = widget.adminService.listarTareas();
  }

  Future<void> _recargar() async {
    setState(() => _futuro = widget.adminService.listarTareas());
    await _futuro.catchError((_) => <ScheduledJob>[]);
  }

  Future<void> _ejecutar(ScheduledJob tarea) async {
    final t = AppLocalizations.of(context);
    final confirmado = await _confirmarAccion(
      context,
      titulo: t.adminEjecutarAhoraConfirmarTitulo,
      texto: t.adminEjecutarAhoraConfirmarTexto,
      confirmar: t.adminConfirmar,
      cancelar: t.perfilCancelar,
    );
    if (!confirmado) return;
    if (!mounted) return;

    setState(() => _procesando.add(tarea.nombre));
    try {
      await widget.adminService.ejecutarTareaAhora(tarea.nombre);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.adminEjecutarAhoraExito)),
      );
      await _recargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.adminTareasError, t: t))),
      );
    } finally {
      if (mounted) setState(() => _procesando.remove(tarea.nombre));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return FutureBuilder<List<ScheduledJob>>(
      future: _futuro,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _EstadoLista(
            icono: Icons.error_outline,
            mensaje: t.adminTareasError,
            onRefresh: _recargar,
          );
        }
        final tareas = snapshot.data!;
        if (tareas.isEmpty) {
          return _EstadoLista(
            icono: Icons.schedule_outlined,
            mensaje: t.adminTareasVacio,
            onRefresh: _recargar,
          );
        }
        return RefreshIndicator(
          onRefresh: _recargar,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tareas.length,
            itemBuilder: (context, index) {
              final tarea = tareas[index];
              return EntradaAnimada(
                retraso: Duration(milliseconds: 30 * index),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TareaCard(
                    tarea: tarea,
                    procesando: _procesando.contains(tarea.nombre),
                    onEjecutar: () => _ejecutar(tarea),
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

class _TareaCard extends StatelessWidget {
  const _TareaCard({
    required this.tarea,
    required this.procesando,
    required this.onEjecutar,
  });

  final ScheduledJob tarea;
  final bool procesando;
  final VoidCallback onEjecutar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final formatoFecha = DateFormat.yMMMd(t.localeName).add_Hm();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    tarea.descripcion,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                if (tarea.enCurso)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t.adminTareaEnCurso,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colorScheme.tertiary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${tarea.nombre} · ${t.adminTareaCada(tarea.intervaloMinutos)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              tarea.ultimaEjecucionAt != null
                  ? t.adminTareaUltimaEjecucion(formatoFecha.format(tarea.ultimaEjecucionAt!))
                  : t.adminTareaNuncaEjecutada,
              style: const TextStyle(fontSize: 12.5),
            ),
            if (tarea.proximaEjecucionAprox != null)
              Text(
                t.adminTareaProximaEjecucion(formatoFecha.format(tarea.proximaEjecucionAprox!)),
                style: const TextStyle(fontSize: 12.5),
              ),
            Text(
              t.adminTareaEjecuciones(tarea.ejecuciones),
              style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
            ),
            if (tarea.fallosConsecutivos > 0)
              Text(
                t.adminTareaFallosConsecutivos(tarea.fallosConsecutivos),
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colorScheme.error),
              ),
            if (tarea.ultimoResultado != null) ...[
              const SizedBox(height: 4),
              Text(
                t.adminTareaUltimoResultado(tarea.ultimoResultado!),
                style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
              ),
            ],
            if (tarea.ultimoError != null) ...[
              const SizedBox(height: 4),
              Text(
                t.adminTareaUltimoError(tarea.ultimoError!),
                style: TextStyle(fontSize: 12.5, color: colorScheme.error),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (procesando || tarea.enCurso) ? null : onEjecutar,
                icon: procesando
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(t.adminEjecutarAhora),
              ),
            ),
          ],
        ),
      ),
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
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                // Desde B4 el documento solo se sirve con sesión válida
                // y rol admin — sin esta cabecera, 404.
                httpHeaders: cabecerasImagen(),
              ),
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
            child: CachedNetworkImage(
              imageUrl: docUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              // memCacheWidth/Height: decodifica ya a tamaño de miniatura en
              // vez de decodificar la imagen completa (hasta 1920px tras el
              // redimensionado del servidor) solo para mostrarla a 48x48 —
              // esta miniatura se repite por cada profesional pendiente de
              // revisión en la cola del admin.
              memCacheWidth: 96,
              memCacheHeight: 96,
              errorWidget: (context, url, error) => Container(
                width: 48,
                height: 48,
                color: colorScheme.surfaceContainerHighest,
                child: Icon(Icons.broken_image_outlined, size: 20, color: colorScheme.onSurfaceVariant),
              ),
              placeholder: (context, url) => SizedBox(
                width: 48,
                height: 48,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
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
