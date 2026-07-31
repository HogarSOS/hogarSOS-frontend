import 'package:flutter/material.dart';

/// Paleta de marca de hogarSOS — fuente única de verdad para
/// [AppTheme] (esquema de color de toda la app) y para [HogarSosMark]
/// / [HogarSosWordmark] (el logo). Si el azul o el coral de marca
/// cambian algún día, cambian aquí y se propagan solos a ambos sitios
/// — nunca a valores sueltos copiados en cada archivo.
///
/// - [primary] (verde confianza): color principal, transmite seguridad,
///   estabilidad y "hogar" — el rol que antes cumplía el azul.
/// - [accent] (coral cálido): color de energía/urgencia, reservado a
///   momentos puntuales (el punto de "señal" del logo, la parte "SOS"
///   del wordmark, algún acento de llamada a la acción) — nunca como
///   color base de pantallas enteras, para que mantenga fuerza.
/// - [ink]: casi-negro cálido para texto sobre fondo claro, más suave
///   que negro puro.
class HogarSosColors {
  HogarSosColors._();

  // Antes 0xFF3D4FE0 (azul índigo). Verde bosque profesional — misma
  // familia tonal de "confianza" que el azul, pero con connotación más
  // directa de hogar/seguridad, y contrasta mejor con el coral del
  // acento "SOS" que el azul anterior.
  static const Color primary = Color(0xFF1E8A5A);
  static const Color primaryDeep = Color(0xFF146B45);
  static const Color accent = Color(0xFFFF6A4D);
  static const Color accentDeep = Color(0xFFE8532F);
  static const Color ink = Color(0xFF101828);
}
