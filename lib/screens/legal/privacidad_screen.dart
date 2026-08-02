import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Política de privacidad — redactada para cubrir lo que la app
/// realmente hace (no es una plantilla genérica), pero no sustituye
/// una revisión legal antes de publicar de verdad. Traducida sección a
/// sección vía AppLocalizations igual que el resto de la UI — antes
/// era texto español fijo, así que un usuario en inglés veía un
/// AppBar en inglés seguido de un cuerpo entero en español.
class PrivacidadScreen extends StatelessWidget {
  const PrivacidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.legalPrivacidadTitulo)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Seccion(titulo: t.legalPrivSec1Titulo, texto: t.legalPrivSec1Texto),
          _Seccion(titulo: t.legalPrivSec2Titulo, texto: t.legalPrivSec2Texto),
          _Seccion(titulo: t.legalPrivSec3Titulo, texto: t.legalPrivSec3Texto),
          _Seccion(titulo: t.legalPrivSec4Titulo, texto: t.legalPrivSec4Texto),
          _Seccion(titulo: t.legalPrivSec5Titulo, texto: t.legalPrivSec5Texto),
          _Seccion(titulo: t.legalPrivSec6Titulo, texto: t.legalPrivSec6Texto),
          _Seccion(titulo: t.legalPrivSec7Titulo, texto: t.legalPrivSec7Texto),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.texto});

  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(texto, style: const TextStyle(fontSize: 13.5, height: 1.5)),
        ],
      ),
    );
  }
}
