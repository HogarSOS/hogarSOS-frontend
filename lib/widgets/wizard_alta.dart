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
///
/// Variante DESPLEGABLE (prueba de accesibilidad 2026-08-22): la
/// cabecera (título + % + barra) es una zona táctil grande que
/// expande/contrae el detalle. Reglas:
/// - Abierto por defecto cuando el perfil está incompleto (que el nuevo
///   vea al instante qué le falta) y SIEMPRE en estados de atención
///   (acción necesaria / Stripe caída), donde además no se puede cerrar
///   — una advertencia jamás queda escondida tras un pliegue.
/// - Cerrado por defecto con el perfil ya completo (50%/75%): queda una
///   línea de resumen con el paso pendiente.
/// - La preferencia manual vive solo en el State del widget: al cambiar
///   de cuenta o reiniciar la app, la pantalla se recrea y vuelve al
///   comportamiento por defecto — nunca se hereda entre cuentas.
class WizardAlta extends StatefulWidget {
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
  State<WizardAlta> createState() => _WizardAltaState();
}

class _WizardAltaState extends State<WizardAlta> {
  /// null = comportamiento por defecto; true/false = elección manual del
  /// usuario. Vive solo en este State: al cambiar de cuenta o reabrir la
  /// app la pantalla se recrea y vuelve al valor por defecto — nunca se
  /// hereda un abierto/cerrado de otra cuenta.
  bool? _abiertoManual;

  bool get _perfilOk => widget.fotoOk && widget.categoriaOk && widget.tipoOk;
  bool get _configurada => widget.detalle == DetalleCuentaStripe.configurada;
  bool get _listo => widget.aprobado && _configurada;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    // Alta terminada y ya disponible: el wizard desaparece del todo.
    if (_listo && widget.disponible) return const SizedBox.shrink();

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
                onPressed: widget.activando ? null : widget.onActivarme,
                icon: widget.activando
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.bolt, size: 18),
                label: Text(t.altaBotonActivarme),
              ),
            ),
          ],
        ),
      );
    }

    final pct = WizardAlta.progreso(perfilOk: _perfilOk, detalle: widget.detalle, aprobado: widget.aprobado);
    final stripeCaida = widget.aprobado && !_configurada;
    final atencion = stripeCaida || widget.detalle == DetalleCuentaStripe.accionNecesaria;

    // Cerrado por defecto SOLO en los estados de pura espera (Stripe
    // verificando, o Stripe lista con la aprobación resolviéndose):
    // ahí no hay nada que hacer y el resumen basta. Con cualquier
    // acción del usuario pendiente (perfil incompleto, Stripe sin
    // iniciar o a medias) se abre por defecto — y en atención se FUERZA
    // abierto y sin posibilidad de cerrar: una advertencia jamás queda
    // escondida tras un pliegue.
    final soloEsperando = widget.detalle == DetalleCuentaStripe.enVerificacion ||
        (_configurada && !widget.aprobado);
    final abierto = atencion || (_abiertoManual ?? !soloEsperando);

    final subpasosPendientes =
        [widget.fotoOk, widget.categoriaOk, widget.tipoOk].where((ok) => !ok).length;
    final pasoPendiente = !_perfilOk ? t.altaPasoPerfil : t.altaPasoIdentidadCobros;

    return _Tarjeta(
      borde: stripeCaida ? colorScheme.error.withOpacity(0.5) : null,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera desplegable: TODA la zona (título + % + chevron +
            // barra + resumen) es un único InkWell grande, independiente
            // de los subpasos de abajo — no compiten por el toque.
            InkWell(
              onTap: atencion ? null : () => setState(() => _abiertoManual = !abierto),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
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
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: colorScheme.primary),
                        ),
                        // En atención no hay chevron: no se puede cerrar.
                        if (!atencion) ...[
                          const SizedBox(width: 4),
                          Icon(
                            abierto ? Icons.expand_less : Icons.expand_more,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 5,
                        backgroundColor: colorScheme.surfaceContainerHigh,
                      ),
                    ),
                    if (!abierto) ...[
                      const SizedBox(height: 8),
                      Text(
                        subpasosPendientes > 0
                            ? '${t.altaResumenPendiente(pasoPendiente)} · ${t.altaResumenPasos(subpasosPendientes)}'
                            : t.altaResumenPendiente(pasoPendiente),
                        maxLines: 2,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (abierto) ...[
              const SizedBox(height: 8),
              _Paso(estado: _EstadoPaso.hecho, texto: t.altaPasoCuenta),
              _Paso(
                estado: _perfilOk ? _EstadoPaso.hecho : _EstadoPaso.actual,
                texto: t.altaPasoPerfil,
                hijos: _perfilOk
                    ? null
                    : [
                        _SubPaso(hecho: widget.fotoOk, texto: t.altaFaltaFoto, onTap: widget.onFoto),
                        _SubPaso(hecho: widget.categoriaOk, texto: t.altaFaltaCategoria, onTap: widget.onCategorias),
                        _SubPaso(hecho: widget.tipoOk, texto: t.altaFaltaTipo, onTap: widget.onTipo),
                      ],
              ),
              _Paso(
                estado: _configurada
                    ? _EstadoPaso.hecho
                    : atencion
                        ? _EstadoPaso.atencion
                        : _perfilOk
                            ? _EstadoPaso.actual
                            : _EstadoPaso.pendiente,
                texto: t.altaPasoIdentidadCobros,
              ),
              _Paso(estado: _listo ? _EstadoPaso.hecho : _EstadoPaso.pendiente, texto: t.altaPasoListo),
              // Con el perfil incompleto, los subpasos ya listan qué
              // falta — el mensaje contextual vuelve en cuanto el paso
              // vivo es Stripe (o hay una advertencia que dar).
              if (_perfilOk || stripeCaida) ...[
                const SizedBox(height: 8),
                _mensajeYAccion(t, colorScheme),
              ],
            ],
          ],
        ),
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

    if (widget.aprobado && !_configurada) {
      mensaje = t.altaMsgStripeCaida;
      etiquetaBoton = t.altaBotonContinuar;
      esAdvertencia = true;
    } else if (!_perfilOk) {
      mensaje = t.altaMsgPerfilIncompleto;
      etiquetaBoton = null; // los subpasos de Perfil ya son botones directos
    } else {
      switch (widget.detalle) {
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
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: widget.onStripe,
            // Densidad compacta a propósito (ajuste UX 2026-08-22: la
            // tarjeta debe ceder protagonismo al perfil) — sin
            // minimumSize, que ya dio problemas con FilledButton en el
            // panel de admin.
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            icon: const Icon(Icons.open_in_new, size: 17),
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
      padding: const EdgeInsets.only(bottom: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Revisión adversarial 2ª ronda (2026-08-22): los pasos
              // principales son el NIVEL 2 de la jerarquía — al
              // compactarlos a 12.5/16 quedaron idénticos a los subpasos
              // (12.5/15) y la tarjeta entera se percibía "pequeña". Se
              // restauran a 13.5/18; la altura ganada en la compactación
              // vino de los paddings y de quitar la frase redundante,
              // que se conservan.
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
              padding: const EdgeInsets.only(left: 24, top: 2),
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

    // Revisión de accesibilidad (3ª ronda, 2026-08-22): los subpasos son
    // LAS acciones del alta y deben percibirse como botones, no como
    // tres líneas de texto — fila de ~50dp con fondo tenue, flecha
    // grande y texto a 16 seminegrita, pensada para personas mayores o
    // con dedos grandes. Solo existe con la tarjeta DESPLEGADA (plegada
    // queda el resumen compacto de siempre). Un subpaso ya hecho deja de
    // ser acción: pierde el fondo y queda tachado y atenuado.
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: hecho ? Colors.transparent : colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: hecho ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 50),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    hecho ? Icons.check : Icons.arrow_forward,
                    size: hecho ? 16 : 19,
                    color: hecho ? const Color(0xFF1EA672) : colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      texto,
                      style: TextStyle(
                        fontSize: 16,
                        color: hecho ? colorScheme.onSurfaceVariant : colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: hecho ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
      // 14 y no 18 como el resto de tarjetas del perfil: ajuste UX
      // 2026-08-22 — la tarjeta del alta debe ser compacta para que el
      // perfil tenga más protagonismo en la primera pantalla.
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}
