import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lecturas de flutter_secure_storage a prueba de "almacén restaurado sin
/// clave" (auditoría Build 44, 2026-08-25).
///
/// Caso real reproducido en el Realme: al reinstalar la app, el
/// auto-backup de Android restauró el fichero `FlutterSecureStorage` de
/// shared_prefs (valores cifrados + clave AES envuelta), pero la clave RSA
/// del AndroidKeyStore que la envolvía ya no existía (se destruye al
/// desinstalar). Toda lectura lanzaba `PlatformException` con
/// `BadPaddingException … BAD_DECRYPT`; como el interceptor de Dio lee el
/// access token en CADA petición, hasta el POST /auth/login fallaba y el
/// usuario quedaba clavado en "Ocurrió un error inesperado" sin salida
/// (solo "Borrar datos" en Ajustes lo arreglaba).
///
/// Estrategia, en dos capas:
///  1. AndroidManifest: `allowBackup=false` + reglas de extracción que
///     excluyen el almacén seguro — el sistema deja de restaurarlo.
///  2. Esta guarda: si aun así una lectura falla con un error DE
///     DESCIFRADO (no cualquier error), esos valores son irrecuperables por
///     definición → se vacía el almacén y se devuelve null, que para toda
///     la app significa "no hay sesión / no hay dato": cae al login limpio.
///     Ningún otro error se traga ni borra nada.
///
/// Riesgo aceptado y documentado: si el Keystore fallara de forma
/// transitoria con un error de esta familia en una sesión válida, el
/// usuario vería el login (sin pérdida de datos: todo vive en el backend).
bool esErrorDeDescifrado(Object error) {
  if (error is! PlatformException) return false;
  final texto = '${error.code} ${error.message ?? ''} ${error.details ?? ''}';
  return _firmasDescifrado.any(texto.contains);
}

const _firmasDescifrado = [
  'BAD_DECRYPT',
  'BadPaddingException',
  'AEADBadTagException',
  'IllegalBlockSizeException',
  'InvalidKeyException',
  'KeyPermanentlyInvalidatedException',
  'UnrecoverableKeyException',
];

/// Lee `key`; ante un error de descifrado vacía TODO el almacén seguro
/// (todas sus claves comparten la misma clave AES: si una no se descifra,
/// ninguna lo hará) y devuelve null. Otros errores se propagan tal cual.
Future<String?> leerSeguro(FlutterSecureStorage storage, String key) async {
  try {
    return await storage.read(key: key);
  } catch (e) {
    if (!esErrorDeDescifrado(e)) rethrow;
    debugPrint('[secure_storage] "$key" ilegible (almacén restaurado sin clave): se vacía el almacén seguro. $e');
    try {
      await storage.deleteAll();
    } catch (e2) {
      debugPrint('[secure_storage] No se pudo vaciar el almacén seguro: $e2');
    }
    return null;
  }
}
