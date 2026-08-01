import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/service_category_model.dart';
import '../../models/service_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_request_provider.dart';
import '../../theme/brand_mark.dart';
import '../../utils/category_display.dart';
import '../../widgets/entrada_animada.dart';
import 'mis_solicitudes_screen.dart';
import 'todas_categorias_screen.dart';
import 'wizard/solicitar_wizard_screen.dart';


class HomeClienteScreen extends ConsumerWidget {
  const HomeClienteScreen({super.key});

  void _abrirAsistente(BuildContext context, {ServiceCategory? categoriaInicial}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SolicitarWizardScreen(categoriaInicial: categoriaInicial),
      ),
    );
  }

  /// Saludo según la hora real del dispositivo — dato real, no de
  /// relleno, calculado en el momento en que se construye la pantalla.
  String _saludoPorHora(AppLocalizations t, String nombre) {
    final hora = DateTime.now().hour;
    if (nombre.isEmpty) return t.homeSaludoGenerico;
    if (hora < 12) return t.homeSaludoManana(nombre);
    if (hora < 20) return t.homeSaludoTarde(nombre);
    return t.homeSaludoNoche(nombre);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final categoriasAsync = ref.watch(categoriesProvider);
    final nombre = ref.watch(authProvider).usuario?.nombre.split(' ').first ?? '';
    final resumenAsync = ref.watch(resumenActividadClienteProvider);
    // Mismo cálculo que antes usaba la tarjeta rosa de resumen (ya
    // retirada, duplicaba lo que ya decía el acceso rápido "Mis
    // solicitudes" de aquí abajo) — ahora alimenta el badge de ese
    // acceso rápido en su lugar.
    final activas = resumenAsync.maybeWhen(
      data: (solicitudes) => solicitudes
          .where((s) =>
              s.estado == EstadoSolicitud.pendiente ||
              s.estado == EstadoSolicitud.aceptada ||
              s.estado == EstadoSolicitud.en_progreso)
          .length,
      orElse: () => 0,
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
            ref.invalidate(resumenActividadClienteProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: EntradaAnimada(
                  retraso: Duration.zero,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _saludoPorHora(t, nombre),
                                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, height: 1.2),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t.homeSubtitulo,
                                style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Marca de hogarSOS en la pantalla de Inicio del cliente —
                        // Inicio no tiene AppBar propio (ver diseño de Sprint 2),
                        // así que sin esto la identidad visual solo aparecía en
                        // login/splash y desaparecía en cuanto se entraba a la app.
                        const HogarSosMark(size: 40),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: EntradaAnimada(
                  retraso: const Duration(milliseconds: 60),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _TarjetaSolicitar(
                      titulo: t.homeSolicitarProfesional,
                      subtitulo: t.homeSolicitarProfesionalAyuda,
                      onTap: () => _abrirAsistente(context),
                    ),
                  ),
                ),
              ),
              // "Buscar" y "Favoritos" se ocultaron (no se borró su código:
              // buscar_screen.dart sigue intacto, sin referenciar desde
              // aquí) — el modelo actual de hogarSOS es publicar solicitud
              // → recibir candidaturas, no contactar directo con un
              // profesional ni guardar favoritos (esa función nunca se
              // llegó a implementar). "Mis solicitudes" pasa a ocupar toda
              // la fila, con más protagonismo ahora que no comparte sitio.
              SliverToBoxAdapter(
                child: EntradaAnimada(
                  retraso: const Duration(milliseconds: 120),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _TarjetaMisSolicitudes(
                      activas: activas,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MisSolicitudesScreen()),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: EntradaAnimada(
                    retraso: const Duration(milliseconds: 200),
                    child: Text(
                      t.homeCategoriasTitulo,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                    ),
                  ),
                ),
              ),
              categoriasAsync.when(
                data: (categorias) {
                  // 12 categorías destacadas (3 filas de 4, antes 9 en 3
                  // filas de 3) — al quitar "Buscar" y "Favoritos" de la
                  // fila de accesos rápidos quedó sitio de sobra para que
                  // entren más sin tener que pulsar "Ver todas", y así
                  // "Albañilería" queda garantizada en pantalla sin
                  // depender del tamaño de dispositivo. Orden: los oficios
                  // más solicitados primero, con las dos categorías nuevas
                  // (masajes, manicura y pedicura) al final. El resto sigue
                  // accesible desde "Ver todas las categorías" sin dejar de
                  // cargarse dinámicamente desde el backend. Se admite con
                  // y sin tilde porque category_display.dart ya contempla
                  // ambas variantes como sinónimos válidos.
                  const gruposDestacados = [
                    ['electricista'],
                    ['fontanero'],
                    ['pintor'],
                    ['cerrajería', 'cerrajeria', 'cerrajero'],
                    ['aire acondicionado'],
                    ['limpieza'],
                    ['manitas'],
                    ['albañilería', 'albanileria', 'albañil'],
                    ['jardinería', 'jardineria'],
                    ['reformas'],
                    ['masajes a domicilio'],
                    ['manicura y pedicura'],
                  ];

                  final destacadas = <ServiceCategory>[];
                  for (final sinonimos in gruposDestacados) {
                    for (final categoria in categorias) {
                      if (sinonimos.contains(categoria.nombre.trim().toLowerCase())) {
                        destacadas.add(categoria);
                        break;
                      }
                    }
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    sliver: SliverGrid(
                      // childAspectRatio más bajo que antes (más alto que
                      // ancho): "Aire acondicionado" es más larga que el
                      // resto de categorías destacadas y con el ratio
                      // anterior desbordaba 2 líneas de texto por debajo
                      // de la tarjeta en dispositivos reales.
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final categoria = destacadas[index];
                          return EntradaAnimada(
                            retraso: Duration(milliseconds: 220 + (index * 30)),
                            child: _TarjetaCategoriaDestacada(
                              categoria: categoria,
                              onTap: () => _abrirAsistente(context, categoriaInicial: categoria),
                            ),
                          );
                        },
                        childCount: destacadas.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
                ),
                error: (_, __) => SliverToBoxAdapter(
                  child: Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(t.homeCategoriasError))),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                sliver: SliverToBoxAdapter(
                  child: EntradaAnimada(
                    retraso: const Duration(milliseconds: 380),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.apps),
                      label: Text(t.homeVerTodasCategorias),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TodasCategoriasScreen()),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Envoltorio de animación de entrada reutilizable: fundido + desplazamiento
/// suave hacia arriba, con retraso configurable — el mismo lenguaje visual
/// que ya usa ProfessionalCard en la búsqueda, aplicado aquí para que Inicio
/// se sienta parte de la misma app, no una pantalla aparte.
class _TarjetaSolicitar extends StatelessWidget {
  const _TarjetaSolicitar({required this.titulo, required this.subtitulo, required this.onTap});

  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.82)],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.campaign_outlined, color: colorScheme.onPrimary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(color: colorScheme.onPrimary, fontSize: 16.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.88), fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward, size: 16, color: colorScheme.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta horizontal de "Mis solicitudes" — antes compartía fila con
/// "Buscar" y "Favoritos" (retirados, ver comentario donde se usa esta
/// tarjeta); ahora ocupa toda la fila con más protagonismo, mostrando el
/// número de solicitudes activas como texto además del badge, no solo
/// como un número pequeño encima del icono.
class _TarjetaMisSolicitudes extends StatelessWidget {
  const _TarjetaMisSolicitudes({required this.activas, required this.onTap});

  final int activas;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final hayActivas = activas > 0;

    return Material(
      color: hayActivas ? colorScheme.tertiaryContainer.withOpacity(0.55) : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Badge(
                isLabelVisible: hayActivas,
                label: Text('$activas'),
                backgroundColor: colorScheme.error,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
                  child: Icon(Icons.receipt_long_outlined, size: 21, color: colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.homeAccesoMisSolicitudes,
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                    ),
                    Text(
                      hayActivas ? t.homeResumenActivas(activas) : t.homeMisSolicitudesSinActivas,
                      style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaCategoriaDestacada extends StatefulWidget {
  const _TarjetaCategoriaDestacada({required this.categoria, required this.onTap});

  final ServiceCategory categoria;
  final VoidCallback onTap;

  @override
  State<_TarjetaCategoriaDestacada> createState() => _TarjetaCategoriaDestacadaState();
}

class _TarjetaCategoriaDestacadaState extends State<_TarjetaCategoriaDestacada> {
  bool _presionada = false;

  @override
  Widget build(BuildContext context) {
    final color = colorParaCategoria(widget.categoria.nombre);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _presionada = true),
      onTapUp: (_) => setState(() => _presionada = false),
      onTapCancel: () => setState(() => _presionada = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _presionada ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          // El primer intento (solo pasar de surfaceContainerHigh a
          // surfaceContainerHighest) resultó casi imperceptible: son dos
          // pasos consecutivos de la escala tonal de M3, pensada para
          // diferencias sutiles de "elevación", no para que una tarjeta
          // destaque. Ahora se mezcla directamente un 10% del color propio
          // de la categoría sobre la superficie — un cambio de verdad
          // visible, y además coherente con el color de cada categoría en
          // vez de un gris neutro genérico.
          color: Color.lerp(colorScheme.surface, color, 0.10),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.30), width: 1.2),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  // 0.15 → 0.30 de opacidad: el tinte de color detrás del
                  // icono se veía casi plano/pálido, sobre todo en tonos
                  // ya de por sí claros como el celeste de "aire
                  // acondicionado".
                  decoration: BoxDecoration(color: color.withOpacity(0.30), borderRadius: BorderRadius.circular(16)),
                  child: Icon(iconoParaCategoria(widget.categoria.nombre), size: 27, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  nombreLocalizadoCategoria(context, widget.categoria.nombre),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  // 11.5 → 13.5: se quedaba pequeño para leer cómodo,
                  // sobre todo para gente mayor. maxLines + ellipsis ya
                  // absorbe el texto más grande sin desbordar ni cambiar
                  // el tamaño de la tarjeta/cuadrícula.
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
