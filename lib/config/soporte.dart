/// Configuración ÚNICA de los canales de soporte de HogarSOS
/// (auditoría del centro de ayuda, 2026-08-22). Ninguna pantalla debe
/// hardcodear un email o un número: todo sale de aquí.

/// Buzón oficial de soporte (IONOS, operativo). Es el mismo que ya se
/// publica en la web legal de hogarsos.es.
const String kSoporteEmail = 'soporte@hogarsos.es';

/// Número de WhatsApp de soporte en formato internacional SIN '+'
/// (p. ej. '34600000000'). null = todavía no hay número oficial: la
/// hoja de soporte NO muestra el botón de WhatsApp (ni desactivado, ni
/// "próximamente" — simplemente no existe). Cuando el negocio tenga un
/// número (recomendación: WhatsApp Business dedicado, nunca uno
/// personal), basta con rellenarlo aquí y el botón aparece solo.
const String? kSoporteWhatsapp = null;

/// Por qué llega el usuario al soporte — solo los contextos que existen
/// de verdad hoy. Ampliar añadiendo un valor aquí y sus textos en l10n;
/// nunca duplicando pantallas.
enum ContextoSoporte { general, tipoProfesional }

/// mailto: hacia el buzón oficial con el asunto dado. El asunto es
/// SIEMPRE un texto genérico de l10n — jamás se incluyen datos del
/// usuario (nombre, email, teléfono, IDs, Stripe...).
Uri construirMailtoSoporte(String asunto) {
  return Uri.parse('mailto:$kSoporteEmail?subject=${Uri.encodeComponent(asunto)}');
}

/// Enlace wa.me con el mensaje preparado, o null si no hay número
/// configurado. Mismo principio: solo texto genérico.
Uri? construirWhatsappSoporte(String mensaje, {String? numero = kSoporteWhatsapp}) {
  if (numero == null || numero.isEmpty) return null;
  return Uri.parse('https://wa.me/$numero?text=${Uri.encodeComponent(mensaje)}');
}
