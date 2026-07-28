import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'token_storage.dart';

class AuthResult {
  final AppUser usuario;
  AuthResult(this.usuario);
}

class AuthException implements Exception {
  final String mensaje;
  final Object? causa;
  AuthException(this.mensaje, {this.causa});

  @override
  String toString() => 'AuthException: $mensaje (causa: $causa)';
}

class AuthService {
  final _firebaseAuth = fb.FirebaseAuth.instance;
  final _api = ApiService.instance.client;

  Future<AuthResult> loginConGoogle() async {
    throw UnimplementedError(
      'Configurar google_sign_in en el proyecto nativo antes de usar este método',
    );
  }

  /// Registro/login con email y contraseña vía Firebase, seguido del
  /// intercambio por el JWT propio. Si Firebase crea el usuario pero
  /// el backend falla después, se revierte (borra) el usuario de
  /// Firebase para evitar estados inconsistentes.
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
      throw AuthException(_mensajeFirebase(e), causa: e);
    }

    try {
      final firebaseIdToken = await credencial.user!.getIdToken();

      final respuesta = await _api.post('/auth/register', data: {
        'firebaseIdToken': firebaseIdToken,
        'nombre': nombre,
        'role': role.name,
      });

      return _guardarSesion(respuesta.data, recordarSesion: recordarSesion);
    } on DioException catch (e) {
      debugPrint('[AuthService] Fallo al registrar en el backend: ${e.type} — ${e.message}');
      await _revertirUsuarioFirebase(credencial);
      throw AuthException(_mensajeDio(e), causa: e);
    } catch (e) {
      debugPrint('[AuthService] Error inesperado al registrar en el backend: $e');
      await _revertirUsuarioFirebase(credencial);
      throw AuthException('Ocurrió un error inesperado al completar el registro.', causa: e);
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
      throw AuthException(_mensajeFirebase(e), causa: e);
    }

    try {
      final firebaseIdToken = await credencial.user!.getIdToken();
      final respuesta = await _api.post('/auth/login', data: {
        'firebaseIdToken': firebaseIdToken,
      });
      return _guardarSesion(respuesta.data, recordarSesion: recordarSesion);
    } on DioException catch (e) {
      debugPrint('[AuthService] Fallo al iniciar sesión en el backend: ${e.type} — ${e.message}');
      throw AuthException(_mensajeDio(e), causa: e);
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

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await TokenStorage.instance.clear();
  }

  /// Envía el email de restablecimiento de contraseña de Firebase.
  /// No toca el backend en absoluto — Firebase gestiona el enlace de
  /// reseteo y la propia pantalla de cambio de contraseña de forma
  /// nativa, completamente al margen de la base de datos de hogarSOS.
  Future<void> enviarEmailRecuperacion(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('[AuthService] Error al enviar email de recuperación: ${e.code}');
      throw AuthException(_mensajeFirebase(e), causa: e);
    }
  }

  Future<bool> haySesionActiva() async {
    final token = await TokenStorage.instance.getAccessToken();
    return token != null;
  }

  String _mensajeFirebase(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Ya existe una cuenta de Firebase con este email (puede ser de un '
            'registro anterior que falló a mitad de camino). Revisa Firebase '
            'Console → Authentication → Users para confirmarlo, o prueba con '
            'otro email.';
      case 'invalid-email':
        return 'El email no tiene un formato válido.';
      case 'weak-password':
        return 'La contraseña es demasiado débil (mínimo 6 caracteres).';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email o contraseña incorrectos.';
      case 'network-request-failed':
        return 'No hay conexión a internet.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento antes de volver a intentarlo.';
      default:
        return e.message ?? 'Error de autenticación (${e.code})';
    }
  }

  String _mensajeDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return 'No se pudo conectar con el servidor. Comprueba que el backend '
            'esté corriendo y que API_BASE_URL apunte a la dirección correcta.';
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'El servidor tardó demasiado en responder.';
      default:
        final mensajeServidor = e.response?.data is Map
            ? (e.response?.data as Map)['error']?.toString()
            : null;
        return mensajeServidor ?? 'Error del servidor (${e.response?.statusCode ?? "sin respuesta"})';
    }
  }
}
