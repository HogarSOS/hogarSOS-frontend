import 'package:dio/dio.dart';
import '../l10n/app_localizations.dart';

/// Traduce el `code` estable que manda el backend (ver
/// `res.status(...).json({ error: '...', code: 'ALGO' })` en cada
/// controlador) a un texto localizado. Antes se mostraba directamente
/// `data['error']`, el texto en español que el backend escribe para
/// sus propios logs — eso significaba que CUALQUIER error de negocio
/// (solicitud no encontrada, ya te has postulado, presupuesto no
/// pendiente...) aparecía en español sin importar el idioma de la app.
/// Ahora el backend manda ambos campos: `error` (para logs/depuración)
/// y `code` (estable, para traducir aquí). Un código que no esté en
/// este mapa (versión de la app más vieja que el backend, o un caso
/// nuevo sin migrar) cae al mensaje genérico en vez de mostrar texto
/// sin traducir — perder precisión es preferible a perder el idioma.
String? _mensajePorCodigo(String? code, AppLocalizations t) {
  switch (code) {
    case 'VALIDATION_INVALID':
      return t.apiErrDatosInvalidos;
    case 'AUTH_FORBIDDEN':
      return t.apiErrSinPermiso;
    case 'AUTH_TOKEN_INVALID':
    case 'AUTH_REFRESH_TOKEN_INVALID':
      return t.apiErrTokenInvalido;
    case 'VERIFICATION_REJECT_REASON_REQUIRED':
      return t.apiErrMotivoRechazoRequerido;
    case 'PROFESSIONAL_NOT_FOUND':
      return t.apiErrProfesionalNoEncontrado;
    case 'VERIFICATION_NOT_PENDING':
      return t.apiErrVerificacionNoPendiente;
    case 'DISPUTE_NOT_FOUND':
      return t.apiErrDisputaNoEncontrada;
    case 'DISPUTE_ALREADY_RESOLVED':
      return t.apiErrDisputaResuelta;
    case 'DISPUTE_RESOLUTION_STRIPE_FAILED':
      return t.apiErrResolucionStripeFallida;
    case 'EXTENSION_INVALID_DATA':
      return t.apiErrAmpliacionDatosInvalidos;
    case 'CONTACT_INFO_BLOCKED':
      return t.apiErrDatosContactoBloqueados;
    case 'REQUEST_NOT_FOUND':
      return t.apiErrSolicitudNoEncontrada;
    case 'NOT_ASSIGNED_PROFESSIONAL':
      return t.apiErrNoEresProfesionalAsignado;
    case 'REQUEST_INVALID_STATE_EXTENSION':
      return t.apiErrEstadoInvalidoAmpliacion;
    case 'NO_ACCEPTED_BUDGET':
      return t.apiErrSinPresupuestoAceptado;
    case 'EXTENSION_HOURS_REQUIRED':
      return t.apiErrHorasAdicionalesRequeridas;
    case 'EXTENSION_AMOUNT_REQUIRED':
      return t.apiErrImporteAdicionalRequerido;
    case 'EXTENSION_ALREADY_PENDING':
      return t.apiErrAmpliacionYaPendiente;
    case 'EXTENSION_DECISION_REQUIRED':
      return t.apiErrDecisionAmpliacionRequerida;
    case 'REQUEST_NO_ACCESS':
      return t.apiErrSinAccesoSolicitud;
    case 'EXTENSION_NOT_FOUND':
      return t.apiErrAmpliacionNoEncontrada;
    case 'EXTENSION_NOT_PENDING':
      return t.apiErrAmpliacionNoPendiente;
    case 'AUTH_USER_ALREADY_EXISTS':
      return t.apiErrUsuarioYaExiste;
    case 'AUTH_NO_ACCOUNT':
      return t.apiErrSinCuenta;
    case 'AUTH_ACCOUNT_DISABLED':
      return t.apiErrCuentaDesactivada;
    case 'DISPUTE_ONLY_ON_ACCEPTED_JOB':
      return t.apiErrReclamacionSoloTrabajoAceptado;
    case 'DISPUTE_ALREADY_OPEN':
      return t.apiErrReclamacionYaAbierta;
    case 'PAYMENT_REQUEST_NOT_ACCEPTED':
      return t.apiErrSolicitudNoAceptada;
    case 'PAYMENT_NOTHING_PENDING':
      return t.apiErrNadaPendienteAutorizar;
    case 'NOT_REQUEST_CLIENT':
      return t.apiErrNoEresCliente;
    case 'APPLICATION_NOT_AUTHORIZED':
      return t.apiErrNoAutorizadoPostular;
    case 'REQUEST_NO_LONGER_AVAILABLE':
      return t.apiErrSolicitudNoDisponible;
    case 'APPLICATION_ALREADY_SENT':
      return t.apiErrCandidaturaYaEnviada;
    case 'APPLICATION_NOT_FOUND':
      return t.apiErrCandidaturaNoEncontrada;
    case 'BUDGET_INVALID_DATA':
      return t.apiErrPresupuestoDatosInvalidos;
    case 'REQUEST_INVALID_STATE_BUDGET':
      return t.apiErrEstadoInvalidoPresupuesto;
    case 'BUDGET_ALREADY_PENDING':
      return t.apiErrPresupuestoYaPendiente;
    case 'BUDGET_DECISION_REQUIRED':
      return t.apiErrDecisionPresupuestoRequerida;
    case 'BUDGET_NOT_FOUND':
      return t.apiErrPresupuestoNoEncontrado;
    case 'BUDGET_NOT_PENDING':
      return t.apiErrPresupuestoNoPendiente;
    case 'PROFESSIONAL_PROFILE_NOT_FOUND':
      return t.apiErrPerfilProfesionalNoEncontrado;
    case 'PROFESSIONAL_NOT_VERIFIED':
      return t.apiErrProfesionalNoVerificado;
    case 'PROFESSIONAL_STRIPE_NOT_CONFIGURED':
      return t.apiErrCuentaStripeNoConfigurada;
    case 'CATEGORIES_INVALID':
      return t.apiErrCategoriasInvalidas;
    case 'SEARCH_PARAMS_INVALID':
      return t.apiErrParametrosBusquedaInvalidos;
    case 'REVIEW_ONLY_COMPLETED':
      return t.apiErrValorarSoloCompletado;
    case 'REVIEW_BLOCKED_BY_DISPUTE':
      return t.apiErrValoracionBloqueadaDisputa;
    case 'REQUEST_NO_PROFESSIONAL_ASSIGNED':
      return t.apiErrSinProfesionalAsignado;
    case 'REVIEW_NOT_PARTICIPANT':
      return t.apiErrNoParticipaste;
    case 'REVIEW_ALREADY_SENT':
      return t.apiErrYaValoraste;
    case 'REQUEST_DATE_REQUIRED':
      return t.apiErrFechaRequerida;
    case 'CATEGORY_INVALID':
      return t.apiErrCategoriaInvalida;
    case 'ACCOUNT_NOT_VERIFIED':
      return t.apiErrCuentaNoVerificada;
    case 'REQUEST_ONLY_CREATOR_CANCEL':
      return t.apiErrSoloCreadorCancela;
    case 'REQUEST_CANNOT_CANCEL':
      return t.apiErrNoSePuedeCancelar;
    case 'REQUEST_IN_PROGRESS_USE_DISPUTE':
      return t.apiErrTrabajoEnCursoUsaDisputa;
    case 'REQUEST_ONLY_CREATOR_DELETE':
      return t.apiErrSoloCreadorBorra;
    case 'REQUEST_CANNOT_DELETE_ACCEPTED':
      return t.apiErrNoSePuedeBorrar;
    case 'REQUEST_CANNOT_ARCHIVE':
      return t.apiErrNoSePuedeArchivar;
    case 'CHAT_MESSAGE_REQUIRED':
      return t.apiErrMensajeRequerido;
    case 'REQUEST_INVALID_STATE_COMPLETE':
      return t.apiErrEstadoInvalidoCompletar;
    case 'PAYMENT_NOT_AUTHORIZED':
      return t.apiErrPagoNoAutorizado;
    case 'HOURS_REQUIRED':
      return t.apiErrHorasRequeridas;
    case 'HOURS_CLOSURE_ALREADY_PENDING':
      return t.apiErrCierreYaPendiente;
    case 'HOURS_DECISION_REQUIRED':
      return t.apiErrDecisionHorasRequerida;
    case 'HOURS_CLOSURE_NOT_FOUND':
      return t.apiErrCierreNoEncontrado;
    case 'HOURS_CLOSURE_NOT_PENDING':
      return t.apiErrCierreNoPendiente;
    case 'UPLOAD_NO_FILE':
      return t.apiErrSinArchivo;
    case 'USER_NOT_FOUND':
      return t.apiErrUsuarioNoEncontrado;
    // Códigos de `retryPaymentRelease` (panel admin, cola de pagos
    // atascados) — ver el mapa `respuestas` en `admin.controller.ts`.
    // 'SOLICITUD_NO_ENCONTRADA' reutiliza el mismo texto que
    // 'REQUEST_NOT_FOUND' de arriba (mismo significado, nombre de código
    // distinto porque ese endpoint concreto no sigue la convención en
    // inglés del resto del backend).
    case 'SOLICITUD_NO_ENCONTRADA':
      return t.apiErrSolicitudNoEncontrada;
    case 'PAGO_NO_ENCONTRADO':
      return t.apiErrPagoAtascadoNoEncontrado;
    case 'LIBERACION_YA_EN_CURSO':
      return t.apiErrLiberacionEnCurso;
    case 'PAGO_NO_AUTORIZADO_TODAVIA':
      return t.apiErrPagoNoAutorizadoTodavia;
    case 'PROFESIONAL_SIN_CUENTA_STRIPE':
      return t.apiErrProfesionalSinCuentaStripe;
    case 'PROFESIONAL_CUENTA_STRIPE_NO_OPERATIVA':
      return t.apiErrCuentaStripeNoOperativa;
    case 'PAYMENT_RETRY_STRIPE_FAILED':
      return t.apiErrReintentoStripeFallido;
    // Códigos de `runJob` (panel admin, pestaña "Tareas programadas") —
    // ver el switch de `admin.controller.ts`.
    case 'JOB_NOT_FOUND':
      return t.apiErrTareaNoEncontrada;
    case 'JOB_ALREADY_RUNNING':
      return t.apiErrTareaYaEnCurso;
    case 'JOB_FAILED':
      return t.apiErrTareaFallida;
    // Códigos de `toggleUserActive` (panel admin, pestaña "Usuarios") —
    // ver el switch de `admin.controller.ts`. USER_NOT_FOUND ya está
    // mapeado más arriba, se reutiliza tal cual.
    case 'ADMIN_CANNOT_TOGGLE_SELF':
      return t.apiErrAdminNoPuedeAutoBloquearse;
    case 'ADMIN_CANNOT_BLOCK_LAST_ADMIN':
      return t.apiErrUltimoAdminActivo;
    case 'ADMIN_CANNOT_REACTIVATE_DELETED_ACCOUNT':
      return t.apiErrCuentaEliminadaNoReactivable;
    // Límite de intentos en login/register/forgot-password (auditoría de
    // cierre). Reutiliza el mismo texto que ya existe para el
    // 'too-many-requests' de Firebase — el significado para el usuario
    // es idéntico independientemente de qué lado puso el límite.
    case 'RATE_LIMITED':
      return t.authErrorDemasiadosIntentos;
    default:
      return null;
  }
}

/// Extrae un mensaje legible y localizado de un error de red.
///
/// Antes, varias pantallas mostraban `'$e'` directamente en el
/// SnackBar — para un DioException eso imprime algo como
/// "DioException [bad response]: ...", NUNCA el mensaje real. Luego se
/// pasó a leer `data['error']` tal cual, que sí era legible pero
/// siempre en español (ver comentario de `_mensajePorCodigo` arriba).
/// Ahora se traduce por `code` primero, y solo si el backend no manda
/// uno reconocido se cae al `contexto` que pase la pantalla o al
/// mensaje genérico — nunca al texto en español sin traducir.
///
/// `t` es opcional (no siempre hay un `BuildContext` a mano) — sin él,
/// todo cae al español fijo, igual que antes de la Sprint 2.
String mensajeDeError(Object error, {String? contexto, AppLocalizations? t}) {
  final errorConexion = t?.errorConexion ?? 'No se pudo conectar con el servidor. Comprueba tu conexión.';
  final errorServidorLento = t?.errorServidorLento ?? 'El servidor tardó demasiado en responder.';
  final errorInesperado = t?.errorInesperado ?? 'Ocurrió un error inesperado.';

  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final code = data['code'];
      if (code is String && t != null) {
        final mensaje = _mensajePorCodigo(code, t);
        if (mensaje != null) return mensaje;
      }
      // Sin `t` (no hay BuildContext) o código no reconocido: si aun así
      // hay un texto de error del backend, es mejor que el genérico
      // cuando no hay forma de traducirlo (caso `t == null`); con `t`
      // disponible, un código no reconocido ya cae al genérico
      // localizado más abajo en vez de aquí, para no mostrar español.
      if (t == null && data['error'] is String) {
        return data['error'] as String;
      }
    }
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return errorConexion;
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return errorServidorLento;
      default:
        return contexto ?? errorInesperado;
    }
  }
  return contexto ?? errorInesperado;
}

/// Igual que `_mensajePorCodigo`, pero para los códigos que solo puede
/// producir el flujo de autenticación: los propios de Firebase Auth
/// (`e.code` de `FirebaseAuthException`, ya son identificadores
/// estables tipo `'wrong-password'`) más los sintéticos que genera
/// `AuthService` para fallos de red/servidor (`'connection'`,
/// `'timeout'`, `'server'`, `'unexpected'`) y los códigos de negocio
/// que puede mandar el backend en /auth/register y /auth/login (ver
/// mapa de arriba, reutilizados aquí porque son los mismos códigos).
String mensajeAuthError(String code, AppLocalizations t) {
  switch (code) {
    case 'email-already-in-use':
      return t.authErrorEmailEnUso;
    case 'invalid-email':
      return t.authErrorEmailInvalido;
    case 'weak-password':
      return t.authErrorPasswordDebil;
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return t.authErrorCredencialesIncorrectas;
    case 'network-request-failed':
    case 'connection':
      return t.errorConexion;
    case 'too-many-requests':
      return t.authErrorDemasiadosIntentos;
    case 'invalid-phone-number':
      return t.authErrorTelefonoInvalido;
    case 'invalid-verification-code':
      return t.authErrorCodigoIncorrecto;
    case 'session-expired':
    case 'code-expired':
      return t.authErrorCodigoCaducado;
    case 'quota-exceeded':
      return t.authErrorCuotaSms;
    case 'timeout':
      return t.errorServidorLento;
    case 'AUTH_USER_ALREADY_EXISTS':
      return t.apiErrUsuarioYaExiste;
    case 'AUTH_NO_ACCOUNT':
      return t.apiErrSinCuenta;
    case 'AUTH_ACCOUNT_DISABLED':
      return t.apiErrCuentaDesactivada;
    case 'server':
    case 'unexpected':
    default:
      return t.errorInesperado;
  }
}
