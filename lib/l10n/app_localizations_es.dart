// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Hogar SOS';

  @override
  String get navInicio => 'Inicio';

  @override
  String get navBuscar => 'Buscar';

  @override
  String get navMensajes => 'Mensajes';

  @override
  String get navPerfil => 'Perfil';

  @override
  String get navDisponibilidad => 'Estado';

  @override
  String get navSolicitudesCercanas => 'Solicitudes';

  @override
  String get navCentroPagos => 'Pagos';

  @override
  String get loginTagline => 'Servicios a domicilio de confianza';

  @override
  String get loginFieldNombre => 'Nombre completo';

  @override
  String get loginFieldEmail => 'Email';

  @override
  String get loginFieldPassword => 'Contraseña';

  @override
  String get loginRecordarSesion => 'Mantener sesión iniciada';

  @override
  String get loginRoleCliente => 'Cliente';

  @override
  String get loginRoleProfesional => 'Profesional';

  @override
  String get loginBtnCrearCuenta => 'Crear cuenta';

  @override
  String get loginBtnIniciarSesion => 'Iniciar sesión';

  @override
  String get loginLinkYaTienesCuenta => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get loginLinkNoTienesCuenta => '¿No tienes cuenta? Regístrate';

  @override
  String get loginOlvidasteContrasena => '¿Olvidaste tu contraseña?';

  @override
  String get loginCamposObligatorios => 'Rellena todos los campos';

  @override
  String get loginRecuperarTitulo => 'Recuperar contraseña';

  @override
  String get loginRecuperarEnviar => 'Enviar enlace';

  @override
  String get loginRecuperarExito =>
      'Si existe una cuenta con ese email, te hemos enviado un enlace para restablecer la contraseña';

  @override
  String get loginRecuperarEmailRequerido =>
      'Indica tu email para poder enviarte el enlace';

  @override
  String get loginModoEmail => 'Email';

  @override
  String get loginModoTelefono => 'Teléfono';

  @override
  String get loginFieldTelefono => 'Teléfono';

  @override
  String get loginTelefonoAyuda =>
      'Incluye el prefijo de tu país, ej. +34612345678';

  @override
  String get loginBtnEnviarCodigo => 'Enviar código';

  @override
  String get otpTitulo => 'Verifica tu número';

  @override
  String otpDescripcion(String telefono) {
    return 'Te hemos enviado un código de 6 dígitos por SMS a $telefono';
  }

  @override
  String get otpFieldCodigo => 'Código de 6 dígitos';

  @override
  String get otpBtnConfirmar => 'Confirmar';

  @override
  String get otpReenviarCodigo => 'Reenviar código';

  @override
  String get otpCodigoReenviado => 'Código reenviado';

  @override
  String get otpCambiarNumero => 'Cambiar de número';

  @override
  String get errorConexion =>
      'No se pudo conectar con el servidor. Comprueba tu conexión.';

  @override
  String get errorServidorLento => 'El servidor tardó demasiado en responder.';

  @override
  String get errorInesperado => 'Ocurrió un error inesperado.';

  @override
  String montoConSimbolo(String monto) {
    return '$monto €';
  }

  @override
  String get authErrorEmailEnUso =>
      'Ya existe una cuenta con este email. Intenta iniciar sesión o usa \"¿Olvidaste tu contraseña?\" si no la recuerdas.';

  @override
  String get authErrorEmailInvalido => 'El email no tiene un formato válido.';

  @override
  String get authErrorPasswordDebil =>
      'La contraseña es demasiado débil (mínimo 6 caracteres).';

  @override
  String get authErrorCredencialesIncorrectas =>
      'Email o contraseña incorrectos.';

  @override
  String get authErrorDemasiadosIntentos =>
      'Demasiados intentos. Espera un momento antes de volver a intentarlo.';

  @override
  String get authErrorTelefonoInvalido =>
      'El número de teléfono no es válido. Escríbelo con el prefijo del país (ej. +34).';

  @override
  String get authErrorCodigoIncorrecto =>
      'El código no es correcto. Revisa el SMS e inténtalo de nuevo.';

  @override
  String get authErrorCodigoCaducado =>
      'El código ha caducado. Pide uno nuevo.';

  @override
  String get authErrorCuotaSms =>
      'Se alcanzó el límite de códigos por SMS. Inténtalo más tarde.';

  @override
  String get apiErrDatosInvalidos => 'Datos inválidos';

  @override
  String get apiErrSinPermiso => 'No tienes permiso para esta acción';

  @override
  String get apiErrTokenInvalido =>
      'Tu sesión ha caducado. Inicia sesión de nuevo.';

  @override
  String get apiErrMotivoRechazoRequerido =>
      'Un rechazo requiere indicar un motivo';

  @override
  String get apiErrProfesionalNoEncontrado => 'Profesional no encontrado';

  @override
  String get apiErrVerificacionNoPendiente =>
      'Este profesional no tiene una verificación pendiente';

  @override
  String get apiErrDisputaNoEncontrada => 'Reclamación no encontrada';

  @override
  String get apiErrDisputaResuelta => 'Esta reclamación ya fue resuelta';

  @override
  String get apiErrResolucionStripeFallida =>
      'La resolución no pudo aplicarse en el pago. Inténtalo de nuevo o contacta con soporte.';

  @override
  String get apiErrAmpliacionDatosInvalidos => 'Datos de ampliación inválidos';

  @override
  String get apiErrDatosContactoBloqueados =>
      'Por seguridad, los datos de contacto solo se pueden compartir cuando el trabajo haya sido aceptado';

  @override
  String get apiErrSolicitudNoEncontrada => 'Solicitud no encontrada';

  @override
  String get apiErrNoEresProfesionalAsignado =>
      'No eres el profesional asignado a esta solicitud';

  @override
  String get apiErrEstadoInvalidoAmpliacion =>
      'La solicitud no está en un estado válido para pedir una ampliación';

  @override
  String get apiErrSinPresupuestoAceptado =>
      'No hay un presupuesto aceptado para esta solicitud';

  @override
  String get apiErrHorasAdicionalesRequeridas => 'Indica las horas adicionales';

  @override
  String get apiErrImporteAdicionalRequerido => 'Indica el importe adicional';

  @override
  String get apiErrAmpliacionYaPendiente =>
      'Ya hay una ampliación pendiente de respuesta';

  @override
  String get apiErrDecisionAmpliacionRequerida =>
      'Indica si aceptas o rechazas la ampliación';

  @override
  String get apiErrSinAccesoSolicitud => 'No tienes acceso a esta solicitud';

  @override
  String get apiErrAmpliacionNoEncontrada => 'Ampliación no encontrada';

  @override
  String get apiErrAmpliacionNoPendiente =>
      'Esta ampliación ya no está pendiente de respuesta';

  @override
  String get apiErrUsuarioYaExiste =>
      'Ya existe una cuenta con este email o teléfono';

  @override
  String get apiErrSinCuenta =>
      'No existe una cuenta asociada. Regístrate primero.';

  @override
  String get apiErrCuentaDesactivada => 'Esta cuenta ha sido desactivada';

  @override
  String get apiErrReclamacionSoloTrabajoAceptado =>
      'Solo se puede reportar un problema en un trabajo aceptado';

  @override
  String get apiErrReclamacionYaAbierta =>
      'Ya existe una reclamación abierta para este trabajo';

  @override
  String get apiErrSolicitudNoAceptada =>
      'La solicitud debe estar aceptada por un profesional antes de pagar';

  @override
  String get apiErrNadaPendienteAutorizar =>
      'No hay nada pendiente de autorizar para esta solicitud';

  @override
  String get apiErrNoEresCliente => 'No eres el cliente de esta solicitud';

  @override
  String get apiErrNoAutorizadoPostular =>
      'No estás autorizado para postularte a solicitudes';

  @override
  String get apiErrSolicitudNoDisponible =>
      'Esta solicitud ya no está disponible';

  @override
  String get apiErrCandidaturaYaEnviada =>
      'Ya te has postulado a esta solicitud';

  @override
  String get apiErrCandidaturaNoEncontrada => 'Candidatura no encontrada';

  @override
  String get apiErrPresupuestoDatosInvalidos =>
      'Datos de presupuesto inválidos';

  @override
  String get apiErrEstadoInvalidoPresupuesto =>
      'La solicitud no está en un estado válido para presupuestar';

  @override
  String get apiErrPresupuestoYaPendiente =>
      'Ya hay un presupuesto pendiente de respuesta para esta solicitud';

  @override
  String get apiErrDecisionPresupuestoRequerida =>
      'Indica si aceptas o rechazas el presupuesto';

  @override
  String get apiErrPresupuestoNoEncontrado => 'Presupuesto no encontrado';

  @override
  String get apiErrPresupuestoNoPendiente =>
      'Este presupuesto ya no está pendiente de respuesta';

  @override
  String get apiErrPerfilProfesionalNoEncontrado =>
      'Perfil de profesional no encontrado';

  @override
  String get apiErrProfesionalNoVerificado =>
      'No puedes ponerte disponible hasta ser verificado';

  @override
  String get apiErrCuentaStripeNoConfigurada =>
      'No puedes ponerte disponible hasta configurar tu cuenta de cobro';

  @override
  String get apiErrCategoriasInvalidas => 'Una o más categorías no son válidas';

  @override
  String get apiErrParametrosBusquedaInvalidos =>
      'Parámetros de búsqueda inválidos';

  @override
  String get apiErrValorarSoloCompletado =>
      'Solo se puede valorar un servicio ya completado';

  @override
  String get apiErrValoracionBloqueadaDisputa =>
      'Existe una reclamación abierta — no se puede valorar hasta que se resuelva';

  @override
  String get apiErrSinProfesionalAsignado =>
      'Esta solicitud no tiene profesional asignado';

  @override
  String get apiErrNoParticipaste =>
      'No participaste en esta solicitud, no puedes valorarla';

  @override
  String get apiErrYaValoraste => 'Ya has valorado esta solicitud';

  @override
  String get apiErrFechaRequerida => 'Indica la fecha deseada';

  @override
  String get apiErrCategoriaInvalida => 'Categoría de servicio no válida';

  @override
  String get apiErrCuentaNoVerificada => 'Tu cuenta aún no ha sido verificada';

  @override
  String get apiErrSoloCreadorCancela =>
      'Solo el cliente que creó esta solicitud puede cancelarla';

  @override
  String get apiErrNoSePuedeCancelar =>
      'Esta solicitud ya no se puede cancelar — el profesional ya empezó o ya se resolvió';

  @override
  String get apiErrTrabajoEnCursoUsaDisputa =>
      'El profesional ya ha marcado este trabajo como en curso — para cancelarlo ahora, abre una reclamación';

  @override
  String get apiErrSoloCreadorBorra =>
      'Solo el cliente que creó esta solicitud puede borrarla';

  @override
  String get apiErrNoSePuedeBorrar =>
      'Solo se pueden borrar solicitudes que nadie ha aceptado todavía';

  @override
  String get apiErrNoSePuedeArchivar =>
      'Solo se pueden archivar solicitudes completadas o canceladas';

  @override
  String get apiErrMensajeRequerido => 'Falta el texto del mensaje';

  @override
  String get apiErrEstadoInvalidoCompletar =>
      'La solicitud no está en un estado válido para completarse';

  @override
  String get apiErrPagoNoAutorizado =>
      'El cliente aún no ha autorizado el pago de este servicio';

  @override
  String get apiErrHorasRequeridas => 'Indica las horas reales trabajadas';

  @override
  String get apiErrCierreYaPendiente =>
      'Ya hay un cierre pendiente de confirmación del cliente';

  @override
  String get apiErrDecisionHorasRequerida =>
      'Indica si aceptas o rechazas las horas declaradas';

  @override
  String get apiErrCierreNoEncontrado => 'Cierre no encontrado';

  @override
  String get apiErrCierreNoPendiente =>
      'Este cierre ya no está pendiente de respuesta';

  @override
  String get apiErrHorasDemasiadoBajas =>
      'Las horas declaradas son demasiado bajas';

  @override
  String get apiErrConfirmacionReduccionRequerida =>
      'Esta reducción es muy grande respecto a lo estimado — confírmala explícitamente';

  @override
  String get apiErrSinArchivo => 'No se ha recibido ningún archivo';

  @override
  String get apiErrUsuarioNoEncontrado => 'Usuario no encontrado';

  @override
  String get apiErrPagoAtascadoNoEncontrado =>
      'No queda ninguna autorización pendiente de liberar en esta solicitud';

  @override
  String get apiErrLiberacionEnCurso =>
      'Ya hay una liberación en curso para esta solicitud. Espera unos segundos y vuelve a intentarlo.';

  @override
  String get apiErrPagoNoAutorizadoTodavia =>
      'El cliente nunca llegó a confirmar el pago. Esto no se arregla reintentando: tiene que volver a autorizarlo en la app.';

  @override
  String get apiErrProfesionalSinCuentaStripe =>
      'El profesional no ha completado el onboarding de Stripe Connect';

  @override
  String get apiErrCuentaStripeNoOperativa =>
      'Stripe todavía no habilita los pagos de este profesional (verificación pendiente)';

  @override
  String get apiErrReintentoStripeFallido =>
      'El reintento falló en Stripe. El pago sigue recuperable: vuelve a intentarlo.';

  @override
  String get apiErrTareaNoEncontrada => 'Tarea no encontrada';

  @override
  String get apiErrTareaYaEnCurso =>
      'Esta tarea ya se está ejecutando ahora mismo';

  @override
  String get apiErrTareaFallida =>
      'La tarea falló. Revisa el detalle antes de reintentar.';

  @override
  String get apiErrAdminNoPuedeAutoBloquearse =>
      'No puedes cambiar el estado de tu propia cuenta';

  @override
  String get apiErrUltimoAdminActivo =>
      'No puedes desactivar al único administrador activo';

  @override
  String get apiErrCuentaEliminadaNoReactivable =>
      'Esta cuenta fue eliminada por el propio usuario y no se puede reactivar';

  @override
  String get legalPrivSec1Titulo => '1. Quién trata tus datos';

  @override
  String get legalPrivSec1Texto =>
      'Hogar SOS es una app que conecta a clientes con profesionales de servicios a domicilio. Somos responsables del tratamiento de los datos personales que recoge la aplicación, descritos en esta política.';

  @override
  String get legalPrivSec2Titulo => '2. Qué datos recogemos';

  @override
  String get legalPrivSec2Texto =>
      '• Datos de cuenta: nombre, email y teléfono al registrarte.\n• Ubicación: tu ubicación aproximada o precisa (con tu permiso) para mostrarte profesionales cercanos, o para que un profesional aparezca en las búsquedas de clientes cerca de él.\n• Fotos: las que adjuntes a una solicitud de servicio o a tu perfil.\n• Documentos de verificación (solo profesionales): documento de identidad, certificados y seguro de responsabilidad civil, usados exclusivamente para verificar tu identidad y aptitud antes de permitirte operar en la plataforma.\n• Datos de pago: gestionados directamente por Stripe, nuestro procesador de pagos — Hogar SOS nunca almacena el número completo de tu tarjeta.\n• Mensajes de chat entre cliente y profesional de una misma solicitud.';

  @override
  String get legalPrivSec3Titulo => '3. Para qué usamos tus datos';

  @override
  String get legalPrivSec3Texto =>
      'Para prestar el servicio (conectar clientes con profesionales, procesar pagos, gestionar solicitudes), para verificar la identidad de los profesionales, para enviarte notificaciones relacionadas con tus solicitudes, y para prevenir fraude y resolver disputas.';

  @override
  String get legalPrivSec4Titulo => '4. Con quién compartimos tus datos';

  @override
  String get legalPrivSec4Texto =>
      'Con el otro participante de una solicitud (el cliente ve el nombre del profesional asignado y viceversa). Con proveedores que nos ayudan a operar la app: Firebase/Google (autenticación, notificaciones, chat) y Stripe (pagos). No vendemos tus datos a terceros ni los usamos con fines publicitarios ajenos a la app.';

  @override
  String get legalPrivSec5Titulo => '5. Cuánto tiempo conservamos tus datos';

  @override
  String get legalPrivSec5Texto =>
      'Mientras tu cuenta esté activa. Si la eliminas, borramos o anonimizamos tus datos personales, salvo lo que debamos conservar por obligación legal (p. ej. registros de pagos).';

  @override
  String get legalPrivSec6Titulo => '6. Tus derechos';

  @override
  String get legalPrivSec6Texto =>
      'Puedes acceder, rectificar o eliminar tu cuenta y tus datos personales en cualquier momento desde Perfil → Eliminar cuenta, o visitando hogarsos.es/eliminar-cuenta si no tienes acceso a la app. También puedes retirar los permisos de ubicación, cámara o galería en cualquier momento desde los ajustes de tu teléfono.';

  @override
  String get legalPrivSec7Titulo => '7. Cambios en esta política';

  @override
  String get legalPrivSec7Texto =>
      'Si actualizamos esta política de forma relevante, te lo notificaremos dentro de la app antes de que entre en vigor.';

  @override
  String get legalTerminosSec1Titulo => '1. Qué es Hogar SOS';

  @override
  String get legalTerminosSec1Texto =>
      'Hogar SOS es una plataforma que conecta a clientes que necesitan un servicio a domicilio (electricidad, fontanería, limpieza, etc.) con profesionales independientes que los ofrecen. Hogar SOS no presta los servicios directamente ni es empleador de los profesionales — actúa como intermediario entre ambas partes.';

  @override
  String get legalTerminosSec2Titulo => '2. Cuentas de usuario';

  @override
  String get legalTerminosSec2Texto =>
      'Debes dar información veraz al registrarte. Eres responsable de mantener segura tu cuenta. Los profesionales deben superar un proceso de verificación (documento de identidad y, si aplica, certificados/seguro) antes de poder aceptar solicitudes.';

  @override
  String get legalTerminosSec3Titulo => '3. Pagos y gastos de gestión';

  @override
  String get legalTerminosSec3Texto =>
      'El pago de un servicio se autoriza a través de Stripe al aceptar el trabajo, pero no se cobra hasta que el profesional marca el servicio como completado. Hogar SOS aplica unos gastos de gestión sobre el precio del servicio, que incluyen la verificación de identidad del profesional, el pago protegido hasta la finalización del trabajo y el soporte de Hogar SOS en caso de incidencias; el resto se transfiere al profesional. Los precios los fija el profesional o se acuerdan entre ambas partes por chat.';

  @override
  String get legalTerminosSec4Titulo => '4. Cancelaciones y reembolsos';

  @override
  String get legalTerminosSec4Texto =>
      'El cliente puede cancelar una solicitud sin coste mientras esté pendiente o recién aceptada y el trabajo todavía no haya empezado. Si ya se autorizó un pago, se reembolsa automáticamente al cancelar. Una vez el profesional marca el servicio como \"en curso\", ya no se puede cancelar desde la app — en ese caso, contacta con nosotros para resolverlo.';

  @override
  String get legalTerminosSec5Titulo => '5. Disputas';

  @override
  String get legalTerminosSec5Texto =>
      'Si algo no fue como se esperaba, cliente o profesional pueden abrir una disputa. Un administrador revisa el caso y decide si el pago se libera al profesional o se reembolsa al cliente.';

  @override
  String get legalTerminosSec6Titulo => '6. Responsabilidad';

  @override
  String get legalTerminosSec6Texto =>
      'Hogar SOS facilita el contacto y el pago entre cliente y profesional, pero no supervisa ni garantiza la calidad del trabajo realizado — la relación de servicio es directamente entre ambas partes. Recomendamos revisar las valoraciones de un profesional antes de contratarlo.';

  @override
  String get legalTerminosSec7Titulo => '7. Conducta de los profesionales';

  @override
  String get legalTerminosSec7Texto =>
      'Los profesionales verificados deben prestar el servicio con la diligencia y competencia propias de su oficio. Hogar SOS puede suspender o revocar una cuenta que reciba valoraciones reiteradamente negativas, incumpla estos términos, o cuya verificación resulte fraudulenta.';

  @override
  String get legalTerminosSec8Titulo => '8. Cambios en estos términos';

  @override
  String get legalTerminosSec8Texto =>
      'Podemos actualizar estos términos; los cambios relevantes se notificarán dentro de la app antes de entrar en vigor. Seguir usando Hogar SOS después de un cambio implica aceptarlo.';

  @override
  String get legalTerminosSec9Titulo => '9. Ley aplicable';

  @override
  String get legalTerminosSec9Texto =>
      'Estos términos se rigen por la legislación española.';

  @override
  String homeSaludo(String nombre) {
    return 'Hola, $nombre 👋';
  }

  @override
  String get homeSaludoGenerico => 'Hola 👋';

  @override
  String homeSaludoManana(String nombre) {
    return 'Buenos días, $nombre ☀️';
  }

  @override
  String homeSaludoTarde(String nombre) {
    return 'Buenas tardes, $nombre 👋';
  }

  @override
  String homeSaludoNoche(String nombre) {
    return 'Buenas noches, $nombre 🌙';
  }

  @override
  String get homeAccesoBuscar => 'Buscar';

  @override
  String get homeAccesoMisSolicitudes => 'Mis solicitudes';

  @override
  String get homeAccesoFavoritos => 'Favoritos';

  @override
  String homeResumenActivas(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: 'solicitudes activas',
      one: 'solicitud activa',
    );
    return 'Tienes $cantidad $_temp0';
  }

  @override
  String get homeMisSolicitudesSinActivas =>
      'Ver historial y solicitudes en curso';

  @override
  String get homeSubtitulo => '¿Qué necesitas arreglar hoy?';

  @override
  String get homeBuscarPlaceholder => 'Busca un profesional o servicio...';

  @override
  String get homeCategoriasTitulo => 'Categorías';

  @override
  String get homeCategoriasError => 'No se pudieron cargar las categorías';

  @override
  String get homeSolicitarProfesional => '📢 Solicitar un profesional';

  @override
  String get homeSolicitarProfesionalAyuda =>
      'Cuéntanos qué necesitas y te ponemos en contacto';

  @override
  String get homeDescribeProblema => 'Describe el problema';

  @override
  String get homeErrorDescribe => 'Describe brevemente el problema';

  @override
  String get homeErrorUbicacion =>
      'Necesitamos tu ubicación para buscar profesionales cerca';

  @override
  String get homeErrorCrearSolicitud =>
      'No se pudo crear la solicitud. Inténtalo de nuevo.';

  @override
  String get homeBtnBuscarProfesionales => 'Buscar profesionales';

  @override
  String homeSolicitudCreada(String id) {
    return 'Solicitud creada (#$id)';
  }

  @override
  String get homeBusquedaProximamente =>
      'Búsqueda con filtros: disponible en la próxima fase';

  @override
  String get perfilCerrarSesion => 'Cerrar sesión';

  @override
  String get perfilRolCliente => 'Cliente';

  @override
  String get perfilRolProfesional => 'Profesional';

  @override
  String get perfilRolAdmin => 'Administrador';

  @override
  String get perfilMiembroDesde => 'Miembro de Hogar SOS';

  @override
  String get perfilConfirmarSalir => '¿Seguro que quieres cerrar sesión?';

  @override
  String get perfilCancelar => 'Cancelar';

  @override
  String get perfilEliminarCuenta => 'Eliminar cuenta';

  @override
  String get perfilEliminarCuentaConfirmarTitulo => '¿Eliminar tu cuenta?';

  @override
  String get perfilEliminarCuentaConfirmarTexto =>
      'Esta acción no se puede deshacer. Perderás el acceso de inmediato y se eliminarán tu nombre, email, teléfono, foto y, si eres profesional, tus documentos de verificación.';

  @override
  String get perfilEliminarCuentaBotonConfirmar => 'Sí, eliminar mi cuenta';

  @override
  String get perfilEliminarCuentaError =>
      'No se pudo eliminar tu cuenta. Inténtalo de nuevo.';

  @override
  String get perfilFavoritos => 'Favoritos';

  @override
  String get perfilMisSolicitudes => 'Mis solicitudes';

  @override
  String get perfilConfiguracion => 'Configuración';

  @override
  String get perfilPrivacidad => 'Política de privacidad';

  @override
  String get perfilTerminos => 'Términos de servicio';

  @override
  String get perfilEmailSinVerificarTitulo => 'Verifica tu email';

  @override
  String get perfilEmailSinVerificarDescripcion =>
      'Te hemos enviado un enlace de confirmación. Revisa tu bandeja de entrada (y la carpeta de spam).';

  @override
  String get perfilEmailSinVerificarReenviar => 'Reenviar email';

  @override
  String get perfilEmailSinVerificarYaConfirme => 'Ya lo confirmé';

  @override
  String get perfilEmailVerificacionReenviada =>
      'Email de verificación reenviado';

  @override
  String get perfilEmailAunNoVerificado =>
      'Todavía no lo detectamos. Si acabas de confirmarlo, espera unos segundos e inténtalo de nuevo.';

  @override
  String get perfilEmailVerificadoExito => '¡Email verificado!';

  @override
  String get legalPrivacidadTitulo => 'Política de privacidad';

  @override
  String get legalTerminosTitulo => 'Términos de servicio';

  @override
  String get legalAceptacionPrefijo => 'Al crear una cuenta, aceptas los ';

  @override
  String get legalAceptacionY => ' y la ';

  @override
  String get pagoAceptacionTerminos =>
      'Al continuar, aceptas los Términos de servicio y la política de cancelación';

  @override
  String get proximamenteTitulo => 'Próximamente';

  @override
  String get buscarProximamenteDescripcion =>
      'La búsqueda avanzada con filtros por precio, distancia y valoración llega en la próxima fase.';

  @override
  String get mensajesProximamenteDescripcion =>
      'Aquí verás todas tus conversaciones con clientes y profesionales.';

  @override
  String get mensajesVacioTitulo => 'Sin conversaciones todavía';

  @override
  String get buscarHint => 'Busca por nombre...';

  @override
  String get buscarFiltros => 'Filtros';

  @override
  String get buscarTodasCategorias => 'Todas';

  @override
  String get buscarSinResultadosTitulo => 'No se encontraron profesionales';

  @override
  String get buscarSinResultadosDescripcion =>
      'Prueba a cambiar los filtros o la búsqueda';

  @override
  String get buscarErrorTitulo => 'No se pudo completar la búsqueda';

  @override
  String buscarDesde(String precio) {
    return 'Desde $precio €';
  }

  @override
  String buscarTrabajos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'trabajos',
      one: 'trabajo',
    );
    return '$n $_temp0';
  }

  @override
  String get buscarDisponibleAhora => 'Disponible ahora';

  @override
  String get buscarNoDisponible => 'No disponible';

  @override
  String get buscarUrgente => 'Urgente';

  @override
  String get buscarUrgenteTitulo => '¿Qué necesitas con urgencia?';

  @override
  String get filtroValoracionMinima => 'Valoración mínima';

  @override
  String get filtroPrecioMaximo => 'Precio máximo';

  @override
  String get filtroDistanciaMaxima => 'Distancia máxima';

  @override
  String get filtroLimpiar => 'Limpiar';

  @override
  String get filtroAplicar => 'Aplicar filtros';

  @override
  String get filtroCualquiera => 'Cualquiera';

  @override
  String get filtroSoloDisponibles => 'Disponible ahora';

  @override
  String get perfilProOpinionesTitulo => 'Opiniones';

  @override
  String opinionesTotal(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'valoraciones',
      one: 'valoración',
    );
    return '$n $_temp0';
  }

  @override
  String get misValoracionesTitulo => 'Mis valoraciones';

  @override
  String get misValoracionesError => 'No se pudieron cargar tus valoraciones';

  @override
  String get perfilProSinOpiniones => 'Aún no tiene opiniones';

  @override
  String get perfilProGaleriaTitulo => 'Galería de trabajos';

  @override
  String get perfilProSinGaleria =>
      'Este profesional aún no ha subido fotos de sus trabajos';

  @override
  String get perfilProServiciosTitulo => 'Servicios que ofrece';

  @override
  String get perfilProSolicitarBtn => 'Solicitar este servicio';

  @override
  String get perfilProCargandoError => 'No se pudo cargar el perfil';

  @override
  String get perfilProSolicitarInfo =>
      'De momento, las solicitudes se envían a los profesionales disponibles cerca de ti desde Inicio, no a uno concreto todavía';

  @override
  String get categoriaElectricista => 'Electricista';

  @override
  String get categoriaFontanero => 'Fontanero';

  @override
  String get categoriaPintor => 'Pintor';

  @override
  String get categoriaManitas => 'Manitas';

  @override
  String get categoriaLimpieza => 'Limpieza';

  @override
  String get categoriaJardineria => 'Jardinería';

  @override
  String get categoriaCerrajeria => 'Cerrajería';

  @override
  String get categoriaReformas => 'Reformas';

  @override
  String get categoriaAireAcondicionado => 'Aire acondicionado y climatización';

  @override
  String get categoriaCarpinteria => 'Carpintería';

  @override
  String get categoriaAlbanileria => 'Albañilería';

  @override
  String get categoriaTejados => 'Tejados y cubiertas';

  @override
  String get categoriaInstalacionCristales => 'Instalación de cristales';

  @override
  String get categoriaCarpinteriaMetalica =>
      'Carpintería metálica / Aluminio y PVC';

  @override
  String get categoriaAntenas => 'Antenas y telecomunicaciones';

  @override
  String get categoriaSeguridad => 'Sistemas de seguridad';

  @override
  String get categoriaMudanzas => 'Mudanzas';

  @override
  String get categoriaLimpiezaCristales => 'Limpieza de cristales';

  @override
  String get categoriaPiscinas => 'Piscinas';

  @override
  String get categoriaControlPlagas => 'Control de plagas';

  @override
  String get categoriaPetSitter => 'Pet sitter';

  @override
  String get categoriaTecnicoTelefonia => 'Técnico de telefonía';

  @override
  String get categoriaMasajes => 'Masajes a domicilio';

  @override
  String get categoriaManicuraPedicura => 'Manicura y pedicura';

  @override
  String get wizardEjemploGenerico =>
      'Ej: se ha roto una tubería bajo el fregadero y hay una fuga...';

  @override
  String get wizardEjemploElectricista =>
      'Ej: ha saltado el diferencial y no puedo volver a subirlo...';

  @override
  String get wizardEjemploFontanero =>
      'Ej: tengo una fuga debajo del fregadero...';

  @override
  String get wizardEjemploPintor => 'Ej: quiero pintar el salón, unos 20 m²...';

  @override
  String get wizardEjemploManitas => 'Ej: necesito montar unas estanterías...';

  @override
  String get wizardEjemploLimpieza =>
      'Ej: necesito una limpieza completa de un piso...';

  @override
  String get wizardEjemploJardineria =>
      'Ej: necesito podar el seto y cortar el césped...';

  @override
  String get wizardEjemploCerrajeria =>
      'Ej: he perdido las llaves y no puedo entrar en casa...';

  @override
  String get wizardEjemploReformas => 'Ej: quiero reformar el baño completo...';

  @override
  String get wizardEjemploAireAcondicionado =>
      'Ej: el aire acondicionado no enfría...';

  @override
  String get wizardEjemploCarpinteria =>
      'Ej: necesito una puerta de armario a medida...';

  @override
  String get wizardEjemploAlbanileria =>
      'Ej: tengo una grieta en la pared del salón...';

  @override
  String get wizardEjemploTejados => 'Ej: tengo una gotera en el tejado...';

  @override
  String get wizardEjemploInstalacionCristales =>
      'Ej: se ha roto el cristal de una ventana...';

  @override
  String get wizardEjemploCarpinteriaMetalica =>
      'Ej: necesito reparar una persiana metálica...';

  @override
  String get wizardEjemploAntenas =>
      'Ej: no tengo señal de antena en el televisor...';

  @override
  String get wizardEjemploSeguridad =>
      'Ej: quiero instalar una alarma en casa...';

  @override
  String get wizardEjemploMudanzas =>
      'Ej: necesito ayuda para mudarme a un piso de 2 habitaciones...';

  @override
  String get wizardEjemploLimpiezaCristales =>
      'Ej: necesito limpiar los cristales de un tercer piso...';

  @override
  String get wizardEjemploPiscinas => 'Ej: mi piscina tiene el agua verde...';

  @override
  String get wizardEjemploControlPlagas =>
      'Ej: tengo cucarachas en la cocina...';

  @override
  String get wizardEjemploPetSitter =>
      'Ej: necesito que alguien cuide de mi perro este fin de semana...';

  @override
  String get wizardEjemploTecnicoTelefonia =>
      'Ej: se me ha roto la pantalla del móvil...';

  @override
  String get wizardEjemploMasajes =>
      'Ej: quiero un masaje relajante de una hora en casa...';

  @override
  String get wizardEjemploManicuraPedicura =>
      'Ej: quiero una manicura y pedicura completa a domicilio...';

  @override
  String get profesionalTituloSolicitudes => 'Solicitudes cerca de ti';

  @override
  String get profesionalDisponibleAhoraAviso =>
      'Estás disponible: te pueden llegar solicitudes nuevas';

  @override
  String get profesionalChipDisponible => 'Disponible';

  @override
  String get profesionalChipNoDisponible => 'No disponible';

  @override
  String profesionalEstadoLinea(String estado) {
    return 'Tu estado · $estado';
  }

  @override
  String get salirPulsaOtraVez => 'Pulsa atrás otra vez para salir';

  @override
  String get profesionalSinSolicitudes =>
      'No hay solicitudes cerca ahora mismo';

  @override
  String get profesionalErrorCargar => 'No se pudieron cargar las solicitudes';

  @override
  String get profesionalIgnorar => 'Ignorar';

  @override
  String get profesionalErrorIgnorar => 'No se pudo ignorar la solicitud';

  @override
  String get profesionalAceptar => 'Aceptar';

  @override
  String get profesionalSolicitudAceptada =>
      'Solicitud aceptada. El cliente autorizará el pago.';

  @override
  String get profesionalYaNoDisponible =>
      'No se pudo aceptar — puede que ya no esté disponible';

  @override
  String get profesionalPostularme => 'Enviar candidatura';

  @override
  String get profesionalYaPostulado => 'Candidatura enviada';

  @override
  String get profesionalPostulacionEnviada =>
      'Candidatura enviada — el cliente elegirá entre los profesionales interesados';

  @override
  String get profesionalPostulacionMensajeObligatorio =>
      'Escribe cuándo puedes hacer el trabajo antes de enviar tu candidatura';

  @override
  String get profesionalDisponibilidadTitulo =>
      '¿Cuándo puedes hacer este trabajo?';

  @override
  String get profesionalDisponibilidadSubtitulo =>
      'El cliente lo verá en tu candidatura junto a tu foto y valoración';

  @override
  String get profesionalDisponibilidadHint =>
      'Ej: puedo ir mañana por la tarde...';

  @override
  String get profesionalDisponibilidadSugerencia1 =>
      'Puedo ir mañana por la tarde';

  @override
  String get profesionalDisponibilidadSugerencia2 =>
      'Estoy disponible el viernes a las 10:00';

  @override
  String get profesionalDisponibilidadSugerencia3 =>
      'Puedo pasar esta misma tarde';

  @override
  String get profesionalDisponibilidadConfirmar => 'Enviar candidatura';

  @override
  String profesionalDistanciaKm(String km) {
    return 'A $km km';
  }

  @override
  String profesionalTrabajosActivos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'trabajos activos',
      one: 'trabajo activo',
    );
    return 'Tienes $n $_temp0';
  }

  @override
  String get trabajosActivosTitulo => 'Trabajos activos';

  @override
  String trabajosActivosTeEligieron(String categoria) {
    return '¡Te han elegido para $categoria! Ahora está en Trabajos activos.';
  }

  @override
  String trabajosActivosTeEligieronVarios(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'trabajos nuevos',
      one: 'trabajo nuevo',
    );
    return '¡Te han elegido para $n $_temp0! Revisa Trabajos activos.';
  }

  @override
  String get trabajosActivosVerTrabajo => 'Ver trabajo';

  @override
  String get trabajosActivosVacio => 'No tienes trabajos activos ahora mismo';

  @override
  String get trabajosActivosErrorCargar => 'No se pudieron cargar tus trabajos';

  @override
  String get trabajosActivosChat => 'Chat';

  @override
  String get trabajosActivosCompletar => 'Marcar como completado';

  @override
  String get trabajosActivosPrecioFinalTitulo => 'Precio final del servicio';

  @override
  String get trabajosActivosPrecioFinalHint => 'Precio (€)';

  @override
  String get trabajosActivosPrecioFinalConfirmar => 'Confirmar';

  @override
  String get trabajosActivosCompletadoExito =>
      'Servicio marcado como completado';

  @override
  String get trabajosActivosCompletadoError =>
      'No se pudo completar el servicio';

  @override
  String get trabajosActivosIniciarTrabajo => 'Iniciar trabajo';

  @override
  String get trabajosActivosIniciarTrabajoConfirmarTitulo =>
      '¿Iniciar este trabajo?';

  @override
  String get trabajosActivosIniciarTrabajoConfirmarTexto =>
      'A partir de ahora el cliente ya no podrá cancelarlo directamente — si hace falta, tendrá que abrir una reclamación.';

  @override
  String get trabajosActivosIniciarTrabajoExito => 'Trabajo iniciado';

  @override
  String get trabajosActivosIniciarTrabajoError =>
      'No se pudo iniciar el trabajo';

  @override
  String get trabajosActivosDeshacerInicio => 'Deshacer inicio';

  @override
  String get trabajosActivosDeshacerInicioExito => 'Inicio deshecho';

  @override
  String get trabajosActivosDeshacerInicioError =>
      'No se pudo deshacer el inicio';

  @override
  String get profesionalErrorDisponibilidad =>
      'No se pudo actualizar tu disponibilidad';

  @override
  String get profesionalDisponibleAyuda =>
      'Recibirás solicitudes cercanas a tu ubicación';

  @override
  String get profesionalNoDisponibleAyuda =>
      'Actívalo para empezar a recibir trabajos';

  @override
  String get profesionalPonerseDisponibleBoton => 'Ponerme disponible';

  @override
  String get disponibilidadTitulo => 'Disponibilidad';

  @override
  String get disponibilidadEnLineaTitulo => 'Estado actual';

  @override
  String get disponibilidadModoTitulo => 'Modo de disponibilidad';

  @override
  String get disponibilidadModoAyuda =>
      'Elige cuándo quieres recibir solicitudes. Podrás cambiarlo cuando quieras.';

  @override
  String get disponibilidadModoHorarioLaboral =>
      'Disponible en horario laboral';

  @override
  String get disponibilidadModoHorarioLaboralAyuda =>
      'Recibes solicitudes en tu horario habitual de trabajo';

  @override
  String get disponibilidadModo24h => 'Servicio 24 horas';

  @override
  String get disponibilidadModo24hAyuda =>
      'Recibes solicitudes a cualquier hora, día y noche';

  @override
  String get disponibilidadModoActualizado =>
      'Modo de disponibilidad actualizado';

  @override
  String get disponibilidadModoError =>
      'No se pudo actualizar el modo de disponibilidad';

  @override
  String get disponibilidadPerfilIncompleto =>
      'Completa tu perfil (foto y al menos una categoría) antes de activarte — así te podrán encontrar los clientes.';

  @override
  String get disponibilidadPendienteVerificacion =>
      'Tu cuenta está pendiente de revisión por un administrador. Podrás activarte en cuanto se apruebe.';

  @override
  String get disponibilidadPendienteStripe =>
      'Configura tu cuenta de cobro con Stripe para poder activarte — sin ella no podrías cobrar los trabajos que aceptes.';

  @override
  String get disponibilidadCompletaAlta =>
      'Completa tu alta para empezar a recibir ofertas. Te guiamos desde la tarjeta \"Completa tu alta\", arriba en tu perfil.';

  @override
  String get miPerfilTelefonoAyudaInterno =>
      'Solo para uso interno de HogarSOS. Los clientes no lo ven.';

  @override
  String get infoProfTitulo => 'Información profesional';

  @override
  String get infoProfDescripcionCta =>
      'Añade una breve descripción para que los clientes te conozcan mejor';

  @override
  String get infoProfFalloDatos =>
      'No se pudieron guardar los cambios de descripción o precio por hora.';

  @override
  String get infoProfFalloTelefono => 'No se pudo guardar el teléfono.';

  @override
  String get infoProfRestoGuardado => 'El resto de cambios sí se han guardado.';

  @override
  String get infoProfComoTrabajas => 'Cómo trabajas';

  @override
  String get infoProfSinIndicar => 'Sin indicar';

  @override
  String get infoProfTelefonoResumen => 'Teléfono: solo uso interno';

  @override
  String get infoProfPrecio => 'Precio por hora';

  @override
  String get infoProfPrecioOpcional => 'opcional';

  @override
  String get tipoProfesionalCambioSoporte =>
      'Para cambiar tu tipo profesional, contacta con soporte.';

  @override
  String get infoProfDescripcionContactoError =>
      'No puedes incluir teléfonos ni datos de contacto en la descripción. Usa la mensajería de HogarSOS para comunicarte con los clientes.';

  @override
  String get soporteTitulo => 'Ayuda y soporte';

  @override
  String get soportePregunta => '¿Necesitas ayuda con HogarSOS?';

  @override
  String get soporteEmailBoton => 'Escríbenos por email';

  @override
  String get soporteWhatsappBoton => 'Escríbenos por WhatsApp';

  @override
  String get soporteAsuntoGeneral => 'Ayuda con HogarSOS';

  @override
  String get soporteAsuntoTipoProfesional => 'Cambio de tipo profesional';

  @override
  String get soporteWhatsappGeneral => 'Hola, necesito ayuda con HogarSOS.';

  @override
  String get soporteWhatsappTipoProfesional =>
      'Hola, necesito ayuda con el cambio de tipo profesional en HogarSOS.';

  @override
  String get soporteMotivoTipoProfesional =>
      'Motivo: cambio de tipo profesional';

  @override
  String get soporteCopiar => 'Copiar';

  @override
  String get soporteEmailCopiado => 'Email copiado';

  @override
  String get soporteErrorAbrir =>
      'No se pudo abrir. Copia el email y escríbenos.';

  @override
  String get disponibilidadCompletarPerfil => 'Completar perfil';

  @override
  String get disponibilidadEstadoTitulo => 'Tu disponibilidad';

  @override
  String get disponibilidadEstadoAyuda =>
      'Elige un único estado — determina si y cuándo recibes solicitudes.';

  @override
  String get disponibilidadOpcionNoDisponibleTitulo => 'No disponible';

  @override
  String get disponibilidadOpcionNoDisponibleAyuda =>
      'No recibirás solicitudes nuevas';

  @override
  String get disponibilidadOpcionDisponibleTitulo => 'Disponible';

  @override
  String get disponibilidadOpcionDisponibleAyuda =>
      'Recibirás solicitudes nuevas';

  @override
  String get seguimientoTitulo => 'Tu solicitud';

  @override
  String get seguimientoError => 'No se pudo cargar la solicitud';

  @override
  String get seguimientoBuscando => 'Buscando un profesional cerca de ti...';

  @override
  String get seguimientoAceptada => '¡Un profesional ha aceptado tu solicitud!';

  @override
  String get seguimientoEnProgreso => 'En curso';

  @override
  String get seguimientoCompletada => 'Servicio completado';

  @override
  String get seguimientoCancelada => 'Solicitud cancelada';

  @override
  String get seguimientoCancelarTitulo => 'Cancelar solicitud';

  @override
  String get seguimientoCancelarConfirmar =>
      '¿Seguro que quieres cancelar esta solicitud? Esta acción no se puede deshacer.';

  @override
  String get seguimientoCancelarExito => 'Solicitud cancelada correctamente';

  @override
  String get seguimientoCancelarError => 'No se pudo cancelar la solicitud';

  @override
  String get seguimientoDisputada =>
      'En revisión por nuestro equipo de soporte';

  @override
  String get seguimientoAbrirChat => 'Abrir chat';

  @override
  String get editarPerfilTitulo => 'Editar perfil';

  @override
  String get editarPerfilTelefono => 'Teléfono';

  @override
  String get perfilEditar => 'Editar perfil';

  @override
  String get miPerfilTitulo => 'Mi perfil';

  @override
  String get miPerfilIncompletoTitulo => 'Completa tu perfil';

  @override
  String get miPerfilIncompletoAyuda =>
      'No aparecerás en las búsquedas de clientes hasta que añadas:';

  @override
  String get miPerfilFaltaFoto => 'una foto de perfil';

  @override
  String get miPerfilFaltaCategoria => 'al menos una categoría';

  @override
  String get miPerfilCambiarFoto => 'Cambiar foto';

  @override
  String get miPerfilOficio => 'Oficio principal';

  @override
  String get miPerfilOficioSinAsignar => 'Aún sin categoría asignada';

  @override
  String get miPerfilDescripcionLabel => 'Descripción';

  @override
  String get miPerfilDescripcionAyuda => 'Máximo 250 caracteres';

  @override
  String get miPerfilPrecioLabel => 'Precio por hora (€) — opcional';

  @override
  String get miPerfilPrecioAyuda =>
      'El precio real de cada trabajo se acuerda por presupuesto. Esto solo se usa para el filtro de precio en la búsqueda del cliente.';

  @override
  String get miPerfilDisponible => 'Disponible';

  @override
  String get miPerfilGuardar => 'Guardar cambios';

  @override
  String get miPerfilExito => 'Perfil actualizado correctamente';

  @override
  String get miPerfilErrorGuardar => 'No se pudieron guardar los cambios';

  @override
  String get miPerfilErrorCargar => 'No se pudo cargar tu perfil';

  @override
  String get miPerfilVerificacionTitulo => 'Verificación';

  @override
  String get miPerfilVerificacionEstadoAprobado =>
      'Verificado — ya puedes aceptar trabajos.';

  @override
  String get miPerfilVerificacionEstadoPendiente =>
      'En revisión. Te avisaremos cuando un administrador la apruebe.';

  @override
  String get miPerfilVerificacionEstadoRechazado =>
      'Verificación rechazada. Corrige el documento o la tarifa y vuelve a enviarla.';

  @override
  String get miPerfilVerificacionEstadoSinEnviar =>
      'Aún no has enviado tu documento de identidad — sin esto no podrás aceptar trabajos.';

  @override
  String get miPerfilDocumentoIdentidadLabel => 'Documento de identidad';

  @override
  String get miPerfilDocumentoSeleccionar => 'Seleccionar documento';

  @override
  String get miPerfilEnviarVerificacion => 'Enviar a verificación';

  @override
  String get miPerfilVerificacionExito =>
      'Documentación enviada. Un administrador la revisará pronto.';

  @override
  String get miPerfilVerificacionErrorFaltaDocumento =>
      'Sube tu documento de identidad primero';

  @override
  String get miPerfilVerificacionErrorFaltaTarifa =>
      'Indica una tarifa base válida';

  @override
  String get miPerfilVerificacionErrorEnvio =>
      'No se pudo enviar la verificación';

  @override
  String get tipoProfesionalTitulo => 'Tipo de profesional';

  @override
  String get tipoProfesionalAutonomo => 'Autónomo';

  @override
  String get tipoProfesionalEmpresa => 'Empresa';

  @override
  String get tipoProfesionalPersonaFisica => 'Particular';

  @override
  String get tipoProfesionalTextoLegal =>
      'Selecciona la opción que mejor describa tu situación actual. Eres responsable de cumplir la legislación fiscal y laboral aplicable en tu país para prestar servicios y recibir pagos. HogarSOS actúa únicamente como plataforma de intermediación y no ofrece asesoramiento fiscal o legal.';

  @override
  String get tipoProfesionalErrorFaltaSeleccion =>
      'Selecciona tu tipo de profesional';

  @override
  String get tipoProfesionalPregunta => '¿Cómo trabajas profesionalmente?';

  @override
  String get tipoProfesionalAutonomoDesc =>
      'Estoy dado de alta como trabajador por cuenta propia.';

  @override
  String get tipoProfesionalEmpresaDesc =>
      'Facturo a través de una sociedad (S.L., S.A., cooperativa…).';

  @override
  String get tipoProfesionalPersonaFisicaDesc =>
      'Realizo trabajos de forma puntual o esporádica, no como actividad profesional habitual.';

  @override
  String get tipoProfesionalDeclaracionParticular =>
      'Entiendo y acepto que soy responsable de cumplir las obligaciones legales, fiscales y de Seguridad Social que correspondan a mi actividad.';

  @override
  String get tipoProfesionalAvisoLegal =>
      '⚠️ Importante: antes de aceptar trabajos, asegúrate de que tu situación fiscal y laboral te permite realizar esta actividad legalmente. HogarSOS actúa únicamente como plataforma de intermediación: no determina tu obligación de estar dado de alta ni ofrece asesoramiento fiscal o legal.';

  @override
  String get altaTitulo => 'Completa tu alta';

  @override
  String altaProgreso(int pct) {
    return 'Tu alta está al $pct%';
  }

  @override
  String get altaPasoCuenta => 'Cuenta';

  @override
  String get altaPasoPerfil => 'Perfil';

  @override
  String get altaPasoIdentidadCobros => 'Identidad y cobros';

  @override
  String get altaPasoListo => 'Listo para recibir ofertas';

  @override
  String get altaFaltaFoto => 'Añade tu foto';

  @override
  String get altaFaltaCategoria => 'Elige una categoría';

  @override
  String get altaFaltaTipo => 'Indica cómo trabajas';

  @override
  String get altaMsgPerfilIncompleto =>
      'Te falta completar tu perfil para poder seguir con tu alta.';

  @override
  String get altaMsgStripeSinIniciar =>
      'Último paso: verifica tu identidad y configura tus cobros. Ten a mano tu DNI y tu IBAN (~5 minutos).';

  @override
  String get altaMsgStripeEnProgreso =>
      'Te quedaste a mitad. Continúa donde lo dejaste.';

  @override
  String get altaMsgStripeEnVerificacion =>
      'Stripe está verificando tu identidad. No tienes que hacer nada — te avisaremos.';

  @override
  String get altaMsgStripeAccion =>
      'Stripe necesita un dato más para activar tus cobros.';

  @override
  String get altaMsgRevisionHogarsos =>
      'Estamos revisando tu alta. Te avisaremos en cuanto esté aprobada.';

  @override
  String get altaMsgListo => '🎉 ¡Ya estás listo para recibir ofertas!';

  @override
  String get altaMsgListoAyuda =>
      'Activa tu disponibilidad para que los clientes puedan encontrarte.';

  @override
  String get altaMsgStripeCaida =>
      '⚠️ Tus cobros necesitan una actualización en Stripe.';

  @override
  String get altaBotonContinuar => 'Continuar';

  @override
  String altaResumenPendiente(String paso) {
    return '$paso pendiente';
  }

  @override
  String altaResumenPasos(int n) {
    return '$n pasos';
  }

  @override
  String get altaBotonActivarme => 'Activarme ahora';

  @override
  String get altaActivadoExito =>
      '¡Disponibilidad activada! Ya puedes recibir ofertas.';

  @override
  String get puenteTituloSeguro => '🔐 Verificación y cobros seguros';

  @override
  String get puenteIntro =>
      'Para poder recibir pagos de tus clientes, necesitamos verificar tu identidad y configurar tus datos de cobro.';

  @override
  String get puenteQueEsStripeTitulo => '¿Qué es Stripe?';

  @override
  String get puenteQueEsStripeTexto =>
      'Stripe es la plataforma segura que utilizamos para gestionar la verificación y los pagos de los profesionales.';

  @override
  String get puenteQueEsStripeNota =>
      'HogarSOS no gestiona directamente tus datos bancarios.';

  @override
  String get puenteBloqueIdentidadTitulo => 'Verificación de identidad';

  @override
  String get puenteBloqueIdentidadTexto =>
      'Stripe comprobará tus datos y puede pedirte tu DNI/NIE u otra documentación.';

  @override
  String get puenteBloqueCobrosTitulo => 'Configuración de cobros';

  @override
  String get puenteBloqueCobrosTexto =>
      'Te pedirá los datos necesarios para poder recibir el dinero de tus trabajos.';

  @override
  String get puenteBloqueDatosTitulo => 'Datos protegidos';

  @override
  String get puenteBloqueDatosTexto =>
      'Stripe gestiona esta información de forma segura y HogarSOS recibe la información necesaria para saber si tu cuenta está lista.';

  @override
  String get puentePrefillTitulo => 'Ya hemos rellenado algunos datos por ti';

  @override
  String get puentePrefillTexto =>
      'Usaremos los datos que ya tenemos, como tu nombre, teléfono y email cuando sean válidos, para que tengas que escribir lo menos posible.';

  @override
  String get puenteNecesitarasTitulo => 'Qué necesitarás';

  @override
  String get puenteNecesitarasDni => 'DNI/NIE';

  @override
  String get puenteNecesitarasIban => 'IBAN';

  @override
  String get puenteNecesitarasTelefono => 'Teléfono';

  @override
  String get puenteNecesitarasDatos => 'Datos personales o de empresa';

  @override
  String get puenteNecesitarasExtra =>
      'Stripe puede pedirte información adicional durante la verificación.';

  @override
  String get puenteCambioApp1 =>
      'El siguiente paso se realiza en la página segura de Stripe.';

  @override
  String get puenteCambioApp2 =>
      'Cuando termines, volverás automáticamente a HogarSOS.';

  @override
  String get puenteBoton => 'Continuar con Stripe →';

  @override
  String get puenteBotonRetomar => 'Continúa con Stripe';

  @override
  String get puenteEnProgresoTexto =>
      'Tu configuración no está terminada. Puedes continuar donde lo dejaste.';

  @override
  String get puenteVerificandoTitulo => 'Stripe está verificando tu identidad.';

  @override
  String get puenteVerificandoTexto =>
      'No tienes que hacer nada ahora. Te avisaremos cuando termine.';

  @override
  String get puenteConexionSegura => '🔒 Conexión segura con Stripe';

  @override
  String get puentePerfilIncompleto =>
      'Antes de configurar tus cobros, completa tu perfil: foto, al menos una categoría y cómo trabajas.';

  @override
  String get puenteBotonCompletarPerfil => 'Completar mi perfil';

  @override
  String get cuentaCobroTitulo => 'Cuenta de cobro';

  @override
  String get cuentaCobroEstadoConfigurada =>
      'Configurada — ya puedes recibir pagos.';

  @override
  String get cuentaCobroEstadoPendiente =>
      'Configura tu cuenta de cobro con Stripe para poder recibir pagos por tus trabajos.';

  @override
  String get cuentaCobroEstadoRequiereActualizacion =>
      'Stripe necesita más información para poder pagarte. Complétala para seguir cobrando.';

  @override
  String get cuentaCobroBotonConfigurar => 'Configurar cuenta de cobro';

  @override
  String get cuentaCobroBotonActualizar => 'Actualizar en Stripe';

  @override
  String get cuentaCobroBotonEditar => 'Modificar cuenta de cobro';

  @override
  String get cuentaCobroErrorAbrir =>
      'No se pudo abrir Stripe. Inténtalo de nuevo.';

  @override
  String get cuentaCobroStripeActualizando =>
      'Actualizando el estado de tu cuenta de cobro…';

  @override
  String get cuentaCobroStripeCaducado =>
      'El enlace de Stripe caducó. Pulsa \"Configurar cuenta de cobro\" para volver a intentarlo.';

  @override
  String get centroPagosTitulo => 'Centro de Pagos';

  @override
  String get centroPagosErrorCargar =>
      'No se pudo cargar tu información de pagos';

  @override
  String get centroPagosPendiente => 'Pendiente';

  @override
  String get centroPagosPendienteAyuda =>
      'Cobros ya liberados que Stripe todavía está procesando antes de que estén disponibles.';

  @override
  String get centroPagosDisponible => 'Disponible';

  @override
  String get centroPagosDisponibleAyuda =>
      'Saldo que Stripe ya puede transferir a tu cuenta bancaria.';

  @override
  String get centroPagosHistorialTitulo => 'Historial de cobros';

  @override
  String get centroPagosHistorialVacio =>
      'Todavía no tienes ningún cobro liberado.';

  @override
  String centroPagosImporte(String monto) {
    return '$monto €';
  }

  @override
  String centroPagosPagoDe(String nombre) {
    return 'Pago de $nombre';
  }

  @override
  String get miPerfilStatValoracion => 'Valoración';

  @override
  String get miPerfilStatTrabajos => 'Trabajos';

  @override
  String get miPerfilStatTarifa => 'Tarifa';

  @override
  String get miPerfilStatEstado => 'Estado';

  @override
  String get miPerfilEstadoAprobado => 'Aprobado';

  @override
  String get miPerfilEstadoPendiente => 'Pendiente';

  @override
  String get miPerfilEstadoRechazado => 'Rechazado';

  @override
  String get miPerfilEstadoSinEnviar => 'Sin enviar';

  @override
  String get miPerfilTelefonoVacio => 'Añade tu número de teléfono';

  @override
  String get miPerfilDescripcionVacia =>
      'Añade una breve descripción para que los clientes te conozcan mejor';

  @override
  String get miPerfilCambiar => 'Cambiar';

  @override
  String get miPerfilEditar => 'Editar';

  @override
  String get miPerfilCategoriasTitulo => 'Categorías';

  @override
  String get miPerfilCategoriasEditar => 'Editar categorías';

  @override
  String get miPerfilCategoriasVacia => 'Aún no tienes categorías asignadas';

  @override
  String get miPerfilCategoriasGuardar => 'Guardar';

  @override
  String get miPerfilCategoriasCancelar => 'Cancelar';

  @override
  String get miPerfilCategoriasErrorMinimo =>
      'Selecciona al menos una categoría';

  @override
  String get miPerfilCategoriasExito => 'Categorías actualizadas';

  @override
  String get miPerfilCategoriasError =>
      'No se pudieron actualizar las categorías';

  @override
  String get distintivoVerificado => 'Identidad verificada';

  @override
  String get homeVerTodasCategorias => 'Ver todas las categorías';

  @override
  String get todasCategoriasTitulo => 'Todas las categorías';

  @override
  String get chatTitulo => 'Chat';

  @override
  String get chatSinMensajes => 'Aún no hay mensajes';

  @override
  String get chatErrorCargar => 'No se pudo cargar el chat';

  @override
  String get chatErrorEnviar => 'No se pudo enviar el mensaje';

  @override
  String get chatContactoBloqueado =>
      'Por seguridad, los datos de contacto solo podrán compartirse cuando el trabajo haya sido aceptado.';

  @override
  String get chatHint => 'Escribe un mensaje...';

  @override
  String get seguimientoAutorizarPago => 'Autorizar pago';

  @override
  String get seguimientoValorar => 'Valorar servicio';

  @override
  String get seguimientoYaValorado => 'Ya has valorado este servicio';

  @override
  String get seguimientoPagoRetenido =>
      'Pago autorizado, pendiente de completar el servicio';

  @override
  String get seguimientoPagoLiberado => 'Pago completado';

  @override
  String get seguimientoPagoReembolsado => 'Pago reembolsado';

  @override
  String get seguimientoPagoFallido => 'El pago falló';

  @override
  String get pagoTitulo => 'Confirmar y pagar';

  @override
  String get pagoInfo =>
      'El importe se autoriza ahora pero solo se cobra cuando el profesional complete el servicio.';

  @override
  String get pagoBtnAutorizar => 'Autorizar pago';

  @override
  String get pagoExito =>
      'Pago autorizado. Se cobrará cuando el servicio se complete.';

  @override
  String get pagoErrorGenerico =>
      'No se pudo procesar el pago. Inténtalo de nuevo.';

  @override
  String get pagoErrorStripeDefault => 'El pago no se completó';

  @override
  String get pagoCancelado => 'Has cancelado el pago';

  @override
  String get valoracionTitulo => '¿Cómo fue el servicio?';

  @override
  String get valoracionErrorSeleccion => 'Selecciona una puntuación';

  @override
  String get valoracionErrorEnviar =>
      'No se pudo enviar la valoración. Inténtalo de nuevo.';

  @override
  String get valoracionComentarioLabel => 'Comentario (opcional)';

  @override
  String get valoracionBtnEnviar => 'Enviar valoración';

  @override
  String get progresoBuscando => 'Buscando profesionales';

  @override
  String get progresoSeleccionado => 'Profesional seleccionado';

  @override
  String get progresoFinalizado => 'Trabajo finalizado';

  @override
  String get misSolicitudesError => 'No se pudieron cargar tus solicitudes';

  @override
  String get misSolicitudesVacio => 'Aún no has hecho ninguna solicitud';

  @override
  String get misSolicitudesBorrarTitulo => '¿Borrar esta solicitud?';

  @override
  String get misSolicitudesBorrarMensaje =>
      'Se eliminará de tu historial. Esta acción no se puede deshacer.';

  @override
  String get misSolicitudesBorrarConfirmar => 'Borrar';

  @override
  String get misSolicitudesBorrarExito => 'Solicitud borrada';

  @override
  String get misSolicitudesBorrarError => 'No se pudo borrar la solicitud';

  @override
  String get misSolicitudesArchivarTitulo =>
      '¿Quitar esta solicitud de la lista?';

  @override
  String get misSolicitudesArchivarMensaje =>
      'Se ocultará de tu historial, pero el pago, el chat y las valoraciones se conservan.';

  @override
  String get misSolicitudesArchivarConfirmar => 'Quitar';

  @override
  String get misSolicitudesArchivarExito => 'Solicitud quitada de la lista';

  @override
  String get misSolicitudesArchivarError => 'No se pudo quitar la solicitud';

  @override
  String get misSolicitudesAccionRequerida => 'Necesita tu confirmación';

  @override
  String get trabajosActivosArchivarTitulo =>
      '¿Quitar este trabajo de la lista?';

  @override
  String get trabajosActivosArchivarMensaje =>
      'Se ocultará de tu historial, pero el pago, el chat y las valoraciones se conservan.';

  @override
  String get trabajosActivosArchivarConfirmar => 'Quitar';

  @override
  String get trabajosActivosArchivarExito => 'Trabajo quitado de la lista';

  @override
  String get trabajosActivosArchivarError => 'No se pudo quitar el trabajo';

  @override
  String get wizardTitulo => 'Nueva solicitud';

  @override
  String wizardPaso(int actual, int total) {
    return 'Paso $actual de $total';
  }

  @override
  String get wizardSiguiente => 'Siguiente';

  @override
  String get wizardPublicar => 'Publicar solicitud';

  @override
  String get wizardErrorCategoria => 'Elige una categoría para continuar';

  @override
  String get wizardErrorDescripcion =>
      'Describe el trabajo con un poco más de detalle';

  @override
  String get wizardErrorUbicacion => 'Elige dónde necesitas el servicio';

  @override
  String get wizardErrorFecha => 'Elige una fecha';

  @override
  String get wizardErrorFotosSubiendo =>
      'Espera a que terminen de subirse las fotos';

  @override
  String get fotoErrorSubir => 'No se pudo subir la foto. Inténtalo de nuevo.';

  @override
  String get wizardPaso1Titulo => '¿Qué necesitas?';

  @override
  String get wizardCategoriaCambiar => 'Cambiar';

  @override
  String get wizardCategoriaElegirTitulo => 'Elige una categoría';

  @override
  String get wizardPaso2Titulo => 'Describe el trabajo';

  @override
  String get wizardPaso2Ayuda =>
      'Cuanto más detalle des, mejor podrán ayudarte los profesionales';

  @override
  String get wizardPaso3Titulo => 'Añade fotos (opcional)';

  @override
  String get wizardPaso3Ayuda =>
      'Una foto ayuda al profesional a entender el problema antes de llegar';

  @override
  String get wizardFotoCamara => 'Hacer una foto';

  @override
  String get wizardFotoGaleria => 'Elegir de la galería';

  @override
  String get wizardPaso4Titulo => '¿Dónde es el trabajo?';

  @override
  String get wizardPaso4Ayuda =>
      'Usaremos esta ubicación para encontrar profesionales cerca';

  @override
  String get wizardUbicacionElegir => 'Elegir en el mapa';

  @override
  String get wizardUbicacionCambiar => 'Cambiar ubicación';

  @override
  String get wizardPaso5Titulo => '¿Cuándo lo necesitas?';

  @override
  String get wizardUrgenciaAsap => 'Lo antes posible';

  @override
  String get wizardUrgenciaHoy => 'Hoy';

  @override
  String get wizardUrgenciaManana => 'Mañana';

  @override
  String get wizardUrgenciaFecha => 'Elegir una fecha';

  @override
  String get wizardSeleccionarFecha => 'Seleccionar fecha';

  @override
  String get wizardPaso6Titulo => 'Revisa tu solicitud';

  @override
  String get ubicacionTitulo => 'Elegir ubicación';

  @override
  String get ubicacionDireccionOpcional => 'Dirección o referencia (opcional)';

  @override
  String get ubicacionConfirmar => 'Confirmar ubicación';

  @override
  String get ubicacionAvisoNoDetectada =>
      'No pudimos detectar tu ubicación GPS — mueve el mapa hasta tu zona antes de confirmar';

  @override
  String get adminTituloPanel => 'Panel admin';

  @override
  String get adminTabVerificaciones => 'Verificaciones';

  @override
  String get adminTabDisputas => 'Disputas';

  @override
  String get adminVerificacionesVacio => 'No hay verificaciones pendientes';

  @override
  String get adminVerificacionesError =>
      'No se pudieron cargar las verificaciones';

  @override
  String get adminDisputasVacio => 'No hay disputas abiertas';

  @override
  String get adminDisputasError => 'No se pudieron cargar las disputas';

  @override
  String adminCategoriasLabel(String categorias) {
    return 'Categorías: $categorias';
  }

  @override
  String get adminVerDocumento => 'Ver documento de identidad';

  @override
  String get adminDocumentoSinEnviar => 'Sin documento de identidad enviado';

  @override
  String get adminRechazar => 'Rechazar';

  @override
  String get adminAprobar => 'Aprobar';

  @override
  String get adminFavorCliente => 'A favor del cliente';

  @override
  String get adminFavorProfesional => 'A favor del profesional';

  @override
  String get adminMotivoRechazoTitulo => 'Motivo del rechazo';

  @override
  String get adminMotivoRechazoHint => 'Explica brevemente por qué se rechaza';

  @override
  String get adminMotivoRechazoAyuda =>
      'Mínimo 5 caracteres — el profesional lo verá';

  @override
  String get adminNotasResolucionTitulo => 'Notas de la resolución';

  @override
  String get adminNotasResolucionHint => 'Explica brevemente cómo se resolvió';

  @override
  String get adminNotasResolucionAyuda =>
      'Mínimo 5 caracteres — quedará registrado en la disputa';

  @override
  String get adminConfirmar => 'Confirmar';

  @override
  String get adminDecisionError =>
      'No se pudo registrar la decisión. Inténtalo de nuevo.';

  @override
  String get adminResolucionError =>
      'No se pudo registrar la resolución. Inténtalo de nuevo.';

  @override
  String get adminTabPagosAtascados => 'Pagos atascados';

  @override
  String get adminPagosAtascadosVacio => 'No hay pagos atascados';

  @override
  String get adminPagosAtascadosError =>
      'No se pudieron cargar los pagos atascados';

  @override
  String adminPagosAtascadosResumen(int total, String importe) {
    return 'Total: $total · Retenido en la plataforma: $importe €';
  }

  @override
  String get adminPagoAtascadoCapturadoSinTransferir =>
      'Capturado, sin transferir al profesional';

  @override
  String get adminPagoAtascadoCompletadoSinCapturar =>
      'Trabajo completado, autorización sin capturar';

  @override
  String adminPagoAtascadoAutorizadoEl(String fecha) {
    return 'Autorizado el $fecha';
  }

  @override
  String adminPagoAtascadoCapturadoEl(String fecha) {
    return 'Capturado el $fecha';
  }

  @override
  String adminPagoAtascadoIntentos(int n) {
    return 'Intentos de liberación: $n';
  }

  @override
  String adminPagoAtascadoUltimoError(String error) {
    return 'Último error: $error';
  }

  @override
  String get adminPagoAtascadoSinProfesional => 'Sin profesional asignado';

  @override
  String adminContracargoBadge(String estado, String monto) {
    return '⚠️ Contracargo Stripe: $estado, $monto €';
  }

  @override
  String get adminContracargoVerEnStripe => 'Ver en Stripe';

  @override
  String get adminContracargoBloqueaReintento => 'Bloqueado por disputa';

  @override
  String get adminContracargoErrorAbrirStripe => 'No se pudo abrir Stripe';

  @override
  String get adminReintentarLiberacion => 'Reintentar liberación';

  @override
  String get adminReintentarLiberacionConfirmarTitulo =>
      '¿Reintentar liberación?';

  @override
  String get adminReintentarLiberacionConfirmarTexto =>
      'Se intentará capturar y transferir este pago de nuevo. Es seguro repetir la operación aunque ya esté en curso o parcialmente hecha.';

  @override
  String get adminReintentarLiberacionExito =>
      'Liberación completada correctamente';

  @override
  String get adminTabTareas => 'Tareas programadas';

  @override
  String get adminTareasVacio => 'No hay tareas programadas';

  @override
  String get adminTareasError => 'No se pudieron cargar las tareas programadas';

  @override
  String get adminTareaEnCurso => 'En curso';

  @override
  String adminTareaCada(int n) {
    return 'Cada $n min';
  }

  @override
  String adminTareaUltimaEjecucion(String fecha) {
    return 'Última ejecución: $fecha';
  }

  @override
  String get adminTareaNuncaEjecutada => 'Todavía no se ha ejecutado nunca';

  @override
  String adminTareaProximaEjecucion(String fecha) {
    return 'Próxima aprox.: $fecha';
  }

  @override
  String adminTareaEjecuciones(int n) {
    return 'Ejecuciones: $n';
  }

  @override
  String adminTareaFallosConsecutivos(int n) {
    return 'Fallos consecutivos: $n';
  }

  @override
  String adminTareaUltimoResultado(String texto) {
    return 'Último resultado: $texto';
  }

  @override
  String adminTareaUltimoError(String texto) {
    return 'Último error: $texto';
  }

  @override
  String get adminEjecutarAhora => 'Ejecutar ahora';

  @override
  String get adminEjecutarAhoraConfirmarTitulo => '¿Ejecutar esta tarea ahora?';

  @override
  String get adminEjecutarAhoraConfirmarTexto =>
      'Se forzará su ejecución sin esperar al siguiente ciclo. Si ya está en curso, no se duplicará.';

  @override
  String get adminEjecutarAhoraExito => 'Tarea ejecutada correctamente';

  @override
  String get adminTabUsuarios => 'Usuarios';

  @override
  String get adminUsuarioIdLabel => 'ID del usuario';

  @override
  String get adminUsuarioIdHint => 'Pega o escribe el ID (UUID)';

  @override
  String get adminUsuarioBuscarBoton => 'Buscar';

  @override
  String get adminUsuarioBusquedaError => 'No se pudo encontrar el usuario';

  @override
  String get adminUsuarioEstadoActivo => 'Activo';

  @override
  String get adminUsuarioEstadoBloqueado => 'Bloqueado';

  @override
  String get adminUsuarioCuentaEliminada =>
      'Esta cuenta fue eliminada por el propio usuario (RGPD) — no se puede reactivar.';

  @override
  String get adminUsuarioBloquear => 'Bloquear';

  @override
  String get adminUsuarioActivar => 'Activar';

  @override
  String get adminUsuarioBloquearConfirmarTitulo => '¿Bloquear a este usuario?';

  @override
  String get adminUsuarioBloquearConfirmarTexto =>
      'No podrá iniciar sesión hasta que lo actives de nuevo.';

  @override
  String get adminUsuarioActivarConfirmarTitulo => '¿Activar a este usuario?';

  @override
  String get adminUsuarioActivarConfirmarTexto =>
      'Podrá volver a iniciar sesión con normalidad.';

  @override
  String get adminUsuarioCambioExito => 'Estado actualizado correctamente';

  @override
  String get reportarProblemaTitulo => 'Reportar un problema';

  @override
  String get reportarProblemaMotivoLabel => '¿Qué ha pasado?';

  @override
  String get reportarProblemaMotivoProfesionalNoPresento =>
      'El profesional no se presentó';

  @override
  String get reportarProblemaMotivoClienteAusente =>
      'El cliente no estaba en la dirección';

  @override
  String get reportarProblemaMotivoTrabajoCancelado =>
      'El trabajo fue cancelado';

  @override
  String get reportarProblemaMotivoProblemaPago => 'Problema con el pago';

  @override
  String get reportarProblemaMotivoComportamiento =>
      'Comportamiento inapropiado';

  @override
  String get reportarProblemaMotivoOtro => 'Otro';

  @override
  String get reportarProblemaDescripcionLabel => 'Describe lo ocurrido';

  @override
  String get reportarProblemaDescripcionHint =>
      'Cuéntanos con detalle qué ha pasado';

  @override
  String get reportarProblemaFotosLabel => 'Fotos (opcional)';

  @override
  String get reportarProblemaEnviar => 'Enviar reclamación';

  @override
  String get reportarProblemaExito =>
      'Reclamación enviada — nuestro equipo la revisará';

  @override
  String get reportarProblemaError => 'No se pudo enviar la reclamación';

  @override
  String get reportarProblemaBoton => 'Reportar un problema';

  @override
  String seguimientoVerCandidatos(int n) {
    return 'Ver candidatos ($n)';
  }

  @override
  String get seleccionarProfesionalTitulo => 'Elegir profesional';

  @override
  String get seleccionarProfesionalElegir => 'Elegir profesional';

  @override
  String get seleccionarProfesionalConfirmarTitulo => '¿Confirmar elección?';

  @override
  String seleccionarProfesionalConfirmarTexto(String nombre) {
    return '$nombre quedará asignado a este trabajo. El resto de candidatos serán descartados.';
  }

  @override
  String get seleccionarProfesionalError =>
      'No se pudo completar la selección. Puede que otra persona ya haya elegido.';

  @override
  String get seleccionarProfesionalVacio =>
      'Todavía no hay ninguna candidatura recibida — vuelve más tarde';

  @override
  String get trabajosActivosEnviarPresupuesto => 'Enviar presupuesto';

  @override
  String get trabajosActivosPresupuestoEsperando =>
      'Esperando respuesta del cliente';

  @override
  String get trabajosActivosHorasRealesTitulo => 'Horas reales trabajadas';

  @override
  String trabajosActivosHorasRealesTarifa(String tarifa) {
    return 'Tarifa acordada: $tarifa €/hora';
  }

  @override
  String get trabajosActivosHorasRealesHint => 'Horas';

  @override
  String get trabajosActivosCompletarCerradoConfirmar =>
      '¿Confirmas que el trabajo está completado? Se liberará el pago del presupuesto acordado.';

  @override
  String get presupuestoDialogoTitulo => 'Enviar presupuesto';

  @override
  String get presupuestoTipoCerrado => 'Precio cerrado';

  @override
  String get presupuestoTipoPorHoras => 'Por horas';

  @override
  String get presupuestoDialogoMontoHint => 'Importe (€)';

  @override
  String get presupuestoDialogoTarifaHint => 'Tarifa por hora (€)';

  @override
  String get presupuestoDialogoHorasEstimadasHint => 'Horas estimadas';

  @override
  String get presupuestoDialogoMensajeHint =>
      'Mensaje para el cliente (opcional)';

  @override
  String get presupuestoDialogoIncluyeIva => 'Este presupuesto incluye IVA';

  @override
  String get presupuestoEnviadoExito => 'Presupuesto enviado';

  @override
  String get presupuestoEnviadoError => 'No se pudo enviar el presupuesto';

  @override
  String get seguimientoEsperandoPresupuesto =>
      'Esperando el presupuesto del profesional';

  @override
  String get seguimientoPresupuestoTitulo =>
      'El profesional ha enviado un presupuesto';

  @override
  String seguimientoPresupuestoCerradoDetalle(String monto) {
    return 'Presupuesto: $monto €';
  }

  @override
  String seguimientoPresupuestoPorHorasDetalle(
      String tarifa, String horas, String total) {
    return '$tarifa €/hora × $horas horas estimadas — importe máximo autorizado: $total €';
  }

  @override
  String get seguimientoPresupuestoAceptar => 'Aceptar';

  @override
  String get seguimientoPresupuestoRechazar => 'Rechazar';

  @override
  String get seguimientoPresupuestoRechazarConfirmar =>
      '¿Seguro que quieres rechazar este presupuesto? El profesional podrá enviarte uno nuevo.';

  @override
  String get seguimientoPresupuestoAceptadoExito =>
      'Presupuesto aceptado — ya puedes autorizar el pago';

  @override
  String get seguimientoPresupuestoRechazadoExito => 'Presupuesto rechazado';

  @override
  String get seguimientoPresupuestoRechazadoInfo =>
      'Rechazaste el presupuesto anterior — esperando uno nuevo del profesional';

  @override
  String get seguimientoPresupuestoError =>
      'No se pudo responder al presupuesto';

  @override
  String seguimientoDesgloseComision(
      String base, String comision, String total) {
    return 'Presupuesto: $base € + gastos de gestión: $comision € = total a pagar: $total €';
  }

  @override
  String get seguimientoPromoLanzamiento => '🎉 Promoción de lanzamiento';

  @override
  String get desglosePagoPresupuestoLabel => 'Presupuesto';

  @override
  String get desglosePagoGastosGestionLabel => 'Gastos de gestión';

  @override
  String get desglosePagoGastosGestionInfo =>
      'Los gastos de gestión incluyen la verificación de identidad del profesional, el pago protegido hasta la finalización del trabajo y el soporte de Hogar SOS en caso de incidencias.';

  @override
  String get desglosePagoTotalLabel => 'Total';

  @override
  String get desglosePagoIvaIncluido =>
      'El profesional declara que este importe incluye IVA';

  @override
  String get desglosePagoIvaNoIncluido =>
      'El profesional declara que este importe no incluye IVA';

  @override
  String get trabajosActivosHorasEnviadasExito =>
      'Horas enviadas — esperando que el cliente las confirme';

  @override
  String get trabajosActivosPedirAmpliacionTitulo => 'Pedir más horas';

  @override
  String get trabajosActivosPedirAmpliacionHorasHint => 'Horas adicionales';

  @override
  String get trabajosActivosPedirAmpliacionError =>
      'No se pudo enviar la petición de ampliación';

  @override
  String get trabajosActivosPedirAmpliacionExito => 'Ampliación enviada';

  @override
  String get trabajosActivosPedirAmpliacion => 'Pedir más horas';

  @override
  String get trabajosActivosAmpliacionEsperando =>
      'Esperando respuesta a tu petición de más horas';

  @override
  String get trabajosActivosCierreEsperando =>
      'Esperando que el cliente confirme las horas';

  @override
  String get trabajosActivosAmpliarPresupuesto => 'Ampliar presupuesto';

  @override
  String get trabajosActivosAmpliarPresupuestoTitulo => 'Ampliar presupuesto';

  @override
  String get trabajosActivosAmpliarPresupuestoMontoHint =>
      'Importe adicional (€)';

  @override
  String get trabajosActivosAmpliacionMotivoHint => 'Motivo (opcional)';

  @override
  String get trabajosActivosEstadoSinPresupuesto => 'Sin presupuesto';

  @override
  String get trabajosActivosEstadoPresupuestoPendiente => 'Pendiente';

  @override
  String get trabajosActivosEstadoPresupuestoAceptado => 'Aceptado';

  @override
  String get trabajosActivosEstadoEnCurso => 'En curso';

  @override
  String get trabajosActivosEstadoAmpliacionPendiente => 'Ampliación pendiente';

  @override
  String get trabajosActivosEstadoCierrePendiente => 'Confirmación pendiente';

  @override
  String get trabajosActivosEstadoPagoLiberado => 'Pago liberado';

  @override
  String trabajosActivosDesgloseComision(
      String base, String comision, String recibiras) {
    return 'Importe del trabajo: $base € · Gastos de gestión: $comision € · Recibirás: $recibiras €';
  }

  @override
  String get trabajosActivosPromoLanzamiento =>
      '✅ Sin gastos de gestión para ti';

  @override
  String get seguimientoAmpliacionAceptadaExito => 'Ampliación aceptada';

  @override
  String get seguimientoAmpliacionRechazadaExito => 'Ampliación rechazada';

  @override
  String get seguimientoAmpliacionError =>
      'No se pudo responder a la ampliación';

  @override
  String get seguimientoAmpliacionTitulo =>
      'El profesional necesita más tiempo';

  @override
  String get seguimientoAmpliacionTituloMonto =>
      'El profesional pide ampliar el presupuesto';

  @override
  String seguimientoAmpliacionDetalle(String horas, String importe) {
    return '$horas horas adicionales — importe adicional: $importe €';
  }

  @override
  String seguimientoAmpliacionMontoDetalle(String importe) {
    return 'Importe adicional: $importe €';
  }

  @override
  String get seguimientoCierreHorasConfirmadoExito =>
      'Horas confirmadas — pago liberado';

  @override
  String get seguimientoCierreHorasError =>
      'No se pudo responder al cierre de horas';

  @override
  String get seguimientoCierreHorasTitulo =>
      'El profesional ha terminado el trabajo';

  @override
  String get seguimientoCierreHorasLabelEstimadas => 'Horas estimadas';

  @override
  String get seguimientoCierreHorasLabelReales => 'Horas realizadas';

  @override
  String get seguimientoCierreHorasLabelTarifa => 'Tarifa';

  @override
  String get seguimientoCierreHorasLabelImporte => 'Importe final';

  @override
  String seguimientoCierreHorasAvisoReduccion(String porcentaje) {
    return 'Las horas declaradas son un $porcentaje% de lo estimado. Revisa el importe antes de confirmar.';
  }

  @override
  String get seguimientoCierreHorasDialogoTitulo =>
      '¿Confirmar esta reducción?';

  @override
  String seguimientoCierreHorasDialogoDetalle(
      String reales, String estimadas, String porcentaje) {
    return 'El profesional declaró $reales h reales frente a las $estimadas h estimadas ($porcentaje%). Si confirmas, se cobrará solo el importe de las horas reales y se liberará el resto de lo retenido en tu tarjeta.';
  }

  @override
  String get seguimientoCierreHorasDialogoCancelar => 'Cancelar';

  @override
  String get seguimientoCierreHorasDialogoConfirmar =>
      'Confirmar de todas formas';

  @override
  String get seguimientoCierreHorasReclamar => 'Reclamar';

  @override
  String get seguimientoCierreHorasConfirmar => 'Confirmar';
}
