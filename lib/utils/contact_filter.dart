/// Detecta teléfonos y emails dentro de un mensaje de chat, para
/// bloquear su envío antes de la contratación (ver ChatScreen._enviar).
/// A propósito NO detecta enlaces, redes sociales ni frases sueltas
/// tipo "llámame" — el chat en sí no cambia de comportamiento, solo se
/// impide compartir un teléfono o un email concreto dentro del texto.
library;

/// 9 dígitos seguidos, con o sin separador de un solo carácter (espacio,
/// punto o guion) entre cada uno, con prefijo internacional opcional
/// (+34/0034). No detecta series más cortas (evita falsos positivos con
/// horas como "10:00" o cantidades como "241.50").
final RegExp _telefono = RegExp(r'(?:(?:\+|00)\s?34[\s.\-]?)?\b(?:\d[\s.\-]?){8}\d\b');

final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}');

/// Variante escrita en palabras para esquivar el filtro anterior:
/// "fulano arroba gmail punto com".
final RegExp _emailEnPalabras = RegExp(
  r'\b\w+\s*(arroba|\(at\))\s*\w+\s*(punto|\(dot\))\s*(com|es|net|org)\b',
  caseSensitive: false,
);

/// Devuelve null si el texto no contiene ningún teléfono/email
/// detectable, o una razón corta ('telefono'/'email') si sí.
String? razonBloqueoMensaje(String texto) {
  if (_telefono.hasMatch(texto)) return 'telefono';
  if (_email.hasMatch(texto) || _emailEnPalabras.hasMatch(texto)) return 'email';
  return null;
}
