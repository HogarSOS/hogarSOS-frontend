import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// IDs de trabajos asignados que el profesional ya abrió en "Trabajos
/// activos" en ESTE dispositivo — usado solo para saber si hay que
/// enseñar el punto rojo de "trabajo nuevo sin ver" en esa pestaña
/// (ver profesional_shell_screen.dart), no como fuente de verdad de
/// nada más. Por dispositivo, no por cuenta: reinstalar la app o
/// entrar desde otro móvil vuelve a marcar como "sin ver" los trabajos
/// ya vistos antes — aceptable para un punto rojo, no para datos reales.
class TrabajosVistosNotifier extends StateNotifier<Set<String>> {
  TrabajosVistosNotifier() : super(const {}) {
    _listo = _cargar();
  }

  static const _storageKey = 'hogarsos_trabajos_vistos';
  final _storage = const FlutterSecureStorage();
  late final Future<void> _listo;

  /// Se completa en cuanto termina de leer el estado persistido de disco.
  /// Bug real (auditoría 2026-08-15): `_cargar()` se lanzaba en el
  /// constructor SIN esperar — el estado empezaba en `{}`, así que
  /// cualquier comprobación de "¿ya visto?" hecha antes de que esa
  /// lectura terminara trataba un trabajo YA visto en una sesión
  /// anterior como si fuera nuevo. Peor aún: si `marcarVistos()` corría
  /// primero y añadía ese ID al estado, la lectura de disco, al resolver
  /// DESPUÉS, sobrescribía el estado entero con lo que había en disco —
  /// deshaciendo el "ya visto" recién marcado y dejando la puerta
  /// abierta a que el trabajo volviera a contarse como nuevo en el
  /// siguiente sondeo. Cualquier código que decida "¿es nuevo?" debe
  /// esperar a `listo` antes de leer el estado — así se garantiza que la
  /// única escritura de `_cargar()` ya ocurrió y no puede volver a pisar
  /// nada después.
  Future<void> get listo => _listo;

  Future<void> _cargar() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null) return;
    state = (jsonDecode(raw) as List).cast<String>().toSet();
  }

  /// Se llama al entrar en "Trabajos activos" con los IDs cargados en
  /// ese momento — no hace falta esperar a que el usuario abra cada
  /// tarjeta, con ver la lista ya es "visto" a efectos del punto rojo.
  Future<void> marcarVistos(Iterable<String> ids) async {
    final nuevoState = {...state, ...ids};
    if (nuevoState.length == state.length) return;
    state = nuevoState;
    await _storage.write(key: _storageKey, value: jsonEncode(state.toList()));
  }
}

final trabajosVistosProvider = StateNotifierProvider<TrabajosVistosNotifier, Set<String>>(
  (ref) => TrabajosVistosNotifier(),
);
