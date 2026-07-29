import 'dart:io';
import 'package:flutter/material.dart';
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
import '../profesional_shell_screen.dart';

/// Perfil del profesional — rediseño "tarjetas independientes": cada
/// dato editable (teléfono, descripción, categorías) tiene su propio
/// botón de edición discreto y se guarda al momento en su propio
/// diálogo, en vez de un formulario largo con un único botón "Guardar
/// cambios" al final. Disponibilidad no se edita aquí — solo muestra un
/// resumen y enlaza a su propia pestaña, para no duplicar esa lógica
/// (geolocalización incluida) en dos sitios.
///
/// También es el único sitio del rol profesional con cerrar sesión — a
/// diferencia del cliente (con su propia PerfilScreen), el profesional
/// no tiene una pantalla de perfil separada, así que vive aquí.
class MiPerfilProfesionalScreen extends ConsumerStatefulWidget {
  const MiPerfilProfesionalScreen({super.key});

  @override
  ConsumerState<MiPerfilProfesionalScreen> createState() => _MiPerfilProfesionalScreenState();
}

class _MiPerfilProfesionalScreenState extends ConsumerState<MiPerfilProfesionalScreen> {
  final _professionalService = ProfessionalService();
  final _serviceRequestService = ServiceRequestService();
  final _userService = UserService();
  final _tarifaController = TextEditingController();

  MiPerfilProfesional? _perfil;
  String? _fotoPerfilUrlActual;
  File? _fotoLocalSeleccionada;
  bool _cargando = true;
  bool _subiendoFoto = false;
  String? _errorCarga;

  // Documentación de verificación — antes de esto, submitVerificationDocs
  // (backend) existía completo pero ningún sitio del frontend lo
  // llamaba: un profesional podía "completar" foto+categorías y creer
  // que ya estaba listo, sin disparar nunca el envío real de
  // documentación que un admin pudiera revisar y aprobar.
  String? _documentoIdentidadUrlActual;
  File? _documentoLocalSeleccionado;
  bool _subiendoDocumento = false;
  bool _enviandoVerificacion = false;

  List<ServiceCategory> _todasCategorias = [];
  List<String> _categoriasActuales = [];
  bool _actualizandoCategorias = false;

  /// Lo mínimo para aparecer en búsquedas de forma útil: foto y al
  /// menos una categoría. Se recalcula sobre el estado LOCAL (no el
  /// que vino del servidor) para que el aviso desaparezca al instante
  /// según se va completando.
  bool get _perfilCompleto => _fotoPerfilUrlActual != null && _categoriasActuales.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _tarifaController.dispose();
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
        _documentoIdentidadUrlActual = perfil.documentoIdentidadUrl;
        // tarifaBase empieza en 0 en el backend hasta el primer envío de
        // verificación — mostrarlo como "0.00" invitaría a enviarlo tal
        // cual, y el backend lo rechazaría (tarifaBase debe ser positiva).
        _tarifaController.text = perfil.tarifaBase > 0 ? perfil.tarifaBase.toStringAsFixed(2) : '';
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

  /// Diálogo genérico de un solo campo de texto — usado para nombre,
  /// teléfono y descripción. Solo pide el texto nuevo; qué se hace con
  /// él (a qué endpoint se manda) lo decide cada método que lo llama.
  Future<String?> _pedirTexto({
    required String titulo,
    required String valorInicial,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    final controller = TextEditingController(text: valorInicial);
    final t = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.perfilCancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(t.miPerfilGuardar),
          ),
        ],
      ),
    );
  }

  Future<void> _editarNombre() async {
    final t = AppLocalizations.of(context);
    final nuevo = await _pedirTexto(titulo: t.loginFieldNombre, valorInicial: _perfil?.nombre ?? '');
    if (nuevo == null || nuevo.isEmpty || !mounted) return;

    try {
      final usuario = await _userService.actualizarPerfil(nombre: nuevo);
      ref.read(authProvider.notifier).actualizarUsuario(usuario);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.miPerfilExito)));
      _cargarPerfil();
    } catch (e) {
      debugPrint('[MiPerfilProfesionalScreen] Error al actualizar el nombre: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.miPerfilErrorGuardar}: ${mensajeDeError(e, t: t)}')),
      );
    }
  }

  Future<void> _editarTelefono() async {
    final t = AppLocalizations.of(context);
    final nuevo = await _pedirTexto(
      titulo: t.editarPerfilTelefono,
      valorInicial: _perfil?.telefono ?? '',
      keyboardType: TextInputType.phone,
    );
    if (nuevo == null || !mounted) return;

    try {
      final usuario = await _userService.actualizarPerfil(telefono: nuevo);
      ref.read(authProvider.notifier).actualizarUsuario(usuario);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.miPerfilExito)));
      _cargarPerfil();
    } catch (e) {
      debugPrint('[MiPerfilProfesionalScreen] Error al actualizar el teléfono: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.miPerfilErrorGuardar}: ${mensajeDeError(e, t: t)}')),
      );
    }
  }

  Future<void> _editarDescripcion() async {
    final t = AppLocalizations.of(context);
    final nuevo = await _pedirTexto(
      titulo: t.miPerfilDescripcionLabel,
      valorInicial: _perfil?.descripcion ?? '',
      maxLines: 4,
      maxLength: 250,
    );
    if (nuevo == null || !mounted) return;

    try {
      await _professionalService.actualizarPerfil(descripcion: nuevo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.miPerfilExito)));
      _cargarPerfil();
    } catch (e) {
      debugPrint('[MiPerfilProfesionalScreen] Error al actualizar la descripción: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.miPerfilErrorGuardar}: ${mensajeDeError(e, t: t)}')),
      );
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
      // Persistida ANTES de reflejarla en el estado local — si el PATCH
      // falla, no queremos que la UI muestre la foto como "guardada"
      // mientras el backend todavía tiene la anterior.
      await _professionalService.actualizarPerfil(fotoPerfilUrl: url);
      if (!mounted) return;
      setState(() => _fotoPerfilUrlActual = url);
    } catch (e) {
      debugPrint('[MiPerfilProfesionalScreen] Error al subir la foto: $e');
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      setState(() => _fotoLocalSeleccionada = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.fotoErrorSubir)),
      );
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  Future<void> _elegirDocumento() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600);
    if (imagen == null) return;

    setState(() {
      _documentoLocalSeleccionado = File(imagen.path);
      _subiendoDocumento = true;
    });

    try {
      final url = await ServiceRequestService().subirFoto(_documentoLocalSeleccionado!);
      if (!mounted) return;
      setState(() => _documentoIdentidadUrlActual = url);
    } catch (e) {
      debugPrint('[MiPerfilProfesionalScreen] Error al subir el documento: $e');
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      setState(() => _documentoLocalSeleccionado = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.fotoErrorSubir)),
      );
    } finally {
      if (mounted) setState(() => _subiendoDocumento = false);
    }
  }

  /// Envía documento + categorías + tarifa a revisión de un admin
  /// (POST /professionals/me/verification). Las categorías se mandan
  /// desde aquí también (no solo desde _editarCategorias) porque el
  /// backend las exige juntas en esta llamada.
  Future<void> _enviarVerificacion() async {
    final t = AppLocalizations.of(context);

    if (_documentoIdentidadUrlActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.miPerfilVerificacionErrorFaltaDocumento)),
      );
      return;
    }

    final tarifa = double.tryParse(_tarifaController.text.trim().replaceAll(',', '.'));
    if (tarifa == null || tarifa <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.miPerfilVerificacionErrorFaltaTarifa)),
      );
      return;
    }

    if (_categoriasActuales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.miPerfilCategoriasVacia)),
      );
      return;
    }

    final categoriaIds = _todasCategorias
        .where((c) => _categoriasActuales.contains(c.nombre))
        .map((c) => c.id)
        .toList();

    setState(() => _enviandoVerificacion = true);
    try {
      await _professionalService.enviarVerificacion(
        documentoIdentidadUrl: _documentoIdentidadUrlActual!,
        categoriaIds: categoriaIds,
        tarifaBase: tarifa,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.miPerfilVerificacionExito)),
      );
      _cargarPerfil();
    } catch (e) {
      debugPrint('[MiPerfilProfesionalScreen] Error al enviar verificación: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.miPerfilVerificacionErrorEnvio}: ${mensajeDeError(e, t: t)}')),
      );
    } finally {
      if (mounted) setState(() => _enviandoVerificacion = false);
    }
  }

  IconData get _estadoIcono {
    switch (_perfil?.estadoVerificacion) {
      case 'aprobado':
        return Icons.verified_outlined;
      case 'rechazado':
        return Icons.cancel_outlined;
      default:
        return _documentoIdentidadUrlActual == null ? Icons.upload_file_outlined : Icons.hourglass_top_outlined;
    }
  }

  Color _estadoColor(ColorScheme colorScheme) {
    switch (_perfil?.estadoVerificacion) {
      case 'aprobado':
        return const Color(0xFF1EA672);
      case 'rechazado':
        return colorScheme.error;
      default:
        return _documentoIdentidadUrlActual == null ? colorScheme.outline : const Color(0xFFB98900);
    }
  }

  String _estadoLabel(AppLocalizations t) {
    switch (_perfil?.estadoVerificacion) {
      case 'aprobado':
        return t.miPerfilEstadoAprobado;
      case 'rechazado':
        return t.miPerfilEstadoRechazado;
      default:
        return _documentoIdentidadUrlActual == null ? t.miPerfilEstadoSinEnviar : t.miPerfilEstadoPendiente;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.miPerfilTitulo)),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _errorCarga != null
              ? Center(child: Text(t.miPerfilErrorCargar))
              : RefreshIndicator(
                  onRefresh: _cargarPerfil,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
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
                        child: _Cabecera(
                          nombre: _perfil?.nombre ?? '',
                          oficio: _perfil?.oficioPrincipal != null
                              ? nombreLocalizadoCategoria(context, _perfil!.oficioPrincipal!)
                              : t.miPerfilOficioSinAsignar,
                          verificado: _perfil?.estaVerificado ?? false,
                          valoracionMedia: _perfil?.valoracionMedia ?? 0,
                          totalValoraciones: _perfil?.totalTrabajos ?? 0,
                          fotoLocal: _fotoLocalSeleccionada,
                          fotoUrl: _fotoPerfilUrlActual,
                          subiendoFoto: _subiendoFoto,
                          onCambiarFoto: _elegirFoto,
                          onEditarNombre: _editarNombre,
                          estadoIcono: _estadoIcono,
                          estadoColor: _estadoColor(colorScheme),
                          estadoLabel: _estadoLabel(t),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Categorías va primero — es lo primero que un
                      // profesional nuevo necesita elegir (hace falta para
                      // poder enviar la verificación, justo debajo). La
                      // cabecera ya muestra categoría y estado de un
                      // vistazo (chips bajo el nombre), así que aquí ya no
                      // hace falta repetir esa info en tarjetas de
                      // estadística aparte.
                      EntradaAnimada(
                        retraso: const Duration(milliseconds: 90),
                        child: _TarjetaInfo(
                          icono: Icons.category_outlined,
                          titulo: t.miPerfilCategoriasTitulo,
                          requerido: true,
                          onEditar: _actualizandoCategorias ? null : _editarCategorias,
                          trailing: _actualizandoCategorias
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : null,
                          child: _categoriasActuales.isEmpty
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
                        ),
                      ),
                      if ((_perfil?.estadoVerificacion ?? 'pendiente') != 'aprobado') ...[
                        const SizedBox(height: 16),
                        EntradaAnimada(
                          retraso: const Duration(milliseconds: 120),
                          child: _TarjetaVerificacion(
                            estadoVerificacion: _perfil?.estadoVerificacion,
                            documentoEnviado: _documentoIdentidadUrlActual != null,
                            subiendoDocumento: _subiendoDocumento,
                            enviando: _enviandoVerificacion,
                            tarifaController: _tarifaController,
                            onElegirDocumento: _elegirDocumento,
                            onEnviar: _enviarVerificacion,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      EntradaAnimada(
                        retraso: const Duration(milliseconds: 150),
                        child: _TarjetaContacto(
                          telefono: _perfil?.telefono ?? '',
                          descripcion: _perfil?.descripcion ?? '',
                          onEditarTelefono: _editarTelefono,
                          onEditarDescripcion: _editarDescripcion,
                        ),
                      ),
                      const SizedBox(height: 16),
                      EntradaAnimada(
                        retraso: const Duration(milliseconds: 210),
                        child: _TarjetaInfo(
                          icono: Icons.bolt_outlined,
                          titulo: t.disponibilidadTitulo,
                          trailing: TextButton(
                            onPressed: () => ref.read(profesionalTabIndexProvider.notifier).state = 1,
                            child: Text(t.miPerfilCambiar),
                          ),
                          child: _EstadoDisponibilidad(perfil: _perfil),
                        ),
                      ),
                      const SizedBox(height: 16),
                      EntradaAnimada(
                        retraso: const Duration(milliseconds: 260),
                        child: _TarjetaInfo(
                          icono: Icons.reviews_outlined,
                          titulo: t.perfilProOpinionesTitulo,
                          child: ResumenYListaOpiniones(
                            valoracionMedia: _perfil?.valoracionMedia ?? 0,
                            totalValoraciones: _perfil?.totalTrabajos ?? 0,
                            opiniones: _perfil?.opiniones ?? const [],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      EntradaAnimada(
                        retraso: const Duration(milliseconds: 300),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: _confirmarCerrarSesion,
                            icon: Icon(Icons.logout, size: 18, color: colorScheme.error),
                            label: Text(t.perfilCerrarSesion, style: TextStyle(color: colorScheme.error)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

/// Cabecera del perfil: foto grande, distintivo de verificado, nombre
/// (con edición discreta), profesión y valoración con estrellas.
class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.nombre,
    required this.oficio,
    required this.verificado,
    required this.valoracionMedia,
    required this.totalValoraciones,
    required this.fotoLocal,
    required this.fotoUrl,
    required this.subiendoFoto,
    required this.onCambiarFoto,
    required this.onEditarNombre,
    required this.estadoIcono,
    required this.estadoColor,
    required this.estadoLabel,
  });

  final String nombre;
  final String oficio;
  final bool verificado;
  final double valoracionMedia;
  final int totalValoraciones;
  final File? fotoLocal;
  final String? fotoUrl;
  final bool subiendoFoto;
  final VoidCallback onCambiarFoto;
  final VoidCallback onEditarNombre;
  final IconData estadoIcono;
  final Color estadoColor;
  final String estadoLabel;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final estrellasLlenas = valoracionMedia.round().clamp(0, 5);

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: colorScheme.shadow.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: CircleAvatar(
                radius: 58,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage: fotoLocal != null
                    ? FileImage(fotoLocal!)
                    : (fotoUrl != null ? NetworkImage(fotoUrl!) : null) as ImageProvider?,
                child: (fotoLocal == null && fotoUrl == null)
                    ? Text(
                        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                      )
                    : null,
              ),
            ),
            if (subiendoFoto)
              const Positioned.fill(
                child: CircleAvatar(
                  radius: 58,
                  backgroundColor: Colors.black45,
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Material(
                color: colorScheme.primary,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: subiendoFoto ? null : onCambiarFoto,
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Icon(Icons.camera_alt_outlined, size: 18, color: colorScheme.onPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (verificado) ...[
          const VerificationBadge(conEtiqueta: true),
          const SizedBox(height: 10),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                nombre,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onEditarNombre,
              icon: const Icon(Icons.edit_outlined, size: 16),
              tooltip: t.miPerfilEditar,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(
              5,
              (i) => Icon(
                i < estrellasLlenas ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 18,
                color: Colors.amber.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              valoracionMedia > 0 ? valoracionMedia.toStringAsFixed(1) : '—',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 4),
            Text(
              t.opinionesTotal(totalValoraciones),
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Resumen rápido de categoría + estado justo bajo el nombre y la
        // valoración — antes esta info solo se veía bajando hasta las
        // tarjetas de Categorías/Verificación; con esto se ve de un
        // vistazo sin desplazarse, y permite quitar la tarjeta de
        // estadística "Estado" que quedaba redundante con esto.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _ChipResumen(icono: Icons.category_outlined, color: colorScheme.primary, texto: oficio),
            _ChipResumen(icono: estadoIcono, color: estadoColor, texto: estadoLabel),
          ],
        ),
      ],
    );
  }
}

/// Chip compacto de solo lectura para el resumen rápido de la cabecera
/// (categoría, estado) — a diferencia de [Chip] de Material, sin borde
/// ni sombra, solo un fondo tenue del color dado.
class _ChipResumen extends StatelessWidget {
  const _ChipResumen({required this.icono, required this.color, required this.texto});

  final IconData icono;
  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 6),
          Text(texto, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// Contenedor visual común a todas las tarjetas de información
/// independientes (teléfono, descripción, categorías, disponibilidad,
/// opiniones): fondo limpio, sombra suave, bordes redondeados, título
/// con icono y un botón de edición discreto (solo icono) a la derecha.
class _TarjetaInfo extends StatelessWidget {
  const _TarjetaInfo({
    required this.icono,
    required this.titulo,
    required this.child,
    this.onEditar,
    this.trailing,
    this.requerido = false,
  });

  final IconData icono;
  final String titulo;
  final Widget child;
  final VoidCallback? onEditar;
  final Widget? trailing;
  final bool requerido;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: colorScheme.shadow.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: _FilaInfo(
        icono: icono,
        titulo: titulo,
        onEditar: onEditar,
        trailing: trailing,
        requerido: requerido,
        child: child,
      ),
    );
  }
}

/// El contenido de una _TarjetaInfo (título con icono + botón de edición
/// discreto + contenido) sin el contenedor exterior — se reutiliza para
/// apilar más de un "tema" dentro de una misma tarjeta con sombra
/// (ver la tarjeta combinada de Teléfono + Descripción), en vez de una
/// tarjeta entera por cada dato suelto.
class _FilaInfo extends StatelessWidget {
  const _FilaInfo({
    required this.icono,
    required this.titulo,
    required this.child,
    this.onEditar,
    this.trailing,
    this.requerido = false,
  });

  final IconData icono;
  final String titulo;
  final Widget child;
  final VoidCallback? onEditar;
  final Widget? trailing;
  final bool requerido;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant),
            ),
            if (requerido)
              Text(' *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.error)),
            const Spacer(),
            if (trailing != null) trailing!,
            if (onEditar != null)
              IconButton(
                onPressed: onEditar,
                icon: const Icon(Icons.edit_outlined, size: 17),
                tooltip: t.miPerfilEditar,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

/// Tarjeta combinada de Teléfono + Descripción — dos filas independientes
/// (cada una con su propio botón de edición y su propio diálogo de
/// guardado) dentro de una única tarjeta con sombra, en vez de dos
/// tarjetas completas para dos datos sueltos de una línea cada uno.
class _TarjetaContacto extends StatelessWidget {
  const _TarjetaContacto({
    required this.telefono,
    required this.descripcion,
    required this.onEditarTelefono,
    required this.onEditarDescripcion,
  });

  final String telefono;
  final String descripcion;
  final VoidCallback onEditarTelefono;
  final VoidCallback onEditarDescripcion;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final tieneTelefono = telefono.isNotEmpty;
    final tieneDescripcion = descripcion.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: colorScheme.shadow.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilaInfo(
            icono: Icons.call_outlined,
            titulo: t.editarPerfilTelefono,
            onEditar: onEditarTelefono,
            child: Text(
              tieneTelefono ? telefono : t.miPerfilTelefonoVacio,
              style: TextStyle(
                fontSize: 14.5,
                color: tieneTelefono ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          _FilaInfo(
            icono: Icons.notes_outlined,
            titulo: t.miPerfilDescripcionLabel,
            onEditar: onEditarDescripcion,
            child: Text(
              tieneDescripcion ? descripcion : t.miPerfilDescripcionVacia,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.4,
                color: tieneDescripcion ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Resumen de disponibilidad dentro de su tarjeta — solo lectura; el
/// cambio real (con geolocalización) vive en DisponibilidadProfesionalScreen,
/// aquí solo se enlaza a esa pestaña para no duplicar esa lógica.
class _EstadoDisponibilidad extends StatelessWidget {
  const _EstadoDisponibilidad({required this.perfil});

  final MiPerfilProfesional? perfil;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final disponible = perfil?.disponible ?? false;

    final color = !disponible
        ? Colors.red
        : (perfil?.modoDisponibilidad == ModoDisponibilidad.veinticuatroHoras ? Colors.indigo : Colors.amber.shade700);
    final titulo = !disponible
        ? t.disponibilidadOpcionNoDisponibleTitulo
        : (perfil?.modoDisponibilidad == ModoDisponibilidad.veinticuatroHoras
            ? t.disponibilidadModo24h
            : t.disponibilidadModoHorarioLaboral);

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 10),
        Text(titulo, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
      ],
    );
  }
}

/// Tarjeta de acción para enviar/reenviar documentación de verificación
/// — se muestra mientras el profesional no esté aprobado. A diferencia
/// de las _TarjetaInfo (mostrar + editar), esta es una tarjeta de
/// acción activa, con su propio botón principal.
class _TarjetaVerificacion extends StatelessWidget {
  const _TarjetaVerificacion({
    required this.estadoVerificacion,
    required this.documentoEnviado,
    required this.subiendoDocumento,
    required this.enviando,
    required this.tarifaController,
    required this.onElegirDocumento,
    required this.onEnviar,
  });

  final String? estadoVerificacion;
  final bool documentoEnviado;
  final bool subiendoDocumento;
  final bool enviando;
  final TextEditingController tarifaController;
  final VoidCallback onElegirDocumento;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: colorScheme.shadow.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                t.miPerfilVerificacionTitulo,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            estadoVerificacion == 'rechazado'
                ? t.miPerfilVerificacionEstadoRechazado
                : (!documentoEnviado ? t.miPerfilVerificacionEstadoSinEnviar : t.miPerfilVerificacionEstadoPendiente),
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.35),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: subiendoDocumento ? null : onElegirDocumento,
            icon: subiendoDocumento
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(documentoEnviado ? Icons.check_circle_outline : Icons.upload_file_outlined),
            label: Text(t.miPerfilDocumentoSeleccionar),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: tarifaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: t.miPerfilPrecioLabel),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: enviando ? null : onEnviar,
              child: enviando
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(t.miPerfilEnviarVerificacion),
            ),
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
