import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Hogar SOS'**
  String get appTitle;

  /// No description provided for @navInicio.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navInicio;

  /// No description provided for @navBuscar.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get navBuscar;

  /// No description provided for @navMensajes.
  ///
  /// In es, this message translates to:
  /// **'Mensajes'**
  String get navMensajes;

  /// No description provided for @navPerfil.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navPerfil;

  /// No description provided for @navDisponibilidad.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get navDisponibilidad;

  /// No description provided for @navSolicitudesCercanas.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get navSolicitudesCercanas;

  /// No description provided for @navCentroPagos.
  ///
  /// In es, this message translates to:
  /// **'Pagos'**
  String get navCentroPagos;

  /// No description provided for @loginTagline.
  ///
  /// In es, this message translates to:
  /// **'Servicios a domicilio de confianza'**
  String get loginTagline;

  /// No description provided for @loginFieldNombre.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get loginFieldNombre;

  /// No description provided for @loginFieldEmail.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get loginFieldEmail;

  /// No description provided for @loginFieldPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get loginFieldPassword;

  /// No description provided for @loginRecordarSesion.
  ///
  /// In es, this message translates to:
  /// **'Mantener sesión iniciada'**
  String get loginRecordarSesion;

  /// No description provided for @loginRoleCliente.
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get loginRoleCliente;

  /// No description provided for @loginRoleProfesional.
  ///
  /// In es, this message translates to:
  /// **'Profesional'**
  String get loginRoleProfesional;

  /// No description provided for @loginBtnCrearCuenta.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get loginBtnCrearCuenta;

  /// No description provided for @loginBtnIniciarSesion.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginBtnIniciarSesion;

  /// No description provided for @loginLinkYaTienesCuenta.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Inicia sesión'**
  String get loginLinkYaTienesCuenta;

  /// No description provided for @loginLinkNoTienesCuenta.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate'**
  String get loginLinkNoTienesCuenta;

  /// No description provided for @loginOlvidasteContrasena.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get loginOlvidasteContrasena;

  /// No description provided for @loginCamposObligatorios.
  ///
  /// In es, this message translates to:
  /// **'Rellena todos los campos'**
  String get loginCamposObligatorios;

  /// No description provided for @loginRecuperarTitulo.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get loginRecuperarTitulo;

  /// No description provided for @loginRecuperarEnviar.
  ///
  /// In es, this message translates to:
  /// **'Enviar enlace'**
  String get loginRecuperarEnviar;

  /// No description provided for @loginRecuperarExito.
  ///
  /// In es, this message translates to:
  /// **'Si existe una cuenta con ese email, te hemos enviado un enlace para restablecer la contraseña'**
  String get loginRecuperarExito;

  /// No description provided for @loginRecuperarEmailRequerido.
  ///
  /// In es, this message translates to:
  /// **'Indica tu email para poder enviarte el enlace'**
  String get loginRecuperarEmailRequerido;

  /// No description provided for @loginModoEmail.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get loginModoEmail;

  /// No description provided for @loginModoTelefono.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get loginModoTelefono;

  /// No description provided for @loginFieldTelefono.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get loginFieldTelefono;

  /// No description provided for @loginTelefonoAyuda.
  ///
  /// In es, this message translates to:
  /// **'Incluye el prefijo de tu país, ej. +34612345678'**
  String get loginTelefonoAyuda;

  /// No description provided for @loginBtnEnviarCodigo.
  ///
  /// In es, this message translates to:
  /// **'Enviar código'**
  String get loginBtnEnviarCodigo;

  /// No description provided for @otpTitulo.
  ///
  /// In es, this message translates to:
  /// **'Verifica tu número'**
  String get otpTitulo;

  /// No description provided for @otpDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Te hemos enviado un código de 6 dígitos por SMS a {telefono}'**
  String otpDescripcion(String telefono);

  /// No description provided for @otpFieldCodigo.
  ///
  /// In es, this message translates to:
  /// **'Código de 6 dígitos'**
  String get otpFieldCodigo;

  /// No description provided for @otpBtnConfirmar.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get otpBtnConfirmar;

  /// No description provided for @otpReenviarCodigo.
  ///
  /// In es, this message translates to:
  /// **'Reenviar código'**
  String get otpReenviarCodigo;

  /// No description provided for @otpCodigoReenviado.
  ///
  /// In es, this message translates to:
  /// **'Código reenviado'**
  String get otpCodigoReenviado;

  /// No description provided for @otpCambiarNumero.
  ///
  /// In es, this message translates to:
  /// **'Cambiar de número'**
  String get otpCambiarNumero;

  /// No description provided for @errorConexion.
  ///
  /// In es, this message translates to:
  /// **'No se pudo conectar con el servidor. Comprueba tu conexión.'**
  String get errorConexion;

  /// No description provided for @errorServidorLento.
  ///
  /// In es, this message translates to:
  /// **'El servidor tardó demasiado en responder.'**
  String get errorServidorLento;

  /// No description provided for @errorInesperado.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error inesperado.'**
  String get errorInesperado;

  /// No description provided for @montoConSimbolo.
  ///
  /// In es, this message translates to:
  /// **'{monto} €'**
  String montoConSimbolo(String monto);

  /// No description provided for @authErrorEmailEnUso.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una cuenta con este email. Intenta iniciar sesión o usa \"¿Olvidaste tu contraseña?\" si no la recuerdas.'**
  String get authErrorEmailEnUso;

  /// No description provided for @authErrorEmailInvalido.
  ///
  /// In es, this message translates to:
  /// **'El email no tiene un formato válido.'**
  String get authErrorEmailInvalido;

  /// No description provided for @authErrorPasswordDebil.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es demasiado débil (mínimo 6 caracteres).'**
  String get authErrorPasswordDebil;

  /// No description provided for @authErrorCredencialesIncorrectas.
  ///
  /// In es, this message translates to:
  /// **'Email o contraseña incorrectos.'**
  String get authErrorCredencialesIncorrectas;

  /// No description provided for @authErrorDemasiadosIntentos.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Espera un momento antes de volver a intentarlo.'**
  String get authErrorDemasiadosIntentos;

  /// No description provided for @authErrorTelefonoInvalido.
  ///
  /// In es, this message translates to:
  /// **'El número de teléfono no es válido. Escríbelo con el prefijo del país (ej. +34).'**
  String get authErrorTelefonoInvalido;

  /// No description provided for @authErrorCodigoIncorrecto.
  ///
  /// In es, this message translates to:
  /// **'El código no es correcto. Revisa el SMS e inténtalo de nuevo.'**
  String get authErrorCodigoIncorrecto;

  /// No description provided for @authErrorCodigoCaducado.
  ///
  /// In es, this message translates to:
  /// **'El código ha caducado. Pide uno nuevo.'**
  String get authErrorCodigoCaducado;

  /// No description provided for @authErrorCuotaSms.
  ///
  /// In es, this message translates to:
  /// **'Se alcanzó el límite de códigos por SMS. Inténtalo más tarde.'**
  String get authErrorCuotaSms;

  /// No description provided for @apiErrDatosInvalidos.
  ///
  /// In es, this message translates to:
  /// **'Datos inválidos'**
  String get apiErrDatosInvalidos;

  /// No description provided for @apiErrSinPermiso.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para esta acción'**
  String get apiErrSinPermiso;

  /// No description provided for @apiErrTokenInvalido.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión ha caducado. Inicia sesión de nuevo.'**
  String get apiErrTokenInvalido;

  /// No description provided for @apiErrMotivoRechazoRequerido.
  ///
  /// In es, this message translates to:
  /// **'Un rechazo requiere indicar un motivo'**
  String get apiErrMotivoRechazoRequerido;

  /// No description provided for @apiErrProfesionalNoEncontrado.
  ///
  /// In es, this message translates to:
  /// **'Profesional no encontrado'**
  String get apiErrProfesionalNoEncontrado;

  /// No description provided for @apiErrVerificacionNoPendiente.
  ///
  /// In es, this message translates to:
  /// **'Este profesional no tiene una verificación pendiente'**
  String get apiErrVerificacionNoPendiente;

  /// No description provided for @apiErrDisputaNoEncontrada.
  ///
  /// In es, this message translates to:
  /// **'Reclamación no encontrada'**
  String get apiErrDisputaNoEncontrada;

  /// No description provided for @apiErrDisputaResuelta.
  ///
  /// In es, this message translates to:
  /// **'Esta reclamación ya fue resuelta'**
  String get apiErrDisputaResuelta;

  /// No description provided for @apiErrResolucionStripeFallida.
  ///
  /// In es, this message translates to:
  /// **'La resolución no pudo aplicarse en el pago. Inténtalo de nuevo o contacta con soporte.'**
  String get apiErrResolucionStripeFallida;

  /// No description provided for @apiErrAmpliacionDatosInvalidos.
  ///
  /// In es, this message translates to:
  /// **'Datos de ampliación inválidos'**
  String get apiErrAmpliacionDatosInvalidos;

  /// No description provided for @apiErrDatosContactoBloqueados.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, los datos de contacto solo se pueden compartir cuando el trabajo haya sido aceptado'**
  String get apiErrDatosContactoBloqueados;

  /// No description provided for @apiErrSolicitudNoEncontrada.
  ///
  /// In es, this message translates to:
  /// **'Solicitud no encontrada'**
  String get apiErrSolicitudNoEncontrada;

  /// No description provided for @apiErrNoEresProfesionalAsignado.
  ///
  /// In es, this message translates to:
  /// **'No eres el profesional asignado a esta solicitud'**
  String get apiErrNoEresProfesionalAsignado;

  /// No description provided for @apiErrEstadoInvalidoAmpliacion.
  ///
  /// In es, this message translates to:
  /// **'La solicitud no está en un estado válido para pedir una ampliación'**
  String get apiErrEstadoInvalidoAmpliacion;

  /// No description provided for @apiErrSinPresupuestoAceptado.
  ///
  /// In es, this message translates to:
  /// **'No hay un presupuesto aceptado para esta solicitud'**
  String get apiErrSinPresupuestoAceptado;

  /// No description provided for @apiErrHorasAdicionalesRequeridas.
  ///
  /// In es, this message translates to:
  /// **'Indica las horas adicionales'**
  String get apiErrHorasAdicionalesRequeridas;

  /// No description provided for @apiErrImporteAdicionalRequerido.
  ///
  /// In es, this message translates to:
  /// **'Indica el importe adicional'**
  String get apiErrImporteAdicionalRequerido;

  /// No description provided for @apiErrAmpliacionYaPendiente.
  ///
  /// In es, this message translates to:
  /// **'Ya hay una ampliación pendiente de respuesta'**
  String get apiErrAmpliacionYaPendiente;

  /// No description provided for @apiErrDecisionAmpliacionRequerida.
  ///
  /// In es, this message translates to:
  /// **'Indica si aceptas o rechazas la ampliación'**
  String get apiErrDecisionAmpliacionRequerida;

  /// No description provided for @apiErrSinAccesoSolicitud.
  ///
  /// In es, this message translates to:
  /// **'No tienes acceso a esta solicitud'**
  String get apiErrSinAccesoSolicitud;

  /// No description provided for @apiErrAmpliacionNoEncontrada.
  ///
  /// In es, this message translates to:
  /// **'Ampliación no encontrada'**
  String get apiErrAmpliacionNoEncontrada;

  /// No description provided for @apiErrAmpliacionNoPendiente.
  ///
  /// In es, this message translates to:
  /// **'Esta ampliación ya no está pendiente de respuesta'**
  String get apiErrAmpliacionNoPendiente;

  /// No description provided for @apiErrUsuarioYaExiste.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una cuenta con este email o teléfono'**
  String get apiErrUsuarioYaExiste;

  /// No description provided for @apiErrSinCuenta.
  ///
  /// In es, this message translates to:
  /// **'No existe una cuenta asociada. Regístrate primero.'**
  String get apiErrSinCuenta;

  /// No description provided for @apiErrCuentaDesactivada.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta ha sido desactivada'**
  String get apiErrCuentaDesactivada;

  /// No description provided for @apiErrReclamacionSoloTrabajoAceptado.
  ///
  /// In es, this message translates to:
  /// **'Solo se puede reportar un problema en un trabajo aceptado'**
  String get apiErrReclamacionSoloTrabajoAceptado;

  /// No description provided for @apiErrReclamacionYaAbierta.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una reclamación abierta para este trabajo'**
  String get apiErrReclamacionYaAbierta;

  /// No description provided for @apiErrSolicitudNoAceptada.
  ///
  /// In es, this message translates to:
  /// **'La solicitud debe estar aceptada por un profesional antes de pagar'**
  String get apiErrSolicitudNoAceptada;

  /// No description provided for @apiErrNadaPendienteAutorizar.
  ///
  /// In es, this message translates to:
  /// **'No hay nada pendiente de autorizar para esta solicitud'**
  String get apiErrNadaPendienteAutorizar;

  /// No description provided for @apiErrNoEresCliente.
  ///
  /// In es, this message translates to:
  /// **'No eres el cliente de esta solicitud'**
  String get apiErrNoEresCliente;

  /// No description provided for @apiErrNoAutorizadoPostular.
  ///
  /// In es, this message translates to:
  /// **'No estás autorizado para postularte a solicitudes'**
  String get apiErrNoAutorizadoPostular;

  /// No description provided for @apiErrSolicitudNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Esta solicitud ya no está disponible'**
  String get apiErrSolicitudNoDisponible;

  /// No description provided for @apiErrCandidaturaYaEnviada.
  ///
  /// In es, this message translates to:
  /// **'Ya te has postulado a esta solicitud'**
  String get apiErrCandidaturaYaEnviada;

  /// No description provided for @apiErrCandidaturaNoEncontrada.
  ///
  /// In es, this message translates to:
  /// **'Candidatura no encontrada'**
  String get apiErrCandidaturaNoEncontrada;

  /// No description provided for @apiErrPresupuestoDatosInvalidos.
  ///
  /// In es, this message translates to:
  /// **'Datos de presupuesto inválidos'**
  String get apiErrPresupuestoDatosInvalidos;

  /// No description provided for @apiErrEstadoInvalidoPresupuesto.
  ///
  /// In es, this message translates to:
  /// **'La solicitud no está en un estado válido para presupuestar'**
  String get apiErrEstadoInvalidoPresupuesto;

  /// No description provided for @apiErrPresupuestoYaPendiente.
  ///
  /// In es, this message translates to:
  /// **'Ya hay un presupuesto pendiente de respuesta para esta solicitud'**
  String get apiErrPresupuestoYaPendiente;

  /// No description provided for @apiErrDecisionPresupuestoRequerida.
  ///
  /// In es, this message translates to:
  /// **'Indica si aceptas o rechazas el presupuesto'**
  String get apiErrDecisionPresupuestoRequerida;

  /// No description provided for @apiErrPresupuestoNoEncontrado.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto no encontrado'**
  String get apiErrPresupuestoNoEncontrado;

  /// No description provided for @apiErrPresupuestoNoPendiente.
  ///
  /// In es, this message translates to:
  /// **'Este presupuesto ya no está pendiente de respuesta'**
  String get apiErrPresupuestoNoPendiente;

  /// No description provided for @apiErrPerfilProfesionalNoEncontrado.
  ///
  /// In es, this message translates to:
  /// **'Perfil de profesional no encontrado'**
  String get apiErrPerfilProfesionalNoEncontrado;

  /// No description provided for @apiErrProfesionalNoVerificado.
  ///
  /// In es, this message translates to:
  /// **'No puedes ponerte disponible hasta ser verificado'**
  String get apiErrProfesionalNoVerificado;

  /// No description provided for @apiErrCuentaStripeNoConfigurada.
  ///
  /// In es, this message translates to:
  /// **'No puedes ponerte disponible hasta configurar tu cuenta de cobro'**
  String get apiErrCuentaStripeNoConfigurada;

  /// No description provided for @apiErrCategoriasInvalidas.
  ///
  /// In es, this message translates to:
  /// **'Una o más categorías no son válidas'**
  String get apiErrCategoriasInvalidas;

  /// No description provided for @apiErrParametrosBusquedaInvalidos.
  ///
  /// In es, this message translates to:
  /// **'Parámetros de búsqueda inválidos'**
  String get apiErrParametrosBusquedaInvalidos;

  /// No description provided for @apiErrValorarSoloCompletado.
  ///
  /// In es, this message translates to:
  /// **'Solo se puede valorar un servicio ya completado'**
  String get apiErrValorarSoloCompletado;

  /// No description provided for @apiErrValoracionBloqueadaDisputa.
  ///
  /// In es, this message translates to:
  /// **'Existe una reclamación abierta — no se puede valorar hasta que se resuelva'**
  String get apiErrValoracionBloqueadaDisputa;

  /// No description provided for @apiErrSinProfesionalAsignado.
  ///
  /// In es, this message translates to:
  /// **'Esta solicitud no tiene profesional asignado'**
  String get apiErrSinProfesionalAsignado;

  /// No description provided for @apiErrNoParticipaste.
  ///
  /// In es, this message translates to:
  /// **'No participaste en esta solicitud, no puedes valorarla'**
  String get apiErrNoParticipaste;

  /// No description provided for @apiErrYaValoraste.
  ///
  /// In es, this message translates to:
  /// **'Ya has valorado esta solicitud'**
  String get apiErrYaValoraste;

  /// No description provided for @apiErrFechaRequerida.
  ///
  /// In es, this message translates to:
  /// **'Indica la fecha deseada'**
  String get apiErrFechaRequerida;

  /// No description provided for @apiErrCategoriaInvalida.
  ///
  /// In es, this message translates to:
  /// **'Categoría de servicio no válida'**
  String get apiErrCategoriaInvalida;

  /// No description provided for @apiErrCuentaNoVerificada.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta aún no ha sido verificada'**
  String get apiErrCuentaNoVerificada;

  /// No description provided for @apiErrSoloCreadorCancela.
  ///
  /// In es, this message translates to:
  /// **'Solo el cliente que creó esta solicitud puede cancelarla'**
  String get apiErrSoloCreadorCancela;

  /// No description provided for @apiErrNoSePuedeCancelar.
  ///
  /// In es, this message translates to:
  /// **'Esta solicitud ya no se puede cancelar — el profesional ya empezó o ya se resolvió'**
  String get apiErrNoSePuedeCancelar;

  /// No description provided for @apiErrTrabajoEnCursoUsaDisputa.
  ///
  /// In es, this message translates to:
  /// **'El profesional ya ha marcado este trabajo como en curso — para cancelarlo ahora, abre una reclamación'**
  String get apiErrTrabajoEnCursoUsaDisputa;

  /// No description provided for @apiErrSoloCreadorBorra.
  ///
  /// In es, this message translates to:
  /// **'Solo el cliente que creó esta solicitud puede borrarla'**
  String get apiErrSoloCreadorBorra;

  /// No description provided for @apiErrNoSePuedeBorrar.
  ///
  /// In es, this message translates to:
  /// **'Solo se pueden borrar solicitudes que nadie ha aceptado todavía'**
  String get apiErrNoSePuedeBorrar;

  /// No description provided for @apiErrNoSePuedeArchivar.
  ///
  /// In es, this message translates to:
  /// **'Solo se pueden archivar solicitudes completadas o canceladas'**
  String get apiErrNoSePuedeArchivar;

  /// No description provided for @apiErrMensajeRequerido.
  ///
  /// In es, this message translates to:
  /// **'Falta el texto del mensaje'**
  String get apiErrMensajeRequerido;

  /// No description provided for @apiErrEstadoInvalidoCompletar.
  ///
  /// In es, this message translates to:
  /// **'La solicitud no está en un estado válido para completarse'**
  String get apiErrEstadoInvalidoCompletar;

  /// No description provided for @apiErrPagoNoAutorizado.
  ///
  /// In es, this message translates to:
  /// **'El cliente aún no ha autorizado el pago de este servicio'**
  String get apiErrPagoNoAutorizado;

  /// No description provided for @apiErrHorasRequeridas.
  ///
  /// In es, this message translates to:
  /// **'Indica las horas reales trabajadas'**
  String get apiErrHorasRequeridas;

  /// No description provided for @apiErrCierreYaPendiente.
  ///
  /// In es, this message translates to:
  /// **'Ya hay un cierre pendiente de confirmación del cliente'**
  String get apiErrCierreYaPendiente;

  /// No description provided for @apiErrDecisionHorasRequerida.
  ///
  /// In es, this message translates to:
  /// **'Indica si aceptas o rechazas las horas declaradas'**
  String get apiErrDecisionHorasRequerida;

  /// No description provided for @apiErrCierreNoEncontrado.
  ///
  /// In es, this message translates to:
  /// **'Cierre no encontrado'**
  String get apiErrCierreNoEncontrado;

  /// No description provided for @apiErrCierreNoPendiente.
  ///
  /// In es, this message translates to:
  /// **'Este cierre ya no está pendiente de respuesta'**
  String get apiErrCierreNoPendiente;

  /// No description provided for @apiErrHorasDemasiadoBajas.
  ///
  /// In es, this message translates to:
  /// **'Las horas declaradas son demasiado bajas'**
  String get apiErrHorasDemasiadoBajas;

  /// No description provided for @apiErrConfirmacionReduccionRequerida.
  ///
  /// In es, this message translates to:
  /// **'Esta reducción es muy grande respecto a lo estimado — confírmala explícitamente'**
  String get apiErrConfirmacionReduccionRequerida;

  /// No description provided for @apiErrSinArchivo.
  ///
  /// In es, this message translates to:
  /// **'No se ha recibido ningún archivo'**
  String get apiErrSinArchivo;

  /// No description provided for @apiErrUsuarioNoEncontrado.
  ///
  /// In es, this message translates to:
  /// **'Usuario no encontrado'**
  String get apiErrUsuarioNoEncontrado;

  /// No description provided for @apiErrPagoAtascadoNoEncontrado.
  ///
  /// In es, this message translates to:
  /// **'No queda ninguna autorización pendiente de liberar en esta solicitud'**
  String get apiErrPagoAtascadoNoEncontrado;

  /// No description provided for @apiErrLiberacionEnCurso.
  ///
  /// In es, this message translates to:
  /// **'Ya hay una liberación en curso para esta solicitud. Espera unos segundos y vuelve a intentarlo.'**
  String get apiErrLiberacionEnCurso;

  /// No description provided for @apiErrPagoNoAutorizadoTodavia.
  ///
  /// In es, this message translates to:
  /// **'El cliente nunca llegó a confirmar el pago. Esto no se arregla reintentando: tiene que volver a autorizarlo en la app.'**
  String get apiErrPagoNoAutorizadoTodavia;

  /// No description provided for @apiErrProfesionalSinCuentaStripe.
  ///
  /// In es, this message translates to:
  /// **'El profesional no ha completado el onboarding de Stripe Connect'**
  String get apiErrProfesionalSinCuentaStripe;

  /// No description provided for @apiErrCuentaStripeNoOperativa.
  ///
  /// In es, this message translates to:
  /// **'Stripe todavía no habilita los pagos de este profesional (verificación pendiente)'**
  String get apiErrCuentaStripeNoOperativa;

  /// No description provided for @apiErrReintentoStripeFallido.
  ///
  /// In es, this message translates to:
  /// **'El reintento falló en Stripe. El pago sigue recuperable: vuelve a intentarlo.'**
  String get apiErrReintentoStripeFallido;

  /// No description provided for @apiErrTareaNoEncontrada.
  ///
  /// In es, this message translates to:
  /// **'Tarea no encontrada'**
  String get apiErrTareaNoEncontrada;

  /// No description provided for @apiErrTareaYaEnCurso.
  ///
  /// In es, this message translates to:
  /// **'Esta tarea ya se está ejecutando ahora mismo'**
  String get apiErrTareaYaEnCurso;

  /// No description provided for @apiErrTareaFallida.
  ///
  /// In es, this message translates to:
  /// **'La tarea falló. Revisa el detalle antes de reintentar.'**
  String get apiErrTareaFallida;

  /// No description provided for @apiErrAdminNoPuedeAutoBloquearse.
  ///
  /// In es, this message translates to:
  /// **'No puedes cambiar el estado de tu propia cuenta'**
  String get apiErrAdminNoPuedeAutoBloquearse;

  /// No description provided for @apiErrUltimoAdminActivo.
  ///
  /// In es, this message translates to:
  /// **'No puedes desactivar al único administrador activo'**
  String get apiErrUltimoAdminActivo;

  /// No description provided for @apiErrCuentaEliminadaNoReactivable.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta fue eliminada por el propio usuario y no se puede reactivar'**
  String get apiErrCuentaEliminadaNoReactivable;

  /// No description provided for @legalPrivSec1Titulo.
  ///
  /// In es, this message translates to:
  /// **'1. Quién trata tus datos'**
  String get legalPrivSec1Titulo;

  /// No description provided for @legalPrivSec1Texto.
  ///
  /// In es, this message translates to:
  /// **'Hogar SOS es una app que conecta a clientes con profesionales de servicios a domicilio. Somos responsables del tratamiento de los datos personales que recoge la aplicación, descritos en esta política.'**
  String get legalPrivSec1Texto;

  /// No description provided for @legalPrivSec2Titulo.
  ///
  /// In es, this message translates to:
  /// **'2. Qué datos recogemos'**
  String get legalPrivSec2Titulo;

  /// No description provided for @legalPrivSec2Texto.
  ///
  /// In es, this message translates to:
  /// **'• Datos de cuenta: nombre, email y teléfono al registrarte.\n• Ubicación: tu ubicación aproximada o precisa (con tu permiso) para mostrarte profesionales cercanos, o para que un profesional aparezca en las búsquedas de clientes cerca de él.\n• Fotos: las que adjuntes a una solicitud de servicio o a tu perfil.\n• Documentos de verificación (solo profesionales): documento de identidad, certificados y seguro de responsabilidad civil, usados exclusivamente para verificar tu identidad y aptitud antes de permitirte operar en la plataforma.\n• Datos de pago: gestionados directamente por Stripe, nuestro procesador de pagos — Hogar SOS nunca almacena el número completo de tu tarjeta.\n• Mensajes de chat entre cliente y profesional de una misma solicitud.'**
  String get legalPrivSec2Texto;

  /// No description provided for @legalPrivSec3Titulo.
  ///
  /// In es, this message translates to:
  /// **'3. Para qué usamos tus datos'**
  String get legalPrivSec3Titulo;

  /// No description provided for @legalPrivSec3Texto.
  ///
  /// In es, this message translates to:
  /// **'Para prestar el servicio (conectar clientes con profesionales, procesar pagos, gestionar solicitudes), para verificar la identidad de los profesionales, para enviarte notificaciones relacionadas con tus solicitudes, y para prevenir fraude y resolver disputas.'**
  String get legalPrivSec3Texto;

  /// No description provided for @legalPrivSec4Titulo.
  ///
  /// In es, this message translates to:
  /// **'4. Con quién compartimos tus datos'**
  String get legalPrivSec4Titulo;

  /// No description provided for @legalPrivSec4Texto.
  ///
  /// In es, this message translates to:
  /// **'Con el otro participante de una solicitud (el cliente ve el nombre del profesional asignado y viceversa). Con proveedores que nos ayudan a operar la app: Firebase/Google (autenticación, notificaciones, chat) y Stripe (pagos). No vendemos tus datos a terceros ni los usamos con fines publicitarios ajenos a la app.'**
  String get legalPrivSec4Texto;

  /// No description provided for @legalPrivSec5Titulo.
  ///
  /// In es, this message translates to:
  /// **'5. Cuánto tiempo conservamos tus datos'**
  String get legalPrivSec5Titulo;

  /// No description provided for @legalPrivSec5Texto.
  ///
  /// In es, this message translates to:
  /// **'Mientras tu cuenta esté activa. Si la eliminas, borramos o anonimizamos tus datos personales, salvo lo que debamos conservar por obligación legal (p. ej. registros de pagos).'**
  String get legalPrivSec5Texto;

  /// No description provided for @legalPrivSec6Titulo.
  ///
  /// In es, this message translates to:
  /// **'6. Tus derechos'**
  String get legalPrivSec6Titulo;

  /// No description provided for @legalPrivSec6Texto.
  ///
  /// In es, this message translates to:
  /// **'Puedes acceder, rectificar o eliminar tu cuenta y tus datos personales en cualquier momento desde Perfil → Eliminar cuenta, o visitando hogarsos.es/eliminar-cuenta si no tienes acceso a la app. También puedes retirar los permisos de ubicación, cámara o galería en cualquier momento desde los ajustes de tu teléfono.'**
  String get legalPrivSec6Texto;

  /// No description provided for @legalPrivSec7Titulo.
  ///
  /// In es, this message translates to:
  /// **'7. Cambios en esta política'**
  String get legalPrivSec7Titulo;

  /// No description provided for @legalPrivSec7Texto.
  ///
  /// In es, this message translates to:
  /// **'Si actualizamos esta política de forma relevante, te lo notificaremos dentro de la app antes de que entre en vigor.'**
  String get legalPrivSec7Texto;

  /// No description provided for @legalTerminosSec1Titulo.
  ///
  /// In es, this message translates to:
  /// **'1. Qué es Hogar SOS'**
  String get legalTerminosSec1Titulo;

  /// No description provided for @legalTerminosSec1Texto.
  ///
  /// In es, this message translates to:
  /// **'Hogar SOS es una plataforma que conecta a clientes que necesitan un servicio a domicilio (electricidad, fontanería, limpieza, etc.) con profesionales independientes que los ofrecen. Hogar SOS no presta los servicios directamente ni es empleador de los profesionales — actúa como intermediario entre ambas partes.'**
  String get legalTerminosSec1Texto;

  /// No description provided for @legalTerminosSec2Titulo.
  ///
  /// In es, this message translates to:
  /// **'2. Cuentas de usuario'**
  String get legalTerminosSec2Titulo;

  /// No description provided for @legalTerminosSec2Texto.
  ///
  /// In es, this message translates to:
  /// **'Debes dar información veraz al registrarte. Eres responsable de mantener segura tu cuenta. Los profesionales deben superar un proceso de verificación (documento de identidad y, si aplica, certificados/seguro) antes de poder aceptar solicitudes.'**
  String get legalTerminosSec2Texto;

  /// No description provided for @legalTerminosSec3Titulo.
  ///
  /// In es, this message translates to:
  /// **'3. Pagos y gastos de gestión'**
  String get legalTerminosSec3Titulo;

  /// No description provided for @legalTerminosSec3Texto.
  ///
  /// In es, this message translates to:
  /// **'El pago de un servicio se autoriza a través de Stripe al aceptar el trabajo, pero no se cobra hasta que el profesional marca el servicio como completado. Hogar SOS aplica unos gastos de gestión sobre el precio del servicio, que incluyen la verificación de identidad del profesional, el pago protegido hasta la finalización del trabajo y el soporte de Hogar SOS en caso de incidencias; el resto se transfiere al profesional. Los precios los fija el profesional o se acuerdan entre ambas partes por chat.'**
  String get legalTerminosSec3Texto;

  /// No description provided for @legalTerminosSec4Titulo.
  ///
  /// In es, this message translates to:
  /// **'4. Cancelaciones y reembolsos'**
  String get legalTerminosSec4Titulo;

  /// No description provided for @legalTerminosSec4Texto.
  ///
  /// In es, this message translates to:
  /// **'El cliente puede cancelar una solicitud sin coste mientras esté pendiente o recién aceptada y el trabajo todavía no haya empezado. Si ya se autorizó un pago, se reembolsa automáticamente al cancelar. Una vez el profesional marca el servicio como \"en curso\", ya no se puede cancelar desde la app — en ese caso, contacta con nosotros para resolverlo.'**
  String get legalTerminosSec4Texto;

  /// No description provided for @legalTerminosSec5Titulo.
  ///
  /// In es, this message translates to:
  /// **'5. Disputas'**
  String get legalTerminosSec5Titulo;

  /// No description provided for @legalTerminosSec5Texto.
  ///
  /// In es, this message translates to:
  /// **'Si algo no fue como se esperaba, cliente o profesional pueden abrir una disputa. Un administrador revisa el caso y decide si el pago se libera al profesional o se reembolsa al cliente.'**
  String get legalTerminosSec5Texto;

  /// No description provided for @legalTerminosSec6Titulo.
  ///
  /// In es, this message translates to:
  /// **'6. Responsabilidad'**
  String get legalTerminosSec6Titulo;

  /// No description provided for @legalTerminosSec6Texto.
  ///
  /// In es, this message translates to:
  /// **'Hogar SOS facilita el contacto y el pago entre cliente y profesional, pero no supervisa ni garantiza la calidad del trabajo realizado — la relación de servicio es directamente entre ambas partes. Recomendamos revisar las valoraciones de un profesional antes de contratarlo.'**
  String get legalTerminosSec6Texto;

  /// No description provided for @legalTerminosSec7Titulo.
  ///
  /// In es, this message translates to:
  /// **'7. Conducta de los profesionales'**
  String get legalTerminosSec7Titulo;

  /// No description provided for @legalTerminosSec7Texto.
  ///
  /// In es, this message translates to:
  /// **'Los profesionales verificados deben prestar el servicio con la diligencia y competencia propias de su oficio. Hogar SOS puede suspender o revocar una cuenta que reciba valoraciones reiteradamente negativas, incumpla estos términos, o cuya verificación resulte fraudulenta.'**
  String get legalTerminosSec7Texto;

  /// No description provided for @legalTerminosSec8Titulo.
  ///
  /// In es, this message translates to:
  /// **'8. Cambios en estos términos'**
  String get legalTerminosSec8Titulo;

  /// No description provided for @legalTerminosSec8Texto.
  ///
  /// In es, this message translates to:
  /// **'Podemos actualizar estos términos; los cambios relevantes se notificarán dentro de la app antes de entrar en vigor. Seguir usando Hogar SOS después de un cambio implica aceptarlo.'**
  String get legalTerminosSec8Texto;

  /// No description provided for @legalTerminosSec9Titulo.
  ///
  /// In es, this message translates to:
  /// **'9. Ley aplicable'**
  String get legalTerminosSec9Titulo;

  /// No description provided for @legalTerminosSec9Texto.
  ///
  /// In es, this message translates to:
  /// **'Estos términos se rigen por la legislación española.'**
  String get legalTerminosSec9Texto;

  /// No description provided for @homeSaludo.
  ///
  /// In es, this message translates to:
  /// **'Hola, {nombre} 👋'**
  String homeSaludo(String nombre);

  /// No description provided for @homeSaludoGenerico.
  ///
  /// In es, this message translates to:
  /// **'Hola 👋'**
  String get homeSaludoGenerico;

  /// No description provided for @homeSaludoManana.
  ///
  /// In es, this message translates to:
  /// **'Buenos días, {nombre} ☀️'**
  String homeSaludoManana(String nombre);

  /// No description provided for @homeSaludoTarde.
  ///
  /// In es, this message translates to:
  /// **'Buenas tardes, {nombre} 👋'**
  String homeSaludoTarde(String nombre);

  /// No description provided for @homeSaludoNoche.
  ///
  /// In es, this message translates to:
  /// **'Buenas noches, {nombre} 🌙'**
  String homeSaludoNoche(String nombre);

  /// No description provided for @homeAccesoBuscar.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get homeAccesoBuscar;

  /// No description provided for @homeAccesoMisSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Mis solicitudes'**
  String get homeAccesoMisSolicitudes;

  /// No description provided for @homeAccesoFavoritos.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get homeAccesoFavoritos;

  /// No description provided for @homeResumenActivas.
  ///
  /// In es, this message translates to:
  /// **'Tienes {cantidad} {cantidad, plural, one{solicitud activa} other{solicitudes activas}}'**
  String homeResumenActivas(int cantidad);

  /// No description provided for @homeMisSolicitudesSinActivas.
  ///
  /// In es, this message translates to:
  /// **'Ver historial y solicitudes en curso'**
  String get homeMisSolicitudesSinActivas;

  /// No description provided for @homeSubtitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Qué necesitas arreglar hoy?'**
  String get homeSubtitulo;

  /// No description provided for @homeBuscarPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Busca un profesional o servicio...'**
  String get homeBuscarPlaceholder;

  /// No description provided for @homeCategoriasTitulo.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get homeCategoriasTitulo;

  /// No description provided for @homeCategoriasError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las categorías'**
  String get homeCategoriasError;

  /// No description provided for @homeSolicitarProfesional.
  ///
  /// In es, this message translates to:
  /// **'📢 Solicitar un profesional'**
  String get homeSolicitarProfesional;

  /// No description provided for @homeSolicitarProfesionalAyuda.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos qué necesitas y te ponemos en contacto'**
  String get homeSolicitarProfesionalAyuda;

  /// No description provided for @homeDescribeProblema.
  ///
  /// In es, this message translates to:
  /// **'Describe el problema'**
  String get homeDescribeProblema;

  /// No description provided for @homeErrorDescribe.
  ///
  /// In es, this message translates to:
  /// **'Describe brevemente el problema'**
  String get homeErrorDescribe;

  /// No description provided for @homeErrorUbicacion.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos tu ubicación para buscar profesionales cerca'**
  String get homeErrorUbicacion;

  /// No description provided for @homeErrorCrearSolicitud.
  ///
  /// In es, this message translates to:
  /// **'No se pudo crear la solicitud. Inténtalo de nuevo.'**
  String get homeErrorCrearSolicitud;

  /// No description provided for @homeBtnBuscarProfesionales.
  ///
  /// In es, this message translates to:
  /// **'Buscar profesionales'**
  String get homeBtnBuscarProfesionales;

  /// No description provided for @homeSolicitudCreada.
  ///
  /// In es, this message translates to:
  /// **'Solicitud creada (#{id})'**
  String homeSolicitudCreada(String id);

  /// No description provided for @homeBusquedaProximamente.
  ///
  /// In es, this message translates to:
  /// **'Búsqueda con filtros: disponible en la próxima fase'**
  String get homeBusquedaProximamente;

  /// No description provided for @perfilCerrarSesion.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get perfilCerrarSesion;

  /// No description provided for @perfilRolCliente.
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get perfilRolCliente;

  /// No description provided for @perfilRolProfesional.
  ///
  /// In es, this message translates to:
  /// **'Profesional'**
  String get perfilRolProfesional;

  /// No description provided for @perfilRolAdmin.
  ///
  /// In es, this message translates to:
  /// **'Administrador'**
  String get perfilRolAdmin;

  /// No description provided for @perfilMiembroDesde.
  ///
  /// In es, this message translates to:
  /// **'Miembro de Hogar SOS'**
  String get perfilMiembroDesde;

  /// No description provided for @perfilConfirmarSalir.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres cerrar sesión?'**
  String get perfilConfirmarSalir;

  /// No description provided for @perfilCancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get perfilCancelar;

  /// No description provided for @perfilEliminarCuenta.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get perfilEliminarCuenta;

  /// No description provided for @perfilEliminarCuentaConfirmarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar tu cuenta?'**
  String get perfilEliminarCuentaConfirmarTitulo;

  /// No description provided for @perfilEliminarCuentaConfirmarTexto.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer. Perderás el acceso de inmediato y se eliminarán tu nombre, email, teléfono, foto y, si eres profesional, tus documentos de verificación.'**
  String get perfilEliminarCuentaConfirmarTexto;

  /// No description provided for @perfilEliminarCuentaBotonConfirmar.
  ///
  /// In es, this message translates to:
  /// **'Sí, eliminar mi cuenta'**
  String get perfilEliminarCuentaBotonConfirmar;

  /// No description provided for @perfilEliminarCuentaError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar tu cuenta. Inténtalo de nuevo.'**
  String get perfilEliminarCuentaError;

  /// No description provided for @perfilFavoritos.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get perfilFavoritos;

  /// No description provided for @perfilMisSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Mis solicitudes'**
  String get perfilMisSolicitudes;

  /// No description provided for @perfilConfiguracion.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get perfilConfiguracion;

  /// No description provided for @perfilPrivacidad.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get perfilPrivacidad;

  /// No description provided for @perfilTerminos.
  ///
  /// In es, this message translates to:
  /// **'Términos de servicio'**
  String get perfilTerminos;

  /// No description provided for @perfilEmailSinVerificarTitulo.
  ///
  /// In es, this message translates to:
  /// **'Verifica tu email'**
  String get perfilEmailSinVerificarTitulo;

  /// No description provided for @perfilEmailSinVerificarDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Te hemos enviado un enlace de confirmación. Revisa tu bandeja de entrada (y la carpeta de spam).'**
  String get perfilEmailSinVerificarDescripcion;

  /// No description provided for @perfilEmailSinVerificarReenviar.
  ///
  /// In es, this message translates to:
  /// **'Reenviar email'**
  String get perfilEmailSinVerificarReenviar;

  /// No description provided for @perfilEmailSinVerificarYaConfirme.
  ///
  /// In es, this message translates to:
  /// **'Ya lo confirmé'**
  String get perfilEmailSinVerificarYaConfirme;

  /// No description provided for @perfilEmailVerificacionReenviada.
  ///
  /// In es, this message translates to:
  /// **'Email de verificación reenviado'**
  String get perfilEmailVerificacionReenviada;

  /// No description provided for @perfilEmailAunNoVerificado.
  ///
  /// In es, this message translates to:
  /// **'Todavía no lo detectamos. Si acabas de confirmarlo, espera unos segundos e inténtalo de nuevo.'**
  String get perfilEmailAunNoVerificado;

  /// No description provided for @perfilEmailVerificadoExito.
  ///
  /// In es, this message translates to:
  /// **'¡Email verificado!'**
  String get perfilEmailVerificadoExito;

  /// No description provided for @legalPrivacidadTitulo.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get legalPrivacidadTitulo;

  /// No description provided for @legalTerminosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Términos de servicio'**
  String get legalTerminosTitulo;

  /// No description provided for @legalAceptacionPrefijo.
  ///
  /// In es, this message translates to:
  /// **'Al crear una cuenta, aceptas los '**
  String get legalAceptacionPrefijo;

  /// No description provided for @legalAceptacionY.
  ///
  /// In es, this message translates to:
  /// **' y la '**
  String get legalAceptacionY;

  /// No description provided for @pagoAceptacionTerminos.
  ///
  /// In es, this message translates to:
  /// **'Al continuar, aceptas los Términos de servicio y la política de cancelación'**
  String get pagoAceptacionTerminos;

  /// No description provided for @proximamenteTitulo.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get proximamenteTitulo;

  /// No description provided for @buscarProximamenteDescripcion.
  ///
  /// In es, this message translates to:
  /// **'La búsqueda avanzada con filtros por precio, distancia y valoración llega en la próxima fase.'**
  String get buscarProximamenteDescripcion;

  /// No description provided for @mensajesProximamenteDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Aquí verás todas tus conversaciones con clientes y profesionales.'**
  String get mensajesProximamenteDescripcion;

  /// No description provided for @mensajesVacioTitulo.
  ///
  /// In es, this message translates to:
  /// **'Sin conversaciones todavía'**
  String get mensajesVacioTitulo;

  /// No description provided for @buscarHint.
  ///
  /// In es, this message translates to:
  /// **'Busca por nombre...'**
  String get buscarHint;

  /// No description provided for @buscarFiltros.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get buscarFiltros;

  /// No description provided for @buscarTodasCategorias.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get buscarTodasCategorias;

  /// No description provided for @buscarSinResultadosTitulo.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron profesionales'**
  String get buscarSinResultadosTitulo;

  /// No description provided for @buscarSinResultadosDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Prueba a cambiar los filtros o la búsqueda'**
  String get buscarSinResultadosDescripcion;

  /// No description provided for @buscarErrorTitulo.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la búsqueda'**
  String get buscarErrorTitulo;

  /// No description provided for @buscarDesde.
  ///
  /// In es, this message translates to:
  /// **'Desde {precio} €'**
  String buscarDesde(String precio);

  /// No description provided for @buscarTrabajos.
  ///
  /// In es, this message translates to:
  /// **'{n} {n, plural, one{trabajo} other{trabajos}}'**
  String buscarTrabajos(int n);

  /// No description provided for @buscarDisponibleAhora.
  ///
  /// In es, this message translates to:
  /// **'Disponible ahora'**
  String get buscarDisponibleAhora;

  /// No description provided for @buscarNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'No disponible'**
  String get buscarNoDisponible;

  /// No description provided for @buscarUrgente.
  ///
  /// In es, this message translates to:
  /// **'Urgente'**
  String get buscarUrgente;

  /// No description provided for @buscarUrgenteTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Qué necesitas con urgencia?'**
  String get buscarUrgenteTitulo;

  /// No description provided for @filtroValoracionMinima.
  ///
  /// In es, this message translates to:
  /// **'Valoración mínima'**
  String get filtroValoracionMinima;

  /// No description provided for @filtroPrecioMaximo.
  ///
  /// In es, this message translates to:
  /// **'Precio máximo'**
  String get filtroPrecioMaximo;

  /// No description provided for @filtroDistanciaMaxima.
  ///
  /// In es, this message translates to:
  /// **'Distancia máxima'**
  String get filtroDistanciaMaxima;

  /// No description provided for @filtroLimpiar.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get filtroLimpiar;

  /// No description provided for @filtroAplicar.
  ///
  /// In es, this message translates to:
  /// **'Aplicar filtros'**
  String get filtroAplicar;

  /// No description provided for @filtroCualquiera.
  ///
  /// In es, this message translates to:
  /// **'Cualquiera'**
  String get filtroCualquiera;

  /// No description provided for @filtroSoloDisponibles.
  ///
  /// In es, this message translates to:
  /// **'Disponible ahora'**
  String get filtroSoloDisponibles;

  /// No description provided for @perfilProOpinionesTitulo.
  ///
  /// In es, this message translates to:
  /// **'Opiniones'**
  String get perfilProOpinionesTitulo;

  /// No description provided for @opinionesTotal.
  ///
  /// In es, this message translates to:
  /// **'{n} {n, plural, one{valoración} other{valoraciones}}'**
  String opinionesTotal(int n);

  /// No description provided for @misValoracionesTitulo.
  ///
  /// In es, this message translates to:
  /// **'Mis valoraciones'**
  String get misValoracionesTitulo;

  /// No description provided for @misValoracionesError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar tus valoraciones'**
  String get misValoracionesError;

  /// No description provided for @perfilProSinOpiniones.
  ///
  /// In es, this message translates to:
  /// **'Aún no tiene opiniones'**
  String get perfilProSinOpiniones;

  /// No description provided for @perfilProGaleriaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Galería de trabajos'**
  String get perfilProGaleriaTitulo;

  /// No description provided for @perfilProSinGaleria.
  ///
  /// In es, this message translates to:
  /// **'Este profesional aún no ha subido fotos de sus trabajos'**
  String get perfilProSinGaleria;

  /// No description provided for @perfilProServiciosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Servicios que ofrece'**
  String get perfilProServiciosTitulo;

  /// No description provided for @perfilProSolicitarBtn.
  ///
  /// In es, this message translates to:
  /// **'Solicitar este servicio'**
  String get perfilProSolicitarBtn;

  /// No description provided for @perfilProCargandoError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el perfil'**
  String get perfilProCargandoError;

  /// No description provided for @perfilProSolicitarInfo.
  ///
  /// In es, this message translates to:
  /// **'De momento, las solicitudes se envían a los profesionales disponibles cerca de ti desde Inicio, no a uno concreto todavía'**
  String get perfilProSolicitarInfo;

  /// No description provided for @categoriaElectricista.
  ///
  /// In es, this message translates to:
  /// **'Electricista'**
  String get categoriaElectricista;

  /// No description provided for @categoriaFontanero.
  ///
  /// In es, this message translates to:
  /// **'Fontanero'**
  String get categoriaFontanero;

  /// No description provided for @categoriaPintor.
  ///
  /// In es, this message translates to:
  /// **'Pintor'**
  String get categoriaPintor;

  /// No description provided for @categoriaManitas.
  ///
  /// In es, this message translates to:
  /// **'Manitas'**
  String get categoriaManitas;

  /// No description provided for @categoriaLimpieza.
  ///
  /// In es, this message translates to:
  /// **'Limpieza'**
  String get categoriaLimpieza;

  /// No description provided for @categoriaJardineria.
  ///
  /// In es, this message translates to:
  /// **'Jardinería'**
  String get categoriaJardineria;

  /// No description provided for @categoriaCerrajeria.
  ///
  /// In es, this message translates to:
  /// **'Cerrajería'**
  String get categoriaCerrajeria;

  /// No description provided for @categoriaReformas.
  ///
  /// In es, this message translates to:
  /// **'Reformas'**
  String get categoriaReformas;

  /// No description provided for @categoriaAireAcondicionado.
  ///
  /// In es, this message translates to:
  /// **'Aire acondicionado y climatización'**
  String get categoriaAireAcondicionado;

  /// No description provided for @categoriaCarpinteria.
  ///
  /// In es, this message translates to:
  /// **'Carpintería'**
  String get categoriaCarpinteria;

  /// No description provided for @categoriaAlbanileria.
  ///
  /// In es, this message translates to:
  /// **'Albañilería'**
  String get categoriaAlbanileria;

  /// No description provided for @categoriaTejados.
  ///
  /// In es, this message translates to:
  /// **'Tejados y cubiertas'**
  String get categoriaTejados;

  /// No description provided for @categoriaInstalacionCristales.
  ///
  /// In es, this message translates to:
  /// **'Instalación de cristales'**
  String get categoriaInstalacionCristales;

  /// No description provided for @categoriaCarpinteriaMetalica.
  ///
  /// In es, this message translates to:
  /// **'Carpintería metálica / Aluminio y PVC'**
  String get categoriaCarpinteriaMetalica;

  /// No description provided for @categoriaAntenas.
  ///
  /// In es, this message translates to:
  /// **'Antenas y telecomunicaciones'**
  String get categoriaAntenas;

  /// No description provided for @categoriaSeguridad.
  ///
  /// In es, this message translates to:
  /// **'Sistemas de seguridad'**
  String get categoriaSeguridad;

  /// No description provided for @categoriaMudanzas.
  ///
  /// In es, this message translates to:
  /// **'Mudanzas'**
  String get categoriaMudanzas;

  /// No description provided for @categoriaLimpiezaCristales.
  ///
  /// In es, this message translates to:
  /// **'Limpieza de cristales'**
  String get categoriaLimpiezaCristales;

  /// No description provided for @categoriaPiscinas.
  ///
  /// In es, this message translates to:
  /// **'Piscinas'**
  String get categoriaPiscinas;

  /// No description provided for @categoriaControlPlagas.
  ///
  /// In es, this message translates to:
  /// **'Control de plagas'**
  String get categoriaControlPlagas;

  /// No description provided for @categoriaPetSitter.
  ///
  /// In es, this message translates to:
  /// **'Pet sitter'**
  String get categoriaPetSitter;

  /// No description provided for @categoriaTecnicoTelefonia.
  ///
  /// In es, this message translates to:
  /// **'Técnico de telefonía'**
  String get categoriaTecnicoTelefonia;

  /// No description provided for @categoriaMasajes.
  ///
  /// In es, this message translates to:
  /// **'Masajes a domicilio'**
  String get categoriaMasajes;

  /// No description provided for @categoriaManicuraPedicura.
  ///
  /// In es, this message translates to:
  /// **'Manicura y pedicura'**
  String get categoriaManicuraPedicura;

  /// No description provided for @wizardEjemploGenerico.
  ///
  /// In es, this message translates to:
  /// **'Ej: se ha roto una tubería bajo el fregadero y hay una fuga...'**
  String get wizardEjemploGenerico;

  /// No description provided for @wizardEjemploElectricista.
  ///
  /// In es, this message translates to:
  /// **'Ej: ha saltado el diferencial y no puedo volver a subirlo...'**
  String get wizardEjemploElectricista;

  /// No description provided for @wizardEjemploFontanero.
  ///
  /// In es, this message translates to:
  /// **'Ej: tengo una fuga debajo del fregadero...'**
  String get wizardEjemploFontanero;

  /// No description provided for @wizardEjemploPintor.
  ///
  /// In es, this message translates to:
  /// **'Ej: quiero pintar el salón, unos 20 m²...'**
  String get wizardEjemploPintor;

  /// No description provided for @wizardEjemploManitas.
  ///
  /// In es, this message translates to:
  /// **'Ej: necesito montar unas estanterías...'**
  String get wizardEjemploManitas;

  /// No description provided for @wizardEjemploLimpieza.
  ///
  /// In es, this message translates to:
  /// **'Ej: necesito una limpieza completa de un piso...'**
  String get wizardEjemploLimpieza;

  /// No description provided for @wizardEjemploJardineria.
  ///
  /// In es, this message translates to:
  /// **'Ej: necesito podar el seto y cortar el césped...'**
  String get wizardEjemploJardineria;

  /// No description provided for @wizardEjemploCerrajeria.
  ///
  /// In es, this message translates to:
  /// **'Ej: he perdido las llaves y no puedo entrar en casa...'**
  String get wizardEjemploCerrajeria;

  /// No description provided for @wizardEjemploReformas.
  ///
  /// In es, this message translates to:
  /// **'Ej: quiero reformar el baño completo...'**
  String get wizardEjemploReformas;

  /// No description provided for @wizardEjemploAireAcondicionado.
  ///
  /// In es, this message translates to:
  /// **'Ej: el aire acondicionado no enfría...'**
  String get wizardEjemploAireAcondicionado;

  /// No description provided for @wizardEjemploCarpinteria.
  ///
  /// In es, this message translates to:
  /// **'Ej: necesito una puerta de armario a medida...'**
  String get wizardEjemploCarpinteria;

  /// No description provided for @wizardEjemploAlbanileria.
  ///
  /// In es, this message translates to:
  /// **'Ej: tengo una grieta en la pared del salón...'**
  String get wizardEjemploAlbanileria;

  /// No description provided for @wizardEjemploTejados.
  ///
  /// In es, this message translates to:
  /// **'Ej: tengo una gotera en el tejado...'**
  String get wizardEjemploTejados;

  /// No description provided for @wizardEjemploInstalacionCristales.
  ///
  /// In es, this message translates to:
  /// **'Ej: se ha roto el cristal de una ventana...'**
  String get wizardEjemploInstalacionCristales;

  /// No description provided for @wizardEjemploCarpinteriaMetalica.
  ///
  /// In es, this message translates to:
  /// **'Ej: necesito reparar una persiana metálica...'**
  String get wizardEjemploCarpinteriaMetalica;

  /// No description provided for @wizardEjemploAntenas.
  ///
  /// In es, this message translates to:
  /// **'Ej: no tengo señal de antena en el televisor...'**
  String get wizardEjemploAntenas;

  /// No description provided for @wizardEjemploSeguridad.
  ///
  /// In es, this message translates to:
  /// **'Ej: quiero instalar una alarma en casa...'**
  String get wizardEjemploSeguridad;

  /// No description provided for @wizardEjemploMudanzas.
  ///
  /// In es, this message translates to:
  /// **'Ej: necesito ayuda para mudarme a un piso de 2 habitaciones...'**
  String get wizardEjemploMudanzas;

  /// No description provided for @wizardEjemploLimpiezaCristales.
  ///
  /// In es, this message translates to:
  /// **'Ej: necesito limpiar los cristales de un tercer piso...'**
  String get wizardEjemploLimpiezaCristales;

  /// No description provided for @wizardEjemploPiscinas.
  ///
  /// In es, this message translates to:
  /// **'Ej: mi piscina tiene el agua verde...'**
  String get wizardEjemploPiscinas;

  /// No description provided for @wizardEjemploControlPlagas.
  ///
  /// In es, this message translates to:
  /// **'Ej: tengo cucarachas en la cocina...'**
  String get wizardEjemploControlPlagas;

  /// No description provided for @wizardEjemploPetSitter.
  ///
  /// In es, this message translates to:
  /// **'Ej: necesito que alguien cuide de mi perro este fin de semana...'**
  String get wizardEjemploPetSitter;

  /// No description provided for @wizardEjemploTecnicoTelefonia.
  ///
  /// In es, this message translates to:
  /// **'Ej: se me ha roto la pantalla del móvil...'**
  String get wizardEjemploTecnicoTelefonia;

  /// No description provided for @wizardEjemploMasajes.
  ///
  /// In es, this message translates to:
  /// **'Ej: quiero un masaje relajante de una hora en casa...'**
  String get wizardEjemploMasajes;

  /// No description provided for @wizardEjemploManicuraPedicura.
  ///
  /// In es, this message translates to:
  /// **'Ej: quiero una manicura y pedicura completa a domicilio...'**
  String get wizardEjemploManicuraPedicura;

  /// No description provided for @profesionalTituloSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes cerca de ti'**
  String get profesionalTituloSolicitudes;

  /// No description provided for @profesionalDisponibleAhoraAviso.
  ///
  /// In es, this message translates to:
  /// **'Estás disponible: te pueden llegar solicitudes nuevas'**
  String get profesionalDisponibleAhoraAviso;

  /// No description provided for @profesionalChipDisponible.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get profesionalChipDisponible;

  /// No description provided for @profesionalChipNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'No disponible'**
  String get profesionalChipNoDisponible;

  /// No description provided for @profesionalEstadoLinea.
  ///
  /// In es, this message translates to:
  /// **'Tu estado · {estado}'**
  String profesionalEstadoLinea(String estado);

  /// No description provided for @salirPulsaOtraVez.
  ///
  /// In es, this message translates to:
  /// **'Pulsa atrás otra vez para salir'**
  String get salirPulsaOtraVez;

  /// No description provided for @profesionalSinSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes cerca ahora mismo'**
  String get profesionalSinSolicitudes;

  /// No description provided for @profesionalErrorCargar.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las solicitudes'**
  String get profesionalErrorCargar;

  /// No description provided for @profesionalIgnorar.
  ///
  /// In es, this message translates to:
  /// **'Ignorar'**
  String get profesionalIgnorar;

  /// No description provided for @profesionalErrorIgnorar.
  ///
  /// In es, this message translates to:
  /// **'No se pudo ignorar la solicitud'**
  String get profesionalErrorIgnorar;

  /// No description provided for @profesionalAceptar.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get profesionalAceptar;

  /// No description provided for @profesionalSolicitudAceptada.
  ///
  /// In es, this message translates to:
  /// **'Solicitud aceptada. El cliente autorizará el pago.'**
  String get profesionalSolicitudAceptada;

  /// No description provided for @profesionalYaNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'No se pudo aceptar — puede que ya no esté disponible'**
  String get profesionalYaNoDisponible;

  /// No description provided for @profesionalPostularme.
  ///
  /// In es, this message translates to:
  /// **'Enviar candidatura'**
  String get profesionalPostularme;

  /// No description provided for @profesionalYaPostulado.
  ///
  /// In es, this message translates to:
  /// **'Candidatura enviada'**
  String get profesionalYaPostulado;

  /// No description provided for @profesionalPostulacionEnviada.
  ///
  /// In es, this message translates to:
  /// **'Candidatura enviada — el cliente elegirá entre los profesionales interesados'**
  String get profesionalPostulacionEnviada;

  /// No description provided for @profesionalPostulacionMensajeObligatorio.
  ///
  /// In es, this message translates to:
  /// **'Escribe cuándo puedes hacer el trabajo antes de enviar tu candidatura'**
  String get profesionalPostulacionMensajeObligatorio;

  /// No description provided for @profesionalDisponibilidadTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo puedes hacer este trabajo?'**
  String get profesionalDisponibilidadTitulo;

  /// No description provided for @profesionalDisponibilidadSubtitulo.
  ///
  /// In es, this message translates to:
  /// **'El cliente lo verá en tu candidatura junto a tu foto y valoración'**
  String get profesionalDisponibilidadSubtitulo;

  /// No description provided for @profesionalDisponibilidadHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: puedo ir mañana por la tarde...'**
  String get profesionalDisponibilidadHint;

  /// No description provided for @profesionalDisponibilidadSugerencia1.
  ///
  /// In es, this message translates to:
  /// **'Puedo ir mañana por la tarde'**
  String get profesionalDisponibilidadSugerencia1;

  /// No description provided for @profesionalDisponibilidadSugerencia2.
  ///
  /// In es, this message translates to:
  /// **'Estoy disponible el viernes a las 10:00'**
  String get profesionalDisponibilidadSugerencia2;

  /// No description provided for @profesionalDisponibilidadSugerencia3.
  ///
  /// In es, this message translates to:
  /// **'Puedo pasar esta misma tarde'**
  String get profesionalDisponibilidadSugerencia3;

  /// No description provided for @profesionalDisponibilidadConfirmar.
  ///
  /// In es, this message translates to:
  /// **'Enviar candidatura'**
  String get profesionalDisponibilidadConfirmar;

  /// No description provided for @profesionalDistanciaKm.
  ///
  /// In es, this message translates to:
  /// **'A {km} km'**
  String profesionalDistanciaKm(String km);

  /// No description provided for @profesionalTrabajosActivos.
  ///
  /// In es, this message translates to:
  /// **'Tienes {n} {n, plural, one{trabajo activo} other{trabajos activos}}'**
  String profesionalTrabajosActivos(int n);

  /// No description provided for @trabajosActivosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Trabajos activos'**
  String get trabajosActivosTitulo;

  /// No description provided for @trabajosActivosTeEligieron.
  ///
  /// In es, this message translates to:
  /// **'¡Te han elegido para {categoria}! Ahora está en Trabajos activos.'**
  String trabajosActivosTeEligieron(String categoria);

  /// No description provided for @trabajosActivosVerTrabajo.
  ///
  /// In es, this message translates to:
  /// **'Ver trabajo'**
  String get trabajosActivosVerTrabajo;

  /// No description provided for @trabajosActivosVacio.
  ///
  /// In es, this message translates to:
  /// **'No tienes trabajos activos ahora mismo'**
  String get trabajosActivosVacio;

  /// No description provided for @trabajosActivosErrorCargar.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar tus trabajos'**
  String get trabajosActivosErrorCargar;

  /// No description provided for @trabajosActivosChat.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get trabajosActivosChat;

  /// No description provided for @trabajosActivosCompletar.
  ///
  /// In es, this message translates to:
  /// **'Marcar como completado'**
  String get trabajosActivosCompletar;

  /// No description provided for @trabajosActivosPrecioFinalTitulo.
  ///
  /// In es, this message translates to:
  /// **'Precio final del servicio'**
  String get trabajosActivosPrecioFinalTitulo;

  /// No description provided for @trabajosActivosPrecioFinalHint.
  ///
  /// In es, this message translates to:
  /// **'Precio (€)'**
  String get trabajosActivosPrecioFinalHint;

  /// No description provided for @trabajosActivosPrecioFinalConfirmar.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get trabajosActivosPrecioFinalConfirmar;

  /// No description provided for @trabajosActivosCompletadoExito.
  ///
  /// In es, this message translates to:
  /// **'Servicio marcado como completado'**
  String get trabajosActivosCompletadoExito;

  /// No description provided for @trabajosActivosCompletadoError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar el servicio'**
  String get trabajosActivosCompletadoError;

  /// No description provided for @trabajosActivosIniciarTrabajo.
  ///
  /// In es, this message translates to:
  /// **'Iniciar trabajo'**
  String get trabajosActivosIniciarTrabajo;

  /// No description provided for @trabajosActivosIniciarTrabajoConfirmarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Iniciar este trabajo?'**
  String get trabajosActivosIniciarTrabajoConfirmarTitulo;

  /// No description provided for @trabajosActivosIniciarTrabajoConfirmarTexto.
  ///
  /// In es, this message translates to:
  /// **'A partir de ahora el cliente ya no podrá cancelarlo directamente — si hace falta, tendrá que abrir una reclamación.'**
  String get trabajosActivosIniciarTrabajoConfirmarTexto;

  /// No description provided for @trabajosActivosIniciarTrabajoExito.
  ///
  /// In es, this message translates to:
  /// **'Trabajo iniciado'**
  String get trabajosActivosIniciarTrabajoExito;

  /// No description provided for @trabajosActivosIniciarTrabajoError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar el trabajo'**
  String get trabajosActivosIniciarTrabajoError;

  /// No description provided for @trabajosActivosDeshacerInicio.
  ///
  /// In es, this message translates to:
  /// **'Deshacer inicio'**
  String get trabajosActivosDeshacerInicio;

  /// No description provided for @trabajosActivosDeshacerInicioExito.
  ///
  /// In es, this message translates to:
  /// **'Inicio deshecho'**
  String get trabajosActivosDeshacerInicioExito;

  /// No description provided for @trabajosActivosDeshacerInicioError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo deshacer el inicio'**
  String get trabajosActivosDeshacerInicioError;

  /// No description provided for @profesionalErrorDisponibilidad.
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar tu disponibilidad'**
  String get profesionalErrorDisponibilidad;

  /// No description provided for @profesionalDisponibleAyuda.
  ///
  /// In es, this message translates to:
  /// **'Recibirás solicitudes cercanas a tu ubicación'**
  String get profesionalDisponibleAyuda;

  /// No description provided for @profesionalNoDisponibleAyuda.
  ///
  /// In es, this message translates to:
  /// **'Actívalo para empezar a recibir trabajos'**
  String get profesionalNoDisponibleAyuda;

  /// No description provided for @profesionalPonerseDisponibleBoton.
  ///
  /// In es, this message translates to:
  /// **'Ponerme disponible'**
  String get profesionalPonerseDisponibleBoton;

  /// No description provided for @disponibilidadTitulo.
  ///
  /// In es, this message translates to:
  /// **'Disponibilidad'**
  String get disponibilidadTitulo;

  /// No description provided for @disponibilidadEnLineaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Estado actual'**
  String get disponibilidadEnLineaTitulo;

  /// No description provided for @disponibilidadModoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Modo de disponibilidad'**
  String get disponibilidadModoTitulo;

  /// No description provided for @disponibilidadModoAyuda.
  ///
  /// In es, this message translates to:
  /// **'Elige cuándo quieres recibir solicitudes. Podrás cambiarlo cuando quieras.'**
  String get disponibilidadModoAyuda;

  /// No description provided for @disponibilidadModoHorarioLaboral.
  ///
  /// In es, this message translates to:
  /// **'Disponible en horario laboral'**
  String get disponibilidadModoHorarioLaboral;

  /// No description provided for @disponibilidadModoHorarioLaboralAyuda.
  ///
  /// In es, this message translates to:
  /// **'Recibes solicitudes en tu horario habitual de trabajo'**
  String get disponibilidadModoHorarioLaboralAyuda;

  /// No description provided for @disponibilidadModo24h.
  ///
  /// In es, this message translates to:
  /// **'Servicio 24 horas'**
  String get disponibilidadModo24h;

  /// No description provided for @disponibilidadModo24hAyuda.
  ///
  /// In es, this message translates to:
  /// **'Recibes solicitudes a cualquier hora, día y noche'**
  String get disponibilidadModo24hAyuda;

  /// No description provided for @disponibilidadModoActualizado.
  ///
  /// In es, this message translates to:
  /// **'Modo de disponibilidad actualizado'**
  String get disponibilidadModoActualizado;

  /// No description provided for @disponibilidadModoError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar el modo de disponibilidad'**
  String get disponibilidadModoError;

  /// No description provided for @disponibilidadPerfilIncompleto.
  ///
  /// In es, this message translates to:
  /// **'Completa tu perfil (foto y al menos una categoría) antes de activarte — así te podrán encontrar los clientes.'**
  String get disponibilidadPerfilIncompleto;

  /// No description provided for @disponibilidadPendienteVerificacion.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta está pendiente de revisión por un administrador. Podrás activarte en cuanto se apruebe.'**
  String get disponibilidadPendienteVerificacion;

  /// No description provided for @disponibilidadPendienteStripe.
  ///
  /// In es, this message translates to:
  /// **'Configura tu cuenta de cobro con Stripe para poder activarte — sin ella no podrías cobrar los trabajos que aceptes.'**
  String get disponibilidadPendienteStripe;

  /// No description provided for @disponibilidadCompletarPerfil.
  ///
  /// In es, this message translates to:
  /// **'Completar perfil'**
  String get disponibilidadCompletarPerfil;

  /// No description provided for @disponibilidadEstadoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Tu disponibilidad'**
  String get disponibilidadEstadoTitulo;

  /// No description provided for @disponibilidadEstadoAyuda.
  ///
  /// In es, this message translates to:
  /// **'Elige un único estado — determina si y cuándo recibes solicitudes.'**
  String get disponibilidadEstadoAyuda;

  /// No description provided for @disponibilidadOpcionNoDisponibleTitulo.
  ///
  /// In es, this message translates to:
  /// **'No disponible'**
  String get disponibilidadOpcionNoDisponibleTitulo;

  /// No description provided for @disponibilidadOpcionNoDisponibleAyuda.
  ///
  /// In es, this message translates to:
  /// **'No recibirás solicitudes nuevas'**
  String get disponibilidadOpcionNoDisponibleAyuda;

  /// No description provided for @disponibilidadOpcionDisponibleTitulo.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get disponibilidadOpcionDisponibleTitulo;

  /// No description provided for @disponibilidadOpcionDisponibleAyuda.
  ///
  /// In es, this message translates to:
  /// **'Recibirás solicitudes nuevas'**
  String get disponibilidadOpcionDisponibleAyuda;

  /// No description provided for @seguimientoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud'**
  String get seguimientoTitulo;

  /// No description provided for @seguimientoError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la solicitud'**
  String get seguimientoError;

  /// No description provided for @seguimientoBuscando.
  ///
  /// In es, this message translates to:
  /// **'Buscando un profesional cerca de ti...'**
  String get seguimientoBuscando;

  /// No description provided for @seguimientoAceptada.
  ///
  /// In es, this message translates to:
  /// **'¡Un profesional ha aceptado tu solicitud!'**
  String get seguimientoAceptada;

  /// No description provided for @seguimientoEnProgreso.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get seguimientoEnProgreso;

  /// No description provided for @seguimientoCompletada.
  ///
  /// In es, this message translates to:
  /// **'Servicio completado'**
  String get seguimientoCompletada;

  /// No description provided for @seguimientoCancelada.
  ///
  /// In es, this message translates to:
  /// **'Solicitud cancelada'**
  String get seguimientoCancelada;

  /// No description provided for @seguimientoCancelarTitulo.
  ///
  /// In es, this message translates to:
  /// **'Cancelar solicitud'**
  String get seguimientoCancelarTitulo;

  /// No description provided for @seguimientoCancelarConfirmar.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres cancelar esta solicitud? Esta acción no se puede deshacer.'**
  String get seguimientoCancelarConfirmar;

  /// No description provided for @seguimientoCancelarExito.
  ///
  /// In es, this message translates to:
  /// **'Solicitud cancelada correctamente'**
  String get seguimientoCancelarExito;

  /// No description provided for @seguimientoCancelarError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cancelar la solicitud'**
  String get seguimientoCancelarError;

  /// No description provided for @seguimientoDisputada.
  ///
  /// In es, this message translates to:
  /// **'En revisión por nuestro equipo de soporte'**
  String get seguimientoDisputada;

  /// No description provided for @seguimientoAbrirChat.
  ///
  /// In es, this message translates to:
  /// **'Abrir chat'**
  String get seguimientoAbrirChat;

  /// No description provided for @editarPerfilTitulo.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get editarPerfilTitulo;

  /// No description provided for @editarPerfilTelefono.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get editarPerfilTelefono;

  /// No description provided for @perfilEditar.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get perfilEditar;

  /// No description provided for @miPerfilTitulo.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get miPerfilTitulo;

  /// No description provided for @miPerfilIncompletoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Completa tu perfil'**
  String get miPerfilIncompletoTitulo;

  /// No description provided for @miPerfilIncompletoAyuda.
  ///
  /// In es, this message translates to:
  /// **'No aparecerás en las búsquedas de clientes hasta que añadas:'**
  String get miPerfilIncompletoAyuda;

  /// No description provided for @miPerfilFaltaFoto.
  ///
  /// In es, this message translates to:
  /// **'una foto de perfil'**
  String get miPerfilFaltaFoto;

  /// No description provided for @miPerfilFaltaCategoria.
  ///
  /// In es, this message translates to:
  /// **'al menos una categoría'**
  String get miPerfilFaltaCategoria;

  /// No description provided for @miPerfilCambiarFoto.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get miPerfilCambiarFoto;

  /// No description provided for @miPerfilOficio.
  ///
  /// In es, this message translates to:
  /// **'Oficio principal'**
  String get miPerfilOficio;

  /// No description provided for @miPerfilOficioSinAsignar.
  ///
  /// In es, this message translates to:
  /// **'Aún sin categoría asignada'**
  String get miPerfilOficioSinAsignar;

  /// No description provided for @miPerfilDescripcionLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get miPerfilDescripcionLabel;

  /// No description provided for @miPerfilDescripcionAyuda.
  ///
  /// In es, this message translates to:
  /// **'Máximo 250 caracteres'**
  String get miPerfilDescripcionAyuda;

  /// No description provided for @miPerfilPrecioLabel.
  ///
  /// In es, this message translates to:
  /// **'Precio por hora (€) — opcional'**
  String get miPerfilPrecioLabel;

  /// No description provided for @miPerfilPrecioAyuda.
  ///
  /// In es, this message translates to:
  /// **'El precio real de cada trabajo se acuerda por presupuesto. Esto solo se usa para el filtro de precio en la búsqueda del cliente.'**
  String get miPerfilPrecioAyuda;

  /// No description provided for @miPerfilDisponible.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get miPerfilDisponible;

  /// No description provided for @miPerfilGuardar.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get miPerfilGuardar;

  /// No description provided for @miPerfilExito.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado correctamente'**
  String get miPerfilExito;

  /// No description provided for @miPerfilErrorGuardar.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron guardar los cambios'**
  String get miPerfilErrorGuardar;

  /// No description provided for @miPerfilErrorCargar.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar tu perfil'**
  String get miPerfilErrorCargar;

  /// No description provided for @miPerfilVerificacionTitulo.
  ///
  /// In es, this message translates to:
  /// **'Verificación'**
  String get miPerfilVerificacionTitulo;

  /// No description provided for @miPerfilVerificacionEstadoAprobado.
  ///
  /// In es, this message translates to:
  /// **'Verificado — ya puedes aceptar trabajos.'**
  String get miPerfilVerificacionEstadoAprobado;

  /// No description provided for @miPerfilVerificacionEstadoPendiente.
  ///
  /// In es, this message translates to:
  /// **'En revisión. Te avisaremos cuando un administrador la apruebe.'**
  String get miPerfilVerificacionEstadoPendiente;

  /// No description provided for @miPerfilVerificacionEstadoRechazado.
  ///
  /// In es, this message translates to:
  /// **'Verificación rechazada. Corrige el documento o la tarifa y vuelve a enviarla.'**
  String get miPerfilVerificacionEstadoRechazado;

  /// No description provided for @miPerfilVerificacionEstadoSinEnviar.
  ///
  /// In es, this message translates to:
  /// **'Aún no has enviado tu documento de identidad — sin esto no podrás aceptar trabajos.'**
  String get miPerfilVerificacionEstadoSinEnviar;

  /// No description provided for @miPerfilDocumentoIdentidadLabel.
  ///
  /// In es, this message translates to:
  /// **'Documento de identidad'**
  String get miPerfilDocumentoIdentidadLabel;

  /// No description provided for @miPerfilDocumentoSeleccionar.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar documento'**
  String get miPerfilDocumentoSeleccionar;

  /// No description provided for @miPerfilEnviarVerificacion.
  ///
  /// In es, this message translates to:
  /// **'Enviar a verificación'**
  String get miPerfilEnviarVerificacion;

  /// No description provided for @miPerfilVerificacionExito.
  ///
  /// In es, this message translates to:
  /// **'Documentación enviada. Un administrador la revisará pronto.'**
  String get miPerfilVerificacionExito;

  /// No description provided for @miPerfilVerificacionErrorFaltaDocumento.
  ///
  /// In es, this message translates to:
  /// **'Sube tu documento de identidad primero'**
  String get miPerfilVerificacionErrorFaltaDocumento;

  /// No description provided for @miPerfilVerificacionErrorFaltaTarifa.
  ///
  /// In es, this message translates to:
  /// **'Indica una tarifa base válida'**
  String get miPerfilVerificacionErrorFaltaTarifa;

  /// No description provided for @miPerfilVerificacionErrorEnvio.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar la verificación'**
  String get miPerfilVerificacionErrorEnvio;

  /// No description provided for @tipoProfesionalTitulo.
  ///
  /// In es, this message translates to:
  /// **'Tipo de profesional'**
  String get tipoProfesionalTitulo;

  /// No description provided for @tipoProfesionalAutonomo.
  ///
  /// In es, this message translates to:
  /// **'Autónomo'**
  String get tipoProfesionalAutonomo;

  /// No description provided for @tipoProfesionalEmpresa.
  ///
  /// In es, this message translates to:
  /// **'Empresa'**
  String get tipoProfesionalEmpresa;

  /// No description provided for @tipoProfesionalPersonaFisica.
  ///
  /// In es, this message translates to:
  /// **'Persona física'**
  String get tipoProfesionalPersonaFisica;

  /// No description provided for @tipoProfesionalTextoLegal.
  ///
  /// In es, this message translates to:
  /// **'Selecciona la opción que mejor describa tu situación actual. Eres responsable de cumplir la legislación fiscal y laboral aplicable en tu país para prestar servicios y recibir pagos. HogarSOS actúa únicamente como plataforma de intermediación y no ofrece asesoramiento fiscal o legal.'**
  String get tipoProfesionalTextoLegal;

  /// No description provided for @tipoProfesionalErrorFaltaSeleccion.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu tipo de profesional'**
  String get tipoProfesionalErrorFaltaSeleccion;

  /// No description provided for @cuentaCobroTitulo.
  ///
  /// In es, this message translates to:
  /// **'Cuenta de cobro'**
  String get cuentaCobroTitulo;

  /// No description provided for @cuentaCobroEstadoConfigurada.
  ///
  /// In es, this message translates to:
  /// **'Configurada — ya puedes recibir pagos.'**
  String get cuentaCobroEstadoConfigurada;

  /// No description provided for @cuentaCobroEstadoPendiente.
  ///
  /// In es, this message translates to:
  /// **'Configura tu cuenta de cobro con Stripe para poder recibir pagos por tus trabajos.'**
  String get cuentaCobroEstadoPendiente;

  /// No description provided for @cuentaCobroEstadoRequiereActualizacion.
  ///
  /// In es, this message translates to:
  /// **'Stripe necesita más información para poder pagarte. Complétala para seguir cobrando.'**
  String get cuentaCobroEstadoRequiereActualizacion;

  /// No description provided for @cuentaCobroBotonConfigurar.
  ///
  /// In es, this message translates to:
  /// **'Configurar cuenta de cobro'**
  String get cuentaCobroBotonConfigurar;

  /// No description provided for @cuentaCobroBotonActualizar.
  ///
  /// In es, this message translates to:
  /// **'Actualizar en Stripe'**
  String get cuentaCobroBotonActualizar;

  /// No description provided for @cuentaCobroBotonEditar.
  ///
  /// In es, this message translates to:
  /// **'Editar cuenta de cobro'**
  String get cuentaCobroBotonEditar;

  /// No description provided for @cuentaCobroErrorAbrir.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir Stripe. Inténtalo de nuevo.'**
  String get cuentaCobroErrorAbrir;

  /// No description provided for @cuentaCobroStripeActualizando.
  ///
  /// In es, this message translates to:
  /// **'Actualizando el estado de tu cuenta de cobro…'**
  String get cuentaCobroStripeActualizando;

  /// No description provided for @cuentaCobroStripeCaducado.
  ///
  /// In es, this message translates to:
  /// **'El enlace de Stripe caducó. Pulsa \"Configurar cuenta de cobro\" para volver a intentarlo.'**
  String get cuentaCobroStripeCaducado;

  /// No description provided for @centroPagosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Centro de Pagos'**
  String get centroPagosTitulo;

  /// No description provided for @centroPagosErrorCargar.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar tu información de pagos'**
  String get centroPagosErrorCargar;

  /// No description provided for @centroPagosPendiente.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get centroPagosPendiente;

  /// No description provided for @centroPagosPendienteAyuda.
  ///
  /// In es, this message translates to:
  /// **'Cobros ya liberados que Stripe todavía está procesando antes de que estén disponibles.'**
  String get centroPagosPendienteAyuda;

  /// No description provided for @centroPagosDisponible.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get centroPagosDisponible;

  /// No description provided for @centroPagosDisponibleAyuda.
  ///
  /// In es, this message translates to:
  /// **'Saldo que Stripe ya puede transferir a tu cuenta bancaria.'**
  String get centroPagosDisponibleAyuda;

  /// No description provided for @centroPagosHistorialTitulo.
  ///
  /// In es, this message translates to:
  /// **'Historial de cobros'**
  String get centroPagosHistorialTitulo;

  /// No description provided for @centroPagosHistorialVacio.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes ningún cobro liberado.'**
  String get centroPagosHistorialVacio;

  /// No description provided for @centroPagosImporte.
  ///
  /// In es, this message translates to:
  /// **'{monto} €'**
  String centroPagosImporte(String monto);

  /// No description provided for @centroPagosPagoDe.
  ///
  /// In es, this message translates to:
  /// **'Pago de {nombre}'**
  String centroPagosPagoDe(String nombre);

  /// No description provided for @miPerfilStatValoracion.
  ///
  /// In es, this message translates to:
  /// **'Valoración'**
  String get miPerfilStatValoracion;

  /// No description provided for @miPerfilStatTrabajos.
  ///
  /// In es, this message translates to:
  /// **'Trabajos'**
  String get miPerfilStatTrabajos;

  /// No description provided for @miPerfilStatTarifa.
  ///
  /// In es, this message translates to:
  /// **'Tarifa'**
  String get miPerfilStatTarifa;

  /// No description provided for @miPerfilStatEstado.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get miPerfilStatEstado;

  /// No description provided for @miPerfilEstadoAprobado.
  ///
  /// In es, this message translates to:
  /// **'Aprobado'**
  String get miPerfilEstadoAprobado;

  /// No description provided for @miPerfilEstadoPendiente.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get miPerfilEstadoPendiente;

  /// No description provided for @miPerfilEstadoRechazado.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get miPerfilEstadoRechazado;

  /// No description provided for @miPerfilEstadoSinEnviar.
  ///
  /// In es, this message translates to:
  /// **'Sin enviar'**
  String get miPerfilEstadoSinEnviar;

  /// No description provided for @miPerfilTelefonoVacio.
  ///
  /// In es, this message translates to:
  /// **'Añade tu número de teléfono'**
  String get miPerfilTelefonoVacio;

  /// No description provided for @miPerfilDescripcionVacia.
  ///
  /// In es, this message translates to:
  /// **'Añade una breve descripción para que los clientes te conozcan mejor'**
  String get miPerfilDescripcionVacia;

  /// No description provided for @miPerfilCambiar.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get miPerfilCambiar;

  /// No description provided for @miPerfilEditar.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get miPerfilEditar;

  /// No description provided for @miPerfilCategoriasTitulo.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get miPerfilCategoriasTitulo;

  /// No description provided for @miPerfilCategoriasEditar.
  ///
  /// In es, this message translates to:
  /// **'Editar categorías'**
  String get miPerfilCategoriasEditar;

  /// No description provided for @miPerfilCategoriasVacia.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes categorías asignadas'**
  String get miPerfilCategoriasVacia;

  /// No description provided for @miPerfilCategoriasGuardar.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get miPerfilCategoriasGuardar;

  /// No description provided for @miPerfilCategoriasCancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get miPerfilCategoriasCancelar;

  /// No description provided for @miPerfilCategoriasErrorMinimo.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos una categoría'**
  String get miPerfilCategoriasErrorMinimo;

  /// No description provided for @miPerfilCategoriasExito.
  ///
  /// In es, this message translates to:
  /// **'Categorías actualizadas'**
  String get miPerfilCategoriasExito;

  /// No description provided for @miPerfilCategoriasError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron actualizar las categorías'**
  String get miPerfilCategoriasError;

  /// No description provided for @distintivoVerificado.
  ///
  /// In es, this message translates to:
  /// **'Identidad verificada'**
  String get distintivoVerificado;

  /// No description provided for @homeVerTodasCategorias.
  ///
  /// In es, this message translates to:
  /// **'Ver todas las categorías'**
  String get homeVerTodasCategorias;

  /// No description provided for @todasCategoriasTitulo.
  ///
  /// In es, this message translates to:
  /// **'Todas las categorías'**
  String get todasCategoriasTitulo;

  /// No description provided for @chatTitulo.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get chatTitulo;

  /// No description provided for @chatSinMensajes.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay mensajes'**
  String get chatSinMensajes;

  /// No description provided for @chatErrorCargar.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el chat'**
  String get chatErrorCargar;

  /// No description provided for @chatErrorEnviar.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el mensaje'**
  String get chatErrorEnviar;

  /// No description provided for @chatContactoBloqueado.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, los datos de contacto solo podrán compartirse cuando el trabajo haya sido aceptado.'**
  String get chatContactoBloqueado;

  /// No description provided for @chatHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje...'**
  String get chatHint;

  /// No description provided for @seguimientoAutorizarPago.
  ///
  /// In es, this message translates to:
  /// **'Autorizar pago'**
  String get seguimientoAutorizarPago;

  /// No description provided for @seguimientoValorar.
  ///
  /// In es, this message translates to:
  /// **'Valorar servicio'**
  String get seguimientoValorar;

  /// No description provided for @seguimientoYaValorado.
  ///
  /// In es, this message translates to:
  /// **'Ya has valorado este servicio'**
  String get seguimientoYaValorado;

  /// No description provided for @seguimientoPagoRetenido.
  ///
  /// In es, this message translates to:
  /// **'Pago autorizado, pendiente de completar el servicio'**
  String get seguimientoPagoRetenido;

  /// No description provided for @seguimientoPagoLiberado.
  ///
  /// In es, this message translates to:
  /// **'Pago completado'**
  String get seguimientoPagoLiberado;

  /// No description provided for @seguimientoPagoReembolsado.
  ///
  /// In es, this message translates to:
  /// **'Pago reembolsado'**
  String get seguimientoPagoReembolsado;

  /// No description provided for @seguimientoPagoFallido.
  ///
  /// In es, this message translates to:
  /// **'El pago falló'**
  String get seguimientoPagoFallido;

  /// No description provided for @pagoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Confirmar y pagar'**
  String get pagoTitulo;

  /// No description provided for @pagoInfo.
  ///
  /// In es, this message translates to:
  /// **'El importe se autoriza ahora pero solo se cobra cuando el profesional complete el servicio.'**
  String get pagoInfo;

  /// No description provided for @pagoBtnAutorizar.
  ///
  /// In es, this message translates to:
  /// **'Autorizar pago'**
  String get pagoBtnAutorizar;

  /// No description provided for @pagoExito.
  ///
  /// In es, this message translates to:
  /// **'Pago autorizado. Se cobrará cuando el servicio se complete.'**
  String get pagoExito;

  /// No description provided for @pagoErrorGenerico.
  ///
  /// In es, this message translates to:
  /// **'No se pudo procesar el pago. Inténtalo de nuevo.'**
  String get pagoErrorGenerico;

  /// No description provided for @pagoErrorStripeDefault.
  ///
  /// In es, this message translates to:
  /// **'El pago no se completó'**
  String get pagoErrorStripeDefault;

  /// No description provided for @pagoCancelado.
  ///
  /// In es, this message translates to:
  /// **'Has cancelado el pago'**
  String get pagoCancelado;

  /// No description provided for @valoracionTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo fue el servicio?'**
  String get valoracionTitulo;

  /// No description provided for @valoracionErrorSeleccion.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una puntuación'**
  String get valoracionErrorSeleccion;

  /// No description provided for @valoracionErrorEnviar.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar la valoración. Inténtalo de nuevo.'**
  String get valoracionErrorEnviar;

  /// No description provided for @valoracionComentarioLabel.
  ///
  /// In es, this message translates to:
  /// **'Comentario (opcional)'**
  String get valoracionComentarioLabel;

  /// No description provided for @valoracionBtnEnviar.
  ///
  /// In es, this message translates to:
  /// **'Enviar valoración'**
  String get valoracionBtnEnviar;

  /// No description provided for @progresoBuscando.
  ///
  /// In es, this message translates to:
  /// **'Buscando profesionales'**
  String get progresoBuscando;

  /// No description provided for @progresoSeleccionado.
  ///
  /// In es, this message translates to:
  /// **'Profesional seleccionado'**
  String get progresoSeleccionado;

  /// No description provided for @progresoFinalizado.
  ///
  /// In es, this message translates to:
  /// **'Trabajo finalizado'**
  String get progresoFinalizado;

  /// No description provided for @misSolicitudesError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar tus solicitudes'**
  String get misSolicitudesError;

  /// No description provided for @misSolicitudesVacio.
  ///
  /// In es, this message translates to:
  /// **'Aún no has hecho ninguna solicitud'**
  String get misSolicitudesVacio;

  /// No description provided for @misSolicitudesBorrarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar esta solicitud?'**
  String get misSolicitudesBorrarTitulo;

  /// No description provided for @misSolicitudesBorrarMensaje.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará de tu historial. Esta acción no se puede deshacer.'**
  String get misSolicitudesBorrarMensaje;

  /// No description provided for @misSolicitudesBorrarConfirmar.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get misSolicitudesBorrarConfirmar;

  /// No description provided for @misSolicitudesBorrarExito.
  ///
  /// In es, this message translates to:
  /// **'Solicitud borrada'**
  String get misSolicitudesBorrarExito;

  /// No description provided for @misSolicitudesBorrarError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo borrar la solicitud'**
  String get misSolicitudesBorrarError;

  /// No description provided for @misSolicitudesArchivarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar esta solicitud de la lista?'**
  String get misSolicitudesArchivarTitulo;

  /// No description provided for @misSolicitudesArchivarMensaje.
  ///
  /// In es, this message translates to:
  /// **'Se ocultará de tu historial, pero el pago, el chat y las valoraciones se conservan.'**
  String get misSolicitudesArchivarMensaje;

  /// No description provided for @misSolicitudesArchivarConfirmar.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get misSolicitudesArchivarConfirmar;

  /// No description provided for @misSolicitudesArchivarExito.
  ///
  /// In es, this message translates to:
  /// **'Solicitud quitada de la lista'**
  String get misSolicitudesArchivarExito;

  /// No description provided for @misSolicitudesArchivarError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo quitar la solicitud'**
  String get misSolicitudesArchivarError;

  /// No description provided for @misSolicitudesAccionRequerida.
  ///
  /// In es, this message translates to:
  /// **'Necesita tu confirmación'**
  String get misSolicitudesAccionRequerida;

  /// No description provided for @trabajosActivosArchivarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar este trabajo de la lista?'**
  String get trabajosActivosArchivarTitulo;

  /// No description provided for @trabajosActivosArchivarMensaje.
  ///
  /// In es, this message translates to:
  /// **'Se ocultará de tu historial, pero el pago, el chat y las valoraciones se conservan.'**
  String get trabajosActivosArchivarMensaje;

  /// No description provided for @trabajosActivosArchivarConfirmar.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get trabajosActivosArchivarConfirmar;

  /// No description provided for @trabajosActivosArchivarExito.
  ///
  /// In es, this message translates to:
  /// **'Trabajo quitado de la lista'**
  String get trabajosActivosArchivarExito;

  /// No description provided for @trabajosActivosArchivarError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo quitar el trabajo'**
  String get trabajosActivosArchivarError;

  /// No description provided for @wizardTitulo.
  ///
  /// In es, this message translates to:
  /// **'Nueva solicitud'**
  String get wizardTitulo;

  /// No description provided for @wizardPaso.
  ///
  /// In es, this message translates to:
  /// **'Paso {actual} de {total}'**
  String wizardPaso(int actual, int total);

  /// No description provided for @wizardSiguiente.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get wizardSiguiente;

  /// No description provided for @wizardPublicar.
  ///
  /// In es, this message translates to:
  /// **'Publicar solicitud'**
  String get wizardPublicar;

  /// No description provided for @wizardErrorCategoria.
  ///
  /// In es, this message translates to:
  /// **'Elige una categoría para continuar'**
  String get wizardErrorCategoria;

  /// No description provided for @wizardErrorDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Describe el trabajo con un poco más de detalle'**
  String get wizardErrorDescripcion;

  /// No description provided for @wizardErrorUbicacion.
  ///
  /// In es, this message translates to:
  /// **'Elige dónde necesitas el servicio'**
  String get wizardErrorUbicacion;

  /// No description provided for @wizardErrorFecha.
  ///
  /// In es, this message translates to:
  /// **'Elige una fecha'**
  String get wizardErrorFecha;

  /// No description provided for @wizardErrorFotosSubiendo.
  ///
  /// In es, this message translates to:
  /// **'Espera a que terminen de subirse las fotos'**
  String get wizardErrorFotosSubiendo;

  /// No description provided for @fotoErrorSubir.
  ///
  /// In es, this message translates to:
  /// **'No se pudo subir la foto. Inténtalo de nuevo.'**
  String get fotoErrorSubir;

  /// No description provided for @wizardPaso1Titulo.
  ///
  /// In es, this message translates to:
  /// **'¿Qué necesitas?'**
  String get wizardPaso1Titulo;

  /// No description provided for @wizardCategoriaCambiar.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get wizardCategoriaCambiar;

  /// No description provided for @wizardCategoriaElegirTitulo.
  ///
  /// In es, this message translates to:
  /// **'Elige una categoría'**
  String get wizardCategoriaElegirTitulo;

  /// No description provided for @wizardPaso2Titulo.
  ///
  /// In es, this message translates to:
  /// **'Describe el trabajo'**
  String get wizardPaso2Titulo;

  /// No description provided for @wizardPaso2Ayuda.
  ///
  /// In es, this message translates to:
  /// **'Cuanto más detalle des, mejor podrán ayudarte los profesionales'**
  String get wizardPaso2Ayuda;

  /// No description provided for @wizardPaso3Titulo.
  ///
  /// In es, this message translates to:
  /// **'Añade fotos (opcional)'**
  String get wizardPaso3Titulo;

  /// No description provided for @wizardPaso3Ayuda.
  ///
  /// In es, this message translates to:
  /// **'Una foto ayuda al profesional a entender el problema antes de llegar'**
  String get wizardPaso3Ayuda;

  /// No description provided for @wizardFotoCamara.
  ///
  /// In es, this message translates to:
  /// **'Hacer una foto'**
  String get wizardFotoCamara;

  /// No description provided for @wizardFotoGaleria.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get wizardFotoGaleria;

  /// No description provided for @wizardPaso4Titulo.
  ///
  /// In es, this message translates to:
  /// **'¿Dónde es el trabajo?'**
  String get wizardPaso4Titulo;

  /// No description provided for @wizardPaso4Ayuda.
  ///
  /// In es, this message translates to:
  /// **'Usaremos esta ubicación para encontrar profesionales cerca'**
  String get wizardPaso4Ayuda;

  /// No description provided for @wizardUbicacionElegir.
  ///
  /// In es, this message translates to:
  /// **'Elegir en el mapa'**
  String get wizardUbicacionElegir;

  /// No description provided for @wizardUbicacionCambiar.
  ///
  /// In es, this message translates to:
  /// **'Cambiar ubicación'**
  String get wizardUbicacionCambiar;

  /// No description provided for @wizardPaso5Titulo.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo lo necesitas?'**
  String get wizardPaso5Titulo;

  /// No description provided for @wizardUrgenciaAsap.
  ///
  /// In es, this message translates to:
  /// **'Lo antes posible'**
  String get wizardUrgenciaAsap;

  /// No description provided for @wizardUrgenciaHoy.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get wizardUrgenciaHoy;

  /// No description provided for @wizardUrgenciaManana.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get wizardUrgenciaManana;

  /// No description provided for @wizardUrgenciaFecha.
  ///
  /// In es, this message translates to:
  /// **'Elegir una fecha'**
  String get wizardUrgenciaFecha;

  /// No description provided for @wizardSeleccionarFecha.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar fecha'**
  String get wizardSeleccionarFecha;

  /// No description provided for @wizardPaso6Titulo.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu solicitud'**
  String get wizardPaso6Titulo;

  /// No description provided for @ubicacionTitulo.
  ///
  /// In es, this message translates to:
  /// **'Elegir ubicación'**
  String get ubicacionTitulo;

  /// No description provided for @ubicacionDireccionOpcional.
  ///
  /// In es, this message translates to:
  /// **'Dirección o referencia (opcional)'**
  String get ubicacionDireccionOpcional;

  /// No description provided for @ubicacionConfirmar.
  ///
  /// In es, this message translates to:
  /// **'Confirmar ubicación'**
  String get ubicacionConfirmar;

  /// No description provided for @ubicacionAvisoNoDetectada.
  ///
  /// In es, this message translates to:
  /// **'No pudimos detectar tu ubicación GPS — mueve el mapa hasta tu zona antes de confirmar'**
  String get ubicacionAvisoNoDetectada;

  /// No description provided for @adminTituloPanel.
  ///
  /// In es, this message translates to:
  /// **'Panel admin'**
  String get adminTituloPanel;

  /// No description provided for @adminTabVerificaciones.
  ///
  /// In es, this message translates to:
  /// **'Verificaciones'**
  String get adminTabVerificaciones;

  /// No description provided for @adminTabDisputas.
  ///
  /// In es, this message translates to:
  /// **'Disputas'**
  String get adminTabDisputas;

  /// No description provided for @adminVerificacionesVacio.
  ///
  /// In es, this message translates to:
  /// **'No hay verificaciones pendientes'**
  String get adminVerificacionesVacio;

  /// No description provided for @adminVerificacionesError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las verificaciones'**
  String get adminVerificacionesError;

  /// No description provided for @adminDisputasVacio.
  ///
  /// In es, this message translates to:
  /// **'No hay disputas abiertas'**
  String get adminDisputasVacio;

  /// No description provided for @adminDisputasError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las disputas'**
  String get adminDisputasError;

  /// No description provided for @adminCategoriasLabel.
  ///
  /// In es, this message translates to:
  /// **'Categorías: {categorias}'**
  String adminCategoriasLabel(String categorias);

  /// No description provided for @adminVerDocumento.
  ///
  /// In es, this message translates to:
  /// **'Ver documento de identidad'**
  String get adminVerDocumento;

  /// No description provided for @adminDocumentoSinEnviar.
  ///
  /// In es, this message translates to:
  /// **'Sin documento de identidad enviado'**
  String get adminDocumentoSinEnviar;

  /// No description provided for @adminRechazar.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get adminRechazar;

  /// No description provided for @adminAprobar.
  ///
  /// In es, this message translates to:
  /// **'Aprobar'**
  String get adminAprobar;

  /// No description provided for @adminFavorCliente.
  ///
  /// In es, this message translates to:
  /// **'A favor del cliente'**
  String get adminFavorCliente;

  /// No description provided for @adminFavorProfesional.
  ///
  /// In es, this message translates to:
  /// **'A favor del profesional'**
  String get adminFavorProfesional;

  /// No description provided for @adminMotivoRechazoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Motivo del rechazo'**
  String get adminMotivoRechazoTitulo;

  /// No description provided for @adminMotivoRechazoHint.
  ///
  /// In es, this message translates to:
  /// **'Explica brevemente por qué se rechaza'**
  String get adminMotivoRechazoHint;

  /// No description provided for @adminMotivoRechazoAyuda.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 5 caracteres — el profesional lo verá'**
  String get adminMotivoRechazoAyuda;

  /// No description provided for @adminNotasResolucionTitulo.
  ///
  /// In es, this message translates to:
  /// **'Notas de la resolución'**
  String get adminNotasResolucionTitulo;

  /// No description provided for @adminNotasResolucionHint.
  ///
  /// In es, this message translates to:
  /// **'Explica brevemente cómo se resolvió'**
  String get adminNotasResolucionHint;

  /// No description provided for @adminNotasResolucionAyuda.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 5 caracteres — quedará registrado en la disputa'**
  String get adminNotasResolucionAyuda;

  /// No description provided for @adminConfirmar.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get adminConfirmar;

  /// No description provided for @adminDecisionError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo registrar la decisión. Inténtalo de nuevo.'**
  String get adminDecisionError;

  /// No description provided for @adminResolucionError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo registrar la resolución. Inténtalo de nuevo.'**
  String get adminResolucionError;

  /// No description provided for @adminTabPagosAtascados.
  ///
  /// In es, this message translates to:
  /// **'Pagos atascados'**
  String get adminTabPagosAtascados;

  /// No description provided for @adminPagosAtascadosVacio.
  ///
  /// In es, this message translates to:
  /// **'No hay pagos atascados'**
  String get adminPagosAtascadosVacio;

  /// No description provided for @adminPagosAtascadosError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los pagos atascados'**
  String get adminPagosAtascadosError;

  /// No description provided for @adminPagosAtascadosResumen.
  ///
  /// In es, this message translates to:
  /// **'Total: {total} · Retenido en la plataforma: {importe} €'**
  String adminPagosAtascadosResumen(int total, String importe);

  /// No description provided for @adminPagoAtascadoCapturadoSinTransferir.
  ///
  /// In es, this message translates to:
  /// **'Capturado, sin transferir al profesional'**
  String get adminPagoAtascadoCapturadoSinTransferir;

  /// No description provided for @adminPagoAtascadoCompletadoSinCapturar.
  ///
  /// In es, this message translates to:
  /// **'Trabajo completado, autorización sin capturar'**
  String get adminPagoAtascadoCompletadoSinCapturar;

  /// No description provided for @adminPagoAtascadoAutorizadoEl.
  ///
  /// In es, this message translates to:
  /// **'Autorizado el {fecha}'**
  String adminPagoAtascadoAutorizadoEl(String fecha);

  /// No description provided for @adminPagoAtascadoCapturadoEl.
  ///
  /// In es, this message translates to:
  /// **'Capturado el {fecha}'**
  String adminPagoAtascadoCapturadoEl(String fecha);

  /// No description provided for @adminPagoAtascadoIntentos.
  ///
  /// In es, this message translates to:
  /// **'Intentos de liberación: {n}'**
  String adminPagoAtascadoIntentos(int n);

  /// No description provided for @adminPagoAtascadoUltimoError.
  ///
  /// In es, this message translates to:
  /// **'Último error: {error}'**
  String adminPagoAtascadoUltimoError(String error);

  /// No description provided for @adminPagoAtascadoSinProfesional.
  ///
  /// In es, this message translates to:
  /// **'Sin profesional asignado'**
  String get adminPagoAtascadoSinProfesional;

  /// No description provided for @adminContracargoBadge.
  ///
  /// In es, this message translates to:
  /// **'⚠️ Contracargo Stripe: {estado}, {monto} €'**
  String adminContracargoBadge(String estado, String monto);

  /// No description provided for @adminContracargoVerEnStripe.
  ///
  /// In es, this message translates to:
  /// **'Ver en Stripe'**
  String get adminContracargoVerEnStripe;

  /// No description provided for @adminContracargoBloqueaReintento.
  ///
  /// In es, this message translates to:
  /// **'Bloqueado por disputa'**
  String get adminContracargoBloqueaReintento;

  /// No description provided for @adminContracargoErrorAbrirStripe.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir Stripe'**
  String get adminContracargoErrorAbrirStripe;

  /// No description provided for @adminReintentarLiberacion.
  ///
  /// In es, this message translates to:
  /// **'Reintentar liberación'**
  String get adminReintentarLiberacion;

  /// No description provided for @adminReintentarLiberacionConfirmarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Reintentar liberación?'**
  String get adminReintentarLiberacionConfirmarTitulo;

  /// No description provided for @adminReintentarLiberacionConfirmarTexto.
  ///
  /// In es, this message translates to:
  /// **'Se intentará capturar y transferir este pago de nuevo. Es seguro repetir la operación aunque ya esté en curso o parcialmente hecha.'**
  String get adminReintentarLiberacionConfirmarTexto;

  /// No description provided for @adminReintentarLiberacionExito.
  ///
  /// In es, this message translates to:
  /// **'Liberación completada correctamente'**
  String get adminReintentarLiberacionExito;

  /// No description provided for @adminTabTareas.
  ///
  /// In es, this message translates to:
  /// **'Tareas programadas'**
  String get adminTabTareas;

  /// No description provided for @adminTareasVacio.
  ///
  /// In es, this message translates to:
  /// **'No hay tareas programadas'**
  String get adminTareasVacio;

  /// No description provided for @adminTareasError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las tareas programadas'**
  String get adminTareasError;

  /// No description provided for @adminTareaEnCurso.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get adminTareaEnCurso;

  /// No description provided for @adminTareaCada.
  ///
  /// In es, this message translates to:
  /// **'Cada {n} min'**
  String adminTareaCada(int n);

  /// No description provided for @adminTareaUltimaEjecucion.
  ///
  /// In es, this message translates to:
  /// **'Última ejecución: {fecha}'**
  String adminTareaUltimaEjecucion(String fecha);

  /// No description provided for @adminTareaNuncaEjecutada.
  ///
  /// In es, this message translates to:
  /// **'Todavía no se ha ejecutado nunca'**
  String get adminTareaNuncaEjecutada;

  /// No description provided for @adminTareaProximaEjecucion.
  ///
  /// In es, this message translates to:
  /// **'Próxima aprox.: {fecha}'**
  String adminTareaProximaEjecucion(String fecha);

  /// No description provided for @adminTareaEjecuciones.
  ///
  /// In es, this message translates to:
  /// **'Ejecuciones: {n}'**
  String adminTareaEjecuciones(int n);

  /// No description provided for @adminTareaFallosConsecutivos.
  ///
  /// In es, this message translates to:
  /// **'Fallos consecutivos: {n}'**
  String adminTareaFallosConsecutivos(int n);

  /// No description provided for @adminTareaUltimoResultado.
  ///
  /// In es, this message translates to:
  /// **'Último resultado: {texto}'**
  String adminTareaUltimoResultado(String texto);

  /// No description provided for @adminTareaUltimoError.
  ///
  /// In es, this message translates to:
  /// **'Último error: {texto}'**
  String adminTareaUltimoError(String texto);

  /// No description provided for @adminEjecutarAhora.
  ///
  /// In es, this message translates to:
  /// **'Ejecutar ahora'**
  String get adminEjecutarAhora;

  /// No description provided for @adminEjecutarAhoraConfirmarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Ejecutar esta tarea ahora?'**
  String get adminEjecutarAhoraConfirmarTitulo;

  /// No description provided for @adminEjecutarAhoraConfirmarTexto.
  ///
  /// In es, this message translates to:
  /// **'Se forzará su ejecución sin esperar al siguiente ciclo. Si ya está en curso, no se duplicará.'**
  String get adminEjecutarAhoraConfirmarTexto;

  /// No description provided for @adminEjecutarAhoraExito.
  ///
  /// In es, this message translates to:
  /// **'Tarea ejecutada correctamente'**
  String get adminEjecutarAhoraExito;

  /// No description provided for @adminTabUsuarios.
  ///
  /// In es, this message translates to:
  /// **'Usuarios'**
  String get adminTabUsuarios;

  /// No description provided for @adminUsuarioIdLabel.
  ///
  /// In es, this message translates to:
  /// **'ID del usuario'**
  String get adminUsuarioIdLabel;

  /// No description provided for @adminUsuarioIdHint.
  ///
  /// In es, this message translates to:
  /// **'Pega o escribe el ID (UUID)'**
  String get adminUsuarioIdHint;

  /// No description provided for @adminUsuarioBuscarBoton.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get adminUsuarioBuscarBoton;

  /// No description provided for @adminUsuarioBusquedaError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo encontrar el usuario'**
  String get adminUsuarioBusquedaError;

  /// No description provided for @adminUsuarioEstadoActivo.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get adminUsuarioEstadoActivo;

  /// No description provided for @adminUsuarioEstadoBloqueado.
  ///
  /// In es, this message translates to:
  /// **'Bloqueado'**
  String get adminUsuarioEstadoBloqueado;

  /// No description provided for @adminUsuarioCuentaEliminada.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta fue eliminada por el propio usuario (RGPD) — no se puede reactivar.'**
  String get adminUsuarioCuentaEliminada;

  /// No description provided for @adminUsuarioBloquear.
  ///
  /// In es, this message translates to:
  /// **'Bloquear'**
  String get adminUsuarioBloquear;

  /// No description provided for @adminUsuarioActivar.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get adminUsuarioActivar;

  /// No description provided for @adminUsuarioBloquearConfirmarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Bloquear a este usuario?'**
  String get adminUsuarioBloquearConfirmarTitulo;

  /// No description provided for @adminUsuarioBloquearConfirmarTexto.
  ///
  /// In es, this message translates to:
  /// **'No podrá iniciar sesión hasta que lo actives de nuevo.'**
  String get adminUsuarioBloquearConfirmarTexto;

  /// No description provided for @adminUsuarioActivarConfirmarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Activar a este usuario?'**
  String get adminUsuarioActivarConfirmarTitulo;

  /// No description provided for @adminUsuarioActivarConfirmarTexto.
  ///
  /// In es, this message translates to:
  /// **'Podrá volver a iniciar sesión con normalidad.'**
  String get adminUsuarioActivarConfirmarTexto;

  /// No description provided for @adminUsuarioCambioExito.
  ///
  /// In es, this message translates to:
  /// **'Estado actualizado correctamente'**
  String get adminUsuarioCambioExito;

  /// No description provided for @reportarProblemaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Reportar un problema'**
  String get reportarProblemaTitulo;

  /// No description provided for @reportarProblemaMotivoLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Qué ha pasado?'**
  String get reportarProblemaMotivoLabel;

  /// No description provided for @reportarProblemaMotivoProfesionalNoPresento.
  ///
  /// In es, this message translates to:
  /// **'El profesional no se presentó'**
  String get reportarProblemaMotivoProfesionalNoPresento;

  /// No description provided for @reportarProblemaMotivoClienteAusente.
  ///
  /// In es, this message translates to:
  /// **'El cliente no estaba en la dirección'**
  String get reportarProblemaMotivoClienteAusente;

  /// No description provided for @reportarProblemaMotivoTrabajoCancelado.
  ///
  /// In es, this message translates to:
  /// **'El trabajo fue cancelado'**
  String get reportarProblemaMotivoTrabajoCancelado;

  /// No description provided for @reportarProblemaMotivoProblemaPago.
  ///
  /// In es, this message translates to:
  /// **'Problema con el pago'**
  String get reportarProblemaMotivoProblemaPago;

  /// No description provided for @reportarProblemaMotivoComportamiento.
  ///
  /// In es, this message translates to:
  /// **'Comportamiento inapropiado'**
  String get reportarProblemaMotivoComportamiento;

  /// No description provided for @reportarProblemaMotivoOtro.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get reportarProblemaMotivoOtro;

  /// No description provided for @reportarProblemaDescripcionLabel.
  ///
  /// In es, this message translates to:
  /// **'Describe lo ocurrido'**
  String get reportarProblemaDescripcionLabel;

  /// No description provided for @reportarProblemaDescripcionHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos con detalle qué ha pasado'**
  String get reportarProblemaDescripcionHint;

  /// No description provided for @reportarProblemaFotosLabel.
  ///
  /// In es, this message translates to:
  /// **'Fotos (opcional)'**
  String get reportarProblemaFotosLabel;

  /// No description provided for @reportarProblemaEnviar.
  ///
  /// In es, this message translates to:
  /// **'Enviar reclamación'**
  String get reportarProblemaEnviar;

  /// No description provided for @reportarProblemaExito.
  ///
  /// In es, this message translates to:
  /// **'Reclamación enviada — nuestro equipo la revisará'**
  String get reportarProblemaExito;

  /// No description provided for @reportarProblemaError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar la reclamación'**
  String get reportarProblemaError;

  /// No description provided for @reportarProblemaBoton.
  ///
  /// In es, this message translates to:
  /// **'Reportar un problema'**
  String get reportarProblemaBoton;

  /// No description provided for @seguimientoVerCandidatos.
  ///
  /// In es, this message translates to:
  /// **'Ver candidatos ({n})'**
  String seguimientoVerCandidatos(int n);

  /// No description provided for @seleccionarProfesionalTitulo.
  ///
  /// In es, this message translates to:
  /// **'Elegir profesional'**
  String get seleccionarProfesionalTitulo;

  /// No description provided for @seleccionarProfesionalElegir.
  ///
  /// In es, this message translates to:
  /// **'Elegir profesional'**
  String get seleccionarProfesionalElegir;

  /// No description provided for @seleccionarProfesionalConfirmarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Confirmar elección?'**
  String get seleccionarProfesionalConfirmarTitulo;

  /// No description provided for @seleccionarProfesionalConfirmarTexto.
  ///
  /// In es, this message translates to:
  /// **'{nombre} quedará asignado a este trabajo. El resto de candidatos serán descartados.'**
  String seleccionarProfesionalConfirmarTexto(String nombre);

  /// No description provided for @seleccionarProfesionalError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la selección. Puede que otra persona ya haya elegido.'**
  String get seleccionarProfesionalError;

  /// No description provided for @seleccionarProfesionalVacio.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay ninguna candidatura recibida — vuelve más tarde'**
  String get seleccionarProfesionalVacio;

  /// No description provided for @trabajosActivosEnviarPresupuesto.
  ///
  /// In es, this message translates to:
  /// **'Enviar presupuesto'**
  String get trabajosActivosEnviarPresupuesto;

  /// No description provided for @trabajosActivosPresupuestoEsperando.
  ///
  /// In es, this message translates to:
  /// **'Esperando respuesta del cliente'**
  String get trabajosActivosPresupuestoEsperando;

  /// No description provided for @trabajosActivosHorasRealesTitulo.
  ///
  /// In es, this message translates to:
  /// **'Horas reales trabajadas'**
  String get trabajosActivosHorasRealesTitulo;

  /// No description provided for @trabajosActivosHorasRealesTarifa.
  ///
  /// In es, this message translates to:
  /// **'Tarifa acordada: {tarifa} €/hora'**
  String trabajosActivosHorasRealesTarifa(String tarifa);

  /// No description provided for @trabajosActivosHorasRealesHint.
  ///
  /// In es, this message translates to:
  /// **'Horas'**
  String get trabajosActivosHorasRealesHint;

  /// No description provided for @trabajosActivosCompletarCerradoConfirmar.
  ///
  /// In es, this message translates to:
  /// **'¿Confirmas que el trabajo está completado? Se liberará el pago del presupuesto acordado.'**
  String get trabajosActivosCompletarCerradoConfirmar;

  /// No description provided for @presupuestoDialogoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Enviar presupuesto'**
  String get presupuestoDialogoTitulo;

  /// No description provided for @presupuestoTipoCerrado.
  ///
  /// In es, this message translates to:
  /// **'Precio cerrado'**
  String get presupuestoTipoCerrado;

  /// No description provided for @presupuestoTipoPorHoras.
  ///
  /// In es, this message translates to:
  /// **'Por horas'**
  String get presupuestoTipoPorHoras;

  /// No description provided for @presupuestoDialogoMontoHint.
  ///
  /// In es, this message translates to:
  /// **'Importe (€)'**
  String get presupuestoDialogoMontoHint;

  /// No description provided for @presupuestoDialogoTarifaHint.
  ///
  /// In es, this message translates to:
  /// **'Tarifa por hora (€)'**
  String get presupuestoDialogoTarifaHint;

  /// No description provided for @presupuestoDialogoHorasEstimadasHint.
  ///
  /// In es, this message translates to:
  /// **'Horas estimadas'**
  String get presupuestoDialogoHorasEstimadasHint;

  /// No description provided for @presupuestoDialogoMensajeHint.
  ///
  /// In es, this message translates to:
  /// **'Mensaje para el cliente (opcional)'**
  String get presupuestoDialogoMensajeHint;

  /// No description provided for @presupuestoDialogoIncluyeIva.
  ///
  /// In es, this message translates to:
  /// **'Este presupuesto incluye IVA'**
  String get presupuestoDialogoIncluyeIva;

  /// No description provided for @presupuestoEnviadoExito.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto enviado'**
  String get presupuestoEnviadoExito;

  /// No description provided for @presupuestoEnviadoError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el presupuesto'**
  String get presupuestoEnviadoError;

  /// No description provided for @seguimientoEsperandoPresupuesto.
  ///
  /// In es, this message translates to:
  /// **'Esperando el presupuesto del profesional'**
  String get seguimientoEsperandoPresupuesto;

  /// No description provided for @seguimientoPresupuestoTitulo.
  ///
  /// In es, this message translates to:
  /// **'El profesional ha enviado un presupuesto'**
  String get seguimientoPresupuestoTitulo;

  /// No description provided for @seguimientoPresupuestoCerradoDetalle.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto: {monto} €'**
  String seguimientoPresupuestoCerradoDetalle(String monto);

  /// No description provided for @seguimientoPresupuestoPorHorasDetalle.
  ///
  /// In es, this message translates to:
  /// **'{tarifa} €/hora × {horas} horas estimadas — importe máximo autorizado: {total} €'**
  String seguimientoPresupuestoPorHorasDetalle(
      String tarifa, String horas, String total);

  /// No description provided for @seguimientoPresupuestoAceptar.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get seguimientoPresupuestoAceptar;

  /// No description provided for @seguimientoPresupuestoRechazar.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get seguimientoPresupuestoRechazar;

  /// No description provided for @seguimientoPresupuestoRechazarConfirmar.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres rechazar este presupuesto? El profesional podrá enviarte uno nuevo.'**
  String get seguimientoPresupuestoRechazarConfirmar;

  /// No description provided for @seguimientoPresupuestoAceptadoExito.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto aceptado — ya puedes autorizar el pago'**
  String get seguimientoPresupuestoAceptadoExito;

  /// No description provided for @seguimientoPresupuestoRechazadoExito.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto rechazado'**
  String get seguimientoPresupuestoRechazadoExito;

  /// No description provided for @seguimientoPresupuestoRechazadoInfo.
  ///
  /// In es, this message translates to:
  /// **'Rechazaste el presupuesto anterior — esperando uno nuevo del profesional'**
  String get seguimientoPresupuestoRechazadoInfo;

  /// No description provided for @seguimientoPresupuestoError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo responder al presupuesto'**
  String get seguimientoPresupuestoError;

  /// No description provided for @seguimientoDesgloseComision.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto: {base} € + gastos de gestión: {comision} € = total a pagar: {total} €'**
  String seguimientoDesgloseComision(
      String base, String comision, String total);

  /// No description provided for @seguimientoPromoLanzamiento.
  ///
  /// In es, this message translates to:
  /// **'🎉 Promoción de lanzamiento'**
  String get seguimientoPromoLanzamiento;

  /// No description provided for @desglosePagoPresupuestoLabel.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto'**
  String get desglosePagoPresupuestoLabel;

  /// No description provided for @desglosePagoGastosGestionLabel.
  ///
  /// In es, this message translates to:
  /// **'Gastos de gestión'**
  String get desglosePagoGastosGestionLabel;

  /// No description provided for @desglosePagoGastosGestionInfo.
  ///
  /// In es, this message translates to:
  /// **'Los gastos de gestión incluyen la verificación de identidad del profesional, el pago protegido hasta la finalización del trabajo y el soporte de Hogar SOS en caso de incidencias.'**
  String get desglosePagoGastosGestionInfo;

  /// No description provided for @desglosePagoTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get desglosePagoTotalLabel;

  /// No description provided for @desglosePagoIvaIncluido.
  ///
  /// In es, this message translates to:
  /// **'El profesional declara que este importe incluye IVA'**
  String get desglosePagoIvaIncluido;

  /// No description provided for @desglosePagoIvaNoIncluido.
  ///
  /// In es, this message translates to:
  /// **'El profesional declara que este importe no incluye IVA'**
  String get desglosePagoIvaNoIncluido;

  /// No description provided for @trabajosActivosHorasEnviadasExito.
  ///
  /// In es, this message translates to:
  /// **'Horas enviadas — esperando que el cliente las confirme'**
  String get trabajosActivosHorasEnviadasExito;

  /// No description provided for @trabajosActivosPedirAmpliacionTitulo.
  ///
  /// In es, this message translates to:
  /// **'Pedir más horas'**
  String get trabajosActivosPedirAmpliacionTitulo;

  /// No description provided for @trabajosActivosPedirAmpliacionHorasHint.
  ///
  /// In es, this message translates to:
  /// **'Horas adicionales'**
  String get trabajosActivosPedirAmpliacionHorasHint;

  /// No description provided for @trabajosActivosPedirAmpliacionError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar la petición de ampliación'**
  String get trabajosActivosPedirAmpliacionError;

  /// No description provided for @trabajosActivosPedirAmpliacionExito.
  ///
  /// In es, this message translates to:
  /// **'Ampliación enviada'**
  String get trabajosActivosPedirAmpliacionExito;

  /// No description provided for @trabajosActivosPedirAmpliacion.
  ///
  /// In es, this message translates to:
  /// **'Pedir más horas'**
  String get trabajosActivosPedirAmpliacion;

  /// No description provided for @trabajosActivosAmpliacionEsperando.
  ///
  /// In es, this message translates to:
  /// **'Esperando respuesta a tu petición de más horas'**
  String get trabajosActivosAmpliacionEsperando;

  /// No description provided for @trabajosActivosCierreEsperando.
  ///
  /// In es, this message translates to:
  /// **'Esperando que el cliente confirme las horas'**
  String get trabajosActivosCierreEsperando;

  /// No description provided for @trabajosActivosAmpliarPresupuesto.
  ///
  /// In es, this message translates to:
  /// **'Ampliar presupuesto'**
  String get trabajosActivosAmpliarPresupuesto;

  /// No description provided for @trabajosActivosAmpliarPresupuestoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Ampliar presupuesto'**
  String get trabajosActivosAmpliarPresupuestoTitulo;

  /// No description provided for @trabajosActivosAmpliarPresupuestoMontoHint.
  ///
  /// In es, this message translates to:
  /// **'Importe adicional (€)'**
  String get trabajosActivosAmpliarPresupuestoMontoHint;

  /// No description provided for @trabajosActivosAmpliacionMotivoHint.
  ///
  /// In es, this message translates to:
  /// **'Motivo (opcional)'**
  String get trabajosActivosAmpliacionMotivoHint;

  /// No description provided for @trabajosActivosEstadoSinPresupuesto.
  ///
  /// In es, this message translates to:
  /// **'Sin presupuesto'**
  String get trabajosActivosEstadoSinPresupuesto;

  /// No description provided for @trabajosActivosEstadoPresupuestoPendiente.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get trabajosActivosEstadoPresupuestoPendiente;

  /// No description provided for @trabajosActivosEstadoPresupuestoAceptado.
  ///
  /// In es, this message translates to:
  /// **'Aceptado'**
  String get trabajosActivosEstadoPresupuestoAceptado;

  /// No description provided for @trabajosActivosEstadoEnCurso.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get trabajosActivosEstadoEnCurso;

  /// No description provided for @trabajosActivosEstadoAmpliacionPendiente.
  ///
  /// In es, this message translates to:
  /// **'Ampliación pendiente'**
  String get trabajosActivosEstadoAmpliacionPendiente;

  /// No description provided for @trabajosActivosEstadoCierrePendiente.
  ///
  /// In es, this message translates to:
  /// **'Confirmación pendiente'**
  String get trabajosActivosEstadoCierrePendiente;

  /// No description provided for @trabajosActivosEstadoPagoLiberado.
  ///
  /// In es, this message translates to:
  /// **'Pago liberado'**
  String get trabajosActivosEstadoPagoLiberado;

  /// No description provided for @trabajosActivosDesgloseComision.
  ///
  /// In es, this message translates to:
  /// **'Importe del trabajo: {base} € · Gastos de gestión: {comision} € · Recibirás: {recibiras} €'**
  String trabajosActivosDesgloseComision(
      String base, String comision, String recibiras);

  /// No description provided for @trabajosActivosPromoLanzamiento.
  ///
  /// In es, this message translates to:
  /// **'✅ Sin gastos de gestión para ti'**
  String get trabajosActivosPromoLanzamiento;

  /// No description provided for @seguimientoAmpliacionAceptadaExito.
  ///
  /// In es, this message translates to:
  /// **'Ampliación aceptada'**
  String get seguimientoAmpliacionAceptadaExito;

  /// No description provided for @seguimientoAmpliacionRechazadaExito.
  ///
  /// In es, this message translates to:
  /// **'Ampliación rechazada'**
  String get seguimientoAmpliacionRechazadaExito;

  /// No description provided for @seguimientoAmpliacionError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo responder a la ampliación'**
  String get seguimientoAmpliacionError;

  /// No description provided for @seguimientoAmpliacionTitulo.
  ///
  /// In es, this message translates to:
  /// **'El profesional necesita más tiempo'**
  String get seguimientoAmpliacionTitulo;

  /// No description provided for @seguimientoAmpliacionTituloMonto.
  ///
  /// In es, this message translates to:
  /// **'El profesional pide ampliar el presupuesto'**
  String get seguimientoAmpliacionTituloMonto;

  /// No description provided for @seguimientoAmpliacionDetalle.
  ///
  /// In es, this message translates to:
  /// **'{horas} horas adicionales — importe adicional: {importe} €'**
  String seguimientoAmpliacionDetalle(String horas, String importe);

  /// No description provided for @seguimientoAmpliacionMontoDetalle.
  ///
  /// In es, this message translates to:
  /// **'Importe adicional: {importe} €'**
  String seguimientoAmpliacionMontoDetalle(String importe);

  /// No description provided for @seguimientoCierreHorasConfirmadoExito.
  ///
  /// In es, this message translates to:
  /// **'Horas confirmadas — pago liberado'**
  String get seguimientoCierreHorasConfirmadoExito;

  /// No description provided for @seguimientoCierreHorasError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo responder al cierre de horas'**
  String get seguimientoCierreHorasError;

  /// No description provided for @seguimientoCierreHorasTitulo.
  ///
  /// In es, this message translates to:
  /// **'El profesional ha terminado el trabajo'**
  String get seguimientoCierreHorasTitulo;

  /// No description provided for @seguimientoCierreHorasLabelEstimadas.
  ///
  /// In es, this message translates to:
  /// **'Horas estimadas'**
  String get seguimientoCierreHorasLabelEstimadas;

  /// No description provided for @seguimientoCierreHorasLabelReales.
  ///
  /// In es, this message translates to:
  /// **'Horas realizadas'**
  String get seguimientoCierreHorasLabelReales;

  /// No description provided for @seguimientoCierreHorasLabelTarifa.
  ///
  /// In es, this message translates to:
  /// **'Tarifa'**
  String get seguimientoCierreHorasLabelTarifa;

  /// No description provided for @seguimientoCierreHorasLabelImporte.
  ///
  /// In es, this message translates to:
  /// **'Importe final'**
  String get seguimientoCierreHorasLabelImporte;

  /// No description provided for @seguimientoCierreHorasAvisoReduccion.
  ///
  /// In es, this message translates to:
  /// **'Las horas declaradas son un {porcentaje}% de lo estimado. Revisa el importe antes de confirmar.'**
  String seguimientoCierreHorasAvisoReduccion(String porcentaje);

  /// No description provided for @seguimientoCierreHorasDialogoTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Confirmar esta reducción?'**
  String get seguimientoCierreHorasDialogoTitulo;

  /// No description provided for @seguimientoCierreHorasDialogoDetalle.
  ///
  /// In es, this message translates to:
  /// **'El profesional declaró {reales} h reales frente a las {estimadas} h estimadas ({porcentaje}%). Si confirmas, se cobrará solo el importe de las horas reales y se liberará el resto de lo retenido en tu tarjeta.'**
  String seguimientoCierreHorasDialogoDetalle(
      String reales, String estimadas, String porcentaje);

  /// No description provided for @seguimientoCierreHorasDialogoCancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get seguimientoCierreHorasDialogoCancelar;

  /// No description provided for @seguimientoCierreHorasDialogoConfirmar.
  ///
  /// In es, this message translates to:
  /// **'Confirmar de todas formas'**
  String get seguimientoCierreHorasDialogoConfirmar;

  /// No description provided for @seguimientoCierreHorasReclamar.
  ///
  /// In es, this message translates to:
  /// **'Reclamar'**
  String get seguimientoCierreHorasReclamar;

  /// No description provided for @seguimientoCierreHorasConfirmar.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get seguimientoCierreHorasConfirmar;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
