import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Sistema de presentación de categorías.
///
/// La base de datos guarda un único nombre canónico en español (ver
/// backend/prisma/seed.ts) — es una clave interna, no lo que ve el
/// usuario. Aquí se traduce esa clave a: icono, color de marca y
/// nombre en el idioma activo. Añadir una categoría nueva: una entrada
/// en el seed + una entrada en _estilos de abajo + una clave .arb.
/// Si llega una categoría que aún no está mapeada aquí, cae en un
/// estilo neutro genérico en vez de romper la UI.
class CategoriaEstilo {
  final IconData icono;
  final Color color;
  const CategoriaEstilo(this.icono, this.color);
}

// Paleta curada para las categorías (Sprint 1 — identidad visual): en
// vez de los Colors.* con nombre de Material (Colors.amber,
// Colors.deepPurple...) — que vienen de una paleta genérica pensada
// para estados de UI, no para una marca — cada categoría tiene ahora un
// tono elegido a mano, coordinado en saturación/luminosidad con el
// resto para que la cuadrícula de categorías se sienta un sistema
// diseñado propio en vez de una demo de Flutter.
const CategoriaEstilo _estiloGenerico = CategoriaEstilo(Icons.build_outlined, Color(0xFF94A3B8));

final Map<String, CategoriaEstilo> _estilos = {
  'electricista': const CategoriaEstilo(Icons.bolt_outlined, Color(0xFFF5A623)),
  'fontanero': const CategoriaEstilo(Icons.plumbing_outlined, Color(0xFF2E90FA)),
  'pintor': const CategoriaEstilo(Icons.format_paint_outlined, Color(0xFF7A5AF8)),
  'manitas': const CategoriaEstilo(Icons.handyman_outlined, Color(0xFFF76B1C)),
  'limpieza': const CategoriaEstilo(Icons.auto_awesome_outlined, Color(0xFF12B3A8)),
  'jardinería': const CategoriaEstilo(Icons.grass_outlined, Color(0xFF3FB950)),
  'jardineria': const CategoriaEstilo(Icons.grass_outlined, Color(0xFF3FB950)),
  'cerrajería': const CategoriaEstilo(Icons.key_outlined, Color(0xFF4C5FD5)),
  'cerrajeria': const CategoriaEstilo(Icons.key_outlined, Color(0xFF4C5FD5)),
  'cerrajero': const CategoriaEstilo(Icons.key_outlined, Color(0xFF4C5FD5)),
  'reformas': const CategoriaEstilo(Icons.construction_outlined, Color(0xFFC2762B)),
  'aire acondicionado': const CategoriaEstilo(Icons.ac_unit_outlined, Color(0xFF39C0F2)),
  'carpintería': const CategoriaEstilo(Icons.carpenter_outlined, Color(0xFF8A5A34)),
  'carpinteria': const CategoriaEstilo(Icons.carpenter_outlined, Color(0xFF8A5A34)),
  'albañilería': const CategoriaEstilo(Icons.foundation_outlined, Color(0xFF64748B)),
  'albanileria': const CategoriaEstilo(Icons.foundation_outlined, Color(0xFF64748B)),
  'tejados y cubiertas': const CategoriaEstilo(Icons.roofing_outlined, Color(0xFFE5484D)),
  'cristalería': const CategoriaEstilo(Icons.window_outlined, Color(0xFF22B8CF)),
  'cristaleria': const CategoriaEstilo(Icons.window_outlined, Color(0xFF22B8CF)),
  'carpintería metálica': const CategoriaEstilo(Icons.hardware_outlined, Color(0xFF8D8F99)),
  'carpinteria metalica': const CategoriaEstilo(Icons.hardware_outlined, Color(0xFF8D8F99)),
  'antenas y telecomunicaciones': const CategoriaEstilo(Icons.settings_input_antenna_outlined, Color(0xFF9B4DE0)),
  'sistemas de seguridad': const CategoriaEstilo(Icons.security_outlined, Color(0xFFE13B3B)),
  'mudanzas': const CategoriaEstilo(Icons.local_shipping_outlined, Color(0xFFB98900)),
  'limpieza de cristales': const CategoriaEstilo(Icons.water_drop_outlined, Color(0xFF5AC8FA)),
  'piscinas': const CategoriaEstilo(Icons.pool_outlined, Color(0xFF17A2B8)),
  'control de plagas': const CategoriaEstilo(Icons.pest_control_outlined, Color(0xFF4C9A2A)),
  'veterinaria a domicilio': const CategoriaEstilo(Icons.pets_outlined, Color(0xFFEC4899)),
  'técnico de telefonía': const CategoriaEstilo(Icons.smartphone_outlined, Color(0xFF0EA5E9)),
  'tecnico de telefonia': const CategoriaEstilo(Icons.smartphone_outlined, Color(0xFF0EA5E9)),
  // Compatibilidad con nombres antiguos usados antes de la Fase 2:
  'limpieza del hogar': const CategoriaEstilo(Icons.auto_awesome_outlined, Color(0xFF12B3A8)),
  'otras': _estiloGenerico,
};

CategoriaEstilo _estiloParaCategoria(String nombre) {
  final clave = nombre.trim().toLowerCase();
  return _estilos[clave] ?? _estiloGenerico;
}

/// Icono de la categoría — se mantiene este nombre de función porque
/// ya se usa en varias pantallas (Fase 1 y 2).
IconData iconoParaCategoria(String nombre) => _estiloParaCategoria(nombre).icono;

/// Color de marca coherente de la categoría.
Color colorParaCategoria(String nombre) => _estiloParaCategoria(nombre).color;

/// Nombre de la categoría en el idioma activo de la app. El nombre
/// canónico (español, el que vive en la base de datos) se usa como
/// clave — si llega una categoría todavía no traducida aquí, se
/// muestra tal cual en vez de romper la pantalla.
String nombreLocalizadoCategoria(BuildContext context, String nombreCanonico) {
  final t = AppLocalizations.of(context);
  switch (nombreCanonico.trim().toLowerCase()) {
    case 'electricista':
      return t.categoriaElectricista;
    case 'fontanero':
      return t.categoriaFontanero;
    case 'pintor':
      return t.categoriaPintor;
    case 'manitas':
      return t.categoriaManitas;
    case 'limpieza':
    case 'limpieza del hogar':
      return t.categoriaLimpieza;
    case 'jardinería':
    case 'jardineria':
      return t.categoriaJardineria;
    case 'cerrajería':
    case 'cerrajeria':
    case 'cerrajero':
      return t.categoriaCerrajeria;
    case 'reformas':
      return t.categoriaReformas;
    case 'aire acondicionado':
      return t.categoriaAireAcondicionado;
    case 'carpintería':
    case 'carpinteria':
      return t.categoriaCarpinteria;
    case 'albañilería':
    case 'albanileria':
      return t.categoriaAlbanileria;
    case 'tejados y cubiertas':
      return t.categoriaTejados;
    case 'cristalería':
    case 'cristaleria':
      return t.categoriaCristaleria;
    case 'carpintería metálica':
    case 'carpinteria metalica':
      return t.categoriaCarpinteriaMetalica;
    case 'antenas y telecomunicaciones':
      return t.categoriaAntenas;
    case 'sistemas de seguridad':
      return t.categoriaSeguridad;
    case 'mudanzas':
      return t.categoriaMudanzas;
    case 'limpieza de cristales':
      return t.categoriaLimpiezaCristales;
    case 'piscinas':
      return t.categoriaPiscinas;
    case 'control de plagas':
      return t.categoriaControlPlagas;
    case 'veterinaria a domicilio':
      return t.categoriaVeterinaria;
    case 'técnico de telefonía':
    case 'tecnico de telefonia':
      return t.categoriaTecnicoTelefonia;
    default:
      return nombreCanonico; // categoría futura aún sin traducir — no rompe la UI
  }
}

/// Ejemplo de descripción específico de la categoría, para el hint del
/// paso 2 del asistente ("Describe el trabajo") — ver
/// solicitar_wizard_screen.dart. Antes había un único ejemplo genérico
/// de fontanería para todas las categorías (raro si estabas pidiendo un
/// electricista); ahora cada oficio muestra un ejemplo realista del
/// problema típico de esa categoría, que además sirve de guía implícita
/// de qué tipo de detalle conviene dar. Si `nombreCanonico` es `null`
/// (aún no se ha elegido categoría) o no está mapeado, cae en el
/// ejemplo genérico.
String ejemploDescripcionParaCategoria(BuildContext context, String? nombreCanonico) {
  final t = AppLocalizations.of(context);
  switch (nombreCanonico?.trim().toLowerCase()) {
    case 'electricista':
      return t.wizardEjemploElectricista;
    case 'fontanero':
      return t.wizardEjemploFontanero;
    case 'pintor':
      return t.wizardEjemploPintor;
    case 'manitas':
      return t.wizardEjemploManitas;
    case 'limpieza':
    case 'limpieza del hogar':
      return t.wizardEjemploLimpieza;
    case 'jardinería':
    case 'jardineria':
      return t.wizardEjemploJardineria;
    case 'cerrajería':
    case 'cerrajeria':
    case 'cerrajero':
      return t.wizardEjemploCerrajeria;
    case 'reformas':
      return t.wizardEjemploReformas;
    case 'aire acondicionado':
      return t.wizardEjemploAireAcondicionado;
    case 'carpintería':
    case 'carpinteria':
      return t.wizardEjemploCarpinteria;
    case 'albañilería':
    case 'albanileria':
      return t.wizardEjemploAlbanileria;
    case 'tejados y cubiertas':
      return t.wizardEjemploTejados;
    case 'cristalería':
    case 'cristaleria':
      return t.wizardEjemploCristaleria;
    case 'carpintería metálica':
    case 'carpinteria metalica':
      return t.wizardEjemploCarpinteriaMetalica;
    case 'antenas y telecomunicaciones':
      return t.wizardEjemploAntenas;
    case 'sistemas de seguridad':
      return t.wizardEjemploSeguridad;
    case 'mudanzas':
      return t.wizardEjemploMudanzas;
    case 'limpieza de cristales':
      return t.wizardEjemploLimpiezaCristales;
    case 'piscinas':
      return t.wizardEjemploPiscinas;
    case 'control de plagas':
      return t.wizardEjemploControlPlagas;
    case 'veterinaria a domicilio':
      return t.wizardEjemploVeterinaria;
    case 'técnico de telefonía':
    case 'tecnico de telefonia':
      return t.wizardEjemploTecnicoTelefonia;
    default:
      return t.wizardEjemploGenerico;
  }
}
