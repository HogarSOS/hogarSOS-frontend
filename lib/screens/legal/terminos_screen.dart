import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Términos de servicio — mismo criterio que privacidad_screen.dart:
/// redactado para lo que la app realmente hace, no una plantilla
/// genérica ni un sustituto de revisión legal real. Traducido sección
/// a sección vía AppLocalizations (ver comentario de
/// PrivacidadScreen).
class TerminosScreen extends StatelessWidget {
  const TerminosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.legalTerminosTitulo)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Seccion(titulo: t.legalTerminosSec1Titulo, texto: t.legalTerminosSec1Texto),
          _Seccion(titulo: t.legalTerminosSec2Titulo, texto: t.legalTerminosSec2Texto),
          _Seccion(titulo: t.legalTerminosSec3Titulo, texto: t.legalTerminosSec3Texto),
          _Seccion(titulo: t.legalTerminosSec4Titulo, texto: t.legalTerminosSec4Texto),
          _Seccion(titulo: t.legalTerminosSec5Titulo, texto: t.legalTerminosSec5Texto),
          _Seccion(titulo: t.legalTerminosSec6Titulo, texto: t.legalTerminosSec6Texto),
          _Seccion(titulo: t.legalTerminosSec7Titulo, texto: t.legalTerminosSec7Texto),
          _Seccion(titulo: t.legalTerminosSec8Titulo, texto: t.legalTerminosSec8Texto),
          _Seccion(titulo: t.legalTerminosSec9Titulo, texto: t.legalTerminosSec9Texto),
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
