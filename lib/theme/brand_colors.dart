import 'package:flutter/material.dart';

/// Paleta de marca de hogarSOS — fuente única de verdad para
/// [AppTheme] (esquema de color de toda la app) y para [HogarSosMark]
/// / [HogarSosWordmark] (el logo). Si el azul o el coral de marca
/// cambian algún día, cambian aquí y se propagan solos a ambos sitios
/// — nunca a valores sueltos copiados en cada archivo.
///
/// - [primary] (azul confiado): color principal, transmite seguridad y
///   profesionalidad — el rol que ya cumplía el antiguo `brandSeed`.
/// - [accent] (coral cálido): color de energía/urgencia, reservado a
///   momentos puntuales (el punto de "señal" del logo, la parte "SOS"
///   del wordmark, algún acento de llamada a la acción) — nunca como
///   color base de pantallas enteras, para que mantenga fuerza.
/// - [ink]: casi-negro cálido para texto sobre fondo claro, más suave
///   que negro puro.
class HogarSosColors {
  HogarSosColors._();

  static const Color primary = Color(0xFF1554F0);
  static const Color primaryDeep = Color(0xFF0C3AC2);
  static const Color accent = Color(0xFFFF6A4D);
  static const Color accentDeep = Color(0xFFE8532F);
  static const Color ink = Color(0xFF101828);
}
