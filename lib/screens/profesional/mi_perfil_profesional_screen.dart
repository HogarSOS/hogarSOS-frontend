import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../models/service_category_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/professional_service.dart';
import '../../services/service_request_service.dart';
import '../../services/user_service.dart';
import '../../utils/category_display.dart';
import '../../utils/error_extraction.dart';
import '../../widgets/entrada_animada.dart';
import '../../widgets/lista_opiniones.dart';
import '../../widgets/verification_badge.dart';
import '../auth/login_screen.dart';

/// Pantalla de edición del propio perfil del profesional. Al entrar/salir
/// de "Disponible" NO se navega a ningún sitio — se queda en la misma
/// pantalla, tal como se pidió; el interruptor solo actualiza el estado
/// local hasta que se pulsa "Guardar cambios".
///
/// También es el único sitio del rol profesional con cerrar sesión — a
/// diferencia del cliente (con su propia PerfilScreen), el profesional no
/// tiene una pantalla de perfil separada, así que vive aquí.
class MiPerfilProfesionalScreen extends ConsumerStatefulWidget {
  const MiPerfilProfesionalScreen({super.key});

  @override
  ConsumerState<MiPerfilProfesionalScreen> createState() => _MiPerfilProfesionalScreenState();
}

class _MiPerfilProfesionalScreenState extends ConsumerState<MiPerfilProfesionalScreen> {
  final _professionalService = ProfessionalService();
  final _serviceRequestService = ServiceRequestService();
  final _userService = UserService();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _descripcionController = TextEditingController();

  MiPerfilProfesional? _perfil;
  String? _fotoPerfilUrlActual;
  File? _fotoLocalSeleccionada;
  bool _cargando = true;
  bool _guardando = false;
  bool _subiendoFoto = false;
  String? _errorCarga;

  List<ServiceCategory> _todasCategorias = [];
  List<String> _categoriasActuales = [];
  bool _actualizandoCategorias = false;

  /// Lo mínimo para aparecer en búsquedas de forma útil: foto y al
  /// menos una categoría. Se recalcula sobre el estado LOCAL (no el
  /// que vino del servidor) para que el aviso desaparezca al instante
  /// según se va completando, sin esperar a guardar.
  bool get _perfilCompleto => _fotoPerfilUrlActual != null && _categoriasActuales.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    try {
      final resultados = await Future.wait([
        _professionalService.obtenerMiPerfil(),
        _serviceRequestService.obtenerCategorias(),
      ]);
      final perfil = resultados[0] as MiPerfilProfesional;
      final categorias = resultados[1] as List<ServiceCategory>;
      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _fotoPerfilUrlActual = perfil.fotoPerfilUrl;
        _nombreController.text = perfil.nombre;
        _telefonoController.text = perfil.telefono ?? '';
        _descripcionController.text = perfil.descripcion ?? '';
        _todasCategorias = categorias;
        _categoriasActuales = List<String>.from(perfil.categorias);
        _cargando = false;
      });
    } catch (e) {
      debugPrint('[MiPerfilProfesionalScreen] Error al cargar el perfil: $e');
      if (!mounted) return;
      setState(() {
        _errorCarga = 'error';
        _cargando = false;
      });
    }
  }

  Future<void> _editarCategorias() async {
    final t = AppLocalizations.of(context);
    final seleccionInicial = _todasCategorias
        .where((c) => _categoriasActuales.contains(c.nombre))
        .map((c) => c.id)
        .toSet();

    final resultado = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditorCategoriasSheet(
        todasCategorias: _todasCategorias,
        seleccionInicial: seleccionInicial,
      ),
    );

    if (resultado == null || !mounted) return;

    setState(() => _actualizandoCategorias = true);
    try {
      await _professionalService.actualizarCategorias(resultado);
      final nombresNuevos = _todasCategorias
          .where((c) => resultado.contains(c.id))
          .map((c) => c.nombre)
          .toList();
      if (!mounted) return;
      setState(() => _categoriasActuales = nombresNuevos);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.miPerfilCategoriasExito)),
      );
    } catch (e) {
      debugPrint('[MiPerfilProfesionalScreen] Error al actualizar categorías: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.miPerfilCategoriasError)),
      );
    } finally {
      if (mounted) setState(() => _actualizandoCategorias = false);
    }
  }

  Future<void> _confirmarCerrarSesion() async {
    final t = AppLocalizations.of(context);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.perfilCerrarSesion),
        content: Text(t.perfilConfirmarSalir),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.perfilCancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.perfilCerrarSesion),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _elegirFoto() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (imagen == null) return;

    setState(() {
      _fotoLocalSeleccionada = File(imagen.path);
      _subiendoFoto = true;
    });

    try {
      // Reutiliza el mismo endpoint de subida ya construido para las
      // fotos de solicitudes — es un almacén de archivos genérico, no
      // hace falta un endpoint nuevo para fotos de perfil.
      final url = await ServiceRequestService().subirFoto(_fotoLocalSeleccionada!);
      if (!mounted) return;
      setState(() => _fotoPerfilUrlActual = url);
    } catch (e) {
      debugPrint('[MiPerfilProfesionalScreen] Error al subir la foto: $e');
      if (!mounted) return;
      setState(() => _fotoLocalSeleccionada = null);
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  Future<void> _guardar() async {
    final t = AppLocalizations.of(context);
    setState(() => _guardando = true);

    try {
      // Dos llamadas porque nombre/teléfono viven en `users` (comunes a
      // cualquier rol) y descripción/foto en `professionals` — cada una
      // a su propio endpoint, no hay uno combinado ni falta que lo haya.
      final usuarioActualizado = await _userService.actualizarPerfil(
        nombre: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
      );
      await _professionalService.actualizarPerfil(
        descripcion: _descripcionController.text.trim(),
        fotoPerfilUrl: _fotoPerfilUrlActual,
      );

      ref.read(authProvider.notifier).actualizarUsuario(usuarioActualizado);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.miPerfilExito)),
      );
      _cargarPerfil(); // refresca estadoVerificacion/perfilCompleto por si acaso
    } catch (e) {
      debugPrint('[MiPerfilProfesionalScreen] Error al guardar: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.miPerfilErrorGuardar}: ${mensajeDeError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.miPerfilTitulo)), // el botón Atrás lo pone Flutter automáticamente
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _errorCarga != null
              ? Center(child: Text(t.miPerfilErrorCargar))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (!_perfilCompleto)
                      EntradaAnimada(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _AvisoPerfilIncompleto(
                            faltaFoto: _fotoPerfilUrlActual == null,
                            faltaCategoria: _categoriasActuales.isEmpty,
                          ),
                        ),
                      ),
                    EntradaAnimada(
                      child: Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 52,
                              backgroundColor: colorScheme.primaryContainer,
                              backgroundImage: _fotoLocalSeleccionada != null
                                  ? FileImage(_fotoLocalSeleccionada!)
                                  : (_fotoPerfilUrlActual != null
                                      ? NetworkImage(_fotoPerfilUrlActual!)
                                      : null) as ImageProvider?,
                              child: (_fotoLocalSeleccionada == null && _fotoPerfilUrlActual == null)
                                  ? Text(
                                      (_perfil?.nombre.isNotEmpty ?? false)
                                          ? _perfil!.nombre[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                    )
                                  : null,
                            ),
                            if (_subiendoFoto)
                              Positioned.fill(
                                child: CircleAvatar(
                                  radius: 52,
                                  backgroundColor: Colors.black45,
                                  child: const CircularProgressIndicator(color: Colors.white),
                                ),
                              ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Material(
                                color: colorScheme.primary,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _subiendoFoto ? null : _elegirFoto,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(Icons.camera_alt, size: 18, color: colorScheme.onPrimary),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_perfil?.estaVerificado ?? false) ...[
                      const SizedBox(height: 10),
                      const Center(child: VerificationBadge(conEtiqueta: true)),
                    ],
                    const SizedBox(height: 20),
                    EntradaAnimada(
                      retraso: const Duration(milliseconds: 60),
                      child: TextField(
                        controller: _nombreController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(labelText: t.loginFieldNombre),
                      ),
                    ),
                    const SizedBox(height: 16),
                    EntradaAnimada(
                      retraso: const Duration(milliseconds: 80),
                      child: TextField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(labelText: t.editarPerfilTelefono),
                      ),
                    ),
                    const SizedBox(height: 28),
                    EntradaAnimada(
                      retraso: const Duration(milliseconds: 100),
                      child: TextField(
                        controller: _descripcionController,
                        maxLength: 250,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: t.miPerfilDescripcionLabel,
                          helperText: t.miPerfilDescripcionAyuda,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    EntradaAnimada(
                      retraso: const Duration(milliseconds: 140),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    t.miPerfilCategoriasTitulo,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    ' *',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              _actualizandoCategorias
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : TextButton.icon(
                                      onPressed: _editarCategorias,
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      label: Text(t.miPerfilCategoriasEditar),
                                    ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _categoriasActuales.isEmpty
                              ? Text(
                                  t.miPerfilCategoriasVacia,
                                  style: TextStyle(fontSize: 13, color: colorScheme.error),
                                )
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _categoriasActuales.map((c) {
                                    return Chip(
                                      avatar: Icon(iconoParaCategoria(c), size: 16, color: colorParaCategoria(c)),
                                      label: Text(nombreLocalizadoCategoria(context, c)),
                                    );
                                  }).toList(),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    EntradaAnimada(
                      retraso: const Duration(milliseconds: 220),
                      child: FilledButton(
                        onPressed: _guardando ? null : _guardar,
                        child: _guardando
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(t.miPerfilGuardar),
                      ),
                    ),
                    const SizedBox(height: 12),
                    EntradaAnimada(
                      retraso: const Duration(milliseconds: 260),
                      child: OutlinedButton.icon(
                        onPressed: _confirmarCerrarSesion,
                        icon: const Icon(Icons.logout),
                        label: Text(t.perfilCerrarSesion),
                        style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(t.perfilProOpinionesTitulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ResumenYListaOpiniones(
                      valoracionMedia: _perfil?.valoracionMedia ?? 0,
                      totalValoraciones: _perfil?.totalTrabajos ?? 0,
                      opiniones: _perfil?.opiniones ?? const [],
                    ),
                  ],
                ),
    );
  }
}

class _AvisoPerfilIncompleto extends StatelessWidget {
  const _AvisoPerfilIncompleto({required this.faltaFoto, required this.faltaCategoria});

  final bool faltaFoto;
  final bool faltaCategoria;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final partes = <String>[
      if (faltaFoto) t.miPerfilFaltaFoto,
      if (faltaCategoria) t.miPerfilFaltaCategoria,
    ];

    return Material(
      color: colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.miPerfilIncompletoTitulo,
                    style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onErrorContainer),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${t.miPerfilIncompletoAyuda} ${partes.join(", ")}.',
                    style: TextStyle(fontSize: 12.5, color: colorScheme.onErrorContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hoja inferior para elegir qué categorías ofrece el profesional. Vive
/// fuera del flujo de verificación: guardar aquí solo llama a
/// PATCH /professionals/me/categories, sin tocar documentos ni
/// estadoVerificacion.
class _EditorCategoriasSheet extends StatefulWidget {
  const _EditorCategoriasSheet({required this.todasCategorias, required this.seleccionInicial});

  final List<ServiceCategory> todasCategorias;
  final Set<int> seleccionInicial;

  @override
  State<_EditorCategoriasSheet> createState() => _EditorCategoriasSheetState();
}

class _EditorCategoriasSheetState extends State<_EditorCategoriasSheet> {
  late Set<int> _seleccion;

  @override
  void initState() {
    super.initState();
    _seleccion = Set<int>.from(widget.seleccionInicial);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        // La lista de categorías (~20 entradas) no cabe siempre en pantalla,
        // sobre todo con el teclado abierto — sin este límite + scroll, el
        // contenido desbordaba y los botones Guardar/Cancelar quedaban
        // fuera de la pantalla, inalcanzables.
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.miPerfilCategoriasEditar, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.todasCategorias.map((categoria) {
                      final seleccionada = _seleccion.contains(categoria.id);
                      return FilterChip(
                        avatar: Icon(iconoParaCategoria(categoria.nombre), size: 16, color: colorParaCategoria(categoria.nombre)),
                        label: Text(nombreLocalizadoCategoria(context, categoria.nombre)),
                        selected: seleccionada,
                        onSelected: (valor) => setState(() {
                          if (valor) {
                            _seleccion.add(categoria.id);
                          } else {
                            _seleccion.remove(categoria.id);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(t.miPerfilCategoriasCancelar),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _seleccion.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(_seleccion.toList()),
                      child: Text(t.miPerfilCategoriasGuardar),
                    ),
                  ),
                ],
              ),
              if (_seleccion.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  t.miPerfilCategoriasErrorMinimo,
                  style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
