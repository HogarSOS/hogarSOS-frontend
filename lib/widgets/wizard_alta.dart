import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/professional_service.dart';

/// Wizard "Completa tu alta" — el checklist de progreso del alta del
/// profesional (rediseño del flujo de alta, 2026-08-22):
///
///   CUENTA ✓ → PERFIL → IDENTIDAD Y COBROS → LISTO PARA RECIBIR OFERTAS
///
/// Reglas de diseño fijadas en la revisión adversarial:
/// - El progreso es POR HITOS (25/50/75/100), nunca por número de campos.
/// - 100% y "Listo" significan EXCLUSIVAMENTE aprobado + Stripe operativa.
/// - Cada estado dice qué falta, quién tiene la pelota (tú / Stripe /
///   nadie, solo esperar) y ofrece el botón de acción si corresponde.
/// - Si Stripe pierde operatividad DESPUÉS de la aprobación, el wizard
///   reaparece con el paso en ⚠️ — nunca se muestra "listo" con los
///   cobros caídos.
///
/// Todo el estado viene del servidor (GET /professionals/me) — cerrar la
/// app y volver retoma exactamente donde estaba, sin persistencia local.
class WizardAlta extends StatelessWidget {
  const WizardAlta({
    super.key,
    required this.fotoOk,
    required this.categoriaOk,
    required this.tipoOk,
    required this.aprobado,
    required this.detalle,
    required this.disponible,
    required this.activando,
    required this.onFoto,
    required this.onCategorias,
    required this.onTipo,
    required this.onStripe,
    required this.onActivarme,
  });

  final bool fotoOk;
  final bool categoriaOk;

  /// true cuando el tipo profesional ya está PERSISTIDO en el servidor
  /// (se guarda vía POST /me/verification al completar el paso Perfil).
  final bool tipoOk;
  final bool aprobado;
  final DetalleCuentaStripe detalle;
  final bool disponible;
  final bool activando;
  final VoidCallback onFoto;
  final VoidCallback onCategorias;
  final VoidCallback onTipo;
  final VoidCallback onStripe;
  final VoidCallback onActivarme;

  bool get _perfilOk => fotoOk && categoriaOk && tipoOk;
  bool get _configurada => detalle == DetalleCuentaStripe.configurada;
  bool get _listo => aprobado && _configurada;

  /// Progreso por hitos. Pura y estática para poder testearla sin montar
  /// el widget. NUNCA devuelve 100 si Stripe no está operativa o falta
  /// la aprobación — esa es la regla que hace que el porcentaje no
  /// engañe (un 75% con "te avisaremos" es honesto; un 100% sin poder
  /// recibir ofertas no lo sería).
  static int progreso({
    required bool perfilOk,
    required DetalleCuentaStripe detalle,
    required bool aprobado,
  }) {
    final configurada = detalle == DetalleCuentaStripe.configurada;
    if (aprobado && configurada) return 100;
    // KYC ya entregado a Stripe (verificando o pidiendo un dato más), o
    // Stripe lista pero la aprobación de HogarSOS aún resolviéndose.
    if (detalle == DetalleCuentaStripe.enVerificacion ||
        detalle == DetalleCuentaStripe.accionNecesaria ||
        configurada) {
      return 75;
    }
    if (perfilOk) return 50;
    return 25;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    // Alta terminada y ya disponible: el wizard desaparece del todo.
    if (_listo && disponible) return const SizedBox.shrink();

    // Alta terminada pero fuera de línea: banner compacto con el último
    // toque — "Activarme ahora". (También cubre al que se puso "No
    // disponible" a propósito: le recuerda que está invisible.)
    if (_listo) {
      return _Tarjeta(
        borde: const Color(0xFF1EA672),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.altaMsgListo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(t.altaMsgListoAyuda, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: activando ? null : onActivarme,
                icon: activando
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.bolt, size: 18),
                label: Text(t.altaBotonActivarme),
              ),
            ),
          ],
        ),
      );
    }

    final pct = progreso(perfilOk: _perfilOk, detalle: detalle, aprobado: aprobado);
    final stripeCaida = aprobado && !_configurada;

    return _Tarjeta(
      borde: stripeCaida ? colorScheme.error.withOpacity(0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.altaTitulo,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant),
                ),
              ),
              Text(
                t.altaProgreso(pct),
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHigh,
            ),
          ),
          const SizedBox(height: 14),
          _Paso(estado: _EstadoPaso.hecho, texto: t.altaPasoCuenta),
          _Paso(
            estado: _perfilOk ? _EstadoPaso.hecho : _EstadoPaso.actual,
            texto: t.altaPasoPerfil,
            hijos: _perfilOk
                ? null
                : [
                    _SubPaso(hecho: fotoOk, texto: t.altaFaltaFoto, onTap: onFoto),
                    _SubPaso(hecho: categoriaOk, texto: t.altaFaltaCategoria, onTap: onCategorias),
                    _SubPaso(hecho: tipoOk, texto: t.altaFaltaTipo, onTap: onTipo),
                  ],
          ),
          _Paso(
            estado: _configurada
                ? _EstadoPaso.hecho
                : stripeCaida || detalle == DetalleCuentaStripe.accionNecesaria
                    ? _EstadoPaso.atencion
                    : _perfilOk
                        ? _EstadoPaso.actual
                        : _EstadoPaso.pendiente,
            texto: t.altaPasoIdentidadCobros,
          ),
          _Paso(estado: _listo ? _EstadoPaso.hecho : _EstadoPaso.pendiente, texto: t.altaPasoListo),
          const SizedBox(height: 12),
          _mensajeYAccion(t, colorScheme),
        ],
      ),
    );
  }

  /// El mensaje contextual + botón de acción del estado actual — la
  /// tripleta "qué falta / quién actúa / botón" de la revisión
  /// adversarial. Un único mensaje cada vez, el del paso vivo.
  Widget _mensajeYAccion(AppLocalizations t, ColorScheme colorScheme) {
    String mensaje;
    String? etiquetaBoton;
    bool esAdvertencia = false;

    if (aprobado && !_configurada) {
      mensaje = t.altaMsgStripeCaida;
      etiquetaBoton = t.altaBotonContinuar;
      esAdvertencia = true;
    } else if (!_perfilOk) {
      mensaje = t.altaMsgPerfilIncompleto;
      etiquetaBoton = null; // los subpasos de Perfil ya son botones directos
    } else {
      switch (detalle) {
        case DetalleCuentaStripe.sinIniciar:
          mensaje = t.altaMsgStripeSinIniciar;
          etiquetaBoton = t.altaBotonContinuar;
          break;
        case DetalleCuentaStripe.enProgreso:
          mensaje = t.altaMsgStripeEnProgreso;
          etiquetaBoton = t.altaBotonContinuar;
          break;
        case DetalleCuentaStripe.enVerificacion:
          mensaje = t.altaMsgStripeEnVerificacion;
          etiquetaBoton = null; // la pelota la tiene Stripe — solo esperar
          break;
        case DetalleCuentaStripe.accionNecesaria:
          mensaje = t.altaMsgStripeAccion;
          etiquetaBoton = t.altaBotonContinuar;
          esAdvertencia = true;
          break;
        case DetalleCuentaStripe.configurada:
          // Stripe lista, aprobación de HogarSOS resolviéndose (ventana
          // corta: la aprobación automática corre en el servidor).
          mensaje = t.altaMsgRevisionHogarsos;
          etiquetaBoton = null;
          break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          mensaje,
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            color: esAdvertencia ? colorScheme.error : colorScheme.onSurfaceVariant,
            fontWeight: esAdvertencia ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        if (etiquetaBoton != null) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onStripe,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(etiquetaBoton),
          ),
        ],
      ],
    );
  }
}

enum _EstadoPaso { hecho, actual, pendiente, atencion }

class _Paso extends StatelessWidget {
  const _Paso({required this.estado, required this.texto, this.hijos});

  final _EstadoPaso estado;
  final String texto;
  final List<Widget>? hijos;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (icono, color) = switch (estado) {
      _EstadoPaso.hecho => (Icons.check_circle, const Color(0xFF1EA672)),
      _EstadoPaso.actual => (Icons.radio_button_checked, colorScheme.primary),
      _EstadoPaso.atencion => (Icons.error_outline, colorScheme.error),
      _EstadoPaso.pendiente => (Icons.radio_button_unchecked, colorScheme.outline),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                texto,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: estado == _EstadoPaso.pendiente ? FontWeight.w500 : FontWeight.w700,
                  color: estado == _EstadoPaso.pendiente ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                ),
              ),
            ],
          ),
          if (hijos != null)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: hijos!),
            ),
        ],
      ),
    );
  }
}

/// Subpaso del paso Perfil: cada elemento que falta es un enlace directo
/// a su acción (abrir selector de foto, hoja de categorías, diálogo de
/// tipo) — botones directos, sin hacer buscar al usuario dónde se hace.
class _SubPaso extends StatelessWidget {
  const _SubPaso({required this.hecho, required this.texto, required this.onTap});

  final bool hecho;
  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: hecho ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              hecho ? Icons.check : Icons.arrow_forward,
              size: 15,
              color: hecho ? const Color(0xFF1EA672) : colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              texto,
              style: TextStyle(
                fontSize: 12.5,
                color: hecho ? colorScheme.onSurfaceVariant : colorScheme.primary,
                fontWeight: hecho ? FontWeight.w400 : FontWeight.w600,
                decoration: hecho ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mismo contenedor visual que las tarjetas de "Mi perfil" (sombra
/// suave, bordes redondeados) para que el wizard no parezca un cuerpo
/// extraño en la pantalla.
class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child, this.borde});

  final Widget child;
  final Color? borde;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borde ?? colorScheme.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: colorScheme.shadow.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }
}
