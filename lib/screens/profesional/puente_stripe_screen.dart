import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../services/professional_service.dart';
import '../../utils/error_extraction.dart';

/// Pantalla puente antes del onboarding de Stripe Connect — la ÚNICA
/// puerta de entrada al onboarding mientras el profesional no está
/// aprobado (tanto desde "Mi perfil"/wizard como desde el Centro de
/// Pagos, revisión adversarial punto 12). Fija expectativas ANTES del
/// salto: qué es Stripe, qué está ya rellenado, qué van a pedirle y qué
/// debe tener a mano. Deliberadamente NO promete "no tendrás que volver
/// a introducir datos" — Stripe puede pedir información adicional.
///
/// Comprueba ella misma el perfil (obtenerMiPerfil, con deduplicación
/// single-flight, barato): si falta foto/categoría/tipo, en vez del
/// salto muestra el aviso y devuelve al perfil — así el Centro de Pagos
/// no puede saltarse el orden del wizard y no hay lógica duplicada.
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
      appBar: AppBar(title: Text(t.cuentaCobroTitulo)),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: !_perfilListo
                    ? _AvisoPerfilIncompleto(t: t, colorScheme: colorScheme)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(Icons.verified_user_outlined, size: 32, color: colorScheme.primary),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    t.puenteTitulo,
                                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, height: 1.25),
                                  ),
                                  const SizedBox(height: 16),
                                  _Parrafo(texto: t.puenteParrafo1),
                                  _Parrafo(texto: t.puenteParrafo2),
                                  _Parrafo(texto: t.puenteParrafo3),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.badge_outlined, size: 20, color: colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            t.puenteTenAMano,
                                            style: TextStyle(fontSize: 13, height: 1.4, color: colorScheme.onSurfaceVariant),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _abriendoStripe ? null : _continuarConStripe,
                            icon: _abriendoStripe
                                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.open_in_new, size: 18),
                            label: Text(t.puenteBoton),
                          ),
                        ],
                      ),
              ),
            ),
    );
  }
}

class _Parrafo extends StatelessWidget {
  const _Parrafo({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        texto,
        style: TextStyle(fontSize: 14, height: 1.45, color: Theme.of(context).colorScheme.onSurface),
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
    );
  }
}
