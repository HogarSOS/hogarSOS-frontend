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
import '../../widgets/informacion_profesional.dart';
import '../../widgets/selector_tipo_profesional.dart';
import '../../widgets/soporte_sheet.dart';
import '../../widgets/lista_opiniones.dart';
import '../../widgets/wizard_alta.dart';
import 'puente_stripe_screen.dart';
import '../legal/privacidad_screen.dart';
import '../legal/terminos_screen.dart';
import '../../widgets/verification_badge.dart';
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
  bool _activandoDisponibilidad = false;

  List<ServiceCategory> _todasCategorias = [];
  List<String> _categoriasActuales = [];
  bool _actualizandoCategorias = false;

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
        // El del servidor manda; pero si el servidor aún no tiene tipo
        // (se persiste solo con foto+categoría completas), un refresco
        // NO debe pisar la elección local todavía sin enviar — sin este
        // ??, cualquier _cargarPerfil intermedio deshacía la selección
        // y el subpaso del wizard volvía a "pendiente" solo.
        _tipoProfesionalSeleccionado = perfil.tipoProfesional ?? _tipoProfesionalSeleccionado;
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

  /// Editor unificado "Información profesional" (simplificación de Mi
  /// perfil, 2026-08-22): descripción + teléfono + tarifa en una sola
  /// hoja. Cada campo conserva su endpoint (teléfono → /users/me;
  /// descripción y tarifa → /professionals/me/profile) y solo se envía
  /// lo que cambió; si un endpoint falla, el mensaje dice exactamente
  /// qué se guardó y qué no — nunca un error genérico.
  Future<void> _editarInformacionProfesional() async {
    final t = AppLocalizations.of(context);

    // El tipo queda fijado tras aprobado + Stripe operativa: el
    // business_type de la cuenta Connect no puede seguir a un cambio
    // (KYC congelado tras el primer Account Link) — la vía es soporte.
    // Durante el alta se sigue cambiando desde el wizard, como siempre.
    final tipoBloqueado = _perfil?.estadoVerificacion == 'aprobado' &&
        _perfil?.estadoCuentaStripeDetalle == DetalleCuentaStripe.configurada;
    final tipoActual = _perfil?.tipoProfesional;

    final resultado = await showModalBottomSheet<InformacionProfesionalResultado>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditorInformacionProfesional(
        descripcionInicial: _perfil?.descripcion ?? '',
        telefonoInicial: _perfil?.telefono ?? '',
        tarifaInicial: (_perfil?.tarifaBase ?? 0) > 0 ? _perfil!.tarifaBase : null,
        tipoEtiqueta: tipoActual != null ? etiquetaTipoProfesional(t, tipoActual) : null,
        tipoBloqueado: tipoBloqueado,
      ),
    );
    if (resultado == null || !mounted) return;

    final plan = planGuardadoInfoProfesional(
      descripcionActual: _perfil?.descripcion ?? '',
      telefonoActual: _perfil?.telefono ?? '',
      tarifaActual: _perfil?.tarifaBase ?? 0,
      resultado: resultado,
    );
    if (!plan.hayCambios) return;

    var okDatos = true;
    var okTelefono = true;

    if (plan.guardarDatosProfesionales) {
      try {
        await _professionalService.actualizarPerfil(
          descripcion: plan.guardarDescripcion ? resultado.descripcion : null,
          tarifaBase: plan.guardarTarifa ? resultado.tarifa : null,
        );
      } catch (e) {
        debugPrint('[MiPerfilProfesionalScreen] Error al guardar descripción/tarifa: $e');
        okDatos = false;
      }
    }

    if (plan.guardarTelefono) {
      try {
        final usuario = await _userService.actualizarPerfil(telefono: resultado.telefono);
        ref.read(authProvider.notifier).actualizarUsuario(usuario);
      } catch (e) {
        debugPrint('[MiPerfilProfesionalScreen] Error al guardar el teléfono: $e');
        okTelefono = false;
      }
    }

    if (!mounted) return;

    final mensajeFallo = componerMensajeGuardadoInfoProfesional(
      intentoDatos: plan.guardarDatosProfesionales,
      okDatos: okDatos,
      intentoTelefono: plan.guardarTelefono,
      okTelefono: okTelefono,
      falloDatos: t.infoProfFalloDatos,
      falloTelefono: t.infoProfFalloTelefono,
      restoGuardado: t.infoProfRestoGuardado,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensajeFallo ?? t.miPerfilExito)),
    );
    _cargarPerfil();
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
    _intentarEnviarPerfilAlta();
  }

  /// Selector del tipo profesional — rediseño 2026-08-22 (widget propio
  /// SelectorTipoProfesional): tarjetas seleccionables con estado
  /// visible + botón Continuar, y declaración de responsabilidad
  /// obligatoria para "Particular". Devuelve el tipo elegido solo al
  /// confirmar; cancelar no guarda nada. Los valores enviados al
  /// backend (autonomo/empresa/persona_fisica) no cambian.
  Future<void> _elegirTipoProfesionalAlta() async {
    final elegido = await showDialog<TipoProfesional>(
      context: context,
      builder: (context) => SelectorTipoProfesional(seleccionInicial: _tipoProfesionalSeleccionado),
    );

    if (elegido == null || !mounted) return;
    setState(() => _tipoProfesionalSeleccionado = elegido);
    _intentarEnviarPerfilAlta();
  }

  /// Cierra el paso "Perfil" del wizard: en cuanto foto + categoría +
  /// tipo existen, persiste el tipo vía POST /me/verification (SIN
  /// documento de identidad — la verificación de identidad real la hace
  /// Stripe; el DNI manual queda solo para incidencias) y deja armada la
  /// aprobación automática del backend. Idempotente y silencioso: se
  /// llama tras cada pieza completada y solo actúa cuando toca.
  Future<void> _intentarEnviarPerfilAlta() async {
    if (_enviandoVerificacion) return;
    final perfil = _perfil;
    if (perfil == null) return;
    // Las incidencias (rechazado) se reenvían desde su propia tarjeta,
    // con documento — nunca desde este camino silencioso.
    if (perfil.estadoVerificacion == 'rechazado') return;

    final tipo = _tipoProfesionalSeleccionado;
    if (tipo == null || _fotoPerfilUrlActual == null || _categoriasActuales.isEmpty) return;
    // Ya persistido con el mismo tipo — nada que hacer.
    if (perfil.tipoProfesional == tipo) return;

    final categoriaIds = _todasCategorias
        .where((c) => _categoriasActuales.contains(c.nombre))
        .map((c) => c.id)
        .toList();
    if (categoriaIds.isEmpty) return;

    setState(() => _enviandoVerificacion = true);
    try {
      await _professionalService.enviarVerificacion(
        categoriaIds: categoriaIds,
        tipoProfesional: tipo,
      );
      if (!mounted) return;
      await _cargarPerfil();
    } catch (e) {
      debugPrint('[MiPerfilProfesionalScreen] Error al enviar el perfil del alta: $e');
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.miPerfilVerificacionErrorEnvio}: ${mensajeDeError(e, t: t)}')),
      );
    } finally {
      if (mounted) setState(() => _enviandoVerificacion = false);
    }
  }

  /// Puerta única al onboarding de Stripe mientras no está aprobado —
  /// siempre a través de la pantalla puente (nunca salto directo).
  void _abrirPuenteStripe() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PuenteStripeScreen()),
    );
  }

  /// Último toque del wizard: activa la disponibilidad con el endpoint
  /// de siempre (mismos gates del backend — nunca se auto-activa).
  Future<void> _activarmeAhora() async {
    final t = AppLocalizations.of(context);
    final estadoDisp = ref.read(disponibilidadProvider).valueOrNull;

    setState(() => _activandoDisponibilidad = true);
    try {
      await ref.read(disponibilidadProvider.notifier).actualizar(
            disponible: true,
            modo: estadoDisp?.modo ?? ModoDisponibilidad.horarioLaboral,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.altaActivadoExito)));
      await _cargarPerfil();
    } catch (e) {
      debugPrint('[MiPerfilProfesionalScreen] Error al activar disponibilidad desde el wizard: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.profesionalErrorDisponibilidad, t: t))),
      );
    } finally {
      if (mounted) setState(() => _activandoDisponibilidad = false);
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
      // Fuente única de verdad de navegación (revisión arquitectónica
      // 2026-08-16): no se navega a LoginScreen aquí — AuthGateScreen ya
      // reconstruye solo en cuanto authProvider.usuario pasa a null.
      // Navegar aquí además creaba una segunda instancia del shell
      // compitiendo con la de AuthGateScreen (causa raíz del crash "ref
      // after disposed").
      await ref.read(authProvider.notifier).logout();
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
      _intentarEnviarPerfilAlta();
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

  // El caso "pendiente" ya no distingue por si subió el documento de
  // identidad: con el nuevo flujo de alta el DNI no forma parte del
  // camino estándar (la identidad la verifica Stripe), así que "sin
  // enviar documento" dejó de ser un estado con significado — pendiente
  // es simplemente "alta en curso" (el wizard ya detalla qué falta).
  IconData get _estadoIcono {
    switch (_perfil?.estadoVerificacion) {
      case 'aprobado':
        return Icons.verified_outlined;
      case 'rechazado':
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_top_outlined;
    }
  }

  Color _estadoColor(ColorScheme colorScheme) {
    switch (_perfil?.estadoVerificacion) {
      case 'aprobado':
        return const Color(0xFF1EA672);
      case 'rechazado':
        return colorScheme.error;
      default:
        return const Color(0xFFB98900);
    }
  }

  String _estadoLabel(AppLocalizations t) {
    switch (_perfil?.estadoVerificacion) {
      case 'aprobado':
        return t.miPerfilEstadoAprobado;
      case 'rechazado':
        return t.miPerfilEstadoRechazado;
      default:
        return t.miPerfilEstadoPendiente;
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
                      // Wizard "Completa tu alta" — la guía única del
                      // alta (sustituye al antiguo aviso de perfil
                      // incompleto). Se oculta solo cuando el alta está
                      // terminada Y disponible (lo decide el propio
                      // widget), y también en 'rechazado': ahí manda la
                      // tarjeta de incidencia de más abajo.
                      if ((_perfil?.estadoVerificacion ?? 'pendiente') != 'rechazado')
                        EntradaAnimada(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: WizardAlta(
                              fotoOk: _fotoPerfilUrlActual != null,
                              categoriaOk: _categoriasActuales.isNotEmpty,
                              // Cuenta también la selección local (parte
                              // del fix del selector, 2026-08-22): el
                              // tipo elegido se persiste vía POST
                              // /me/verification solo cuando foto y
                              // categoría existen — sin esto, elegir el
                              // tipo primero no daba NINGÚN feedback y
                              // el subpaso parecía roto.
                              tipoOk: _tipoProfesionalSeleccionado != null || _perfil?.tipoProfesional != null,
                              aprobado: _perfil?.estadoVerificacion == 'aprobado',
                              detalle: _perfil?.estadoCuentaStripeDetalle ?? DetalleCuentaStripe.sinIniciar,
                              disponible: ref.watch(disponibilidadProvider).valueOrNull?.disponible ??
                                  _perfil?.disponible ??
                                  false,
                              activando: _activandoDisponibilidad,
                              onFoto: _elegirFoto,
                              onCategorias: _editarCategorias,
                              onTipo: _elegirTipoProfesionalAlta,
                              onStripe: _abrirPuenteStripe,
                              onActivarme: _activarmeAhora,
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
                      // Tarjeta de incidencia/revisión manual: SOLO en
                      // 'rechazado'. El camino estándar del alta ya no
                      // pide la foto del DNI (la identidad la verifica
                      // Stripe) — el endpoint, el almacenamiento y esta
                      // tarjeta se conservan para reenvíos tras un
                      // rechazo con revisión de un admin.
                      if ((_perfil?.estadoVerificacion ?? 'pendiente') == 'rechazado') ...[
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
                      // Reestructura Perfil/Pagos (2026-08-22): para el
                      // profesional aprobado y operativo la cuenta de
                      // cobro tiene un ÚNICO hogar post-alta, la pestaña
                      // Pagos (estado + "Editar cuenta de cobro" — BUG
                      // 003 sigue cubierto ALLÍ, no aquí). Esta tarjeta
                      // solo queda en Perfil para la incidencia
                      // ('rechazado', junto a la tarjeta de reenvío de
                      // documentación). El resto de estados con acción
                      // (alta incompleta, Stripe pendiente/verificando/
                      // caída tras aprobar) los cubre el wizard de
                      // arriba, que reaparece solo — regla crítica F.
                      if (_perfil?.estadoVerificacion == 'rechazado') ...[
                        const SizedBox(height: 16),
                        EntradaAnimada(
                          retraso: const Duration(milliseconds: 135),
                          child: _TarjetaCuentaCobro(
                            estado: _perfil?.estadoCuentaStripe ?? EstadoCuentaStripe.pendiente,
                            cargando: _iniciandoOnboardingStripe,
                            onConfigurar: _perfil?.estadoCuentaStripe == EstadoCuentaStripe.configurada
                                ? _configurarCuentaCobro
                                : _abrirPuenteStripe,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      EntradaAnimada(
                        retraso: const Duration(milliseconds: 150),
                        // Sección "Información profesional" compacta
                        // (ajuste 2026-08-22): cuatro filas de una
                        // línea — tipo (público), descripción resumida
                        // (pública), teléfono SIN número (uso interno)
                        // y precio. Lápiz único → editor.
                        child: _TarjetaInfo(
                          icono: Icons.notes_outlined,
                          titulo: t.infoProfTitulo,
                          onEditar: _editarInformacionProfesional,
                          child: InformacionProfesionalResumen(
                            tipoEtiqueta: _perfil?.tipoProfesional != null
                                ? etiquetaTipoProfesional(t, _perfil!.tipoProfesional!)
                                : null,
                            descripcion: _perfil?.descripcion ?? '',
                            tarifaBase: _perfil?.tarifaBase ?? 0,
                          ),
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
                      // Centro de ayuda (auditoría 2026-08-22): primera
                      // fila de la zona inferior, por encima de los
                      // legales y bien separada de Cerrar sesión /
                      // Eliminar cuenta. Mismo componente que el perfil
                      // del cliente.
                      EntradaAnimada(
                        retraso: const Duration(milliseconds: 280),
                        child: const FilaAyudaSoporte(),
                      ),
                      const SizedBox(height: 4),
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

enum _OpcionDisponibilidad { noDisponible, disponible }

/// Selector de disponibilidad — antes era su propia pestaña
/// (DisponibilidadProfesionalScreen), movida aquí dentro de "Mi perfil"
/// por decisión del roadmap económico (punto 2: Registro → Verificación
/// + Stripe en paralelo → Disponible, todo centrado en el perfil).
///
/// Revisión de producto 2026-08-16: antes había un tercer estado
/// ("horario laboral" vs "24h"), pero `modoDisponibilidad` nunca tuvo
/// ningún efecto real — ninguna query, notificación ni job lo leía, no
/// se mostraba al cliente en ningún sitio, y no hay ninguna franja
/// horaria real detrás de "horario laboral" (confirmado con grep en
/// todo el backend). Se colapsó a un único "Disponible" para no
/// preguntarle al profesional algo cuya respuesta no cambiaba nada. El
/// campo sigue en BD sin tocar (backend, migración) — si algún día se
/// decide dar valor real a "24h" (ej. insignia visible al cliente), se
/// reengancha ahí, no hace falta reconstruirlo desde cero.
class _SelectorDisponibilidad extends ConsumerWidget {
  const _SelectorDisponibilidad();

  Future<void> _elegir(BuildContext context, WidgetRef ref, DisponibilidadState actual, _OpcionDisponibilidad opcion) async {
    final t = AppLocalizations.of(context);
    final opcionActual = actual.disponible ? _OpcionDisponibilidad.disponible : _OpcionDisponibilidad.noDisponible;
    if (opcion == opcionActual) return;

    // Activarse exige el alta completa: perfil + verificación + Stripe
    // (los mismos gates que el backend re-comprueba en el PATCH — esto
    // es solo la cara amable; la protección real es el 403 del
    // servidor). "No disponible" nunca se bloquea.
    if (opcion != _OpcionDisponibilidad.noDisponible &&
        (!actual.perfilCompleto || !actual.puedeActivarse)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.disponibilidadCompletaAlta)));
      return;
    }

    try {
      // modo: se reenvía el que ya hubiera, sin preguntar — el campo
      // sigue en BD pero ya no se elige desde aquí (ver comentario de
      // la clase).
      await ref.read(disponibilidadProvider.notifier).actualizar(
            disponible: opcion != _OpcionDisponibilidad.noDisponible,
            modo: actual.modo,
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
        final opcionActual = estado.disponible ? _OpcionDisponibilidad.disponible : _OpcionDisponibilidad.noDisponible;
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
              icono: Icons.bolt,
              color: Colors.amber.shade700,
              titulo: t.disponibilidadOpcionDisponibleTitulo,
              ayuda: t.disponibilidadOpcionDisponibleAyuda,
              seleccionada: opcionActual == _OpcionDisponibilidad.disponible,
              deshabilitada: bloqueado,
              onTap: () => _elegir(context, ref, estado, _OpcionDisponibilidad.disponible),
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
          // Siempre responde al toque, incluso "bloqueada" (se sigue
          // viendo atenuada): _elegir explica por qué no se puede
          // activar todavía ("Completa tu alta…") en vez de un toque
          // muerto sin respuesta — el bloqueo real vive en el backend.
          onTap: onTap,
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
