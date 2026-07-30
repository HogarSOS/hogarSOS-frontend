import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/service_category_model.dart';
import '../../providers/search_provider.dart';
import '../../providers/service_request_provider.dart';
import '../../utils/category_display.dart';
import '../../widgets/entrada_animada.dart';
import '../cliente_shell_screen.dart';
import 'professional_detail_screen.dart';
import 'widgets/filtros_sheet.dart';
import 'widgets/professional_card.dart';

class BuscarScreen extends ConsumerStatefulWidget {
  const BuscarScreen({super.key});

  @override
  ConsumerState<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends ConsumerState<BuscarScreen> {
  final _textoController = TextEditingController();
  bool _yaBuscoInicial = false;

  // Categorías consideradas "urgentes" — es una curación de UX sobre
  // categorías REALES que ya existen en el backend, no un campo nuevo
  // ni un dato inventado. Se comparan por nombre canónico.
  static const _nombresUrgentes = {'electricista', 'fontanero', 'cerrajería', 'cerrajeria'};

  Future<void> _mostrarUrgentes(
    BuildContext context,
    List<ServiceCategory> categorias,
    SearchNotifier notifier,
  ) async {
    final t = AppLocalizations.of(context);
    final urgentes = categorias.where((c) => _nombresUrgentes.contains(c.nombre.trim().toLowerCase())).toList();

    if (urgentes.isEmpty) return; // aún no sembradas en esta BD — no rompe nada

    final elegido = await showModalBottomSheet<ServiceCategory>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(t.buscarUrgenteTitulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            for (final categoria in urgentes)
              ListTile(
                leading: Icon(iconoParaCategoria(categoria.nombre), color: colorParaCategoria(categoria.nombre)),
                title: Text(nombreLocalizadoCategoria(context, categoria.nombre)),
                onTap: () => Navigator.of(context).pop(categoria),
              ),
          ],
        ),
      ),
    );

    if (elegido != null) {
      notifier.actualizarCategoria(elegido.id);
    }
  }

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final categoriasAsync = ref.watch(categoriesProvider);
    final searchState = ref.watch(searchProvider);
    final searchNotifier = ref.read(searchProvider.notifier);

    // Primera carga: muestra resultados desde el principio (no espera
    // a que el usuario escriba o toque un filtro). Se espera a que esta
    // pestaña esté realmente seleccionada (índice 1 en
    // ClienteShellScreen) antes de disparar la búsqueda inicial y el
    // permiso de ubicación que conlleva — como ClienteShellScreen usa
    // IndexedStack, este widget se construye en cuanto se inicia sesión
    // aunque el usuario esté viendo "Inicio"; sin este guardado, la
    // búsqueda (y el diálogo de permiso de ubicación) se disparaba de
    // inmediato al hacer login, compitiendo por red con las llamadas
    // que sí hacían falta para pintar Inicio.
    if (!_yaBuscoInicial && ref.watch(clienteTabIndexProvider) == 1) {
      _yaBuscoInicial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => searchNotifier.buscarInicial());
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.navBuscar)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: EntradaAnimada(
              child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textoController,
                    onChanged: searchNotifier.actualizarTexto,
                    decoration: InputDecoration(
                      hintText: t.buscarHint,
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Material(
                      color: searchState.filtros.tieneFiltrosActivos
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          final resultado = await mostrarHojaDeFiltros(
                            context,
                            minValoracionActual: searchState.filtros.minValoracion,
                            precioMaxActual: searchState.filtros.precioMax,
                            radioMetrosActual: searchState.filtros.radioMetros,
                          );
                          if (resultado != null) {
                            searchNotifier.aplicarFiltros(
                              minValoracion: resultado.minValoracion,
                              precioMax: resultado.precioMax,
                              radioMetros: resultado.radioMetros,
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Icon(
                            Icons.tune,
                            color: searchState.filtros.tieneFiltrosActivos
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    if (searchState.filtros.tieneFiltrosActivos)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: colorScheme.error, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ],
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: categoriasAsync.when(
              data: (categorias) => ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                // +1 "Todas", +1 "Disponible ahora", +1 "Urgente"
                itemCount: categorias.length + 3,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final seleccionado = searchState.filtros.categoryId == null;
                    return ChoiceChip(
                      label: Text(t.buscarTodasCategorias),
                      selected: seleccionado,
                      onSelected: (_) => searchNotifier.actualizarCategoria(null),
                    );
                  }
                  if (index == 1) {
                    return ChoiceChip(
                      avatar: const Icon(Icons.bolt_outlined, size: 16),
                      label: Text(t.filtroSoloDisponibles),
                      selected: searchState.filtros.soloDisponibles,
                      onSelected: (_) => searchNotifier.alternarSoloDisponibles(),
                    );
                  }
                  if (index == 2) {
                    // "Urgente" no es un dato del backend — es un atajo de UX
                    // que preselecciona las categorías típicamente urgentes
                    // (electricista, fontanero, cerrajería). No inventa datos,
                    // solo filtra sobre categorías reales ya existentes.
                    return ActionChip(
                      avatar: const Icon(Icons.whatshot_outlined, size: 16),
                      label: Text(t.buscarUrgente),
                      onPressed: () => _mostrarUrgentes(context, categorias, searchNotifier),
                    );
                  }
                  final categoria = categorias[index - 3];
                  final seleccionado = searchState.filtros.categoryId == categoria.id;
                  return ChoiceChip(
                    avatar: Icon(iconoParaCategoria(categoria.nombre), size: 16, color: colorParaCategoria(categoria.nombre)),
                    label: Text(nombreLocalizadoCategoria(context, categoria.nombre)),
                    selected: seleccionado,
                    onSelected: (_) => searchNotifier.actualizarCategoria(seleccionado ? null : categoria.id),
                  );
                },
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: searchState.resultados.when(
              data: (resultados) {
                if (resultados.isEmpty) {
                  return _EstadoVacio(
                    icono: Icons.search_off,
                    titulo: t.buscarSinResultadosTitulo,
                    descripcion: t.buscarSinResultadosDescripcion,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: resultados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final profesional = resultados[index];
                    return ProfessionalCard(
                      profesional: profesional,
                      retraso: Duration(milliseconds: 40 * index),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfessionalDetailScreen(userId: profesional.userId),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _EstadoVacio(
                icono: Icons.error_outline,
                titulo: t.buscarErrorTitulo,
                descripcion: '',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio({required this.icono, required this.titulo, required this.descripcion});

  final IconData icono;
  final String titulo;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            if (descripcion.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                descripcion,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
