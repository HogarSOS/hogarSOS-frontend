// P2 #6 (auditoría 2026-08-14, punto 6): registrarConEmail() revertía
// (borraba) el usuario de Firebase ante CUALQUIER fallo tras crearlo,
// incluida una respuesta perdida cuando el backend ya había creado la
// fila en Postgres — dejando un email permanentemente bloqueado (ni
// login ni registro funcionaban). El fix reduce la decisión de "¿es
// seguro revertir Firebase?" a `esRechazoConfirmadoDelBackend`, una
// función pura de un DioException — se prueba directamente aquí.
//
// Por qué esta forma de probarlo: este proyecto no tiene
// mockito/mocktail ni un adaptador de Dio de pruebas, y AuthService usa
// FirebaseAuth.instance/ApiService.instance directamente (sin punto de
// inyección) — no hay manera de simular createUserWithEmailAndPassword
// ni una petición HTTP real sin añadir dependencias nuevas o refactorizar
// AuthService para inyección, ninguna de las dos pedida en el alcance de
// P2 #6. `esRechazoConfirmadoDelBackend` se dejó no-privada
// (@visibleForTesting) precisamente para poder probar la decisión real
// sin necesitar nada de eso — es la lógica completa que decide el
// rollback, un DioException de prueba es todo lo que hace falta.
//
// Casos NO cubiertos aquí por la misma razón (documentado, no ignorado):
// 1) "Firebase falla antes del backend → rollback" es la PRIMERA rama de
//    registrarConEmail (`on FirebaseAuthException`), sin cambios en este
//    fix — no hay nada nuevo que probar, y no hay infraestructura para
//    simular Firebase.
// 7) "201 + saveTokens falla → NO rollback" depende del catch genérico
//    (no-DioException) de registrarConEmail, que ya NO llama a
//    _revertirUsuarioFirebase en ningún caso (ver el código) — verificado
//    por inspección del diff, no por un test ejecutable, por la misma
//    limitación de mocking.
// 8) "retry con el mismo firebaseUid completa el registro" es
//    comportamiento del BACKEND (idempotencia de /register), cubierto en
//    profundidad en auth.controller.test.ts — no hay lógica nueva en el
//    frontend específica de "reintentar", más allá de no borrar Firebase
//    (ya cubierto en los casos 3-6 de abajo).

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/services/auth_service.dart';

DioException _conRespuesta(int statusCode, Map<String, dynamic>? data) {
  final opciones = RequestOptions(path: '/auth/register');
  return DioException(
    requestOptions: opciones,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: opciones, statusCode: statusCode, data: data),
  );
}

DioException _sinRespuesta(DioExceptionType tipo) {
  return DioException(requestOptions: RequestOptions(path: '/auth/register'), type: tipo);
}

void main() {
  group('esRechazoConfirmadoDelBackend — P2 #6', () {
    // Caso 2: rechazo explícito y confirmado del backend → SÍ revertir.
    for (final codigo in [
      'VALIDATION_INVALID',
      'AUTH_FIREBASE_TOKEN_INVALID',
      'AUTH_FIREBASE_TOKEN_NO_CONTACT',
      'AUTH_USER_ALREADY_EXISTS',
    ]) {
      test('$codigo (rechazo confirmado del backend) → true (revertir)', () {
        final e = _conRespuesta(codigo == 'AUTH_USER_ALREADY_EXISTS' ? 409 : 400, {'code': codigo});
        expect(AuthService.esRechazoConfirmadoDelBackend(e), isTrue);
      });
    }

    // Caso 3
    test('timeout (receiveTimeout, sin respuesta) → false (NO revertir)', () {
      final e = _sinRespuesta(DioExceptionType.receiveTimeout);
      expect(AuthService.esRechazoConfirmadoDelBackend(e), isFalse);
    });

    // Caso 4
    test('connectionError (sin respuesta) → false (NO revertir)', () {
      final e = _sinRespuesta(DioExceptionType.connectionError);
      expect(AuthService.esRechazoConfirmadoDelBackend(e), isFalse);
    });

    test('connectionTimeout (sin respuesta) → false (NO revertir)', () {
      final e = _sinRespuesta(DioExceptionType.connectionTimeout);
      expect(AuthService.esRechazoConfirmadoDelBackend(e), isFalse);
    });

    // Caso 5: el backend SÍ respondió, pero con un fallo genérico que no
    // confirma "nada se creó" — ver errorHandler global en index.ts,
    // que devuelve exactamente este code para cualquier error no manejado.
    test('500 con code INTERNAL_ERROR → false (NO revertir: pudo haber creado el User antes de fallar)', () {
      final e = _conRespuesta(500, {'code': 'INTERNAL_ERROR', 'error': 'Error interno del servidor'});
      expect(AuthService.esRechazoConfirmadoDelBackend(e), isFalse);
    });

    // Caso 6: respuesta inesperada — sin campo `code`, o sin cuerpo JSON.
    test('respuesta sin campo "code" → false (NO revertir)', () {
      final e = _conRespuesta(500, {'mensaje': 'algo salió mal'});
      expect(AuthService.esRechazoConfirmadoDelBackend(e), isFalse);
    });

    test('respuesta sin cuerpo (data null) → false (NO revertir)', () {
      final e = _conRespuesta(502, null);
      expect(AuthService.esRechazoConfirmadoDelBackend(e), isFalse);
    });

    test('respuesta con cuerpo que no es un Map (ej. texto plano de un proxy) → false (NO revertir)', () {
      final opciones = RequestOptions(path: '/auth/register');
      final e = DioException(
        requestOptions: opciones,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: opciones, statusCode: 502, data: '<html>Bad Gateway</html>'),
      );
      expect(AuthService.esRechazoConfirmadoDelBackend(e), isFalse);
    });

    // Un código de negocio real pero AJENO a "nada se creó" (ej. una
    // respuesta con algún otro `code` del backend que no está en la
    // lista) tampoco debe disparar el borrado — solo los 4 explícitos.
    test('code de negocio no relacionado con creación fallida → false (NO revertir)', () {
      final e = _conRespuesta(403, {'code': 'AUTH_ACCOUNT_DISABLED'});
      expect(AuthService.esRechazoConfirmadoDelBackend(e), isFalse);
    });
  });
}
