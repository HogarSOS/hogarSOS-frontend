// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'hogarSOS';

  @override
  String get navInicio => 'Home';

  @override
  String get navBuscar => 'Search';

  @override
  String get navMensajes => 'Messages';

  @override
  String get navPerfil => 'Profile';

  @override
  String get navDisponibilidad => 'Availability';

  @override
  String get loginTagline => 'Trusted home services';

  @override
  String get loginFieldNombre => 'Full name';

  @override
  String get loginFieldEmail => 'Email';

  @override
  String get loginFieldPassword => 'Password';

  @override
  String get loginRecordarSesion => 'Keep me signed in';

  @override
  String get loginRoleCliente => 'Customer';

  @override
  String get loginRoleProfesional => 'Professional';

  @override
  String get loginBtnCrearCuenta => 'Create account';

  @override
  String get loginBtnIniciarSesion => 'Sign in';

  @override
  String get loginLinkYaTienesCuenta => 'Already have an account? Sign in';

  @override
  String get loginLinkNoTienesCuenta => 'Don\'t have an account? Sign up';

  @override
  String get loginOlvidasteContrasena => 'Forgot your password?';

  @override
  String get loginCamposObligatorios => 'Fill in all fields';

  @override
  String get loginRecuperarTitulo => 'Reset password';

  @override
  String get loginRecuperarEnviar => 'Send link';

  @override
  String get loginRecuperarExito =>
      'If an account exists with that email, we\'ve sent a password reset link';

  @override
  String get errorConexion =>
      'Couldn\'t connect to the server. Check your connection.';

  @override
  String get errorServidorLento => 'The server took too long to respond.';

  @override
  String get errorInesperado => 'Something went wrong.';

  @override
  String homeSaludo(String nombre) {
    return 'Hi, $nombre 👋';
  }

  @override
  String get homeSaludoGenerico => 'Hi 👋';

  @override
  String homeSaludoManana(String nombre) {
    return 'Good morning, $nombre ☀️';
  }

  @override
  String homeSaludoTarde(String nombre) {
    return 'Good afternoon, $nombre 👋';
  }

  @override
  String homeSaludoNoche(String nombre) {
    return 'Good evening, $nombre 🌙';
  }

  @override
  String get homeAccesoBuscar => 'Search';

  @override
  String get homeAccesoMisSolicitudes => 'My requests';

  @override
  String get homeAccesoFavoritos => 'Favorites';

  @override
  String homeResumenActivas(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: 'requests',
      one: 'request',
    );
    return 'You have $cantidad active $_temp0';
  }

  @override
  String get homeSubtitulo => 'What do you need fixed today?';

  @override
  String get homeBuscarPlaceholder => 'Search for a pro or service...';

  @override
  String get homeCategoriasTitulo => 'Categories';

  @override
  String get homeCategoriasError => 'Couldn\'t load categories';

  @override
  String get homeSolicitarProfesional => '📢 Request a professional';

  @override
  String get homeSolicitarProfesionalAyuda =>
      'Tell us what you need and we\'ll connect you';

  @override
  String get homeDescribeProblema => 'Describe the problem';

  @override
  String get homeErrorDescribe => 'Please describe the problem briefly';

  @override
  String get homeErrorUbicacion => 'We need your location to find pros nearby';

  @override
  String get homeErrorCrearSolicitud =>
      'Couldn\'t create the request. Please try again.';

  @override
  String get homeBtnBuscarProfesionales => 'Find professionals';

  @override
  String homeSolicitudCreada(String id) {
    return 'Request created (#$id)';
  }

  @override
  String get homeBusquedaProximamente =>
      'Advanced search: coming in the next phase';

  @override
  String get perfilCerrarSesion => 'Sign out';

  @override
  String get perfilRolCliente => 'Customer';

  @override
  String get perfilRolProfesional => 'Professional';

  @override
  String get perfilRolAdmin => 'Administrator';

  @override
  String get perfilMiembroDesde => 'hogarSOS member';

  @override
  String get perfilConfirmarSalir => 'Are you sure you want to sign out?';

  @override
  String get perfilCancelar => 'Cancel';

  @override
  String get perfilFavoritos => 'Favorites';

  @override
  String get perfilMisSolicitudes => 'My requests';

  @override
  String get perfilConfiguracion => 'Settings';

  @override
  String get proximamenteTitulo => 'Coming soon';

  @override
  String get buscarProximamenteDescripcion =>
      'Advanced search with price, distance and rating filters is coming in the next phase.';

  @override
  String get mensajesProximamenteDescripcion =>
      'This is where you\'ll see all your conversations with customers and professionals.';

  @override
  String get buscarHint => 'Search by name...';

  @override
  String get buscarFiltros => 'Filters';

  @override
  String get buscarTodasCategorias => 'All';

  @override
  String get buscarSinResultadosTitulo => 'No professionals found';

  @override
  String get buscarSinResultadosDescripcion =>
      'Try changing the filters or your search';

  @override
  String get buscarErrorTitulo => 'Search couldn\'t be completed';

  @override
  String buscarDesde(String precio) {
    return 'From $precio €';
  }

  @override
  String buscarTrabajos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'jobs',
      one: 'job',
    );
    return '$n $_temp0';
  }

  @override
  String get buscarDisponibleAhora => 'Available now';

  @override
  String get buscarNoDisponible => 'Not available';

  @override
  String get buscarUrgente => 'Urgent';

  @override
  String get buscarUrgenteTitulo => 'What do you need urgently?';

  @override
  String get filtroValoracionMinima => 'Minimum rating';

  @override
  String get filtroPrecioMaximo => 'Maximum price';

  @override
  String get filtroDistanciaMaxima => 'Maximum distance';

  @override
  String get filtroLimpiar => 'Clear';

  @override
  String get filtroAplicar => 'Apply filters';

  @override
  String get filtroCualquiera => 'Any';

  @override
  String get filtroSoloDisponibles => 'Available now';

  @override
  String get perfilProOpinionesTitulo => 'Reviews';

  @override
  String opinionesTotal(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'reviews',
      one: 'review',
    );
    return '$n $_temp0';
  }

  @override
  String get misValoracionesTitulo => 'My reviews';

  @override
  String get misValoracionesError => 'Couldn\'t load your reviews';

  @override
  String get perfilProSinOpiniones => 'No reviews yet';

  @override
  String get perfilProGaleriaTitulo => 'Work gallery';

  @override
  String get perfilProSinGaleria =>
      'This professional hasn\'t uploaded any work photos yet';

  @override
  String get perfilProServiciosTitulo => 'Services offered';

  @override
  String get perfilProSolicitarBtn => 'Request this service';

  @override
  String get perfilProCargandoError => 'Couldn\'t load this profile';

  @override
  String get perfilProSolicitarInfo =>
      'For now, requests go out to available professionals near you from Home, not to one specific pro yet';

  @override
  String get categoriaElectricista => 'Electrician';

  @override
  String get categoriaFontanero => 'Plumber';

  @override
  String get categoriaPintor => 'Painter';

  @override
  String get categoriaManitas => 'Handyman';

  @override
  String get categoriaLimpieza => 'Cleaning';

  @override
  String get categoriaJardineria => 'Gardening';

  @override
  String get categoriaCerrajeria => 'Locksmith';

  @override
  String get categoriaReformas => 'Renovations';

  @override
  String get categoriaAireAcondicionado => 'Air conditioning & HVAC';

  @override
  String get categoriaCarpinteria => 'Carpentry';

  @override
  String get categoriaAlbanileria => 'Masonry';

  @override
  String get categoriaTejados => 'Roofing';

  @override
  String get categoriaCristaleria => 'Glazing';

  @override
  String get categoriaCarpinteriaMetalica => 'Metalwork / Aluminum & PVC';

  @override
  String get categoriaAntenas => 'Antennas & telecom';

  @override
  String get categoriaSeguridad => 'Security systems';

  @override
  String get categoriaMudanzas => 'Moving services';

  @override
  String get categoriaLimpiezaCristales => 'Window cleaning';

  @override
  String get categoriaPiscinas => 'Pools';

  @override
  String get categoriaControlPlagas => 'Pest control';

  @override
  String get categoriaVeterinaria => 'Home veterinary services';

  @override
  String get wizardEjemploGenerico =>
      'E.g.: a pipe burst under the sink and it\'s leaking...';

  @override
  String get wizardEjemploElectricista =>
      'E.g.: the circuit breaker keeps tripping and won\'t reset...';

  @override
  String get wizardEjemploFontanero =>
      'E.g.: I have a leak under the kitchen sink...';

  @override
  String get wizardEjemploPintor =>
      'E.g.: I need my living room painted, about 20 m²...';

  @override
  String get wizardEjemploManitas => 'E.g.: I need some shelves assembled...';

  @override
  String get wizardEjemploLimpieza =>
      'E.g.: I need a full apartment cleaning...';

  @override
  String get wizardEjemploJardineria =>
      'E.g.: I need the hedge trimmed and the lawn mowed...';

  @override
  String get wizardEjemploCerrajeria =>
      'E.g.: I\'ve lost my keys and I\'m locked out...';

  @override
  String get wizardEjemploReformas =>
      'E.g.: I want to fully renovate my bathroom...';

  @override
  String get wizardEjemploAireAcondicionado =>
      'E.g.: my air conditioner isn\'t cooling...';

  @override
  String get wizardEjemploCarpinteria =>
      'E.g.: I need a custom-made wardrobe door...';

  @override
  String get wizardEjemploAlbanileria =>
      'E.g.: there\'s a crack in my living room wall...';

  @override
  String get wizardEjemploTejados => 'E.g.: I have a leak in my roof...';

  @override
  String get wizardEjemploCristaleria => 'E.g.: a window pane is broken...';

  @override
  String get wizardEjemploCarpinteriaMetalica =>
      'E.g.: I need a metal shutter repaired...';

  @override
  String get wizardEjemploAntenas =>
      'E.g.: I\'m not getting antenna signal on my TV...';

  @override
  String get wizardEjemploSeguridad =>
      'E.g.: I want to install a home alarm system...';

  @override
  String get wizardEjemploMudanzas =>
      'E.g.: I need help moving to a 2-bedroom apartment...';

  @override
  String get wizardEjemploLimpiezaCristales =>
      'E.g.: I need the windows cleaned on a third floor...';

  @override
  String get wizardEjemploPiscinas => 'E.g.: my pool water has turned green...';

  @override
  String get wizardEjemploControlPlagas =>
      'E.g.: I have cockroaches in my kitchen...';

  @override
  String get wizardEjemploVeterinaria =>
      'E.g.: my dog needs a checkup at home...';

  @override
  String get profesionalTituloSolicitudes => 'Requests near you';

  @override
  String get salirPulsaOtraVez => 'Press back again to exit';

  @override
  String get profesionalSinSolicitudes => 'No requests nearby right now';

  @override
  String get profesionalErrorCargar => 'Couldn\'t load requests';

  @override
  String get profesionalIgnorar => 'Ignore';

  @override
  String get profesionalAceptar => 'Accept';

  @override
  String get profesionalSolicitudAceptada =>
      'Request accepted. The customer will authorize payment.';

  @override
  String get profesionalYaNoDisponible =>
      'Couldn\'t accept — it may no longer be available';

  @override
  String profesionalDistanciaKm(String km) {
    return '$km km away';
  }

  @override
  String profesionalTrabajosActivos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'jobs',
      one: 'job',
    );
    return 'You have $n active $_temp0';
  }

  @override
  String get trabajosActivosTitulo => 'Active jobs';

  @override
  String get trabajosActivosVacio => 'You have no active jobs right now';

  @override
  String get trabajosActivosErrorCargar => 'Couldn\'t load your jobs';

  @override
  String get trabajosActivosChat => 'Chat';

  @override
  String get trabajosActivosCompletar => 'Mark as completed';

  @override
  String get trabajosActivosPrecioFinalTitulo => 'Final price of the service';

  @override
  String get trabajosActivosPrecioFinalHint => 'Price (€)';

  @override
  String get trabajosActivosPrecioFinalConfirmar => 'Confirm';

  @override
  String get trabajosActivosCompletadoExito => 'Service marked as completed';

  @override
  String get trabajosActivosCompletadoError => 'Couldn\'t complete the service';

  @override
  String get profesionalErrorDisponibilidad =>
      'Couldn\'t update your availability';

  @override
  String get profesionalDisponibleAyuda =>
      'You\'ll receive requests near your location';

  @override
  String get profesionalNoDisponibleAyuda =>
      'Turn it on to start receiving jobs';

  @override
  String get disponibilidadTitulo => 'Availability';

  @override
  String get disponibilidadEnLineaTitulo => 'Current status';

  @override
  String get disponibilidadModoTitulo => 'Availability mode';

  @override
  String get disponibilidadModoAyuda =>
      'Choose when you want to receive requests. You can change this anytime.';

  @override
  String get disponibilidadModoHorarioLaboral =>
      'Available during business hours';

  @override
  String get disponibilidadModoHorarioLaboralAyuda =>
      'You\'ll receive requests during your usual working hours';

  @override
  String get disponibilidadModo24h => '24-hour service';

  @override
  String get disponibilidadModo24hAyuda =>
      'You\'ll receive requests any time, day or night';

  @override
  String get disponibilidadModoActualizado => 'Availability mode updated';

  @override
  String get disponibilidadModoError =>
      'Couldn\'t update the availability mode';

  @override
  String get disponibilidadPerfilIncompleto =>
      'Complete your profile (photo and at least one category) before going online — that\'s how clients can find you.';

  @override
  String get disponibilidadPendienteVerificacion =>
      'Your account is pending review by an administrator. You\'ll be able to go online once it\'s approved.';

  @override
  String get disponibilidadCompletarPerfil => 'Complete profile';

  @override
  String get disponibilidadEstadoTitulo => 'Your availability';

  @override
  String get disponibilidadEstadoAyuda =>
      'Choose a single state — it determines if and when you receive requests.';

  @override
  String get disponibilidadOpcionNoDisponibleTitulo => 'Not available';

  @override
  String get disponibilidadOpcionNoDisponibleAyuda =>
      'You won\'t receive new requests';

  @override
  String get seguimientoTitulo => 'Your request';

  @override
  String get seguimientoError => 'Couldn\'t load the request';

  @override
  String get seguimientoBuscando => 'Looking for a professional near you...';

  @override
  String get seguimientoAceptada => 'A professional has accepted your request!';

  @override
  String get seguimientoEnProgreso =>
      'The professional is working on your request';

  @override
  String get seguimientoCompletada => 'Service completed';

  @override
  String get seguimientoCancelada => 'Request cancelled';

  @override
  String get seguimientoCancelarTitulo => 'Cancel request';

  @override
  String get seguimientoCancelarConfirmar =>
      'Are you sure you want to cancel this request? This can\'t be undone.';

  @override
  String get seguimientoCancelarExito => 'Request cancelled successfully';

  @override
  String get seguimientoCancelarError => 'Couldn\'t cancel the request';

  @override
  String get seguimientoDisputada => 'Under review by our support team';

  @override
  String get seguimientoAbrirChat => 'Open chat';

  @override
  String get editarPerfilTitulo => 'Edit profile';

  @override
  String get editarPerfilTelefono => 'Phone';

  @override
  String get perfilEditar => 'Edit profile';

  @override
  String get miPerfilTitulo => 'My profile';

  @override
  String get miPerfilIncompletoTitulo => 'Complete your profile';

  @override
  String get miPerfilIncompletoAyuda =>
      'You won\'t show up in client searches until you add:';

  @override
  String get miPerfilFaltaFoto => 'a profile photo';

  @override
  String get miPerfilFaltaCategoria => 'at least one category';

  @override
  String get miPerfilCambiarFoto => 'Change photo';

  @override
  String get miPerfilOficio => 'Main trade';

  @override
  String get miPerfilOficioSinAsignar => 'No category assigned yet';

  @override
  String get miPerfilDescripcionLabel => 'Description';

  @override
  String get miPerfilDescripcionAyuda => 'Maximum 250 characters';

  @override
  String get miPerfilPrecioLabel => 'Price per hour (€)';

  @override
  String get miPerfilDisponible => 'Available';

  @override
  String get miPerfilGuardar => 'Save changes';

  @override
  String get miPerfilExito => 'Profile updated successfully';

  @override
  String get miPerfilErrorGuardar => 'Couldn\'t save the changes';

  @override
  String get miPerfilErrorCargar => 'Couldn\'t load your profile';

  @override
  String get miPerfilCategoriasTitulo => 'Categories';

  @override
  String get miPerfilCategoriasEditar => 'Edit categories';

  @override
  String get miPerfilCategoriasVacia =>
      'You don\'t have any categories assigned yet';

  @override
  String get miPerfilCategoriasGuardar => 'Save';

  @override
  String get miPerfilCategoriasCancelar => 'Cancel';

  @override
  String get miPerfilCategoriasErrorMinimo => 'Select at least one category';

  @override
  String get miPerfilCategoriasExito => 'Categories updated';

  @override
  String get miPerfilCategoriasError => 'Couldn\'t update the categories';

  @override
  String get distintivoVerificado => 'Verified';

  @override
  String get homeVerTodasCategorias => 'See all categories';

  @override
  String get todasCategoriasTitulo => 'All categories';

  @override
  String get chatTitulo => 'Chat';

  @override
  String get chatSinMensajes => 'No messages yet';

  @override
  String get chatErrorCargar => 'Couldn\'t load the chat';

  @override
  String get chatErrorEnviar => 'Couldn\'t send the message';

  @override
  String get chatHint => 'Write a message...';

  @override
  String get seguimientoAutorizarPago => 'Authorize payment';

  @override
  String get seguimientoValorar => 'Rate service';

  @override
  String get seguimientoYaValorado => 'You\'ve already rated this service';

  @override
  String get seguimientoPagoRetenido =>
      'Payment authorized, pending service completion';

  @override
  String get seguimientoPagoLiberado => 'Payment completed';

  @override
  String get seguimientoPagoReembolsado => 'Payment refunded';

  @override
  String get seguimientoPagoFallido => 'Payment failed';

  @override
  String get pagoTitulo => 'Confirm and pay';

  @override
  String get pagoInfo =>
      'The amount is authorized now but only charged once the professional completes the service.';

  @override
  String get pagoBtnAutorizar => 'Authorize payment';

  @override
  String get pagoExito =>
      'Payment authorized. It will be charged when the service is completed.';

  @override
  String get pagoErrorGenerico =>
      'Couldn\'t process the payment. Please try again.';

  @override
  String get pagoErrorStripeDefault => 'The payment wasn\'t completed';

  @override
  String get valoracionTitulo => 'How was the service?';

  @override
  String get valoracionErrorSeleccion => 'Select a rating';

  @override
  String get valoracionErrorEnviar =>
      'Couldn\'t submit your rating. Please try again.';

  @override
  String get valoracionComentarioLabel => 'Comment (optional)';

  @override
  String get valoracionBtnEnviar => 'Submit rating';

  @override
  String get progresoBuscando => 'Finding professionals';

  @override
  String get progresoSeleccionado => 'Professional selected';

  @override
  String get progresoFinalizado => 'Job finished';

  @override
  String get misSolicitudesError => 'Couldn\'t load your requests';

  @override
  String get misSolicitudesVacio => 'You haven\'t made any requests yet';

  @override
  String get wizardTitulo => 'New request';

  @override
  String wizardPaso(int actual, int total) {
    return 'Step $actual of $total';
  }

  @override
  String get wizardSiguiente => 'Next';

  @override
  String get wizardPublicar => 'Publish request';

  @override
  String get wizardErrorCategoria => 'Choose a category to continue';

  @override
  String get wizardErrorDescripcion => 'Describe the job in a bit more detail';

  @override
  String get wizardErrorUbicacion => 'Choose where you need the service';

  @override
  String get wizardErrorFecha => 'Choose a date';

  @override
  String get wizardPaso1Titulo => 'What do you need?';

  @override
  String get wizardCategoriaCambiar => 'Change';

  @override
  String get wizardCategoriaElegirTitulo => 'Choose a category';

  @override
  String get wizardPaso2Titulo => 'Describe the job';

  @override
  String get wizardPaso2Ayuda =>
      'The more detail you give, the better professionals can help you';

  @override
  String get wizardPaso3Titulo => 'Add photos (optional)';

  @override
  String get wizardPaso3Ayuda =>
      'A photo helps the professional understand the problem before arriving';

  @override
  String get wizardFotoCamara => 'Take a photo';

  @override
  String get wizardFotoGaleria => 'Choose from gallery';

  @override
  String get wizardPaso4Titulo => 'Where is the job?';

  @override
  String get wizardPaso4Ayuda =>
      'We\'ll use this location to find professionals nearby';

  @override
  String get wizardUbicacionElegir => 'Choose on map';

  @override
  String get wizardUbicacionCambiar => 'Change location';

  @override
  String get wizardPaso5Titulo => 'When do you need it?';

  @override
  String get wizardUrgenciaAsap => 'As soon as possible';

  @override
  String get wizardUrgenciaHoy => 'Today';

  @override
  String get wizardUrgenciaManana => 'Tomorrow';

  @override
  String get wizardUrgenciaFecha => 'Choose a date';

  @override
  String get wizardSeleccionarFecha => 'Select date';

  @override
  String get wizardPaso6Titulo => 'Review your request';

  @override
  String get ubicacionTitulo => 'Choose location';

  @override
  String get ubicacionDireccionOpcional => 'Address or reference (optional)';

  @override
  String get ubicacionConfirmar => 'Confirm location';

  @override
  String get adminTituloPanel => 'Admin panel';

  @override
  String get adminTabVerificaciones => 'Verifications';

  @override
  String get adminTabDisputas => 'Disputes';

  @override
  String get adminVerificacionesVacio => 'No pending verifications';

  @override
  String get adminVerificacionesError => 'Couldn\'t load verifications';

  @override
  String get adminDisputasVacio => 'No open disputes';

  @override
  String get adminDisputasError => 'Couldn\'t load disputes';

  @override
  String adminCategoriasLabel(String categorias) {
    return 'Categories: $categorias';
  }

  @override
  String get adminRechazar => 'Reject';

  @override
  String get adminAprobar => 'Approve';

  @override
  String get adminFavorCliente => 'In favor of the customer';

  @override
  String get adminFavorProfesional => 'In favor of the professional';

  @override
  String get adminMotivoRechazoTitulo => 'Rejection reason';

  @override
  String get adminMotivoRechazoHint =>
      'Briefly explain why it\'s being rejected';

  @override
  String get adminMotivoRechazoAyuda =>
      'Minimum 5 characters — the professional will see this';

  @override
  String get adminNotasResolucionTitulo => 'Resolution notes';

  @override
  String get adminNotasResolucionHint => 'Briefly explain how it was resolved';

  @override
  String get adminNotasResolucionAyuda =>
      'Minimum 5 characters — this will be recorded on the dispute';

  @override
  String get adminConfirmar => 'Confirm';

  @override
  String get adminDecisionError =>
      'Couldn\'t record the decision. Please try again.';

  @override
  String get adminResolucionError =>
      'Couldn\'t record the resolution. Please try again.';
}
