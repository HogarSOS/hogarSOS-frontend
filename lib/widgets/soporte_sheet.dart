import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/soporte.dart';
import '../l10n/app_localizations.dart';

/// Hoja de "Ayuda y soporte" — el ÚNICO centro de soporte de la app
/// (auditoría 2026-08-22), compartido por cliente y profesional y por
/// todas las puertas de entrada (fila del perfil, nota del tipo
/// profesional...). v1 deliberadamente mínima: email operativo desde el
/// primer día y WhatsApp preparado pero oculto hasta que exista número
/// oficial (ver config/soporte.dart). Sin backend, sin tickets, sin
/// chat, sin FAQ — cuando eso llegue, se amplía ESTA hoja, no la
/// navegación.
///
/// Privacidad: los mensajes/asuntos preparados son texto genérico de
/// l10n; nunca se adjunta automáticamente ningún dato del usuario. El
/// teléfono interno del profesional no interviene en nada.
///
/// Distinto de ReportarProblemaScreen (reclamación de UN trabajo, con
/// fotos y backend de disputas) — no se mezclan.
Future<void> mostrarSoporte(BuildContext context, {ContextoSoporte contexto = ContextoSoporte.general}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => SoporteSheet(contexto: contexto),
  );
}

class SoporteSheet extends StatelessWidget {
  const SoporteSheet({
    super.key,
    this.contexto = ContextoSoporte.general,
    this.whatsappNumero = kSoporteWhatsapp,
  });

  final ContextoSoporte contexto;

  /// Inyectable solo para tests; en la app siempre viene de config.
  final String? whatsappNumero;

  String _asunto(AppLocalizations t) {
    switch (contexto) {
      case ContextoSoporte.tipoProfesional:
        return t.soporteAsuntoTipoProfesional;
      case ContextoSoporte.general:
        return t.soporteAsuntoGeneral;
    }
  }

  String _mensajeWhatsapp(AppLocalizations t) {
    switch (contexto) {
      case ContextoSoporte.tipoProfesional:
        return t.soporteWhatsappTipoProfesional;
      case ContextoSoporte.general:
        return t.soporteWhatsappGeneral;
    }
  }

  Future<void> _abrir(BuildContext context, Uri uri) async {
    final t = AppLocalizations.of(context);
    var abierto = false;
    try {
      abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[SoporteSheet] Error al abrir $uri: $e');
    }
    if (!abierto && context.mounted) {
      // Nunca un botón roto: el email en texto + Copiar siguen delante.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.soporteErrorAbrir)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final whatsappUri = construirWhatsappSoporte(_mensajeWhatsapp(t), numero: whatsappNumero);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        // Desplazable: con escala de fuente grande el contenido crece y
        // nada debe quedar inalcanzable.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.soporteTitulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                t.soportePregunta,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.35),
              ),
              // El usuario debe saber por qué motivo está contactando
              // cuando llegó desde una puerta contextual.
              if (contexto == ContextoSoporte.tipoProfesional) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    t.soporteMotivoTipoProfesional,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Botones grandes (≥56dp): pensados para personas mayores
              // y dedos grandes — sin reducir tipografías.
              FilledButton.icon(
                onPressed: () => _abrir(context, construirMailtoSoporte(_asunto(t))),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                icon: const Icon(Icons.mail_outline, size: 20),
                label: Text(t.soporteEmailBoton, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              // WhatsApp: SOLO si hay número configurado — sin botones
              // desactivados ni "próximamente".
              if (whatsappUri != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _abrir(context, whatsappUri),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  icon: const Icon(Icons.chat_outlined, size: 20),
                  label: Text(t.soporteWhatsappBoton, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ],
              const SizedBox(height: 14),
              // Último fallback SIEMPRE visible: la dirección tal cual +
              // Copiar (cubre dispositivos sin app de correo).
              Row(
                children: [
                  Expanded(
                    child: Text(
                      kSoporteEmail,
                      style: TextStyle(fontSize: 13.5, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(const ClipboardData(text: kSoporteEmail));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.soporteEmailCopiado)));
                      }
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: Text(t.soporteCopiar),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila "❓ Ayuda y soporte" para la zona inferior de los perfiles —
/// EL MISMO componente en cliente y profesional. Fila completa pulsable,
/// ≥56dp, icono + texto (nunca solo icono).
class FilaAyudaSoporte extends StatelessWidget {
  const FilaAyudaSoporte({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => mostrarSoporte(context),
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.help_outline, size: 22, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.soporteTitulo,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.chevron_right, size: 22, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
