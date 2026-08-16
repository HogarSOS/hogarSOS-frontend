// BUG 2 (auditoría 2026-08-15): el aviso "¡Te han elegido!" podía
// reaparecer varias veces en "Trabajos activos" antes de quedarse
// marcado como visto de verdad.
//
// Causa confirmada, trazada sin adivinar: TrabajosVistosNotifier lanzaba
// _cargar() (lectura de flutter_secure_storage, async) en el constructor
// SIN esperarla — el estado empezaba en `{}`. Cualquier comprobación de
// "¿ya visto?" hecha antes de que esa lectura terminara trataba un
// trabajo ya visto en una sesión anterior como nuevo otra vez. Peor: si
// marcarVistos() corría PRIMERO (marcando el trabajo como visto), y la
// lectura de disco resolvía DESPUÉS, esa lectura sobrescribía el estado
// entero con lo que hubiera en disco — deshaciendo el "visto" recién
// marcado.
//
// Fix: TrabajosVistosNotifier expone `listo` (el Future de _cargar()) —
// cualquier código que decida "¿es nuevo?" debe esperarlo antes de leer
// el estado. Estos tests prueban el contrato expuesto por el notifier
// directamente (sin montar la pantalla completa, que arrastra sondeo,
// chat, badges, etc.), mockeando el canal de flutter_secure_storage para
// controlar con precisión cuánto tarda "el disco" en cada escenario.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/providers/trabajos_vistos_provider.dart';

const _canal = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

/// Almacenamiento en memoria que responde al mismo canal que usa
/// flutter_secure_storage de verdad — así TrabajosVistosNotifier (que
/// crea su propio `FlutterSecureStorage()` internamente, sin inyección)
/// se prueba tal cual es en producción, no una reimplementación aparte.
class _AlmacenFalso {
  final Map<String, String> _datos = {};

  /// Si no es null, la próxima llamada a `read` espera a que se complete
  /// este Completer antes de responder — simula "el disco tarda" de
  /// forma determinista, sin depender de tiempos reales.
  Completer<void>? _puertaLectura;

  void retrasarProximaLectura(Completer<void> puerta) => _puertaLectura = puerta;

  void instalar() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      _canal,
      (call) async {
        switch (call.method) {
          case 'read':
            final puerta = _puertaLectura;
            _puertaLectura = null;
            if (puerta != null) await puerta.future;
            return _datos[call.arguments['key']];
          case 'write':
            _datos[call.arguments['key'] as String] = call.arguments['value'] as String;
            return null;
          default:
            return null;
        }
      },
    );
  }

  void desinstalar() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_canal, null);
  }

  void sembrar(Set<String> ids) {
    _datos['hogarsos_trabajos_vistos'] = jsonEncode(ids.toList());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _AlmacenFalso almacen;

  setUp(() {
    almacen = _AlmacenFalso()..instalar();
  });

  tearDown(() {
    almacen.desinstalar();
  });

  test('carga pendiente: el estado sigue vacío hasta que listo se completa (no se puede decidir "nuevo" antes de tiempo)', () async {
    almacen.sembrar({'trabajo-viejo'});
    final puerta = Completer<void>();
    almacen.retrasarProximaLectura(puerta);

    final notifier = TrabajosVistosNotifier();
    addTearDown(notifier.dispose);

    // Justo tras construir, la lectura de disco sigue en vuelo (bloqueada
    // por la puerta) — el estado real en disco tiene 'trabajo-viejo',
    // pero nadie debe poder verlo todavía.
    expect(notifier.state, isEmpty);

    puerta.complete();
    await notifier.listo;

    expect(notifier.state, {'trabajo-viejo'});
  });

  test('carga terminada + trabajo nuevo → se detecta como nuevo', () async {
    almacen.sembrar({'trabajo-A'});
    final notifier = TrabajosVistosNotifier();
    addTearDown(notifier.dispose);

    await notifier.listo;

    expect(notifier.state.contains('trabajo-B'), isFalse); // 'trabajo-B' es nuevo
  });

  test('carga terminada + trabajo ya visto → NO se detecta como nuevo', () async {
    almacen.sembrar({'trabajo-A'});
    final notifier = TrabajosVistosNotifier();
    addTearDown(notifier.dispose);

    await notifier.listo;

    expect(notifier.state.contains('trabajo-A'), isTrue); // ya estaba visto
  });

  test('marcado como visto → los siguientes sondeos ya no lo tratan como nuevo', () async {
    final notifier = TrabajosVistosNotifier();
    addTearDown(notifier.dispose);
    await notifier.listo;

    // Primer "sondeo": trabajo-X es nuevo.
    expect(notifier.state.contains('trabajo-X'), isFalse);
    await notifier.marcarVistos({'trabajo-X'});

    // Sondeos siguientes (10s, 20s, 30s...): ya no es nuevo.
    for (var i = 0; i < 5; i++) {
      expect(notifier.state.contains('trabajo-X'), isTrue);
    }
  });

  test('reinicio de app: una instancia NUEVA del notifier recupera lo persistido por la anterior', () async {
    final primeraSesion = TrabajosVistosNotifier();
    await primeraSesion.listo;
    await primeraSesion.marcarVistos({'trabajo-persistido'});
    primeraSesion.dispose();

    // Simula el reinicio: instancia nueva, mismo almacén de fondo.
    final segundaSesion = TrabajosVistosNotifier();
    addTearDown(segundaSesion.dispose);
    await segundaSesion.listo;

    expect(segundaSesion.state, {'trabajo-persistido'});
  });

  test('carrera carga/sondeo: si el caller espera listo() antes de decidir, el resultado es el mismo sin importar cuánto tarde la lectura de disco', () async {
    // Se repite con lectura instantánea y con lectura artificialmente
    // lenta — el contrato (esperar `listo` antes de leer el estado) debe
    // dar el mismo resultado correcto en los dos casos, sin que la
    // lectura tardía llegue a pisar nada después.
    for (final lenta in [false, true]) {
      final almacenLocal = _AlmacenFalso()..instalar();
      addTearDown(almacenLocal.desinstalar);
      almacenLocal.sembrar(<String>{});

      Completer<void>? puerta;
      if (lenta) {
        puerta = Completer<void>();
        almacenLocal.retrasarProximaLectura(puerta);
      }

      final notifier = TrabajosVistosNotifier();
      addTearDown(notifier.dispose);

      // El patrón correcto (el que ahora usa trabajos_activos_profesional_screen.dart):
      // esperar `listo` ANTES de leer/decidir/marcar.
      final futureListo = notifier.listo;
      if (lenta) {
        // La lectura de disco sigue en vuelo — nada debería poder
        // decidir "es nuevo" todavía en este punto (se comprueba con el
        // test de "carga pendiente" de arriba); aquí solo liberamos la
        // puerta para que listo() pueda completarse.
        puerta!.complete();
      }
      await futureListo;

      final esNuevo = !notifier.state.contains('trabajo-carrera');
      expect(esNuevo, isTrue, reason: 'lenta=$lenta');
      await notifier.marcarVistos({'trabajo-carrera'});

      // Determinista en ambos casos: una vez marcado, se queda marcado —
      // _cargar() ya resolvió (una sola vez) antes de que marcarVistos()
      // pudiera ejecutarse, así que no hay nada pendiente que lo pueda
      // sobrescribir después.
      expect(notifier.state, {'trabajo-carrera'}, reason: 'lenta=$lenta');
    }
  });
}
