import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/service_category_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/disponibilidad_provider.dart';
import '../../providers/stripe_return_provider.dart';
import '../../services/professional_service.dart';
import '../../services/service_request_service.dart';
import '../../services/user_service.dart';
import '../../utils/category_display.dart';
import '../../utils/error_extraction.dart';
import '../../utils/tipo_profesional_display.dart';
import '../../widgets/eliminar_cuenta.dart';
import '../../widgets/entrada_animada.dart';
import '../../widgets/lista_opiniones.dart';
import '../legal/privacidad_screen.dart';
import '../legal/terminos_screen.dart';
import '../../widgets/verification_badge.dart';
import '../auth/login_screen.dart';
import '../../utils/imagen_autenticada.dart';

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
  TipoProfesional? _tipoProfesionalSeleccionado;

  bool _iniciandoOnboardingStripe = false;

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
        _tipoProfesionalSeleccionado = perfil.tipoProfesional;
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
        // El uso con maxLines: 4 (descripción) es el que más riesgo
        // tenía de desbordar con el teclado abierto — mismo fix que en
        // home_profesional_screen.dart.
        content: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
          ),
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
      // El selector de disponibilidad lee `perfilCompleto` de su propio
      // provider (disponibilidadProvider), no de este estado local —
      // sin refrescarlo se queda con el valor viejo (perfil incompleto)
      // aunque la categoría ya se haya guardado.
      ref.read(disponibilidadProvider.notifier).cargar();
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
      final url = await ServiceRequestService().subirFoto(_fotoLocalSeleccionada!, tipo: 'foto_perfil');
      // Persistida ANTES de reflejarla en el estado local — si el PATCH
      // falla, no queremos que la UI muestre la foto como "guardada"
      // mientras el backend todavía tiene la anterior.
      await _professionalService.actualizarPerfil(fotoPerfilUrl: url);
      if (!mounted) return;
      setState(() => _fotoPerfilUrlActual = url);
      // Mismo motivo que en _editarCategorias: el selector de
      // disponibilidad depende de disponibilidadProvider, no de este
      // estado local.
      ref.read(disponibilidadProvider.notifier).cargar();
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
      final url = await ServiceRequestService().subirFoto(_documentoLocalSeleccionado!, tipo: 'documento_identidad');
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

    // Opcional (ver comentario en professional.controller.ts): el precio
    // real de cada servicio ya se acuerda por presupuesto, no por esta
    // tarifa. Si el campo está vacío o no es un número válido, sigue sin
    // enviarse en vez de bloquear la verificación.
    final tarifaTexto = _tarifaController.text.trim().replaceAll(',', '.');
    final tarifa = tarifaTexto.isEmpty ? null : double.tryParse(tarifaTexto);
    if (tarifaTexto.isNotEmpty && (tarifa == null || tarifa <= 0)) {
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

    if (_tipoProfesionalSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.tipoProfesionalErrorFaltaSeleccion)),
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
        documentoIdentidadUrl: _documentoIdentidadUrlActual,
        categoriaIds: categoriaIds,
        tarifaBase: tarifa,
        tipoProfesional: _tipoProfesionalSeleccionado!,
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

  /// Abre el onboarding hospedado de Stripe Connect en el navegador
  /// externo. Al terminar, Stripe redirige a una página propia del
  /// backend (ver stripeOnboarding.routes.ts) que devuelve a la app vía
  /// deep link (`hogarsos://stripe-return/...`) — DeepLinkListener
  /// (services/deep_link_listener.dart) recibe ese link y dispara
  /// stripeReturnEventProvider, que este mismo widget escucha más
  /// arriba en build() para recargar el perfil automáticamente.
  Future<void> _configurarCuentaCobro() async {
    setState(() => _iniciandoOnboardingStripe = true);
    try {
      final url = await _professionalService.iniciarOnboardingStripe();
      final abierto = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!abierto && mounted) {
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.cuentaCobroErrorAbrir)));
      }
    } catch (e) {
      debugPrint('[MiPerfilProfesionalScreen] Error al iniciar onboarding de Stripe: $e');
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.cuentaCobroErrorAbrir)));
    } finally {
      if (mounted) setState(() => _iniciandoOnboardingStripe = false);
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

    // Igual que en CentroPagosScreen: este shell mantiene la pestaña
    // montada de fondo (IndexedStack), así que hay que escuchar el
    // retorno de Stripe explícitamente en vez de confiar en initState.
    ref.listen<int>(stripeReturnEventProvider, (anterior, actual) {
      if (anterior != null && anterior != actual) _cargarPerfil();
    });

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
                          tipoProfesional: _perfil?.tipoProfesional,
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
                            tipoProfesionalSeleccionado: _tipoProfesionalSeleccionado,
                            onElegirTipoProfesional: (tipo) => setState(() => _tipoProfesionalSeleccionado = tipo),
                            onElegirDocumento: _elegirDocumento,
                            onEnviar: _enviarVerificacion,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      EntradaAnimada(
                        retraso: const Duration(milliseconds: 135),
                        child: _TarjetaCuentaCobro(
                          estado: _perfil?.estadoCuentaStripe ?? EstadoCuentaStripe.pendiente,
                          cargando: _iniciandoOnboardingStripe,
                          onConfigurar: _configurarCuentaCobro,
                        ),
                      ),
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
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(color: colorScheme.shadow.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 6)),
                            ],
                          ),
                          padding: const EdgeInsets.all(18),
                          child: const _SelectorDisponibilidad(),
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
                      const SizedBox(height: 24),
                      EntradaAnimada(
                        retraso: const Duration(milliseconds: 290),
                        child: Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const PrivacidadScreen()),
                                ),
                                child: Text(t.perfilPrivacidad, style: const TextStyle(fontSize: 12.5)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const TerminosScreen()),
                                ),
                                child: Text(t.perfilTerminos, style: const TextStyle(fontSize: 12.5)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      EntradaAnimada(
                        retraso: const Duration(milliseconds: 300),
                        // Acción normal, no destructiva — antes en rojo,
                        // el mismo color que "Eliminar cuenta" justo
                        // debajo (y sin separación alguna entre ambas),
                        // lo que las hacía parecer igual de graves y
                        // fáciles de confundir (auditoría UX 2026-08-15).
                        child: Center(
                          child: TextButton.icon(
                            onPressed: _confirmarCerrarSesion,
                            icon: const Icon(Icons.logout, size: 18),
                            label: Text(t.perfilCerrarSesion),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Divider(color: colorScheme.outlineVariant),
                      ),
                      const SizedBox(height: 8),
                      EntradaAnimada(
                        retraso: const Duration(milliseconds: 320),
                        child: Center(
                          child: TextButton(
                            onPressed: () => confirmarYEliminarCuenta(context, ref),
                            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                            child: Text(t.perfilEliminarCuenta, style: const TextStyle(fontSize: 12.5)),
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
    this.tipoProfesional,
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
  final TipoProfesional? tipoProfesional;
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
                    : (fotoUrl != null
                        ? imagenDeRed(fotoUrl!, maxWidth: 320, maxHeight: 320)
                        : null) as ImageProvider?,
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
            if (tipoProfesional != null)
              _ChipResumen(
                icono: Icons.badge_outlined,
                color: colorScheme.onSurfaceVariant,
                texto: etiquetaTipoProfesional(t, tipoProfesional!),
              ),
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

enum _OpcionDisponibilidad { noDisponible, horarioLaboral, veinticuatroHoras }

/// Selector de disponibilidad — antes era su propia pestaña
/// (DisponibilidadProfesionalScreen), movida aquí dentro de "Mi perfil"
/// por decisión del roadmap económico (punto 2: Registro → Verificación
/// + Stripe en paralelo → Disponible, todo centrado en el perfil). Usa
/// `disponibilidadProvider`, compartido con el acceso rápido de "No
/// disponible" en la pestaña Solicitudes cercanas, para que ambos
/// sitios reflejen siempre el mismo estado sin desincronizarse.
class _SelectorDisponibilidad extends ConsumerWidget {
  const _SelectorDisponibilidad();

  Future<void> _elegir(BuildContext context, WidgetRef ref, DisponibilidadState actual, _OpcionDisponibilidad opcion) async {
    final t = AppLocalizations.of(context);
    final opcionActual = !actual.disponible
        ? _OpcionDisponibilidad.noDisponible
        : (actual.modo == ModoDisponibilidad.veinticuatroHoras ? _OpcionDisponibilidad.veinticuatroHoras : _OpcionDisponibilidad.horarioLaboral);
    if (opcion == opcionActual) return;

    // Sin categoría/foto no hay ninguna búsqueda en la que el
    // profesional pueda aparecer — "No disponible" nunca se bloquea.
    final requierePerfilCompleto = opcion != _OpcionDisponibilidad.noDisponible;
    if (requierePerfilCompleto && !actual.perfilCompleto) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.disponibilidadPerfilIncompleto)));
      return;
    }

    try {
      await ref.read(disponibilidadProvider.notifier).actualizar(
            disponible: opcion != _OpcionDisponibilidad.noDisponible,
            modo: opcion == _OpcionDisponibilidad.veinticuatroHoras ? ModoDisponibilidad.veinticuatroHoras : ModoDisponibilidad.horarioLaboral,
          );
    } catch (e) {
      debugPrint('[_SelectorDisponibilidad] Error al cambiar disponibilidad: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.profesionalErrorDisponibilidad, t: t))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final estadoAsync = ref.watch(disponibilidadProvider);

    return estadoAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, __) => Text(t.disponibilidadTitulo, style: TextStyle(fontSize: 13, color: colorScheme.error)),
      data: (estado) {
        final opcionActual = !estado.disponible
            ? _OpcionDisponibilidad.noDisponible
            : (estado.modo == ModoDisponibilidad.veinticuatroHoras ? _OpcionDisponibilidad.veinticuatroHoras : _OpcionDisponibilidad.horarioLaboral);
        final bloqueado = !estado.perfilCompleto || !estado.puedeActivarse;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  t.disponibilidadTitulo,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              t.disponibilidadEstadoAyuda,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (!estado.perfilCompleto)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(t.disponibilidadPerfilIncompleto, style: TextStyle(fontSize: 12.5, color: colorScheme.error)),
              )
            else if (!estado.estaVerificado)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(t.disponibilidadPendienteVerificacion, style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant)),
              )
            else if (estado.estadoCuentaStripe != EstadoCuentaStripe.configurada)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(t.disponibilidadPendienteStripe, style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant)),
              ),
            _TarjetaOpcionDisponibilidad(
              icono: Icons.bolt_outlined,
              color: Colors.red,
              titulo: t.disponibilidadOpcionNoDisponibleTitulo,
              ayuda: t.disponibilidadOpcionNoDisponibleAyuda,
              seleccionada: opcionActual == _OpcionDisponibilidad.noDisponible,
              deshabilitada: false,
              onTap: () => _elegir(context, ref, estado, _OpcionDisponibilidad.noDisponible),
            ),
            const SizedBox(height: 8),
            _TarjetaOpcionDisponibilidad(
              icono: Icons.wb_sunny_outlined,
              color: Colors.amber.shade700,
              titulo: t.disponibilidadModoHorarioLaboral,
              ayuda: t.disponibilidadModoHorarioLaboralAyuda,
              seleccionada: opcionActual == _OpcionDisponibilidad.horarioLaboral,
              deshabilitada: bloqueado,
              onTap: () => _elegir(context, ref, estado, _OpcionDisponibilidad.horarioLaboral),
            ),
            const SizedBox(height: 8),
            _TarjetaOpcionDisponibilidad(
              icono: Icons.nightlight_round,
              color: Colors.indigo,
              titulo: t.disponibilidadModo24h,
              ayuda: t.disponibilidadModo24hAyuda,
              seleccionada: opcionActual == _OpcionDisponibilidad.veinticuatroHoras,
              deshabilitada: bloqueado,
              onTap: () => _elegir(context, ref, estado, _OpcionDisponibilidad.veinticuatroHoras),
            ),
          ],
        );
      },
    );
  }
}

class _TarjetaOpcionDisponibilidad extends StatelessWidget {
  const _TarjetaOpcionDisponibilidad({
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
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: deshabilitada ? null : onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: seleccionada ? color : Colors.transparent, width: 1.5),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: color.withOpacity(0.16), borderRadius: BorderRadius.circular(11)),
                  child: Icon(icono, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: seleccionada ? color : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(ayuda, style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(
                  seleccionada ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: seleccionada ? color : colorScheme.outline,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
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
    required this.tipoProfesionalSeleccionado,
    required this.onElegirTipoProfesional,
    required this.onElegirDocumento,
    required this.onEnviar,
  });

  final String? estadoVerificacion;
  final bool documentoEnviado;
  final bool subiendoDocumento;
  final bool enviando;
  final TextEditingController tarifaController;
  final TipoProfesional? tipoProfesionalSeleccionado;
  final ValueChanged<TipoProfesional> onElegirTipoProfesional;
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
          const SizedBox(height: 6),
          Text(
            t.miPerfilPrecioAyuda,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, height: 1.35),
          ),
          const SizedBox(height: 18),
          Text(
            t.tipoProfesionalTitulo,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              (TipoProfesional.autonomo, t.tipoProfesionalAutonomo),
              (TipoProfesional.empresa, t.tipoProfesionalEmpresa),
              (TipoProfesional.personaFisica, t.tipoProfesionalPersonaFisica),
            ].map((opcion) {
              final (tipo, etiqueta) = opcion;
              return ChoiceChip(
                label: Text(etiqueta),
                selected: tipoProfesionalSeleccionado == tipo,
                onSelected: (_) => onElegirTipoProfesional(tipo),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            t.tipoProfesionalTextoLegal,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, height: 1.35),
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

/// Tarjeta de acción para configurar/actualizar/editar la cuenta de
/// cobro de Stripe Connect — antes solo se mostraba mientras el estado
/// no fuera 'configurada' (ver EstadoCuentaStripe, derivado en el
/// backend de charges_enabled/payouts_enabled/details_submitted
/// reales, no solo de si existe un stripeAccountId), así que una vez
/// configurada no quedaba ningún sitio en la app desde el que
/// modificarla (BUG 003 de QA: "no es una limitación de Stripe, era
/// que esta tarjeta entera desaparecía). Ahora siempre es visible; ya
/// configurada ofrece un botón "Editar" que abre el flujo de edición
/// de Stripe (`account_update`, ver professional.controller.ts) en vez
/// del de onboarding inicial.
class _TarjetaCuentaCobro extends StatelessWidget {
  const _TarjetaCuentaCobro({
    required this.estado,
    required this.cargando,
    required this.onConfigurar,
  });

  final EstadoCuentaStripe estado;
  final bool cargando;
  final VoidCallback onConfigurar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final requiereActualizacion = estado == EstadoCuentaStripe.requiereActualizacion;
    final configurada = estado == EstadoCuentaStripe.configurada;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: requiereActualizacion
              ? colorScheme.error.withOpacity(0.4)
              : colorScheme.outlineVariant.withOpacity(0.3),
        ),
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
              Icon(Icons.account_balance_wallet_outlined, size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                t.cuentaCobroTitulo,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            requiereActualizacion
                ? t.cuentaCobroEstadoRequiereActualizacion
                : (configurada ? t.cuentaCobroEstadoConfigurada : t.cuentaCobroEstadoPendiente),
            style: TextStyle(
              fontSize: 13,
              color: requiereActualizacion ? colorScheme.error : colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: configurada
                ? OutlinedButton.icon(
                    onPressed: cargando ? null : onConfigurar,
                    icon: cargando
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.edit_outlined, size: 18),
                    label: Text(t.cuentaCobroBotonEditar),
                  )
                : FilledButton.icon(
                    onPressed: cargando ? null : onConfigurar,
                    icon: cargando
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.open_in_new, size: 18),
                    label: Text(requiereActualizacion ? t.cuentaCobroBotonActualizar : t.cuentaCobroBotonConfigurar),
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
