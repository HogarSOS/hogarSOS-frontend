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
  /// **'hogarSOS'**
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
  /// **'Miembro de hogarSOS'**
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

  /// No description provided for @categoriaCristaleria.
  ///
  /// In es, this message translates to:
  /// **'Cristalería'**
  String get categoriaCristaleria;

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

  /// No description provided for @categoriaVeterinaria.
  ///
  /// In es, this message translates to:
  /// **'Veterinaria a domicilio'**
  String get categoriaVeterinaria;

  /// No description provided for @categoriaTecnicoTelefonia.
  ///
  /// In es, this message translates to:
  /// **'Técnico de telefonía'**
  String get categoriaTecnicoTelefonia;

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

  /// No description provided for @wizardEjemploCristaleria.
  ///
  /// In es, this message translates to:
  /// **'Ej: se ha roto el cristal de una ventana...'**
  String get wizardEjemploCristaleria;

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

  /// No description provided for @wizardEjemploVeterinaria.
  ///
  /// In es, this message translates to:
  /// **'Ej: mi perro necesita una revisión a domicilio...'**
  String get wizardEjemploVeterinaria;

  /// No description provided for @wizardEjemploTecnicoTelefonia.
  ///
  /// In es, this message translates to:
  /// **'Ej: se me ha roto la pantalla del móvil...'**
  String get wizardEjemploTecnicoTelefonia;

  /// No description provided for @profesionalTituloSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes cerca de ti'**
  String get profesionalTituloSolicitudes;

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
  /// **'Aceptar solicitud'**
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
  /// **'El profesional está trabajando en tu solicitud'**
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
  /// **'Precio por hora (€)'**
  String get miPerfilPrecioLabel;

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
  /// **'Profesional verificado'**
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
