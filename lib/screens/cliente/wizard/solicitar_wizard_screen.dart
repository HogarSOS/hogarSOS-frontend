import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/service_category_model.dart';
import '../../../models/service_request_model.dart';
import '../../../providers/service_request_provider.dart';
import '../../../utils/category_display.dart';
import '../seguimiento_solicitud_screen.dart';
import 'ubicacion_picker_screen.dart';

class SolicitarWizardScreen extends ConsumerStatefulWidget {
  const SolicitarWizardScreen({super.key, this.categoriaInicial});

  /// Si el usuario llega desde un tile de categoría en Inicio, ya viene
  /// preseleccionada — el paso 1 sigue existiendo, pero ya aparece marcado.
  final ServiceCategory? categoriaInicial;

  @override
  ConsumerState<SolicitarWizardScreen> createState() => _SolicitarWizardScreenState();
}

enum _EstadoFoto { subiendo, lista, error }

class _FotoWizard {
  final File archivo;
  _EstadoFoto estado;
  String? url;
  _FotoWizard(this.archivo, {this.estado = _EstadoFoto.subiendo, this.url});
}

enum _PasoWizard { categoria, descripcion, fotos, ubicacion, urgencia, revision }

class _SolicitarWizardScreenState extends ConsumerState<SolicitarWizardScreen> {
  final _pageController = PageController();
  final _descripcionController = TextEditingController();
  int _pasoActual = 0;
  bool _publicando = false;
  String? _errorPaso;

  ServiceCategory? _categoria;
  final List<_FotoWizard> _fotos = [];
  UbicacionSeleccionada? _ubicacion;
  UrgenciaSolicitud _urgencia = UrgenciaSolicitud.loAntesPosible;
  DateTime? _fechaDeseada;

  // Si ya se llega con una categoría elegida (desde un tile de Inicio o
  // de "Ver todas las categorías"), no tiene sentido volver a pedirla en
  // el primer paso del asistente — eso era la duplicidad real: el
  // usuario ya había elegido categoría y el asistente se la volvía a
  // preguntar. En ese caso el paso de categoría desaparece del todo del
  // recorrido; sigue pudiéndose cambiar, pero desde un selector rápido
  // (_abrirSelectorCategoria), no repitiendo un paso completo.
  late final List<_PasoWizard> _pasos = widget.categoriaInicial == null
      ? _PasoWizard.values
      : _PasoWizard.values.where((p) => p != _PasoWizard.categoria).toList();

  int get _totalPasos => _pasos.length;

  @override
  void initState() {
    super.initState();
    _categoria = widget.categoriaInicial;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  bool _validarPasoActual(AppLocalizations t) {
    switch (_pasos[_pasoActual]) {
      case _PasoWizard.categoria:
        if (_categoria == null) {
          setState(() => _errorPaso = t.wizardErrorCategoria);
          return false;
        }
        return true;
      case _PasoWizard.descripcion:
        if (_descripcionController.text.trim().length < 10) {
          setState(() => _errorPaso = t.wizardErrorDescripcion);
          return false;
        }
        return true;
      case _PasoWizard.fotos:
        return true; // las fotos son opcionales
      case _PasoWizard.ubicacion:
        if (_ubicacion == null) {
          setState(() => _errorPaso = t.wizardErrorUbicacion);
          return false;
        }
        return true;
      case _PasoWizard.urgencia:
        if (_urgencia == UrgenciaSolicitud.fechaEspecifica && _fechaDeseada == null) {
          setState(() => _errorPaso = t.wizardErrorFecha);
          return false;
        }
        return true;
      case _PasoWizard.revision:
        return true;
    }
  }

  Future<void> _abrirSelectorCategoria() async {
    final categoria = await showModalBottomSheet<ServiceCategory>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SelectorCategoriaSheet(seleccionada: _categoria),
    );
    if (categoria != null) setState(() => _categoria = categoria);
  }

  void _irSiguiente() {
    final t = AppLocalizations.of(context);
    setState(() => _errorPaso = null);
    if (!_validarPasoActual(t)) return;

    if (_pasoActual == _totalPasos - 1) {
      _publicar();
      return;
    }

    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  void _irAtras() {
    if (_pasoActual == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _errorPaso = null);
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  Future<void> _agregarFoto(ImageSource fuente) async {
    if (_fotos.length >= 6) return;

    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: fuente, imageQuality: 80, maxWidth: 1600);
    if (imagen == null) return;

    final foto = _FotoWizard(File(imagen.path));
    setState(() => _fotos.add(foto));

    try {
      final servicio = ref.read(serviceRequestServiceProvider);
      final url = await servicio.subirFoto(foto.archivo);
      if (!mounted) return;
      setState(() {
        foto.estado = _EstadoFoto.lista;
        foto.url = url;
      });
    } catch (e) {
      debugPrint('[SolicitarWizardScreen] Error al subir foto: $e');
      if (!mounted) return;
      setState(() => foto.estado = _EstadoFoto.error);
    }
  }

  Future<void> _publicar() async {
    final t = AppLocalizations.of(context);
    // Sin este check, pulsar "Publicar" mientras una foto todavía se
    // está subiendo la descartaba en silencio (solo se envían las que
    // ya tienen `estado == lista`) — el usuario creía haber adjuntado
    // N fotos y la solicitud salía con menos, sin ningún aviso.
    if (_fotos.any((f) => f.estado == _EstadoFoto.subiendo)) {
      setState(() => _errorPaso = t.wizardErrorFotosSubiendo);
      return;
    }

    setState(() => _publicando = true);
    try {
      final servicio = ref.read(serviceRequestServiceProvider);
      final urlsListas =
          _fotos.where((f) => f.estado == _EstadoFoto.lista && f.url != null).map((f) => f.url!).toList();

      final solicitudId = await servicio.crearSolicitud(
        categoryId: _categoria!.id,
        descripcion: _descripcionController.text.trim(),
        latitud: _ubicacion!.latitud,
        longitud: _ubicacion!.longitud,
        fotosUrls: urlsListas,
        direccionTexto: _ubicacion!.direccionTexto,
        urgencia: _urgencia,
        fechaDeseada: _fechaDeseada,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => SeguimientoSolicitudScreen(solicitudId: solicitudId)),
      );
    } catch (e) {
      debugPrint('[SolicitarWizardScreen] Error al publicar la solicitud: $e');
      setState(() => _errorPaso = t.homeErrorCrearSolicitud);
    } finally {
      if (mounted) setState(() => _publicando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.wizardTitulo),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _irAtras),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween(begin: 0, end: (_pasoActual + 1) / _totalPasos),
                    builder: (context, valor, _) => LinearProgressIndicator(
                      value: valor,
                      minHeight: 6,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.wizardPaso(_pasoActual + 1, _totalPasos),
                  style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (widget.categoriaInicial != null && _categoria != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _ChipCategoriaElegida(
                categoria: _categoria!,
                onCambiar: _abrirSelectorCategoria,
              ),
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _pasoActual = i),
              children: [
                for (final paso in _pasos)
                  switch (paso) {
                    _PasoWizard.categoria => _PasoCategoria(
                        seleccionada: _categoria,
                        onSeleccionar: (c) => setState(() {
                          _categoria = c;
                          _errorPaso = null;
                        }),
                      ),
                    _PasoWizard.descripcion => _PasoDescripcion(
                        controller: _descripcionController,
                        categoria: _categoria,
                      ),
                    _PasoWizard.fotos => _PasoFotos(
                        fotos: _fotos,
                        onAgregar: _agregarFoto,
                        onEliminar: (f) => setState(() => _fotos.remove(f)),
                      ),
                    _PasoWizard.ubicacion => _PasoUbicacion(
                        ubicacion: _ubicacion,
                        onSeleccionar: (u) => setState(() {
                          _ubicacion = u;
                          _errorPaso = null;
                        }),
                      ),
                    _PasoWizard.urgencia => _PasoUrgencia(
                        urgencia: _urgencia,
                        fechaDeseada: _fechaDeseada,
                        onCambiarUrgencia: (u) => setState(() {
                          _urgencia = u;
                          _errorPaso = null;
                        }),
                        onCambiarFecha: (f) => setState(() => _fechaDeseada = f),
                      ),
                    _PasoWizard.revision => _PasoRevision(
                        categoria: _categoria,
                        descripcion: _descripcionController.text,
                        fotos: _fotos,
                        ubicacion: _ubicacion,
                        urgencia: _urgencia,
                        fechaDeseada: _fechaDeseada,
                      ),
                  },
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorPaso != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _errorPaso!,
                        style: TextStyle(color: colorScheme.error, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  FilledButton(
                    onPressed: _publicando ? null : _irSiguiente,
                    child: _publicando
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_pasoActual == _totalPasos - 1 ? t.wizardPublicar : t.wizardSiguiente),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Paso 1: Categoría ───────────────────────────

class _PasoCategoria extends ConsumerWidget {
  const _PasoCategoria({required this.seleccionada, required this.onSeleccionar});

  final ServiceCategory? seleccionada;
  final ValueChanged<ServiceCategory> onSeleccionar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final categoriasAsync = ref.watch(categoriesProvider);

    return _PasoScaffold(
      titulo: t.wizardPaso1Titulo,
      child: categoriasAsync.when(
        data: (categorias) => GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: categorias.length,
          itemBuilder: (context, index) {
            final categoria = categorias[index];
            final elegida = seleccionada?.id == categoria.id;
            final color = colorParaCategoria(categoria.nombre);

            return AnimatedScale(
              duration: const Duration(milliseconds: 150),
              scale: elegida ? 1.05 : 1.0,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onSeleccionar(categoria),
                child: Container(
                  decoration: BoxDecoration(
                    color: elegida ? color.withOpacity(0.15) : Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: elegida ? color : Colors.transparent, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(iconoParaCategoria(categoria.nombre), color: color, size: 28),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          nombreLocalizadoCategoria(context, categoria.nombre),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(t.homeCategoriasError)),
      ),
    );
  }
}

// ───────────── Chip de categoría ya elegida (evita repetir el paso) ─────────────

class _ChipCategoriaElegida extends StatelessWidget {
  const _ChipCategoriaElegida({required this.categoria, required this.onCambiar});

  final ServiceCategory categoria;
  final VoidCallback onCambiar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final color = colorParaCategoria(categoria.nombre);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onCambiar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(iconoParaCategoria(categoria.nombre), color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nombreLocalizadoCategoria(context, categoria.nombre),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
              ),
              Text(
                t.wizardCategoriaCambiar,
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hoja inferior para cambiar de categoría sin salir del asistente ni
/// repetir un paso entero — reutiliza el mismo diseño de rejilla que
/// _PasoCategoria, para que sea la MISMA forma de elegir categoría en
/// toda la app, no una tercera variante distinta.
class _SelectorCategoriaSheet extends ConsumerWidget {
  const _SelectorCategoriaSheet({required this.seleccionada});

  final ServiceCategory? seleccionada;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final categoriasAsync = ref.watch(categoriesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.wizardCategoriaElegirTitulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Flexible(
                child: categoriasAsync.when(
                  data: (categorias) => GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: categorias.length,
                    itemBuilder: (context, index) {
                      final categoria = categorias[index];
                      final elegida = seleccionada?.id == categoria.id;
                      final color = colorParaCategoria(categoria.nombre);

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.of(context).pop(categoria),
                        child: Container(
                          decoration: BoxDecoration(
                            color: elegida ? color.withOpacity(0.15) : Theme.of(context).colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: elegida ? color : Colors.transparent, width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(iconoParaCategoria(categoria.nombre), color: color, size: 28),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  nombreLocalizadoCategoria(context, categoria.nombre),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text(t.homeCategoriasError)),
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

// ─────────────────────────── Paso 2: Descripción ───────────────────────────

class _PasoDescripcion extends StatelessWidget {
  const _PasoDescripcion({required this.controller, required this.categoria});

  final TextEditingController controller;

  /// Categoría ya elegida en el paso 1 — determina qué ejemplo de
  /// descripción se muestra (ver ejemploDescripcionParaCategoria).
  final ServiceCategory? categoria;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return _PasoScaffold(
      titulo: t.wizardPaso2Titulo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.wizardPaso2Ayuda, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 8,
            maxLength: 1000,
            autofocus: true,
            decoration: InputDecoration(
              hintText: ejemploDescripcionParaCategoria(context, categoria?.nombre),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Paso 3: Fotos ───────────────────────────

class _PasoFotos extends StatelessWidget {
  const _PasoFotos({required this.fotos, required this.onAgregar, required this.onEliminar});

  final List<_FotoWizard> fotos;
  final void Function(ImageSource) onAgregar;
  final void Function(_FotoWizard) onEliminar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return _PasoScaffold(
      titulo: t.wizardPaso3Titulo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.wizardPaso3Ayuda, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...fotos.map((foto) => _MiniaturaFoto(foto: foto, onEliminar: () => onEliminar(foto))),
              if (fotos.length < 6)
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _mostrarOpciones(context),
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.add_a_photo_outlined, color: colorScheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _mostrarOpciones(BuildContext context) {
    final t = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(t.wizardFotoCamara),
              onTap: () {
                Navigator.of(context).pop();
                onAgregar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t.wizardFotoGaleria),
              onTap: () {
                Navigator.of(context).pop();
                onAgregar(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniaturaFoto extends StatelessWidget {
  const _MiniaturaFoto({required this.foto, required this.onEliminar});

  final _FotoWizard foto;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(foto.archivo, width: 88, height: 88, fit: BoxFit.cover),
        ),
        if (foto.estado == _EstadoFoto.subiendo)
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(14)),
            child: const Center(
              child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ),
          ),
        if (foto.estado == _EstadoFoto.error)
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(14)),
            child: const Center(child: Icon(Icons.error_outline, color: Colors.white)),
          ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: onEliminar,
            child: const CircleAvatar(
              radius: 11,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Paso 4: Ubicación ───────────────────────────

class _PasoUbicacion extends StatelessWidget {
  const _PasoUbicacion({required this.ubicacion, required this.onSeleccionar});

  final UbicacionSeleccionada? ubicacion;
  final ValueChanged<UbicacionSeleccionada> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return _PasoScaffold(
      titulo: t.wizardPaso4Titulo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.wizardPaso4Ayuda, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          if (ubicacion != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ubicacion!.direccionTexto ??
                          '${ubicacion!.latitud.toStringAsFixed(5)}, ${ubicacion!.longitud.toStringAsFixed(5)}',
                      style: TextStyle(color: colorScheme.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.map_outlined),
            label: Text(ubicacion == null ? t.wizardUbicacionElegir : t.wizardUbicacionCambiar),
            onPressed: () async {
              final resultado = await Navigator.of(context).push<UbicacionSeleccionada>(
                MaterialPageRoute(builder: (_) => UbicacionPickerScreen(ubicacionInicial: ubicacion)),
              );
              if (resultado != null) onSeleccionar(resultado);
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Paso 5: Urgencia ───────────────────────────

class _PasoUrgencia extends StatelessWidget {
  const _PasoUrgencia({
    required this.urgencia,
    required this.fechaDeseada,
    required this.onCambiarUrgencia,
    required this.onCambiarFecha,
  });

  final UrgenciaSolicitud urgencia;
  final DateTime? fechaDeseada;
  final ValueChanged<UrgenciaSolicitud> onCambiarUrgencia;
  final ValueChanged<DateTime> onCambiarFecha;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final opciones = [
      (UrgenciaSolicitud.loAntesPosible, t.wizardUrgenciaAsap, Icons.bolt_outlined),
      (UrgenciaSolicitud.hoy, t.wizardUrgenciaHoy, Icons.today_outlined),
      (UrgenciaSolicitud.manana, t.wizardUrgenciaManana, Icons.wb_twilight),
      (UrgenciaSolicitud.fechaEspecifica, t.wizardUrgenciaFecha, Icons.event_outlined),
    ];

    return _PasoScaffold(
      titulo: t.wizardPaso5Titulo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final opcion in opciones) ...[
            _OpcionUrgencia(
              icono: opcion.$3,
              etiqueta: opcion.$2,
              seleccionada: urgencia == opcion.$1,
              onTap: () => onCambiarUrgencia(opcion.$1),
            ),
            const SizedBox(height: 10),
          ],
          if (urgencia == UrgenciaSolicitud.fechaEspecifica) ...[
            const SizedBox(height: 4),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                fechaDeseada == null
                    ? t.wizardSeleccionarFecha
                    : '${fechaDeseada!.day}/${fechaDeseada!.month}/${fechaDeseada!.year}',
              ),
              onPressed: () async {
                final ahora = DateTime.now();
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: fechaDeseada ?? ahora.add(const Duration(days: 2)),
                  firstDate: ahora,
                  lastDate: ahora.add(const Duration(days: 180)),
                );
                if (fecha != null) onCambiarFecha(fecha);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _OpcionUrgencia extends StatelessWidget {
  const _OpcionUrgencia({required this.icono, required this.etiqueta, required this.seleccionada, required this.onTap});

  final IconData icono;
  final String etiqueta;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: seleccionada ? colorScheme.primaryContainer : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: seleccionada ? colorScheme.primary : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icono, color: seleccionada ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              etiqueta,
              style: TextStyle(
                fontWeight: seleccionada ? FontWeight.w600 : FontWeight.w400,
                color: seleccionada ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (seleccionada) Icon(Icons.check_circle, color: colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Paso 6: Revisión ───────────────────────────

class _PasoRevision extends StatelessWidget {
  const _PasoRevision({
    required this.categoria,
    required this.descripcion,
    required this.fotos,
    required this.ubicacion,
    required this.urgencia,
    required this.fechaDeseada,
  });

  final ServiceCategory? categoria;
  final String descripcion;
  final List<_FotoWizard> fotos;
  final UbicacionSeleccionada? ubicacion;
  final UrgenciaSolicitud urgencia;
  final DateTime? fechaDeseada;

  String _textoUrgencia(AppLocalizations t) => switch (urgencia) {
        UrgenciaSolicitud.loAntesPosible => t.wizardUrgenciaAsap,
        UrgenciaSolicitud.hoy => t.wizardUrgenciaHoy,
        UrgenciaSolicitud.manana => t.wizardUrgenciaManana,
        UrgenciaSolicitud.fechaEspecifica =>
          fechaDeseada != null ? '${fechaDeseada!.day}/${fechaDeseada!.month}/${fechaDeseada!.year}' : t.wizardUrgenciaFecha,
      };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return _PasoScaffold(
      titulo: t.wizardPaso6Titulo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (categoria != null)
            _FilaRevision(
              icono: iconoParaCategoria(categoria!.nombre),
              color: colorParaCategoria(categoria!.nombre),
              titulo: nombreLocalizadoCategoria(context, categoria!.nombre),
            ),
          const Divider(height: 28),
          Text(descripcion, style: const TextStyle(fontSize: 14)),
          if (fotos.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: fotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(fotos[i].archivo, width: 64, height: 64, fit: BoxFit.cover),
                ),
              ),
            ),
          ],
          const Divider(height: 28),
          _FilaRevision(
            icono: Icons.location_on_outlined,
            color: colorScheme.primary,
            titulo: ubicacion?.direccionTexto ??
                (ubicacion != null
                    ? '${ubicacion!.latitud.toStringAsFixed(5)}, ${ubicacion!.longitud.toStringAsFixed(5)}'
                    : ''),
          ),
          const SizedBox(height: 12),
          _FilaRevision(icono: Icons.schedule_outlined, color: colorScheme.primary, titulo: _textoUrgencia(t)),
        ],
      ),
    );
  }
}

class _FilaRevision extends StatelessWidget {
  const _FilaRevision({required this.icono, required this.color, required this.titulo});

  final IconData icono;
  final Color color;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    );
  }
}

// ─────────────────────────── Contenedor común de cada paso ───────────────────────────

class _PasoScaffold extends StatelessWidget {
  const _PasoScaffold({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
