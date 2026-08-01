import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthState {
  final AppUser? usuario;
  final bool cargando;
  final bool restaurando;
  final String? error;

  const AuthState({this.usuario, this.cargando = false, this.restaurando = true, this.error});

  AuthState copyWith({AppUser? usuario, bool? cargando, bool? restaurando, String? error}) {
    return AuthState(
      usuario: usuario ?? this.usuario,
      cargando: cargando ?? this.cargando,
      restaurando: restaurando ?? this.restaurando,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService) : super(const AuthState()) {
    _restaurarSesionInicial();
  }

  final AuthService _authService;

  /// Se dispara solo, una vez, al crear el provider (es decir, al
  /// arrancar la app). Mientras se resuelve, `restaurando` es true y
  /// la UI (ver auth_gate_screen.dart) muestra una pantalla de carga en
  /// vez de saltar directamente al login.
  Future<void> _restaurarSesionInicial() async {
    try {
      final usuario = await _authService.restaurarSesion();
      state = state.copyWith(usuario: usuario, restaurando: false);
      if (usuario != null) unawaited(NotificationService.instance.registrarToken());
    } catch (e) {
      debugPrint('[AuthNotifier] Error restaurando sesión: $e');
      state = state.copyWith(restaurando: false);
    }
  }

  Future<void> loginConEmail(String email, String password, {bool recordarSesion = true}) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final resultado = await _authService.loginConEmail(
        email: email,
        password: password,
        recordarSesion: recordarSesion,
      );
      state = AuthState(usuario: resultado.usuario, restaurando: false);
      unawaited(NotificationService.instance.registrarToken());
    } catch (e) {
      debugPrint('[AuthNotifier] Error en login: $e');
      final mensaje = e is AuthException ? e.mensaje : 'No se pudo iniciar sesión: $e';
      state = AuthState(error: mensaje, restaurando: false);
    }
  }

  Future<void> registrar({
    required String email,
    required String password,
    required String nombre,
    required UserRole role,
    bool recordarSesion = true,
  }) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final resultado = await _authService.registrarConEmail(
        email: email,
        password: password,
        nombre: nombre,
        role: role,
        recordarSesion: recordarSesion,
      );
      state = AuthState(usuario: resultado.usuario, restaurando: false);
      unawaited(NotificationService.instance.registrarToken());
    } catch (e) {
      // Antes esto siempre mostraba el mismo texto fijo, ocultando la
      // excepción real — ahora se ve el motivo concreto (sin conexión,
      // email ya usado, error del servidor, etc.).
      debugPrint('[AuthNotifier] Error en registro: $e');
      final mensaje = e is AuthException ? e.mensaje : 'No se pudo completar el registro: $e';
      state = AuthState(error: mensaje, restaurando: false);
    }
  }

  /// Último paso del login/registro por teléfono — se llama con la
  /// credencial ya obtenida (autoverificación de Android, ver
  /// login_screen.dart). El envío del SMS en sí (`enviarCodigoTelefono`)
  /// no pasa por aquí: es un paso intermedio sin resultado de sesión,
  /// cada pantalla lo llama directamente sobre AuthService.
  Future<void> completarConCredencialTelefono(
    fb.PhoneAuthCredential credential, {
    required String nombre,
    required UserRole role,
    required bool esRegistro,
    bool recordarSesion = true,
  }) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final resultado = await _authService.completarConCredencialTelefono(
        credential,
        nombre: nombre,
        role: role,
        esRegistro: esRegistro,
        recordarSesion: recordarSesion,
      );
      state = AuthState(usuario: resultado.usuario, restaurando: false);
      unawaited(NotificationService.instance.registrarToken());
    } catch (e) {
      debugPrint('[AuthNotifier] Error al completar sesión por teléfono: $e');
      final mensaje = e is AuthException ? e.mensaje : 'No se pudo completar: $e';
      state = AuthState(error: mensaje, restaurando: false);
    }
  }

  /// Igual que el de arriba, pero a partir del código de 6 dígitos que
  /// escribió el usuario — ver verificar_codigo_screen.dart.
  Future<void> confirmarCodigoTelefono({
    required String verificationId,
    required String smsCode,
    required String nombre,
    required UserRole role,
    required bool esRegistro,
    bool recordarSesion = true,
  }) async {
    state = state.copyWith(cargando: true, error: null);
    try {
      final resultado = await _authService.confirmarCodigoTelefono(
        verificationId: verificationId,
        smsCode: smsCode,
        nombre: nombre,
        role: role,
        esRegistro: esRegistro,
        recordarSesion: recordarSesion,
      );
      state = AuthState(usuario: resultado.usuario, restaurando: false);
      unawaited(NotificationService.instance.registrarToken());
    } catch (e) {
      debugPrint('[AuthNotifier] Error al confirmar código SMS: $e');
      final mensaje = e is AuthException ? e.mensaje : 'No se pudo confirmar el código: $e';
      state = AuthState(error: mensaje, restaurando: false);
    }
  }

  /// Devuelve null si se envió correctamente, o un mensaje de error legible.
  /// No toca el AuthState global a propósito — se usa desde un diálogo
  /// puntual en login_screen.dart, no desde el flujo principal de sesión.
  Future<String?> enviarEmailRecuperacion(String email) async {
    try {
      await _authService.enviarEmailRecuperacion(email);
      return null;
    } catch (e) {
      debugPrint('[AuthNotifier] Error en recuperación de contraseña: $e');
      return e is AuthException ? e.mensaje : 'No se pudo enviar el email: $e';
    }
  }

  /// Actualiza el usuario en memoria tras editar el perfil, sin volver
  /// a pasar por login — la pantalla de edición ya llamó a la API y
  /// tiene el AppUser actualizado de vuelta, esto solo lo refleja en
  /// el estado global para que el resto de la app (avatar, nombre en
  /// el saludo de Inicio...) se entere sin recargar.
  void actualizarUsuario(AppUser usuario) {
    state = state.copyWith(usuario: usuario);
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(restaurando: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});