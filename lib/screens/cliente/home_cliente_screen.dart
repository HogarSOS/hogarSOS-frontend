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
import 'buscar_screen.dart';
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
              SliverToBoxAdapter(
                child: EntradaAnimada(
                  retraso: const Duration(milliseconds: 120),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _AccesoRapido(
                            icono: Icons.search,
                            etiqueta: t.homeAccesoBuscar,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const BuscarScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AccesoRapido(
                            icono: Icons.receipt_long_outlined,
                            etiqueta: t.homeAccesoMisSolicitudes,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const MisSolicitudesScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AccesoRapido(
                            icono: Icons.favorite_border,
                            etiqueta: t.homeAccesoFavoritos,
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(t.proximamenteTitulo)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Resumen de actividad — datos reales de tus propias
              // solicitudes; se oculta sin más si no hay ninguna activa,
              // en vez de mostrar un hueco vacío o un dato inventado.
              resumenAsync.when(
                data: (solicitudes) {
                  final activas = solicitudes
                      .where((s) =>
                          s.estado == EstadoSolicitud.pendiente ||
                          s.estado == EstadoSolicitud.aceptada ||
                          s.estado == EstadoSolicitud.en_progreso)
                      .length;
                  if (activas == 0) return const SliverToBoxAdapter(child: SizedBox.shrink());

                  return SliverToBoxAdapter(
                    child: EntradaAnimada(
                      retraso: const Duration(milliseconds: 160),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _TarjetaResumen(
                          cantidad: activas,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MisSolicitudesScreen()),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
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
                  // 7 categorías destacadas, en este orden — los oficios
                  // más solicitados primero, para que tengan más
                  // protagonismo en la pantalla de Inicio. El resto queda
                  // accesible desde "Ver todas las categorías" sin dejar
                  // de cargarse dinámicamente desde el backend. Se admite
                  // con y sin tilde porque category_display.dart ya
                  // contempla ambas variantes como sinónimos válidos.
                  const gruposDestacados = [
                    ['electricista'],
                    ['fontanero'],
                    ['pintor'],
                    ['cerrajería', 'cerrajeria', 'cerrajero'],
                    ['carpintería', 'carpinteria'],
                    ['aire acondicionado'],
                    ['limpieza'],
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
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.92,
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

class _AccesoRapido extends StatelessWidget {
  const _AccesoRapido({required this.icono, required this.etiqueta, required this.onTap});

  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              Icon(icono, size: 22, color: colorScheme.primary),
              const SizedBox(height: 6),
              Text(
                etiqueta,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  const _TarjetaResumen({required this.cantidad, required this.onTap});

  final int cantidad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.tertiaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.pending_actions_outlined, color: colorScheme.onTertiaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.homeResumenActivas(cantidad),
                  style: TextStyle(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onTertiaryContainer),
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
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(17)),
                  child: Icon(iconoParaCategoria(widget.categoria.nombre), size: 28, color: color),
                ),
                const SizedBox(height: 10),
                Text(
                  nombreLocalizadoCategoria(context, widget.categoria.nombre),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
