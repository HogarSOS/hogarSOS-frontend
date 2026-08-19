import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'installation_id_service.dart';
import 'notification_service.dart';
import 'token_storage.dart';

class AuthResult {
  final AppUser usuario;
  AuthResult(this.usuario);
}

/// `code` es un identificador estable, NO un texto para mostrar — los
/// códigos de Firebase (`FirebaseAuthException.code`, ej.
/// 'wrong-password') se pasan tal cual, los de red/servidor son
/// sintéticos ('connection', 'timeout', 'server', 'unexpected'), y los
/// de negocio del backend vienen en `data['code']` de la respuesta
/// (ver `res.status(...).json({ error: '...', code: '...' })` en cada
/// controlador). Traducir el código a texto es responsabilidad de la
/// pantalla que lo muestra (tiene el `BuildContext`/`AppLocalizations`
/// que este servicio no tiene) — ver `mensajeAuthError` en
/// `utils/error_extraction.dart`. Antes esta clase llevaba el mensaje
/// ya construido en español fijo, así que cualquier error de login
/// aparecía en español sin importar el idioma de la app.
class AuthException implements Exception {
  final String code;
  final Object? causa;
  AuthException(this.code, {this.causa});

  @override
  String toString() => 'AuthException: $code (causa: $causa)';
}

class AuthService {
  final _firebaseAuth = fb.FirebaseAuth.instance;
  final _api = ApiService.instance.client;

  Future<AuthResult> loginConGoogle() async {
    throw UnimplementedError(
      'Configurar google_sign_in en el proyecto nativo antes de usar este método',
    );
  }

  /// Pide a Firebase que mande el SMS con el código a `numeroTelefono`
  /// (formato E.164, ej. "+34612345678"). No hay una llamada "await
  /// que devuelva el código" — Firebase avisa por callbacks porque en
  /// Android puede autoverificar el SMS sola (sin que el usuario
  /// escriba nada) antes incluso de que el código "llegue" de verdad.
  ///
  /// - `onCodigoEnviado`: el SMS ya salió — la UI debe pasar a la
  ///   pantalla de introducir el código, guardando `verificationId`.
  /// - `onAutoVerificado`: Android leyó el SMS solo — ya hay una
  ///   credencial lista para completar sesión sin pedirle nada más al
  ///   usuario (ver completarConCredencialTelefono).
  /// - `onError`: número inválido, cuota de SMS agotada, etc.
  Future<void> enviarCodigoTelefono({
    required String numeroTelefono,
    required void Function(String verificationId) onCodigoEnviado,
    required void Function(fb.PhoneAuthCredential credential) onAutoVerificado,
    required void Function(String codigoError) onError,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: numeroTelefono,
      verificationCompleted: onAutoVerificado,
      verificationFailed: (e) {
        debugPrint('[AuthService] verifyPhoneNumber falló: ${e.code} — ${e.message}');
        onError(e.code);
      },
      codeSent: (verificationId, _) => onCodigoEnviado(verificationId),
      // Firebase sigue aceptando el código bastante después de este
      // timeout — esto solo controla cuánto tiempo intenta la
      // autoverificación por SMS antes de rendirse y dejar que el
      // usuario lo escriba a mano.
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  /// Construye la credencial a partir del código de 6 dígitos que
  /// escribió el usuario, y completa sesión con ella — mismo camino
  /// final que `onAutoVerificado` de arriba (ver
  /// `completarConCredencialTelefono`).
  Future<AuthResult> confirmarCodigoTelefono({
    required String verificationId,
    required String smsCode,
    required String nombre,
    required UserRole role,
    required bool esRegistro,
    bool recordarSesion = true,
  }) {
    final credential = fb.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return completarConCredencialTelefono(
      credential,
      nombre: nombre,
      role: role,
      esRegistro: esRegistro,
      recordarSesion: recordarSesion,
    );
  }

  /// Punto final común tanto para el código escrito a mano como para
  /// la autoverificación de Android — `signInWithCredential` funciona
  /// igual en los dos casos. A diferencia del email (donde
  /// `createUserWithEmailAndPassword` y `signInWithEmailAndPassword`
  /// son llamadas distintas que fallan solas si la cuenta no
  /// corresponde), con teléfono Firebase SIEMPRE deja entrar con un
  /// código válido — cree la cuenta de Firebase sola si hace falta,
  /// sin distinguir "login" de "registro". Por eso aquí SIEMPRE se
  /// revierte el usuario de Firebase si el backend falla, tanto en
  /// registro como en login: un código de SMS válido sin fila
  /// correspondiente en Postgres es el mismo estado huérfano en
  /// cualquiera de los dos casos.
  Future<AuthResult> completarConCredencialTelefono(
    fb.PhoneAuthCredential credential, {
    required String nombre,
    required UserRole role,
    required bool esRegistro,
    bool recordarSesion = true,
  }) async {
    fb.UserCredential credencial;
    try {
      credencial = await _firebaseAuth.signInWithCredential(credential);
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('[AuthService] signInWithCredential (teléfono) falló: ${e.code} — ${e.message}');
      throw AuthException(e.code, causa: e);
    }

    try {
      final firebaseIdToken = await credencial.user!.getIdToken();
      final respuesta = esRegistro
          ? await _api.post('/auth/register', data: {
              'firebaseIdToken': firebaseIdToken,
              'nombre': nombre,
              'role': role.name,
            })
          : await _api.post('/auth/login', data: {'firebaseIdToken': firebaseIdToken});

      return _guardarSesion(respuesta.data, recordarSesion: recordarSesion);
    } on DioException catch (e) {
      debugPrint('[AuthService] Fallo al completar con teléfono en el backend: ${e.type} — ${e.message}');
      await _revertirUsuarioFirebase(credencial);
      throw AuthException(_codigoDio(e), causa: e);
    } catch (e) {
      debugPrint('[AuthService] Error inesperado al completar con teléfono: $e');
      await _revertirUsuarioFirebase(credencial);
      throw AuthException('unexpected', causa: e);
    }
  }

  /// P2 #6: códigos que el backend devuelve cuando /auth/register
  /// rechaza explícitamente la petición SIN haber creado nada — ver
  /// auth.controller.ts (`register`). Son los únicos casos en los que
  /// es seguro revertir el usuario de Firebase: el backend confirmó
  /// que no hay fila en Postgres. Ante cualquier otra cosa (timeout,
  /// error de conexión, 500/INTERNAL_ERROR, una respuesta que no trae
  /// `code`, o un fallo posterior al guardar localmente) no sabemos si
  /// Postgres ya creó la cuenta, así que se conserva la identidad de
  /// Firebase — un reintento con el mismo firebaseUid se reconcilia
  /// solo contra el backend, ya idempotente por diseño.
  static const _codigosRechazoConfirmado = {
    'VALIDATION_INVALID',
    'AUTH_FIREBASE_TOKEN_INVALID',
    'AUTH_FIREBASE_TOKEN_NO_CONTACT',
    'AUTH_USER_ALREADY_EXISTS',
  };

  // No privado, static (con @visibleForTesting) a propósito: es la
  // decisión completa de "revertir o no" reducida a una función pura de
  // un DioException, sin ningún estado de instancia — así se puede
  // probar directamente sin construir un AuthService (su constructor
  // toca FirebaseAuth.instance, que exige Firebase.initializeApp() y
  // este proyecto no tiene mockito/mocktail ni un adaptador de Dio de
  // pruebas para simular ese arranque).
  @visibleForTesting
  static bool esRechazoConfirmadoDelBackend(DioException e) {
    final data = e.response?.data;
    final codigo = data is Map ? data['code']?.toString() : null;
    return codigo != null && _codigosRechazoConfirmado.contains(codigo);
  }

  /// Registro/login con email y contraseña vía Firebase, seguido del
  /// intercambio por el JWT propio. Si Firebase crea el usuario pero
  /// el backend RECHAZA explícitamente la petición (uno de los códigos
  /// de arriba), se revierte (borra) el usuario de Firebase. Ante
  /// cualquier fallo ambiguo (red, timeout, 500, o un fallo al guardar
  /// la sesión localmente DESPUÉS de un 201 exitoso) NO se revierte:
  /// no hay forma de saber desde aquí si el backend ya creó la cuenta,
  /// y borrar Firebase en ese caso es lo que deja al usuario bloqueado
  /// sin poder ni registrarse (email ya usado en Postgres) ni iniciar
  /// sesión (firebaseUid nuevo, sin fila correspondiente).
  Future<AuthResult> registrarConEmail({
    required String email,
    required String password,
    required String nombre,
    required UserRole role,
    bool recordarSesion = true,
  }) async {
    fb.UserCredential? credencial;

    try {
      credencial = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('[AuthService] FirebaseAuthException en registro: ${e.code} — ${e.message}');
      throw AuthException(e.code, causa: e);
    }

    try {
      final firebaseIdToken = await credencial.user!.getIdToken();

      final respuesta = await _api.post('/auth/register', data: {
        'firebaseIdToken': firebaseIdToken,
        'nombre': nombre,
        'role': role.name,
      });

      final resultado = await _guardarSesion(respuesta.data, recordarSesion: recordarSesion);

      // Después de guardar la sesión, no antes: si el registro en el
      // backend falla, revertimos el usuario de Firebase (más abajo) y
      // no tiene sentido haber mandado ya un email de verificación para
      // una cuenta que va a desaparecer. No se espera a que falle el
      // envío del email — un problema aquí no debe bloquear el
      // registro, que ya se completó correctamente.
      credencial.user!.sendEmailVerification().catchError((e) {
        debugPrint('[AuthService] No se pudo enviar el email de verificación: $e');
      });

      return resultado;
    } on DioException catch (e) {
      debugPrint('[AuthService] Fallo al registrar en el backend: ${e.type} — ${e.message}');
      if (AuthService.esRechazoConfirmadoDelBackend(e)) {
        await _revertirUsuarioFirebase(credencial);
      }
      throw AuthException(_codigoDio(e), causa: e);
    } catch (e) {
      // No es un DioException: la petición HTTP en sí no falló (o ni
      // siquiera se sabe si falló — puede ser getIdToken() antes de
      // llamar al backend, o _guardarSesion() DESPUÉS de un 201 ya
      // exitoso). En ninguno de los dos casos hay una confirmación del
      // backend de que no se creó nada, así que no se revierte Firebase.
      debugPrint('[AuthService] Error inesperado al registrar en el backend: $e');
      throw AuthException('unexpected', causa: e);
    }
  }

  Future<void> _revertirUsuarioFirebase(fb.UserCredential credencial) async {
    try {
      await credencial.user?.delete();
    } catch (e) {
      debugPrint('[AuthService] No se pudo revertir el usuario de Firebase: $e');
    }
  }

  Future<AuthResult> loginConEmail({
    required String email,
    required String password,
    bool recordarSesion = true,
  }) async {
    fb.UserCredential credencial;
    try {
      credencial = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('[AuthService] FirebaseAuthException en login: ${e.code} — ${e.message}');
      throw AuthException(e.code, causa: e);
    }

    try {
      final firebaseIdToken = await credencial.user!.getIdToken();
      final respuesta = await _api.post('/auth/login', data: {
        'firebaseIdToken': firebaseIdToken,
      });
      return _guardarSesion(respuesta.data, recordarSesion: recordarSesion);
    } on DioException catch (e) {
      debugPrint('[AuthService] Fallo al iniciar sesión en el backend: ${e.type} — ${e.message}');
      throw AuthException(_codigoDio(e), causa: e);
    }
  }

  /// `recordarSesion` es la casilla "Mantener sesión iniciada" del
  /// login — controla si los tokens se guardan en disco (sobreviven a
  /// cerrar la app del todo) o solo en memoria (se pierden, y el
  /// próximo arranque en frío manda al login). Ver token_storage.dart.
  Future<AuthResult> _guardarSesion(Map<String, dynamic> data, {required bool recordarSesion}) async {
    await TokenStorage.instance.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      persistente: recordarSesion,
    );
    final usuarioJson = data['usuario'] as Map<String, dynamic>;
    await TokenStorage.instance.saveUsuario(usuarioJson, persistente: recordarSesion);
    return AuthResult(AppUser.fromJson(usuarioJson));
  }

  /// Restaura la sesión al arrancar la app en frío. Refresca el access
  /// token contra el backend — es la única forma fiable de comprobar
  /// que el refresh token sigue siendo válido.
  ///
  /// Si el refresco falla, esta pantalla manda al login de todos modos
  /// (no hay forma de operar sin un access token fresco), pero NO borra
  /// los tokens guardados por su cuenta — eso ya lo decide
  /// intentarRefrescarToken() según el motivo real del fallo: solo los
  /// borra si el servidor rechazó el refresh token, no si fue un simple
  /// error de conexión. Así, con conexión intermitente (ej. `adb
  /// reverse` en un dispositivo físico), el próximo arranque con red
  /// puede recuperar la sesión en vez de forzar un login manual.
  ///
  /// Llamado únicamente desde AuthNotifier._restaurarSesionInicial()
  /// en auth_provider.dart.
  Future<AppUser?> restaurarSesion() async {
    final accessToken = await TokenStorage.instance.getAccessToken();
    final refreshToken = await TokenStorage.instance.getRefreshToken();
    final usuarioJson = await TokenStorage.instance.getUsuario();

    if (accessToken == null || refreshToken == null || usuarioJson == null) {
      return null;
    }

    final refrescado = await ApiService.instance.intentarRefrescarToken();
    if (!refrescado) {
      return null;
    }

    return AppUser.fromJson(usuarioJson);
  }

  /// Revoca la sesión en el backend (P2 #4) antes de limpiar el estado
  /// local. Best-effort a propósito: la llamada va ANTES de
  /// `TokenStorage.instance.clear()` porque necesita el access token
  /// todavía guardado para autenticarse, pero si falla (sin red,
  /// backend caído) el logout local se completa igualmente — un fallo
  /// de red nunca debe dejar a alguien atrapado sin poder cerrar
  /// sesión en su propio dispositivo.
  ///
  /// P2 #5: manda también el installationId de ESTE dispositivo, para
  /// que el backend borre solo su UserFcmToken (deja de recibir push
  /// de inmediato) sin tocar los de otros dispositivos del mismo
  /// usuario.
  Future<void> logout() async {
    try {
      final installationId = await InstallationIdService.instance.obtener();
      await ApiService.instance.client.post('/auth/logout', data: {'installationId': installationId});
    } catch (e) {
      debugPrint('[AuthService] Fallo al revocar la sesión en el backend (logout local continúa): $e');
    }
    // Aunque la revocación en el backend haya fallado (p. ej. access token
    // caducado → 401, que corta antes de borrar el UserFcmToken de este
    // dispositivo), invalida el token FCM en el propio aparato para dejar
    // de recibir push de inmediato. Ver NotificationService.desregistrarTokenLocal().
    await NotificationService.instance.desregistrarTokenLocal();
    await _firebaseAuth.signOut();
    await TokenStorage.instance.clear();
  }

  /// Pide al backend que genere el enlace de restablecimiento (Admin
  /// SDK de Firebase) y lo envíe por email con NUESTRA propia página de
  /// destino (`/auth/reset-password`, con confirmación de contraseña).
  /// Antes esto llamaba directamente a
  /// `_firebaseAuth.sendPasswordResetEmail`, que usa la página nativa
  /// de Firebase — con un solo campo de contraseña, sin confirmar, lo
  /// que causaba el BUG 001 de QA (un error de tecleo pasaba
  /// desapercibido). Ver `auth.controller.ts#forgotPassword`.
  Future<void> enviarEmailRecuperacion(String email) async {
    try {
      await _api.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      final codigo = e.response?.data is Map ? (e.response!.data['code']?.toString()) : null;
      debugPrint('[AuthService] Error al enviar email de recuperación: ${codigo ?? e.type}');
      throw AuthException(codigo ?? _codigoDio(e), causa: e);
    }
  }

  Future<bool> haySesionActiva() async {
    final token = await TokenStorage.instance.getAccessToken();
    return token != null;
  }

  /// `true` si hay una cuenta de email/contraseña activa y su email ya
  /// está verificado. Para cuentas de teléfono (sin email) o cuando no
  /// hay sesión de Firebase, devuelve `true` (no aplica el aviso) — el
  /// aviso de "verifica tu email" solo tiene sentido si de verdad hay
  /// un email que verificar.
  bool get emailVerificado {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) return true;
    return user.emailVerified;
  }

  /// Firebase no actualiza `emailVerified` en el objeto `User` en
  /// memoria solo por haber pulsado el enlace del correo — hay que
  /// pedirle explícitamente que recargue sus datos. Se llama al pulsar
  /// "Ya verifiqué mi email" en el aviso de la UI.
  Future<bool> recargarYComprobarEmailVerificado() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return true;
    try {
      await user.reload();
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('[AuthService] Error al recargar el usuario de Firebase: ${e.code}');
    }
    return emailVerificado;
  }

  Future<void> reenviarEmailVerificacion() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    try {
      await user.sendEmailVerification();
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('[AuthService] Error al reenviar el email de verificación: ${e.code}');
      throw AuthException(e.code, causa: e);
    }
  }

  /// Los códigos de `FirebaseAuthException.code` ('wrong-password',
  /// 'invalid-email'...) ya son identificadores estables — no hace
  /// falta traducirlos aquí, se pasan tal cual a `AuthException.code`
  /// y la pantalla los traduce con `mensajeAuthError` (tiene el `t` que
  /// este servicio no tiene). Para uno que Firebase no documenta, la
  /// pantalla ya cae a un mensaje genérico localizado (ver el `default`
  /// de `mensajeAuthError`), así que no hace falta un caso especial
  /// aquí tampoco.
  String _codigoDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return 'connection';
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'timeout';
      default:
        final data = e.response?.data;
        final codigoServidor = data is Map ? data['code']?.toString() : null;
        return codigoServidor ?? 'server';
    }
  }
}
