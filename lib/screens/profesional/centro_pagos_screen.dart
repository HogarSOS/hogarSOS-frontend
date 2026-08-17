import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/stripe_return_provider.dart';
import '../profesional_shell_screen.dart';
import '../../services/payment_service.dart';
import '../../services/professional_service.dart';
import '../../utils/category_display.dart';
import '../../widgets/entrada_animada.dart';

/// Centro de Pagos del profesional (roadmap económico, puntos 1 y 6):
/// cuenta de cobro, Pendiente, Disponible e historial de cobros.
/// Deliberadamente NO muestra "Próximo pago" — los payouts de HogarSOS
/// son bajo demanda, no hay una fecha de pago recurrente que enseñar.
///
/// "Pendiente"/"Disponible" vienen del saldo REAL de Stripe
/// (`GET /payments/me/summary` → `stripe.balance.retrieve`), no de una
/// suma calculada localmente — ver `payment.service.ts` en el backend.
class CentroPagosScreen extends ConsumerStatefulWidget {
  const CentroPagosScreen({super.key});

  @override
  ConsumerState<CentroPagosScreen> createState() => _CentroPagosScreenState();
}

class _CentroPagosScreenState extends ConsumerState<CentroPagosScreen> {
  final _paymentService = PaymentService();
  final _professionalService = ProfessionalService();

  PaymentsSummary? _resumen;
  bool _cargando = true;
  bool _error = false;
  bool _iniciandoOnboardingStripe = false;

  // Carga diferida (auditoría de escalabilidad 2026-08-17): este widget
  // vive en el IndexedStack del shell, que lo monta al abrir la app
  // aunque la pestaña no esté visible — antes su initState disparaba
  // GET /payments/me/summary (que además llama a stripe.balance.retrieve
  // en el backend) en CADA apertura de la app de CADA profesional,
  // compitiendo por red y conexiones con las llamadas que sí pintan la
  // pestaña visible. Mismo patrón que la búsqueda inicial de
  // buscar_screen.dart: no se carga hasta que la pestaña se selecciona
  // de verdad (índice 3 en ProfesionalShellScreen).
  bool _yaCargoInicial = false;

  Future<void> _cargar() async {
    try {
      final resumen = await _paymentService.obtenerResumenPagos();
      if (!mounted) return;
      setState(() {
        _resumen = resumen;
        _cargando = false;
        _error = false;
      });
    } catch (e) {
      debugPrint('[CentroPagosScreen] Error al cargar el resumen de pagos: $e');
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = true;
      });
    }
  }

  Future<void> _configurarCuentaCobro() async {
    setState(() => _iniciandoOnboardingStripe = true);
    try {
      final url = await _professionalService.iniciarOnboardingStripe();
      final abierto = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!abierto && mounted) {
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.cuentaCobroErrorAbrir)));
      }
    } catch (e) {
      debugPrint('[CentroPagosScreen] Error al iniciar onboarding de Stripe: $e');
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.cuentaCobroErrorAbrir)));
    } finally {
      if (mounted) setState(() => _iniciandoOnboardingStripe = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    // Esta pantalla vive dentro de un IndexedStack (ver
    // profesional_shell_screen.dart) que la mantiene montada aunque no
    // esté visible, así que su propio initState no se vuelve a llamar
    // al volver de Stripe — sin esto, "Disponible"/"Pendiente" se
    // quedaban con el saldo de antes de configurar la cuenta de cobro
    // hasta el siguiente pull-to-refresh manual.
    ref.listen<int>(stripeReturnEventProvider, (anterior, actual) {
      if (anterior != null && anterior != actual) _cargar();
    });

    // Primera carga, diferida hasta que la pestaña esté seleccionada —
    // ver el comentario de _yaCargoInicial. Cubre también el salto
    // directo a esta pestaña desde una notificación (deep_link_listener
    // escribe el índice 3 en el mismo provider).
    if (!_yaCargoInicial && ref.watch(profesionalTabIndexProvider) == 3) {
      _yaCargoInicial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _cargar();
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.centroPagosTitulo)),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error || _resumen == null
              ? Center(child: Text(t.centroPagosErrorCargar))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                    children: [
                      EntradaAnimada(
                        child: _TarjetaCuentaCobro(
                          estado: _resumen!.estadoCuentaStripe,
                          cargando: _iniciandoOnboardingStripe,
                          onConfigurar: _configurarCuentaCobro,
                        ),
                      ),
                      const SizedBox(height: 16),
                      EntradaAnimada(
                        retraso: const Duration(milliseconds: 80),
                        child: Row(
                          children: [
                            Expanded(
                              child: _TarjetaSaldo(
                                icono: Icons.hourglass_top_outlined,
                                titulo: t.centroPagosPendiente,
                                ayuda: t.centroPagosPendienteAyuda,
                                monto: _resumen!.pendiente,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TarjetaSaldo(
                                icono: Icons.account_balance_wallet_outlined,
                                titulo: t.centroPagosDisponible,
                                ayuda: t.centroPagosDisponibleAyuda,
                                monto: _resumen!.disponible,
                                destacado: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      EntradaAnimada(
                        retraso: const Duration(milliseconds: 140),
                        child: Text(
                          t.centroPagosHistorialTitulo,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_resumen!.historial.isEmpty)
                        EntradaAnimada(
                          retraso: const Duration(milliseconds: 170),
                          child: _TarjetaVacia(texto: t.centroPagosHistorialVacio),
                        )
                      else
                        ..._resumen!.historial.asMap().entries.map(
                              (entry) => EntradaAnimada(
                                retraso: Duration(milliseconds: 170 + entry.key * 40),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ItemHistorial(cobro: entry.value),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
    );
  }
}

/// Decoración común a todas las tarjetas de esta pantalla — mismo
/// estilo que el resto de tarjetas del rol profesional (ver
/// mi_perfil_profesional_screen.dart).
BoxDecoration _decoracionTarjeta(ColorScheme colorScheme, {Color? colorBorde}) {
  return BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: colorBorde ?? colorScheme.outlineVariant.withOpacity(0.3)),
    boxShadow: [
      BoxShadow(color: colorScheme.shadow.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 6)),
    ],
  );
}

class _TarjetaCuentaCobro extends StatelessWidget {
  const _TarjetaCuentaCobro({
    required this.estado,
    required this.cargando,
    required this.onConfigurar,
  });

  final EstadoCuentaStripe estado;
  final bool cargando;
  final VoidCallback onConfigurar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final configurada = estado == EstadoCuentaStripe.configurada;
    final requiereActualizacion = estado == EstadoCuentaStripe.requiereActualizacion;

    return Container(
      decoration: _decoracionTarjeta(
        colorScheme,
        colorBorde: requiereActualizacion ? colorScheme.error.withOpacity(0.4) : null,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_outlined, size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                t.cuentaCobroTitulo,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant),
              ),
              const Spacer(),
              if (configurada)
                const Icon(Icons.check_circle, size: 18, color: Color(0xFF1EA672)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            configurada
                ? t.cuentaCobroEstadoConfigurada
                : (requiereActualizacion ? t.cuentaCobroEstadoRequiereActualizacion : t.cuentaCobroEstadoPendiente),
            style: TextStyle(
              fontSize: 13,
              color: requiereActualizacion ? colorScheme.error : colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          if (!configurada) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: cargando ? null : onConfigurar,
                icon: cargando
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.open_in_new, size: 18),
                label: Text(requiereActualizacion ? t.cuentaCobroBotonActualizar : t.cuentaCobroBotonConfigurar),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tarjeta de estadística para Pendiente/Disponible. `destacado` resalta
/// "Disponible" (el importe que de verdad importa de un vistazo).
class _TarjetaSaldo extends StatelessWidget {
  const _TarjetaSaldo({
    required this.icono,
    required this.titulo,
    required this.ayuda,
    required this.monto,
    this.destacado = false,
  });

  final IconData icono;
  final String titulo;
  final String ayuda;
  final double monto;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final colorAcento = destacado ? const Color(0xFF1EA672) : colorScheme.onSurfaceVariant;

    return Container(
      decoration: _decoracionTarjeta(colorScheme),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 16, color: colorAcento),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colorAcento),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t.centroPagosImporte(monto.toStringAsFixed(2)),
            style: TextStyle(
              fontSize: destacado ? 21 : 18,
              fontWeight: FontWeight.w800,
              color: destacado ? colorAcento : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ayuda,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _TarjetaVacia extends StatelessWidget {
  const _TarjetaVacia({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: _decoracionTarjeta(colorScheme),
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13.5, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _ItemHistorial extends StatelessWidget {
  const _ItemHistorial({required this.cobro});

  final CobroHistorial cobro;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: _decoracionTarjeta(colorScheme),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1EA672).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_downward_rounded, size: 18, color: Color(0xFF1EA672)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.centroPagosPagoDe(cobro.nombreCliente),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  // BUG 006 (QA, 2026-08-03): `cobro.categoria` es el
                  // nombre canónico en español que vive en la base de
                  // datos (ver seed.ts) — mostrarlo tal cual mezclaba
                  // español con el resto de la pantalla en inglés.
                  '${nombreLocalizadoCategoria(context, cobro.categoria)} · ${DateFormat.yMMMd(t.localeName).format(cobro.fecha)}',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            t.centroPagosImporte(cobro.monto.toStringAsFixed(2)),
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF1EA672)),
          ),
        ],
      ),
    );
  }
}
