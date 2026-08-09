import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';

/// Número en el icono de la app, en el launcher/pantalla de inicio —
/// distinto del punto rojo DENTRO de la app (Badge de NavigationBar).
///
/// Los shells que llaman a `actualizar()` solo mandan 0 o 1 (nunca la
/// cuenta real de pendientes) — iOS no tiene un "punto sin número" a
/// nivel de sistema (su API nativa siempre es un entero), así que 1 es
/// lo más parecido a un punto que permite la plataforma. Este método
/// en sí sigue aceptando cualquier `int` porque es solo un envoltorio
/// fino sobre el plugin; la decisión de 0/1 vive en quien lo llama.
///
/// Se recalcula y se aplica cada vez que build() de los shells corre
/// (ver profesional_shell_screen.dart / cliente_shell_screen.dart), a
/// partir de datos que YA viven en el cliente (chats sin leer vía
/// Firestore, trabajos aceptados sin ver vía trabajos_vistos_provider)
/// — no depende de que el backend calcule ni envíe ningún número.
///
/// Limitación real, no un bug: como el número lo calcula la app en
/// vivo, solo se actualiza mientras la app corre (primer plano o
/// segundo plano) — con la app cerrada del todo no puede cambiar el
/// badge hasta el próximo arranque, a diferencia de un badge fijado
/// desde el propio payload de APNs. Arreglar eso exigiría que el
/// backend calculara y mandara el número en cada push (infraestructura
/// que hoy no existe, ver notification.service.ts), fuera del alcance
/// de este cambio.
class AppBadgeService {
  AppBadgeService._internal();
  static final AppBadgeService instance = AppBadgeService._internal();

  int? _ultimoValorAplicado;

  Future<void> actualizar(int numero) async {
    if (_ultimoValorAplicado == numero) return;
    _ultimoValorAplicado = numero;
    try {
      await AppBadgePlus.updateBadge(numero);
    } catch (e) {
      // Launcher/plataforma sin soporte (frecuente en Android) — no es
      // un error real, simplemente no hay badge que mostrar ahí.
      debugPrint('[AppBadgeService] Sin soporte de badge en este dispositivo: $e');
    }
  }
}
