// Auditoría Build 44 (2026-08-25): almacén seguro restaurado por el
// auto-backup de Android sin la clave del Keystore → toda lectura lanza
// PlatformException BAD_DECRYPT y el login se queda en "Ocurrió un error
// inesperado". Ver secure_storage_guard.dart.
//
// Contrato probado aquí:
//  - esErrorDeDescifrado solo reconoce errores de descifrado (no red, no
//    genéricos);
//  - leerSeguro vacía el almacén y devuelve null SOLO ante esos errores;
//    cualquier otro error se propaga sin borrar nada (no se destruyen
//    credenciales válidas por un fallo ajeno);
//  - TokenStorage / InstallationIdService, que son quienes leen en el
//    arranque y en cada petición, quedan usables tras la limpieza (login
//    limpio, id de instalación nuevo) en vez de reventar.

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
// Transitiva de flutter_secure_storage (no la reexporta): solo la necesita
// este test para sustituir la plataforma por el fake.
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/services/installation_id_service.dart';
import 'package:hogarsos/services/secure_storage_guard.dart';
import 'package:hogarsos/services/token_storage.dart';

/// Plataforma de pruebas que reproduce el almacén restaurado sin clave:
/// `read` lanza el PlatformException real de Android hasta que se vacía.
class _AlmacenRestauradoSinClave extends TestFlutterSecureStoragePlatform {
  _AlmacenRestauradoSinClave(super.data, {this.error});

  /// null → comportamiento normal (lee el mapa).
  PlatformException? error;
  int lecturas = 0;
  int borradosTotales = 0;

  @override
  Future<String?> read({required String key, required Map<String, String> options}) async {
    lecturas++;
    if (error != null) throw error!;
    return data[key];
  }

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {
    borradosTotales++;
    // Tras vaciar, el almacén vuelve a ser legible (queda vacío) — como en
    // Android, donde borrar el fichero hace que la siguiente escritura
    // genere una clave nueva.
    error = null;
    data.clear();
  }
}

PlatformException _badDecrypt() => PlatformException(
      code: 'Exception encountered',
      message: 'read',
      details:
          'javax.crypto.BadPaddingException: error:1e000065:Cipher functions:OPENSSL_internal:BAD_DECRYPT\n\tat com.android.org.conscrypt.NativeCrypto.EVP_CipherFinal_ex(Native Method)',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('esErrorDeDescifrado', () {
    test('reconoce el BAD_DECRYPT real de Android (BadPaddingException en details)', () {
      expect(esErrorDeDescifrado(_badDecrypt()), isTrue);
    });

    test('reconoce otras firmas de clave perdida/inválida', () {
      for (final firma in ['AEADBadTagException', 'KeyPermanentlyInvalidatedException', 'InvalidKeyException']) {
        expect(esErrorDeDescifrado(PlatformException(code: 'x', message: 'java.security.$firma: boom')), isTrue, reason: firma);
      }
    });

    test('NO reconoce errores ajenos: red, genéricos, otros tipos', () {
      expect(esErrorDeDescifrado(PlatformException(code: 'x', message: 'Something else happened')), isFalse);
      expect(esErrorDeDescifrado(Exception('SocketException: Failed host lookup')), isFalse);
      expect(esErrorDeDescifrado(StateError('otro')), isFalse);
    });
  });

  group('leerSeguro', () {
    late _AlmacenRestauradoSinClave plataforma;
    const storage = FlutterSecureStorage();

    setUp(() {
      plataforma = _AlmacenRestauradoSinClave({'hogarsos_access_token': 'cifrado-ilegible'}, error: _badDecrypt());
      FlutterSecureStoragePlatform.instance = plataforma;
    });

    test('ante BAD_DECRYPT vacía el almacén una vez y devuelve null', () async {
      expect(await leerSeguro(storage, 'hogarsos_access_token'), isNull);
      expect(plataforma.borradosTotales, 1);
      // Y a partir de ahí el almacén funciona (vacío): no hay bucle de errores.
      expect(await leerSeguro(storage, 'hogarsos_access_token'), isNull);
      expect(plataforma.borradosTotales, 1);
      await storage.write(key: 'hogarsos_access_token', value: 'nuevo');
      expect(await leerSeguro(storage, 'hogarsos_access_token'), 'nuevo');
    });

    test('un error que NO es de descifrado se propaga y NO borra nada', () async {
      plataforma.error = PlatformException(code: 'x', message: 'fallo transitorio del sistema');
      await expectLater(leerSeguro(storage, 'hogarsos_access_token'), throwsA(isA<PlatformException>()));
      expect(plataforma.borradosTotales, 0);
      expect(plataforma.data, containsPair('hogarsos_access_token', 'cifrado-ilegible'));
    });

    test('lectura normal sin errores no toca el almacén', () async {
      plataforma.error = null;
      expect(await leerSeguro(storage, 'hogarsos_access_token'), 'cifrado-ilegible');
      expect(plataforma.borradosTotales, 0);
    });
  });

  group('integración con TokenStorage e InstallationIdService (el camino real del login)', () {
    test('TokenStorage: con el almacén restaurado sin clave, la sesión se da por inexistente y el login puede continuar',
        () async {
      final plataforma = _AlmacenRestauradoSinClave(
        {'hogarsos_access_token': 'x', 'hogarsos_refresh_token': 'y', 'hogarsos_usuario': '{}'},
        error: _badDecrypt(),
      );
      FlutterSecureStoragePlatform.instance = plataforma;
      await TokenStorage.instance.clear(); // estado en memoria limpio para el test

      // Lo que hace el interceptor de Dio en CADA petición (incluido POST /auth/login):
      expect(await TokenStorage.instance.getAccessToken(), isNull);
      expect(await TokenStorage.instance.getRefreshToken(), isNull);
      expect(await TokenStorage.instance.getUsuario(), isNull);
      expect(plataforma.borradosTotales, 1);

      // Un login posterior guarda y lee con normalidad.
      await TokenStorage.instance.saveTokens(accessToken: 'a1', refreshToken: 'r1', persistente: true);
      expect(await TokenStorage.instance.getAccessToken(), 'a1');
      expect(await TokenStorage.instance.getRefreshToken(), 'r1');
      await TokenStorage.instance.clear();
    });

    test('InstallationIdService: genera un id nuevo en vez de fallar', () async {
      final plataforma = _AlmacenRestauradoSinClave({'hogarsos_installation_id': 'viejo'}, error: _badDecrypt());
      FlutterSecureStoragePlatform.instance = plataforma;

      final id = await InstallationIdService.instance.obtener();
      expect(id, hasLength(32));
      expect(id, isNot('viejo'));
      expect(plataforma.data['hogarsos_installation_id'], id);
    });
  });
}
