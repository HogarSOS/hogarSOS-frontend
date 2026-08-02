import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/professional_service.dart';

final professionalServiceProvider = Provider((ref) => ProfessionalService());

/// Solo lo que hace falta para pintar/editar disponibilidad — no el
/// `MiPerfilProfesional` completo, que sigue viviendo como estado local
/// de `MiPerfilProfesionalScreen` (foto, categorías, verificación...).
/// Compartido por la pestaña "Solicitudes" (acceso rápido a "No
/// disponible") y la sección de disponibilidad en "Mi perfil" — antes
/// de este provider, Disponibilidad era una pestaña propia con su
/// propio fetch; unificarlo aquí evita que las dos pantallas se
/// desincronicen entre sí.
class DisponibilidadState {
  final bool disponible;
  final ModoDisponibilidad modo;
  final bool perfilCompleto;
  final bool estaVerificado;
  final EstadoCuentaStripe estadoCuentaStripe;

  const DisponibilidadState({
    required this.disponible,
    required this.modo,
    required this.perfilCompleto,
    required this.estaVerificado,
    required this.estadoCuentaStripe,
  });

  /// Roadmap económico punto 5: Registro → (Verificación + Stripe en
  /// paralelo) → Disponible para trabajar — hace falta terminar AMBAS
  /// ramas para poder activarse, no solo la verificación.
  bool get puedeActivarse => estaVerificado && estadoCuentaStripe == EstadoCuentaStripe.configurada;
}

class DisponibilidadNotifier extends StateNotifier<AsyncValue<DisponibilidadState>> {
  DisponibilidadNotifier(this._servicio) : super(const AsyncValue.loading()) {
    cargar();
  }

  final ProfessionalService _servicio;

  Future<void> cargar() async {
    if (!state.hasValue) state = const AsyncValue.loading();
    try {
      final perfil = await _servicio.obtenerMiPerfil();
      state = AsyncValue.data(DisponibilidadState(
        disponible: perfil.disponible,
        modo: perfil.modoDisponibilidad,
        perfilCompleto: perfil.perfilCompleto,
        estaVerificado: perfil.estaVerificado,
        estadoCuentaStripe: perfil.estadoCuentaStripe,
      ));
    } catch (e, st) {
      if (!state.hasValue) state = AsyncValue.error(e, st);
    }
  }

  /// Cambia disponibilidad — pide ubicación solo si se está activando
  /// (mismo comportamiento que tenía la pantalla dedicada). Optimista:
  /// refleja el cambio de inmediato y revierte si la llamada falla, para
  /// que tanto el selector de "Mi perfil" como el acceso rápido de
  /// "Solicitudes" respondan al instante.
  Future<void> actualizar({required bool disponible, required ModoDisponibilidad modo}) async {
    final anterior = state;
    state = state.whenData((s) => DisponibilidadState(
          disponible: disponible,
          modo: modo,
          perfilCompleto: s.perfilCompleto,
          estaVerificado: s.estaVerificado,
          estadoCuentaStripe: s.estadoCuentaStripe,
        ));

    try {
      double? lat;
      double? lng;
      if (disponible) {
        var permiso = await Geolocator.checkPermission();
        if (permiso == LocationPermission.denied) {
          permiso = await Geolocator.requestPermission();
        }
        if (permiso != LocationPermission.denied && permiso != LocationPermission.deniedForever) {
          final posicion = await Geolocator.getCurrentPosition();
          lat = posicion.latitude;
          lng = posicion.longitude;
        }
      }
      await _servicio.actualizarDisponibilidad(disponible: disponible, modo: modo, latitud: lat, longitud: lng);
    } catch (e) {
      state = anterior;
      rethrow;
    }
  }
}

final disponibilidadProvider =
    StateNotifierProvider<DisponibilidadNotifier, AsyncValue<DisponibilidadState>>((ref) {
  return DisponibilidadNotifier(ref.watch(professionalServiceProvider));
});
