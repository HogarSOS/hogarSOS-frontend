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
    _cargar();
  }

  static const _storageKey = 'hogarsos_trabajos_vistos';
  final _storage = const FlutterSecureStorage();

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
