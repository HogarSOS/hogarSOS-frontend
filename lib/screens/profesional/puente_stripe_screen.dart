import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../services/professional_service.dart';
import '../../utils/error_extraction.dart';
import '../../widgets/wizard_alta.dart';

/// Pantalla puente antes del onboarding de Stripe Connect — la ÚNICA
/// puerta de entrada al onboarding mientras el profesional no está
/// aprobado (tanto desde "Mi perfil"/wizard como desde el Centro de
/// Pagos, revisión adversarial punto 12). Fija expectativas ANTES del
/// salto: por qué aparece Stripe, qué es, qué va a pedir, qué hemos
/// rellenado ya, y que al terminar se vuelve automáticamente a HogarSOS.
/// Deliberadamente NO promete "no tendrás que volver a introducir
/// datos" — Stripe puede pedir información adicional.
///
/// Comprueba ella misma el perfil (obtenerMiPerfil, con deduplicación
/// single-flight, barato): si falta foto/categoría/tipo, en vez del
/// salto muestra el aviso y devuelve al perfil — así el Centro de Pagos
/// no puede saltarse el orden del wizard y no hay lógica duplicada.
/// También adapta su contenido al estado real de la cuenta:
/// - sin iniciar → explicación completa + "Continuar con Stripe →"
/// - en progreso → "Continúa con Stripe" + "no está terminada"
/// - en verificación → SIN botón: solo hay que esperar a Stripe
/// - acción necesaria → aviso + botón para retomar
///
/// El onboarding en sí se abre en el NAVEGADOR EXTERNO
/// (LaunchMode.externalApplication): Stripe no soporta su onboarding
/// hospedado dentro de WebViews embebidos. La vuelta llega por deep
/// link (hogarsos://stripe-return/...) exactamente igual que antes.
class PuenteStripeScreen extends StatefulWidget {
  const PuenteStripeScreen({super.key});

  @override
  State<PuenteStripeScreen> createState() => _PuenteStripeScreenState();
}

class _PuenteStripeScreenState extends State<PuenteStripeScreen> {
  final _professionalService = ProfessionalService();

  bool _cargando = true;
  bool _perfilListo = false;
  bool _abriendoStripe = false;
  DetalleCuentaStripe _detalle = DetalleCuentaStripe.sinIniciar;
  int _pct = 50;

  @override
  void initState() {
    super.initState();
    _comprobarPerfil();
  }

  Future<void> _comprobarPerfil() async {
    try {
      final perfil = await _professionalService.obtenerMiPerfil();
      if (!mounted) return;
      setState(() {
        _perfilListo = perfil.perfilCompleto && perfil.tipoProfesional != null;
        _detalle = perfil.estadoCuentaStripeDetalle;
        // Mismo cálculo por hitos que el wizard — nunca dos números
        // distintos en pantallas contiguas.
        _pct = WizardAlta.progreso(
          perfilOk: _perfilListo,
          detalle: perfil.estadoCuentaStripeDetalle,
          aprobado: perfil.estaVerificado,
        );
        _cargando = false;
      });
    } catch (e) {
      debugPrint('[PuenteStripeScreen] Error al comprobar el perfil: $e');
      if (!mounted) return;
      // Si no se pudo comprobar, se deja pasar: el backend prefill-ea lo
      // que tenga y Stripe pide el resto — bloquear aquí por un fallo de
      // red sería peor que un prefill incompleto.
      setState(() {
        _perfilListo = true;
        _cargando = false;
      });
    }
  }

  Future<void> _continuarConStripe() async {
    final t = AppLocalizations.of(context);
    setState(() => _abriendoStripe = true);
    try {
      final url = await _professionalService.iniciarOnboardingStripe();
      final abierto = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (abierto) {
        // El usuario sigue en el navegador; al volver (deep link), la
        // pantalla de perfil se refresca sola — esta ya no pinta nada.
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.cuentaCobroErrorAbrir)));
      }
    } catch (e) {
      debugPrint('[PuenteStripeScreen] Error al iniciar onboarding: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.cuentaCobroErrorAbrir, t: t))),
      );
    } finally {
      if (mounted) setState(() => _abriendoStripe = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.altaPasoIdentidadCobros)),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: !_perfilListo
                  ? _AvisoPerfilIncompleto(t: t, colorScheme: colorScheme)
                  : _detalle == DetalleCuentaStripe.enVerificacion
                      ? _VistaVerificando(t: t, colorScheme: colorScheme, pct: _pct)
                      : _contenidoPrincipal(t, colorScheme),
            ),
    );
  }

  /// Contenido para los estados con acción (sin iniciar / en progreso /
  /// acción necesaria): explicación + botón fijo abajo.
  Widget _contenidoPrincipal(AppLocalizations t, ColorScheme colorScheme) {
    final retomando = _detalle == DetalleCuentaStripe.enProgreso;
    final accionNecesaria = _detalle == DetalleCuentaStripe.accionNecesaria;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CabeceraProgreso(t: t, colorScheme: colorScheme, pct: _pct),
                const SizedBox(height: 18),
                Text(
                  t.puenteTituloSeguro,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1.25),
                ),
                const SizedBox(height: 8),
                Text(
                  t.puenteIntro,
                  style: TextStyle(fontSize: 13.5, height: 1.4, color: colorScheme.onSurface),
                ),
                // Aviso de estado (retomar / acción necesaria) bien
                // arriba, antes de la explicación general.
                if (retomando || accionNecesaria) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accionNecesaria
                          ? colorScheme.errorContainer.withOpacity(0.55)
                          : colorScheme.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      accionNecesaria ? t.altaMsgStripeAccion : t.puenteEnProgresoTexto,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: accionNecesaria ? colorScheme.onErrorContainer : colorScheme.primary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // ¿Qué es Stripe?
                _TarjetaSeccion(
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.puenteQueEsStripeTitulo,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.puenteQueEsStripeTexto,
                        style: TextStyle(fontSize: 12.5, height: 1.4, color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.puenteQueEsStripeNota,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Qué hará Stripe — 3 bloques compactos.
                _TarjetaSeccion(
                  colorScheme: colorScheme,
                  child: Column(
                    children: [
                      _BloqueCheck(titulo: t.puenteBloqueIdentidadTitulo, texto: t.puenteBloqueIdentidadTexto),
                      const SizedBox(height: 10),
                      _BloqueCheck(titulo: t.puenteBloqueCobrosTitulo, texto: t.puenteBloqueCobrosTexto),
                      const SizedBox(height: 10),
                      _BloqueCheck(titulo: t.puenteBloqueDatosTitulo, texto: t.puenteBloqueDatosTexto),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Ya hemos rellenado algunos datos por ti — destacado.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.35)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.puentePrefillTitulo,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colorScheme.primary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.puentePrefillTexto,
                              style: TextStyle(fontSize: 12.5, height: 1.4, color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Qué necesitarás — visual y compacto.
                _TarjetaSeccion(
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.puenteNecesitarasTitulo,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ChipNecesitas(emoji: '📄', texto: t.puenteNecesitarasDni),
                          _ChipNecesitas(emoji: '🏦', texto: t.puenteNecesitarasIban),
                          _ChipNecesitas(emoji: '📱', texto: t.puenteNecesitarasTelefono),
                          _ChipNecesitas(emoji: '🏠', texto: t.puenteNecesitarasDatos),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t.puenteNecesitarasExtra,
                        style: TextStyle(fontSize: 11.5, height: 1.35, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Cambio de app: que nadie piense que salió por accidente.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.swap_horiz, size: 18, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${t.puenteCambioApp1} ${t.puenteCambioApp2}',
                        style: TextStyle(fontSize: 12, height: 1.4, color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Botón fijo abajo + sello de conexión segura.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _abriendoStripe ? null : _continuarConStripe,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                icon: _abriendoStripe
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.open_in_new, size: 18),
                label: Text(
                  (retomando || accionNecesaria) ? t.puenteBotonRetomar : t.puenteBoton,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.puenteConexionSegura,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Cabecera con el progreso del alta — mismo número y mismos hitos que
/// el wizard de "Mi perfil" (WizardAlta.progreso), para no enseñar dos
/// porcentajes distintos en pantallas contiguas.
class _CabeceraProgreso extends StatelessWidget {
  const _CabeceraProgreso({required this.t, required this.colorScheme, required this.pct});

  final AppLocalizations t;
  final ColorScheme colorScheme;
  final int pct;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.altaProgreso(pct),
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: colorScheme.primary),
              ),
            ),
            Text(
              t.altaPasoIdentidadCobros,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 6,
            backgroundColor: colorScheme.surfaceContainerHigh,
          ),
        ),
      ],
    );
  }
}

/// Estado "en verificación": la pelota la tiene Stripe — sin botón,
/// para no invitar a reabrir el onboarding innecesariamente.
class _VistaVerificando extends StatelessWidget {
  const _VistaVerificando({required this.t, required this.colorScheme, required this.pct});

  final AppLocalizations t;
  final ColorScheme colorScheme;
  final int pct;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CabeceraProgreso(t: t, colorScheme: colorScheme, pct: pct),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.hourglass_top_outlined, size: 34, color: colorScheme.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t.puenteVerificandoTitulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.puenteVerificandoTexto,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, height: 1.4, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta compacta de sección — mismo lenguaje visual que el resto de
/// tarjetas de la app, con relleno algo más apretado para móvil.
class _TarjetaSeccion extends StatelessWidget {
  const _TarjetaSeccion({required this.colorScheme, required this.child});

  final ColorScheme colorScheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.35)),
      ),
      child: child,
    );
  }
}

class _BloqueCheck extends StatelessWidget {
  const _BloqueCheck({required this.titulo, required this.texto});

  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, size: 17, color: Color(0xFF1EA672)),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                texto,
                style: TextStyle(fontSize: 12, height: 1.35, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChipNecesitas extends StatelessWidget {
  const _ChipNecesitas({required this.emoji, required this.texto});

  final String emoji;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(texto, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AvisoPerfilIncompleto extends StatelessWidget {
  const _AvisoPerfilIncompleto({required this.t, required this.colorScheme});

  final AppLocalizations t;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_late_outlined, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              t.puentePerfilIncompleto,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton(
              // El wizard vive en "Mi perfil" — volver es suficiente: tanto
              // el perfil como el Centro de Pagos quedan detrás de esta
              // pantalla, y los subpasos del wizard son botones directos.
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.puenteBotonCompletarPerfil),
            ),
          ],
        ),
      ),
    );
  }
}
