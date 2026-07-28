import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../l10n/app_localizations.dart';
import '../../services/professional_service.dart';
import '../../utils/error_extraction.dart';
import '../../widgets/entrada_animada.dart';
import '../profesional_shell_screen.dart';

enum _OpcionDisponibilidad { noDisponible, horarioLaboral, veinticuatroHoras }

/// Sección "Disponibilidad" del Panel Profesional.
///
/// Rediseñada a partir del feedback de que el interruptor "en línea" y
/// el "modo" por separado generaban confusión (¿cuál manda?). Ahora es
/// una única selección de 3 estados excluyentes entre sí — no
/// disponible, horario laboral o 24h — que se traduce directamente a
/// `disponible` + `modoDisponibilidad` en la API sin que el usuario
/// tenga que pensar en esos dos campos como conceptos separados.
class DisponibilidadProfesionalScreen extends ConsumerStatefulWidget {
  const DisponibilidadProfesionalScreen({super.key});

  @override
  ConsumerState<DisponibilidadProfesionalScreen> createState() => _DisponibilidadProfesionalScreenState();
}

class _DisponibilidadProfesionalScreenState extends ConsumerState<DisponibilidadProfesionalScreen> {
  final _professionalService = ProfessionalService();

  MiPerfilProfesional? _perfil;
  _OpcionDisponibilidad _opcion = _OpcionDisponibilidad.noDisponible;
  bool _actualizando = false;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final perfil = await _professionalService.obtenerMiPerfil();
      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _opcion = !perfil.disponible
            ? _OpcionDisponibilidad.noDisponible
            : (perfil.modoDisponibilidad == ModoDisponibilidad.veinticuatroHoras
                ? _OpcionDisponibilidad.veinticuatroHoras
                : _OpcionDisponibilidad.horarioLaboral);
        _cargando = false;
      });
    } catch (e) {
      debugPrint('[DisponibilidadProfesionalScreen] Error al cargar: $e');
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  Future<void> _elegir(_OpcionDisponibilidad opcion) async {
    if (opcion == _opcion) return;
    final t = AppLocalizations.of(context);

    // Sin categoría/foto no hay absolutamente ninguna búsqueda en la
    // que el profesional pueda aparecer — activar cualquiera de los
    // dos modos "disponible" en ese estado no fallaría "de forma
    // confusa", sería directamente inútil. "No disponible" nunca se
    // bloquea: siempre se puede desactivar.
    final requierePerfilCompleto = opcion != _OpcionDisponibilidad.noDisponible;
    if (requierePerfilCompleto && _perfil != null && !_perfil!.perfilCompleto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.disponibilidadPerfilIncompleto)),
      );
      return;
    }

    final opcionAnterior = _opcion;
    setState(() {
      _opcion = opcion;
      _actualizando = true;
    });

    try {
      double? lat;
      double? lng;
      final disponible = opcion != _OpcionDisponibilidad.noDisponible;

      if (disponible) {
        var permiso = await Geolocator.checkPermission();
        if (permiso == LocationPermission.denied) {
          permiso = await Geolocator.requestPermission();
        }
        if (permiso != LocationPermission.denied && permiso != LocationPermission.deniedForever) {
          final posicion = await Geolocator.getCurrentPosition();
          lat = posicion.latitude;
          lng = posicion.longitude;
        }
      }

      await _professionalService.actualizarDisponibilidad(
        disponible: disponible,
        modo: opcion == _OpcionDisponibilidad.veinticuatroHoras
            ? ModoDisponibilidad.veinticuatroHoras
            : ModoDisponibilidad.horarioLaboral,
        latitud: lat,
        longitud: lng,
      );
      if (!mounted) return;
    } catch (e) {
      debugPrint('[DisponibilidadProfesionalScreen] Error al cambiar disponibilidad: $e');
      if (!mounted) return;
      setState(() => _opcion = opcionAnterior);
      // Antes esto mostraba la excepción cruda de Dio en vez del
      // motivo real que el backend sí manda (ej. "No puedes ponerte
      // disponible hasta ser verificado").
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.profesionalErrorDisponibilidad, t: t))),
      );
    } finally {
      if (mounted) setState(() => _actualizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final perfilCompleto = _perfil?.perfilCompleto ?? true; // evita parpadeo del aviso mientras carga

    return Scaffold(
      appBar: AppBar(title: Text(t.disponibilidadTitulo)),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (!perfilCompleto)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: EntradaAnimada(
                      child: _AvisoPerfilIncompleto(
                        onCompletar: () => ref.read(profesionalTabIndexProvider.notifier).state = 2,
                      ),
                    ),
                  )
                else if (_perfil != null && !_perfil!.estaVerificado)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: EntradaAnimada(
                      child: _AvisoBloqueo(
                        icono: Icons.hourglass_top_outlined,
                        texto: t.disponibilidadPendienteVerificacion,
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        colorTexto: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                EntradaAnimada(
                  child: Text(
                    t.disponibilidadEstadoTitulo,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 4),
                EntradaAnimada(
                  retraso: const Duration(milliseconds: 40),
                  child: Text(
                    t.disponibilidadEstadoAyuda,
                    style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 14),
                EntradaAnimada(
                  retraso: const Duration(milliseconds: 80),
                  child: _TarjetaOpcion(
                    icono: Icons.bolt_outlined,
                    color: Colors.red,
                    titulo: t.disponibilidadOpcionNoDisponibleTitulo,
                    ayuda: t.disponibilidadOpcionNoDisponibleAyuda,
                    seleccionada: _opcion == _OpcionDisponibilidad.noDisponible,
                    deshabilitada: _actualizando,
                    onTap: () => _elegir(_OpcionDisponibilidad.noDisponible),
                  ),
                ),
                const SizedBox(height: 10),
                EntradaAnimada(
                  retraso: const Duration(milliseconds: 120),
                  child: _TarjetaOpcion(
                    icono: Icons.wb_sunny_outlined,
                    color: Colors.amber.shade700,
                    titulo: t.disponibilidadModoHorarioLaboral,
                    ayuda: t.disponibilidadModoHorarioLaboralAyuda,
                    seleccionada: _opcion == _OpcionDisponibilidad.horarioLaboral,
                    deshabilitada: _actualizando || !perfilCompleto,
                    onTap: () => _elegir(_OpcionDisponibilidad.horarioLaboral),
                  ),
                ),
                const SizedBox(height: 10),
                EntradaAnimada(
                  retraso: const Duration(milliseconds: 160),
                  child: _TarjetaOpcion(
                    icono: Icons.nightlight_round,
                    color: Colors.indigo,
                    titulo: t.disponibilidadModo24h,
                    ayuda: t.disponibilidadModo24hAyuda,
                    seleccionada: _opcion == _OpcionDisponibilidad.veinticuatroHoras,
                    deshabilitada: _actualizando || !perfilCompleto,
                    onTap: () => _elegir(_OpcionDisponibilidad.veinticuatroHoras),
                  ),
                ),
                if (_actualizando) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ],
            ),
    );
  }
}

class _AvisoPerfilIncompleto extends StatelessWidget {
  const _AvisoPerfilIncompleto({required this.onCompletar});

  final VoidCallback onCompletar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: colorScheme.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.disponibilidadPerfilIncompleto,
                    style: TextStyle(fontSize: 13, color: colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onCompletar,
              style: OutlinedButton.styleFrom(foregroundColor: colorScheme.onErrorContainer),
              child: Text(t.disponibilidadCompletarPerfil),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvisoBloqueo extends StatelessWidget {
  const _AvisoBloqueo({
    required this.icono,
    required this.texto,
    required this.color,
    required this.colorTexto,
  });

  final IconData icono;
  final String texto;
  final Color color;
  final Color colorTexto;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: colorTexto),
            const SizedBox(width: 12),
            Expanded(
              child: Text(texto, style: TextStyle(fontSize: 13, color: colorTexto)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaOpcion extends StatelessWidget {
  const _TarjetaOpcion({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.ayuda,
    required this.seleccionada,
    required this.deshabilitada,
    required this.onTap,
  });

  final IconData icono;
  final Color color;
  final String titulo;
  final String ayuda;
  final bool seleccionada;
  final bool deshabilitada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: deshabilitada && !seleccionada ? 0.45 : 1,
      child: Material(
        color: seleccionada ? color.withOpacity(0.14) : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: deshabilitada ? null : onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: seleccionada ? color : Colors.transparent, width: 1.5),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icono, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: seleccionada ? color : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ayuda,
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(
                  seleccionada ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: seleccionada ? color : colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
