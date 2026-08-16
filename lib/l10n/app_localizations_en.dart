// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hogar SOS';

  @override
  String get navInicio => 'Home';

  @override
  String get navBuscar => 'Search';

  @override
  String get navMensajes => 'Messages';

  @override
  String get navPerfil => 'Profile';

  @override
  String get navDisponibilidad => 'Status';

  @override
  String get navSolicitudesCercanas => 'Requests';

  @override
  String get navCentroPagos => 'Wallet';

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
  String get loginRecuperarEmailRequerido =>
      'Enter your email so we can send you the link';

  @override
  String get loginModoEmail => 'Email';

  @override
  String get loginModoTelefono => 'Phone';

  @override
  String get loginFieldTelefono => 'Phone number';

  @override
  String get loginTelefonoAyuda =>
      'Include your country code, e.g. +34612345678';

  @override
  String get loginBtnEnviarCodigo => 'Send code';

  @override
  String get otpTitulo => 'Verify your number';

  @override
  String otpDescripcion(String telefono) {
    return 'We sent a 6-digit code by SMS to $telefono';
  }

  @override
  String get otpFieldCodigo => '6-digit code';

  @override
  String get otpBtnConfirmar => 'Confirm';

  @override
  String get otpReenviarCodigo => 'Resend code';

  @override
  String get otpCodigoReenviado => 'Code resent';

  @override
  String get otpCambiarNumero => 'Change number';

  @override
  String get errorConexion =>
      'Couldn\'t connect to the server. Check your connection.';

  @override
  String get errorServidorLento => 'The server took too long to respond.';

  @override
  String get errorInesperado => 'Something went wrong.';

  @override
  String montoConSimbolo(String monto) {
    return '€$monto';
  }

  @override
  String get authErrorEmailEnUso =>
      'An account with this email already exists. Try signing in, or use \"Forgot your password?\" if you don\'t remember it.';

  @override
  String get authErrorEmailInvalido => 'That email address isn\'t valid.';

  @override
  String get authErrorPasswordDebil =>
      'Your password is too weak (minimum 6 characters).';

  @override
  String get authErrorCredencialesIncorrectas => 'Incorrect email or password.';

  @override
  String get authErrorDemasiadosIntentos =>
      'Too many attempts. Please wait a moment before trying again.';

  @override
  String get authErrorTelefonoInvalido =>
      'That phone number isn\'t valid. Include your country code (e.g. +1).';

  @override
  String get authErrorCodigoIncorrecto =>
      'That code isn\'t correct. Check the SMS and try again.';

  @override
  String get authErrorCodigoCaducado =>
      'That code has expired. Request a new one.';

  @override
  String get authErrorCuotaSms =>
      'You\'ve reached the SMS code limit. Please try again later.';

  @override
  String get apiErrDatosInvalidos => 'Invalid data';

  @override
  String get apiErrSinPermiso => 'You don\'t have permission for this action';

  @override
  String get apiErrTokenInvalido =>
      'Your session has expired. Please log in again.';

  @override
  String get apiErrMotivoRechazoRequerido => 'A rejection requires a reason';

  @override
  String get apiErrProfesionalNoEncontrado => 'Professional not found';

  @override
  String get apiErrVerificacionNoPendiente =>
      'This professional doesn\'t have a pending verification';

  @override
  String get apiErrDisputaNoEncontrada => 'Dispute not found';

  @override
  String get apiErrDisputaResuelta => 'This dispute has already been resolved';

  @override
  String get apiErrResolucionStripeFallida =>
      'The resolution couldn\'t be applied to the payment. Please try again or contact support.';

  @override
  String get apiErrAmpliacionDatosInvalidos => 'Invalid extension data';

  @override
  String get apiErrDatosContactoBloqueados =>
      'For safety, contact details can only be shared once the job has been accepted';

  @override
  String get apiErrSolicitudNoEncontrada => 'Request not found';

  @override
  String get apiErrNoEresProfesionalAsignado =>
      'You\'re not the professional assigned to this request';

  @override
  String get apiErrEstadoInvalidoAmpliacion =>
      'This request isn\'t in a valid state to request an extension';

  @override
  String get apiErrSinPresupuestoAceptado =>
      'There\'s no accepted budget for this request';

  @override
  String get apiErrHorasAdicionalesRequeridas => 'Enter the additional hours';

  @override
  String get apiErrImporteAdicionalRequerido => 'Enter the additional amount';

  @override
  String get apiErrAmpliacionYaPendiente =>
      'There\'s already an extension awaiting a response';

  @override
  String get apiErrDecisionAmpliacionRequerida =>
      'Please indicate whether you accept or reject the extension';

  @override
  String get apiErrSinAccesoSolicitud =>
      'You don\'t have access to this request';

  @override
  String get apiErrAmpliacionNoEncontrada => 'Extension not found';

  @override
  String get apiErrAmpliacionNoPendiente =>
      'This extension is no longer awaiting a response';

  @override
  String get apiErrUsuarioYaExiste =>
      'An account with this email or phone number already exists';

  @override
  String get apiErrSinCuenta =>
      'There\'s no account associated with this. Please sign up first.';

  @override
  String get apiErrCuentaDesactivada => 'This account has been disabled';

  @override
  String get apiErrReclamacionSoloTrabajoAceptado =>
      'You can only report a problem on an accepted job';

  @override
  String get apiErrReclamacionYaAbierta =>
      'There\'s already an open dispute for this job';

  @override
  String get apiErrSolicitudNoAceptada =>
      'The request must be accepted by a professional before paying';

  @override
  String get apiErrNadaPendienteAutorizar =>
      'There\'s nothing pending authorization for this request';

  @override
  String get apiErrNoEresCliente => 'You\'re not the customer for this request';

  @override
  String get apiErrNoAutorizadoPostular =>
      'You\'re not authorized to apply to requests';

  @override
  String get apiErrSolicitudNoDisponible =>
      'This request is no longer available';

  @override
  String get apiErrCandidaturaYaEnviada =>
      'You\'ve already applied to this request';

  @override
  String get apiErrCandidaturaNoEncontrada => 'Application not found';

  @override
  String get apiErrPresupuestoDatosInvalidos => 'Invalid budget data';

  @override
  String get apiErrEstadoInvalidoPresupuesto =>
      'This request isn\'t in a valid state to submit a budget';

  @override
  String get apiErrPresupuestoYaPendiente =>
      'There\'s already a budget awaiting a response for this request';

  @override
  String get apiErrDecisionPresupuestoRequerida =>
      'Please indicate whether you accept or reject the budget';

  @override
  String get apiErrPresupuestoNoEncontrado => 'Budget not found';

  @override
  String get apiErrPresupuestoNoPendiente =>
      'This budget is no longer awaiting a response';

  @override
  String get apiErrPerfilProfesionalNoEncontrado =>
      'Professional profile not found';

  @override
  String get apiErrProfesionalNoVerificado =>
      'You can\'t set yourself as available until you\'re verified';

  @override
  String get apiErrCuentaStripeNoConfigurada =>
      'You can\'t set yourself as available until you set up your payout account';

  @override
  String get apiErrCategoriasInvalidas =>
      'One or more categories aren\'t valid';

  @override
  String get apiErrParametrosBusquedaInvalidos => 'Invalid search parameters';

  @override
  String get apiErrValorarSoloCompletado =>
      'You can only rate a service that\'s already completed';

  @override
  String get apiErrValoracionBloqueadaDisputa =>
      'There\'s an open dispute — you can\'t leave a rating until it\'s resolved';

  @override
  String get apiErrSinProfesionalAsignado =>
      'This request doesn\'t have a professional assigned';

  @override
  String get apiErrNoParticipaste =>
      'You didn\'t take part in this request, so you can\'t rate it';

  @override
  String get apiErrYaValoraste => 'You\'ve already rated this request';

  @override
  String get apiErrFechaRequerida => 'Enter the desired date';

  @override
  String get apiErrCategoriaInvalida => 'Invalid service category';

  @override
  String get apiErrCuentaNoVerificada =>
      'Your account hasn\'t been verified yet';

  @override
  String get apiErrSoloCreadorCancela =>
      'Only the customer who created this request can cancel it';

  @override
  String get apiErrNoSePuedeCancelar =>
      'This request can no longer be canceled — the professional has already started, or it\'s already been resolved';

  @override
  String get apiErrTrabajoEnCursoUsaDisputa =>
      'The professional has already marked this job as in progress — to cancel it now, open a dispute';

  @override
  String get apiErrSoloCreadorBorra =>
      'Only the customer who created this request can delete it';

  @override
  String get apiErrNoSePuedeBorrar =>
      'Only requests that no one has accepted yet can be deleted';

  @override
  String get apiErrNoSePuedeArchivar =>
      'Only completed or canceled requests can be archived';

  @override
  String get apiErrMensajeRequerido => 'The message text is missing';

  @override
  String get apiErrEstadoInvalidoCompletar =>
      'This request isn\'t in a valid state to be completed';

  @override
  String get apiErrPagoNoAutorizado =>
      'The customer hasn\'t authorized payment for this service yet';

  @override
  String get apiErrHorasRequeridas => 'Enter the actual hours worked';

  @override
  String get apiErrCierreYaPendiente =>
      'There\'s already a closing report awaiting the customer\'s confirmation';

  @override
  String get apiErrDecisionHorasRequerida =>
      'Please indicate whether you accept or reject the reported hours';

  @override
  String get apiErrCierreNoEncontrado => 'Closing report not found';

  @override
  String get apiErrCierreNoPendiente =>
      'This closing report is no longer awaiting a response';

  @override
  String get apiErrHorasDemasiadoBajas => 'The reported hours are too low';

  @override
  String get apiErrConfirmacionReduccionRequerida =>
      'This reduction is much lower than estimated — please confirm it explicitly';

  @override
  String get apiErrSinArchivo => 'No file was received';

  @override
  String get apiErrUsuarioNoEncontrado => 'User not found';

  @override
  String get apiErrPagoAtascadoNoEncontrado =>
      'There\'s no pending authorization to release for this request';

  @override
  String get apiErrLiberacionEnCurso =>
      'A release is already in progress for this request. Wait a few seconds and try again.';

  @override
  String get apiErrPagoNoAutorizadoTodavia =>
      'The customer never confirmed the payment. Retrying won\'t fix this: they need to authorize it again in the app.';

  @override
  String get apiErrProfesionalSinCuentaStripe =>
      'The professional hasn\'t completed Stripe Connect onboarding';

  @override
  String get apiErrCuentaStripeNoOperativa =>
      'Stripe doesn\'t enable payments for this professional yet (verification pending)';

  @override
  String get apiErrReintentoStripeFallido =>
      'The retry failed on Stripe. The payment is still recoverable: try again.';

  @override
  String get apiErrTareaNoEncontrada => 'Job not found';

  @override
  String get apiErrTareaYaEnCurso => 'This job is already running right now';

  @override
  String get apiErrTareaFallida =>
      'The job failed. Check the details before retrying.';

  @override
  String get apiErrAdminNoPuedeAutoBloquearse =>
      'You can\'t change the status of your own account';

  @override
  String get apiErrUltimoAdminActivo =>
      'You can\'t deactivate the only active administrator';

  @override
  String get apiErrCuentaEliminadaNoReactivable =>
      'This account was deleted by the user and can\'t be reactivated';

  @override
  String get legalPrivSec1Titulo => '1. Who processes your data';

  @override
  String get legalPrivSec1Texto =>
      'Hogar SOS is an app that connects customers with home-service professionals. We\'re the data controller for the personal data the app collects, as described in this policy.';

  @override
  String get legalPrivSec2Titulo => '2. What data we collect';

  @override
  String get legalPrivSec2Texto =>
      '• Account data: name, email, and phone number when you sign up.\n• Location: your approximate or precise location (with your permission), to show you nearby professionals, or so a professional shows up in searches from customers near them.\n• Photos: any you attach to a service request or your profile.\n• Verification documents (professionals only): ID document, certifications, and liability insurance, used solely to verify your identity and suitability before you can operate on the platform.\n• Payment data: handled directly by Stripe, our payment processor — Hogar SOS never stores your full card number.\n• Chat messages between the customer and professional on a given request.';

  @override
  String get legalPrivSec3Titulo => '3. What we use your data for';

  @override
  String get legalPrivSec3Texto =>
      'To provide the service (connecting customers with professionals, processing payments, managing requests), to verify professionals\' identities, to send you notifications related to your requests, and to prevent fraud and resolve disputes.';

  @override
  String get legalPrivSec4Titulo => '4. Who we share your data with';

  @override
  String get legalPrivSec4Texto =>
      'With the other party on a request (the customer sees the assigned professional\'s name, and vice versa). With providers that help us run the app: Firebase/Google (authentication, notifications, chat) and Stripe (payments). We don\'t sell your data to third parties or use it for advertising outside the app.';

  @override
  String get legalPrivSec5Titulo => '5. How long we keep your data';

  @override
  String get legalPrivSec5Texto =>
      'For as long as your account is active. If you delete it, we erase or anonymize your personal data, except what we\'re legally required to retain (e.g. payment records).';

  @override
  String get legalPrivSec6Titulo => '6. Your rights';

  @override
  String get legalPrivSec6Texto =>
      'You can access, correct, or delete your account and personal data at any time from Profile → Delete account, or by visiting hogarsos.es/eliminar-cuenta if you don\'t have access to the app. You can also withdraw location, camera, or photo library permissions at any time from your phone\'s settings.';

  @override
  String get legalPrivSec7Titulo => '7. Changes to this policy';

  @override
  String get legalPrivSec7Texto =>
      'If we make a material update to this policy, we\'ll notify you in the app before it takes effect.';

  @override
  String get legalTerminosSec1Titulo => '1. What Hogar SOS is';

  @override
  String get legalTerminosSec1Texto =>
      'Hogar SOS is a platform that connects customers who need a home service (electrical, plumbing, cleaning, etc.) with independent professionals who provide them. Hogar SOS doesn\'t perform the services itself and isn\'t the professionals\' employer — it acts as an intermediary between both parties.';

  @override
  String get legalTerminosSec2Titulo => '2. User accounts';

  @override
  String get legalTerminosSec2Texto =>
      'You must provide accurate information when you sign up. You\'re responsible for keeping your account secure. Professionals must complete a verification process (ID document and, where applicable, certifications/insurance) before they can accept requests.';

  @override
  String get legalTerminosSec3Titulo => '3. Payments and management fee';

  @override
  String get legalTerminosSec3Texto =>
      'Payment for a service is authorized through Stripe when the job is accepted, but isn\'t charged until the professional marks the service as completed. Hogar SOS applies a management fee on the price of the service, which covers verifying the professional\'s identity, protecting your payment until the job is finished, and Hogar SOS support if any issue comes up; the rest is transferred to the professional. Prices are set by the professional or agreed between both parties over chat.';

  @override
  String get legalTerminosSec4Titulo => '4. Cancellations and refunds';

  @override
  String get legalTerminosSec4Texto =>
      'The customer can cancel a request at no cost while it\'s still pending or was just accepted and work hasn\'t started yet. If a payment was already authorized, it\'s automatically refunded on cancellation. Once the professional marks the service as \"in progress\", it can no longer be canceled from the app — in that case, contact us to sort it out.';

  @override
  String get legalTerminosSec5Titulo => '5. Disputes';

  @override
  String get legalTerminosSec5Texto =>
      'If something didn\'t go as expected, either the customer or the professional can open a dispute. An admin reviews the case and decides whether the payment is released to the professional or refunded to the customer.';

  @override
  String get legalTerminosSec6Titulo => '6. Liability';

  @override
  String get legalTerminosSec6Texto =>
      'Hogar SOS facilitates contact and payment between customer and professional, but doesn\'t oversee or guarantee the quality of the work performed — the service relationship is directly between both parties. We recommend checking a professional\'s ratings before hiring them.';

  @override
  String get legalTerminosSec7Titulo => '7. Professional conduct';

  @override
  String get legalTerminosSec7Texto =>
      'Verified professionals must perform the service with the diligence and skill expected of their trade. Hogar SOS may suspend or revoke an account that repeatedly receives negative ratings, breaches these terms, or whose verification turns out to be fraudulent.';

  @override
  String get legalTerminosSec8Titulo => '8. Changes to these terms';

  @override
  String get legalTerminosSec8Texto =>
      'We may update these terms; material changes will be announced in the app before they take effect. Continuing to use Hogar SOS after a change means you accept it.';

  @override
  String get legalTerminosSec9Titulo => '9. Governing law';

  @override
  String get legalTerminosSec9Texto =>
      'These terms are governed by the laws of Spain.';

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
  String get homeMisSolicitudesSinActivas =>
      'View history and ongoing requests';

  @override
  String get homeSubtitulo => 'What do you need fixed today?';

  @override
  String get homeBuscarPlaceholder => 'Search for a professional or service...';

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
  String get homeErrorUbicacion =>
      'We need your location to find professionals nearby';

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
  String get perfilMiembroDesde => 'Hogar SOS member';

  @override
  String get perfilConfirmarSalir => 'Are you sure you want to sign out?';

  @override
  String get perfilCancelar => 'Cancel';

  @override
  String get perfilEliminarCuenta => 'Delete account';

  @override
  String get perfilEliminarCuentaConfirmarTitulo => 'Delete your account?';

  @override
  String get perfilEliminarCuentaConfirmarTexto =>
      'This can\'t be undone. You\'ll lose access immediately, and your name, email, phone, photo and, if you\'re a professional, your verification documents will be deleted.';

  @override
  String get perfilEliminarCuentaBotonConfirmar => 'Yes, delete my account';

  @override
  String get perfilEliminarCuentaError =>
      'We couldn\'t delete your account. Please try again.';

  @override
  String get perfilFavoritos => 'Favorites';

  @override
  String get perfilMisSolicitudes => 'My requests';

  @override
  String get perfilConfiguracion => 'Settings';

  @override
  String get perfilPrivacidad => 'Privacy policy';

  @override
  String get perfilTerminos => 'Terms of service';

  @override
  String get perfilEmailSinVerificarTitulo => 'Verify your email';

  @override
  String get perfilEmailSinVerificarDescripcion =>
      'We sent you a confirmation link. Check your inbox (and spam folder).';

  @override
  String get perfilEmailSinVerificarReenviar => 'Resend email';

  @override
  String get perfilEmailSinVerificarYaConfirme => 'I already confirmed it';

  @override
  String get perfilEmailVerificacionReenviada => 'Verification email resent';

  @override
  String get perfilEmailAunNoVerificado =>
      'We still don\'t see it. If you just confirmed it, wait a few seconds and try again.';

  @override
  String get perfilEmailVerificadoExito => 'Email verified!';

  @override
  String get legalPrivacidadTitulo => 'Privacy policy';

  @override
  String get legalTerminosTitulo => 'Terms of service';

  @override
  String get legalAceptacionPrefijo =>
      'By creating an account, you agree to the ';

  @override
  String get legalAceptacionY => ' and the ';

  @override
  String get pagoAceptacionTerminos =>
      'By continuing, you agree to the Terms of service and cancellation policy';

  @override
  String get proximamenteTitulo => 'Coming soon';

  @override
  String get buscarProximamenteDescripcion =>
      'Advanced search with price, distance and rating filters is coming in the next phase.';

  @override
  String get mensajesProximamenteDescripcion =>
      'This is where you\'ll see all your conversations with customers and professionals.';

  @override
  String get mensajesVacioTitulo => 'No conversations yet';

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
    return 'From €$precio';
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
      'For now, new requests are sent to all available professionals near you, not to one specific professional';

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
  String get categoriaInstalacionCristales => 'Glass installation';

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
  String get categoriaPetSitter => 'Pet sitter';

  @override
  String get categoriaTecnicoTelefonia => 'Phone technician';

  @override
  String get categoriaMasajes => 'Home massage';

  @override
  String get categoriaManicuraPedicura => 'Manicure & pedicure';

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
  String get wizardEjemploInstalacionCristales =>
      'E.g.: a window pane is broken...';

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
  String get wizardEjemploPetSitter =>
      'E.g.: I need someone to look after my dog this weekend...';

  @override
  String get wizardEjemploTecnicoTelefonia =>
      'E.g.: my phone screen is cracked...';

  @override
  String get wizardEjemploMasajes =>
      'E.g.: I\'d like a one-hour relaxing massage at home...';

  @override
  String get wizardEjemploManicuraPedicura =>
      'E.g.: I\'d like a full manicure and pedicure at home...';

  @override
  String get profesionalTituloSolicitudes => 'Requests near you';

  @override
  String get profesionalDisponibleAhoraAviso =>
      'You\'re available: new requests can reach you';

  @override
  String get profesionalChipDisponible => 'Available';

  @override
  String get profesionalChipNoDisponible => 'Not available';

  @override
  String profesionalEstadoLinea(String estado) {
    return 'Your status · $estado';
  }

  @override
  String get salirPulsaOtraVez => 'Press back again to exit';

  @override
  String get profesionalSinSolicitudes => 'No requests nearby right now';

  @override
  String get profesionalErrorCargar => 'Couldn\'t load requests';

  @override
  String get profesionalIgnorar => 'Ignore';

  @override
  String get profesionalErrorIgnorar => 'Couldn\'t ignore the request';

  @override
  String get profesionalAceptar => 'Accept';

  @override
  String get profesionalSolicitudAceptada =>
      'Request accepted. The customer will authorize payment.';

  @override
  String get profesionalYaNoDisponible =>
      'Couldn\'t accept — it may no longer be available';

  @override
  String get profesionalPostularme => 'Send application';

  @override
  String get profesionalYaPostulado => 'Application sent';

  @override
  String get profesionalPostulacionEnviada =>
      'Application sent — the customer will choose among interested professionals';

  @override
  String get profesionalPostulacionMensajeObligatorio =>
      'Let the customer know when you\'re available before submitting your application';

  @override
  String get profesionalDisponibilidadTitulo => 'When can you do this job?';

  @override
  String get profesionalDisponibilidadSubtitulo =>
      'The customer will see this on your application, along with your photo and rating';

  @override
  String get profesionalDisponibilidadHint =>
      'E.g.: I can come tomorrow afternoon...';

  @override
  String get profesionalDisponibilidadSugerencia1 =>
      'I can come tomorrow afternoon';

  @override
  String get profesionalDisponibilidadSugerencia2 =>
      'I\'m available Friday at 10:00';

  @override
  String get profesionalDisponibilidadSugerencia3 =>
      'I can come by this afternoon';

  @override
  String get profesionalDisponibilidadConfirmar => 'Send application';

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
  String trabajosActivosTeEligieron(String categoria) {
    return 'You\'ve been selected for $categoria! It\'s now in Active jobs.';
  }

  @override
  String get trabajosActivosVerTrabajo => 'View job';

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
  String get trabajosActivosIniciarTrabajo => 'Start job';

  @override
  String get trabajosActivosIniciarTrabajoConfirmarTitulo => 'Start this job?';

  @override
  String get trabajosActivosIniciarTrabajoConfirmarTexto =>
      'From now on the client won\'t be able to cancel it directly — if needed, they\'ll have to open a dispute.';

  @override
  String get trabajosActivosIniciarTrabajoExito => 'Job started';

  @override
  String get trabajosActivosIniciarTrabajoError => 'Couldn\'t start the job';

  @override
  String get trabajosActivosDeshacerInicio => 'Undo start';

  @override
  String get trabajosActivosDeshacerInicioExito => 'Start undone';

  @override
  String get trabajosActivosDeshacerInicioError => 'Couldn\'t undo the start';

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
  String get profesionalPonerseDisponibleBoton => 'Get available';

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
  String get disponibilidadPendienteStripe =>
      'Set up your payout account with Stripe to be able to go online — without it you wouldn\'t be able to get paid for jobs you accept.';

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
  String get disponibilidadOpcionDisponibleTitulo => 'Available';

  @override
  String get disponibilidadOpcionDisponibleAyuda =>
      'You\'ll receive new requests';

  @override
  String get seguimientoTitulo => 'Your request';

  @override
  String get seguimientoError => 'Couldn\'t load the request';

  @override
  String get seguimientoBuscando => 'Looking for a professional near you...';

  @override
  String get seguimientoAceptada => 'A professional has accepted your request!';

  @override
  String get seguimientoEnProgreso => 'In progress';

  @override
  String get seguimientoCompletada => 'Service completed';

  @override
  String get seguimientoCancelada => 'Request canceled';

  @override
  String get seguimientoCancelarTitulo => 'Cancel request';

  @override
  String get seguimientoCancelarConfirmar =>
      'Are you sure you want to cancel this request? This can\'t be undone.';

  @override
  String get seguimientoCancelarExito => 'Request canceled successfully';

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
      'You won\'t show up in customer searches until you add:';

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
  String get miPerfilPrecioLabel => 'Price per hour (€) — optional';

  @override
  String get miPerfilPrecioAyuda =>
      'The real price of each job is agreed on a quote. This is only used for the price filter in the client\'s search.';

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
  String get miPerfilVerificacionTitulo => 'Verification';

  @override
  String get miPerfilVerificacionEstadoAprobado =>
      'Verified — you can now accept jobs.';

  @override
  String get miPerfilVerificacionEstadoPendiente =>
      'Under review. We\'ll let you know once an admin approves it.';

  @override
  String get miPerfilVerificacionEstadoRechazado =>
      'Verification rejected. Fix the document or your rate, then resubmit.';

  @override
  String get miPerfilVerificacionEstadoSinEnviar =>
      'You haven\'t submitted your ID document yet — without it you won\'t be able to accept jobs.';

  @override
  String get miPerfilDocumentoIdentidadLabel => 'ID document';

  @override
  String get miPerfilDocumentoSeleccionar => 'Select document';

  @override
  String get miPerfilEnviarVerificacion => 'Submit for verification';

  @override
  String get miPerfilVerificacionExito =>
      'Documentation submitted. An admin will review it soon.';

  @override
  String get miPerfilVerificacionErrorFaltaDocumento =>
      'Upload your ID document first';

  @override
  String get miPerfilVerificacionErrorFaltaTarifa => 'Enter a valid base rate';

  @override
  String get miPerfilVerificacionErrorEnvio => 'Couldn\'t submit verification';

  @override
  String get tipoProfesionalTitulo => 'Professional type';

  @override
  String get tipoProfesionalAutonomo => 'Self-employed';

  @override
  String get tipoProfesionalEmpresa => 'Company';

  @override
  String get tipoProfesionalPersonaFisica => 'Private individual';

  @override
  String get tipoProfesionalTextoLegal =>
      'Select the option that best describes your current situation. You are responsible for complying with the tax and labor laws applicable in your country in order to provide services and receive payments. HogarSOS acts solely as an intermediary platform and does not provide tax or legal advice.';

  @override
  String get tipoProfesionalErrorFaltaSeleccion =>
      'Select your professional type';

  @override
  String get cuentaCobroTitulo => 'Payout account';

  @override
  String get cuentaCobroEstadoConfigurada =>
      'Set up — you can now receive payments.';

  @override
  String get cuentaCobroEstadoPendiente =>
      'Set up your payout account with Stripe to get paid for your jobs.';

  @override
  String get cuentaCobroEstadoRequiereActualizacion =>
      'Stripe needs more information to be able to pay you. Complete it to keep getting paid.';

  @override
  String get cuentaCobroBotonConfigurar => 'Set up payout account';

  @override
  String get cuentaCobroBotonActualizar => 'Update on Stripe';

  @override
  String get cuentaCobroBotonEditar => 'Edit payout account';

  @override
  String get cuentaCobroErrorAbrir =>
      'Couldn\'t open Stripe. Please try again.';

  @override
  String get cuentaCobroStripeActualizando =>
      'Updating your payout account status…';

  @override
  String get cuentaCobroStripeCaducado =>
      'The Stripe link expired. Tap \"Set up payout account\" to try again.';

  @override
  String get centroPagosTitulo => 'Payments Center';

  @override
  String get centroPagosErrorCargar =>
      'Couldn\'t load your payments information';

  @override
  String get centroPagosPendiente => 'Pending';

  @override
  String get centroPagosPendienteAyuda =>
      'Released payouts Stripe is still processing before they become available.';

  @override
  String get centroPagosDisponible => 'Available';

  @override
  String get centroPagosDisponibleAyuda =>
      'Balance Stripe can already transfer to your bank account.';

  @override
  String get centroPagosHistorialTitulo => 'Payout history';

  @override
  String get centroPagosHistorialVacio =>
      'You don\'t have any released payouts yet.';

  @override
  String centroPagosImporte(String monto) {
    return '€$monto';
  }

  @override
  String centroPagosPagoDe(String nombre) {
    return 'Payment from $nombre';
  }

  @override
  String get miPerfilStatValoracion => 'Rating';

  @override
  String get miPerfilStatTrabajos => 'Jobs';

  @override
  String get miPerfilStatTarifa => 'Rate';

  @override
  String get miPerfilStatEstado => 'Status';

  @override
  String get miPerfilEstadoAprobado => 'Approved';

  @override
  String get miPerfilEstadoPendiente => 'Pending';

  @override
  String get miPerfilEstadoRechazado => 'Rejected';

  @override
  String get miPerfilEstadoSinEnviar => 'Not submitted';

  @override
  String get miPerfilTelefonoVacio => 'Add your phone number';

  @override
  String get miPerfilDescripcionVacia =>
      'Add a short description so clients get to know you better';

  @override
  String get miPerfilCambiar => 'Change';

  @override
  String get miPerfilEditar => 'Edit';

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
  String get distintivoVerificado => 'Identity verified';

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
  String get chatContactoBloqueado =>
      'For your safety, contact details can only be shared once the job has been accepted.';

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
  String get pagoCancelado => 'You canceled the payment';

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
  String get misSolicitudesBorrarTitulo => 'Delete this request?';

  @override
  String get misSolicitudesBorrarMensaje =>
      'It will be removed from your history. This can\'t be undone.';

  @override
  String get misSolicitudesBorrarConfirmar => 'Delete';

  @override
  String get misSolicitudesBorrarExito => 'Request deleted';

  @override
  String get misSolicitudesBorrarError => 'Couldn\'t delete the request';

  @override
  String get misSolicitudesArchivarTitulo =>
      'Remove this request from the list?';

  @override
  String get misSolicitudesArchivarMensaje =>
      'It will be hidden from your history, but the payment, chat, and reviews are kept.';

  @override
  String get misSolicitudesArchivarConfirmar => 'Remove';

  @override
  String get misSolicitudesArchivarExito => 'Request removed from the list';

  @override
  String get misSolicitudesArchivarError => 'Couldn\'t remove the request';

  @override
  String get misSolicitudesAccionRequerida => 'Needs your confirmation';

  @override
  String get trabajosActivosArchivarTitulo => 'Remove this job from the list?';

  @override
  String get trabajosActivosArchivarMensaje =>
      'It will be hidden from your history, but the payment, chat, and reviews are kept.';

  @override
  String get trabajosActivosArchivarConfirmar => 'Remove';

  @override
  String get trabajosActivosArchivarExito => 'Job removed from the list';

  @override
  String get trabajosActivosArchivarError => 'Couldn\'t remove the job';

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
  String get wizardErrorFotosSubiendo =>
      'Wait for the photos to finish uploading';

  @override
  String get fotoErrorSubir => 'Couldn\'t upload the photo. Please try again.';

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
  String get ubicacionAvisoNoDetectada =>
      'We couldn\'t detect your GPS location — move the map to your area before confirming';

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
  String get adminVerDocumento => 'View ID document';

  @override
  String get adminDocumentoSinEnviar => 'No ID document submitted';

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

  @override
  String get adminTabPagosAtascados => 'Stuck payments';

  @override
  String get adminPagosAtascadosVacio => 'No stuck payments';

  @override
  String get adminPagosAtascadosError => 'Couldn\'t load stuck payments';

  @override
  String adminPagosAtascadosResumen(int total, String importe) {
    return 'Total: $total · Held on the platform: €$importe';
  }

  @override
  String get adminPagoAtascadoCapturadoSinTransferir =>
      'Captured, not yet transferred to the professional';

  @override
  String get adminPagoAtascadoCompletadoSinCapturar =>
      'Job completed, authorization not captured';

  @override
  String adminPagoAtascadoAutorizadoEl(String fecha) {
    return 'Authorized on $fecha';
  }

  @override
  String adminPagoAtascadoCapturadoEl(String fecha) {
    return 'Captured on $fecha';
  }

  @override
  String adminPagoAtascadoIntentos(int n) {
    return 'Release attempts: $n';
  }

  @override
  String adminPagoAtascadoUltimoError(String error) {
    return 'Last error: $error';
  }

  @override
  String get adminPagoAtascadoSinProfesional => 'No professional assigned';

  @override
  String adminContracargoBadge(String estado, String monto) {
    return '⚠️ Stripe chargeback: $estado, $monto €';
  }

  @override
  String get adminContracargoVerEnStripe => 'View in Stripe';

  @override
  String get adminContracargoBloqueaReintento => 'Blocked by dispute';

  @override
  String get adminContracargoErrorAbrirStripe => 'Couldn\'t open Stripe';

  @override
  String get adminReintentarLiberacion => 'Retry release';

  @override
  String get adminReintentarLiberacionConfirmarTitulo => 'Retry release?';

  @override
  String get adminReintentarLiberacionConfirmarTexto =>
      'This will try to capture and transfer this payment again. It\'s safe to repeat even if it\'s already in progress or partially done.';

  @override
  String get adminReintentarLiberacionExito => 'Release completed successfully';

  @override
  String get adminTabTareas => 'Scheduled jobs';

  @override
  String get adminTareasVacio => 'No scheduled jobs';

  @override
  String get adminTareasError => 'Couldn\'t load scheduled jobs';

  @override
  String get adminTareaEnCurso => 'Running';

  @override
  String adminTareaCada(int n) {
    return 'Every $n min';
  }

  @override
  String adminTareaUltimaEjecucion(String fecha) {
    return 'Last run: $fecha';
  }

  @override
  String get adminTareaNuncaEjecutada => 'Never run yet';

  @override
  String adminTareaProximaEjecucion(String fecha) {
    return 'Next run (approx.): $fecha';
  }

  @override
  String adminTareaEjecuciones(int n) {
    return 'Runs: $n';
  }

  @override
  String adminTareaFallosConsecutivos(int n) {
    return 'Consecutive failures: $n';
  }

  @override
  String adminTareaUltimoResultado(String texto) {
    return 'Last result: $texto';
  }

  @override
  String adminTareaUltimoError(String texto) {
    return 'Last error: $texto';
  }

  @override
  String get adminEjecutarAhora => 'Run now';

  @override
  String get adminEjecutarAhoraConfirmarTitulo => 'Run this job now?';

  @override
  String get adminEjecutarAhoraConfirmarTexto =>
      'This will force it to run without waiting for its next cycle. If it\'s already running, it won\'t be duplicated.';

  @override
  String get adminEjecutarAhoraExito => 'Job ran successfully';

  @override
  String get adminTabUsuarios => 'Users';

  @override
  String get adminUsuarioIdLabel => 'User ID';

  @override
  String get adminUsuarioIdHint => 'Paste or type the ID (UUID)';

  @override
  String get adminUsuarioBuscarBoton => 'Search';

  @override
  String get adminUsuarioBusquedaError => 'Couldn\'t find the user';

  @override
  String get adminUsuarioEstadoActivo => 'Active';

  @override
  String get adminUsuarioEstadoBloqueado => 'Blocked';

  @override
  String get adminUsuarioCuentaEliminada =>
      'This account was deleted by the user themselves (GDPR) — it can\'t be reactivated.';

  @override
  String get adminUsuarioBloquear => 'Block';

  @override
  String get adminUsuarioActivar => 'Activate';

  @override
  String get adminUsuarioBloquearConfirmarTitulo => 'Block this user?';

  @override
  String get adminUsuarioBloquearConfirmarTexto =>
      'They won\'t be able to sign in until you activate them again.';

  @override
  String get adminUsuarioActivarConfirmarTitulo => 'Activate this user?';

  @override
  String get adminUsuarioActivarConfirmarTexto =>
      'They\'ll be able to sign in normally again.';

  @override
  String get adminUsuarioCambioExito => 'Status updated successfully';

  @override
  String get reportarProblemaTitulo => 'Report a problem';

  @override
  String get reportarProblemaMotivoLabel => 'What happened?';

  @override
  String get reportarProblemaMotivoProfesionalNoPresento =>
      'The professional didn\'t show up';

  @override
  String get reportarProblemaMotivoClienteAusente =>
      'The customer wasn\'t at the address';

  @override
  String get reportarProblemaMotivoTrabajoCancelado => 'The job was canceled';

  @override
  String get reportarProblemaMotivoProblemaPago => 'Payment issue';

  @override
  String get reportarProblemaMotivoComportamiento => 'Inappropriate behavior';

  @override
  String get reportarProblemaMotivoOtro => 'Other';

  @override
  String get reportarProblemaDescripcionLabel => 'Describe what happened';

  @override
  String get reportarProblemaDescripcionHint =>
      'Tell us in detail what happened';

  @override
  String get reportarProblemaFotosLabel => 'Photos (optional)';

  @override
  String get reportarProblemaEnviar => 'Send report';

  @override
  String get reportarProblemaExito => 'Report sent — our team will review it';

  @override
  String get reportarProblemaError => 'Couldn\'t send the report';

  @override
  String get reportarProblemaBoton => 'Report a problem';

  @override
  String seguimientoVerCandidatos(int n) {
    return 'See candidates ($n)';
  }

  @override
  String get seleccionarProfesionalTitulo => 'Choose professional';

  @override
  String get seleccionarProfesionalElegir => 'Choose professional';

  @override
  String get seleccionarProfesionalConfirmarTitulo => 'Confirm your choice?';

  @override
  String seleccionarProfesionalConfirmarTexto(String nombre) {
    return '$nombre will be assigned to this job. The other candidates will be declined.';
  }

  @override
  String get seleccionarProfesionalError =>
      'Couldn\'t complete the selection. Someone else may have already chosen.';

  @override
  String get seleccionarProfesionalVacio =>
      'No applications received yet — check back later';

  @override
  String get trabajosActivosEnviarPresupuesto => 'Send quote';

  @override
  String get trabajosActivosPresupuestoEsperando =>
      'Waiting for the customer\'s response';

  @override
  String get trabajosActivosHorasRealesTitulo => 'Actual hours worked';

  @override
  String trabajosActivosHorasRealesTarifa(String tarifa) {
    return 'Agreed rate: €$tarifa/hour';
  }

  @override
  String get trabajosActivosHorasRealesHint => 'Hours';

  @override
  String get trabajosActivosCompletarCerradoConfirmar =>
      'Is the job complete? The agreed payment will be released.';

  @override
  String get presupuestoDialogoTitulo => 'Send quote';

  @override
  String get presupuestoTipoCerrado => 'Fixed price';

  @override
  String get presupuestoTipoPorHoras => 'Hourly rate';

  @override
  String get presupuestoDialogoMontoHint => 'Amount (€)';

  @override
  String get presupuestoDialogoTarifaHint => 'Rate per hour (€)';

  @override
  String get presupuestoDialogoHorasEstimadasHint => 'Estimated hours';

  @override
  String get presupuestoDialogoMensajeHint =>
      'Message for the customer (optional)';

  @override
  String get presupuestoDialogoIncluyeIva => 'This quote includes VAT';

  @override
  String get presupuestoEnviadoExito => 'Quote sent';

  @override
  String get presupuestoEnviadoError => 'Couldn\'t send the quote';

  @override
  String get seguimientoEsperandoPresupuesto =>
      'Waiting for the professional\'s quote';

  @override
  String get seguimientoPresupuestoTitulo =>
      'The professional has sent a quote';

  @override
  String seguimientoPresupuestoCerradoDetalle(String monto) {
    return 'Quote: €$monto';
  }

  @override
  String seguimientoPresupuestoPorHorasDetalle(
      String tarifa, String horas, String total) {
    return '€$tarifa/hour × $horas estimated hours — maximum authorized amount: €$total';
  }

  @override
  String get seguimientoPresupuestoAceptar => 'Accept';

  @override
  String get seguimientoPresupuestoRechazar => 'Decline';

  @override
  String get seguimientoPresupuestoRechazarConfirmar =>
      'Are you sure you want to decline this quote? The professional will be able to send a new one.';

  @override
  String get seguimientoPresupuestoAceptadoExito =>
      'Quote accepted — you can now authorize payment';

  @override
  String get seguimientoPresupuestoRechazadoExito => 'Quote declined';

  @override
  String get seguimientoPresupuestoRechazadoInfo =>
      'You declined the previous quote — waiting for a new one from the professional';

  @override
  String get seguimientoPresupuestoError => 'Couldn\'t respond to the quote';

  @override
  String seguimientoDesgloseComision(
      String base, String comision, String total) {
    return 'Quote: €$base + management fee: €$comision = total to pay: €$total';
  }

  @override
  String get seguimientoPromoLanzamiento => '🎉 Launch promotion';

  @override
  String get desglosePagoPresupuestoLabel => 'Quote';

  @override
  String get desglosePagoGastosGestionLabel => 'Management fee';

  @override
  String get desglosePagoGastosGestionInfo =>
      'The management fee covers verifying the professional\'s identity, protecting your payment until the job is finished, and Hogar SOS support if any issue comes up.';

  @override
  String get desglosePagoTotalLabel => 'Total';

  @override
  String get desglosePagoIvaIncluido =>
      'The professional states this amount includes VAT';

  @override
  String get desglosePagoIvaNoIncluido =>
      'The professional states this amount does not include VAT';

  @override
  String get trabajosActivosHorasEnviadasExito =>
      'Hours sent — waiting for the customer to confirm them';

  @override
  String get trabajosActivosPedirAmpliacionTitulo => 'Ask for more hours';

  @override
  String get trabajosActivosPedirAmpliacionHorasHint => 'Additional hours';

  @override
  String get trabajosActivosPedirAmpliacionError =>
      'Couldn\'t send the extension request';

  @override
  String get trabajosActivosPedirAmpliacionExito => 'Extension request sent';

  @override
  String get trabajosActivosPedirAmpliacion => 'Ask for more hours';

  @override
  String get trabajosActivosAmpliacionEsperando =>
      'Waiting for a response to your extension request';

  @override
  String get trabajosActivosCierreEsperando =>
      'Waiting for the customer to confirm the hours';

  @override
  String get trabajosActivosAmpliarPresupuesto => 'Extend budget';

  @override
  String get trabajosActivosAmpliarPresupuestoTitulo => 'Extend budget';

  @override
  String get trabajosActivosAmpliarPresupuestoMontoHint =>
      'Additional amount (€)';

  @override
  String get trabajosActivosAmpliacionMotivoHint => 'Reason (optional)';

  @override
  String get trabajosActivosEstadoSinPresupuesto => 'No budget';

  @override
  String get trabajosActivosEstadoPresupuestoPendiente => 'Pending';

  @override
  String get trabajosActivosEstadoPresupuestoAceptado => 'Accepted';

  @override
  String get trabajosActivosEstadoEnCurso => 'In progress';

  @override
  String get trabajosActivosEstadoAmpliacionPendiente => 'Extension pending';

  @override
  String get trabajosActivosEstadoCierrePendiente => 'Confirmation pending';

  @override
  String get trabajosActivosEstadoPagoLiberado => 'Payment released';

  @override
  String trabajosActivosDesgloseComision(
      String base, String comision, String recibiras) {
    return 'Job amount: €$base · Management fee: €$comision · You\'ll receive: €$recibiras';
  }

  @override
  String get trabajosActivosPromoLanzamiento => '✅ No management fee for you';

  @override
  String get seguimientoAmpliacionAceptadaExito => 'Extension accepted';

  @override
  String get seguimientoAmpliacionRechazadaExito => 'Extension declined';

  @override
  String get seguimientoAmpliacionError =>
      'Couldn\'t respond to the extension request';

  @override
  String get seguimientoAmpliacionTitulo => 'The professional needs more time';

  @override
  String get seguimientoAmpliacionTituloMonto =>
      'The professional is requesting a budget extension';

  @override
  String seguimientoAmpliacionDetalle(String horas, String importe) {
    return '$horas more hours — additional amount: €$importe';
  }

  @override
  String seguimientoAmpliacionMontoDetalle(String importe) {
    return 'Additional amount: €$importe';
  }

  @override
  String get seguimientoCierreHorasConfirmadoExito =>
      'Hours confirmed — payment released';

  @override
  String get seguimientoCierreHorasError =>
      'Couldn\'t respond to the hours closure';

  @override
  String get seguimientoCierreHorasTitulo =>
      'The professional has finished the job';

  @override
  String get seguimientoCierreHorasLabelEstimadas => 'Estimated hours';

  @override
  String get seguimientoCierreHorasLabelReales => 'Actual hours';

  @override
  String get seguimientoCierreHorasLabelTarifa => 'Rate';

  @override
  String get seguimientoCierreHorasLabelImporte => 'Final amount';

  @override
  String seguimientoCierreHorasAvisoReduccion(String porcentaje) {
    return 'The reported hours are $porcentaje% of what was estimated. Review the amount before confirming.';
  }

  @override
  String get seguimientoCierreHorasDialogoTitulo => 'Confirm this reduction?';

  @override
  String seguimientoCierreHorasDialogoDetalle(
      String reales, String estimadas, String porcentaje) {
    return 'The professional reported $reales actual hours vs. $estimadas estimated hours ($porcentaje%). If you confirm, only the amount for the actual hours will be charged and the rest of the hold on your card will be released.';
  }

  @override
  String get seguimientoCierreHorasDialogoCancelar => 'Cancel';

  @override
  String get seguimientoCierreHorasDialogoConfirmar => 'Confirm anyway';

  @override
  String get seguimientoCierreHorasReclamar => 'Report a problem';

  @override
  String get seguimientoCierreHorasConfirmar => 'Confirm';
}
