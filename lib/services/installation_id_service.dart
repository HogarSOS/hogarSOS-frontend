import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Identificador de ESTA instalación de la app (P2 #5) — no de la
/// sesión. Deliberadamente independiente de `TokenStorage`: debe
/// sobrevivir a logout, a un login posterior del mismo usuario, e
/// incluso a un cambio de cuenta en el mismo dispositivo, porque
/// identifica "este teléfono con esta app instalada", no "quién tiene
/// la sesión iniciada ahora" — es lo que permite al backend saber que
/// una rotación de token FCM sigue siendo el mismo dispositivo (ver
/// `UserFcmToken` en el backend). Solo cambia si se reinstala la app
/// (y ni siquiera siempre entonces: el Keychain de iOS puede sobrevivir
/// a una desinstalación, comportamiento de la plataforma, no de esta
/// clase).
///
/// Valor puramente aleatorio, sin ningún dato del hardware ni de la
/// persona — no identifica físicamente a nadie, solo una instalación
/// de push ante el backend de HogarSOS.
class InstallationIdService {
  InstallationIdService._internal();
  static final InstallationIdService instance = InstallationIdService._internal();

  static const _storage = FlutterSecureStorage();
  static const _key = 'hogarsos_installation_id';

  String? _cache;

  Future<String> obtener() async {
    if (_cache != null) return _cache!;
    var id = await _storage.read(key: _key);
    if (id == null) {
      id = _generar();
      await _storage.write(key: _key, value: id);
    }
    _cache = id;
    return id;
  }

  /// 32 caracteres hexadecimales de `Random.secure()` — sin añadir el
  /// paquete `uuid` (no es una dependencia existente del proyecto),
  /// suficiente entropía para no colisionar entre instalaciones reales.
  String _generar() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
