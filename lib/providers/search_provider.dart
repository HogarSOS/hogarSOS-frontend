import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/professional_summary_model.dart';
import '../services/professional_service.dart';

final professionalServiceProvider = Provider((ref) => ProfessionalService());

class SearchState {
  final SearchFilters filtros;
  final AsyncValue<List<ProfessionalSummary>> resultados;

  const SearchState({required this.filtros, required this.resultados});

  SearchState copyWith({SearchFilters? filtros, AsyncValue<List<ProfessionalSummary>>? resultados}) {
    return SearchState(
      filtros: filtros ?? this.filtros,
      resultados: resultados ?? this.resultados,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this._servicio)
      : super(SearchState(filtros: const SearchFilters(), resultados: const AsyncValue.data([])));

  final ProfessionalService _servicio;
  Timer? _debounce;
  Position? _ubicacionCacheada;
  bool _yaPreguntoUbicacion = false;

  /// Se pide la ubicación una sola vez por sesión de búsqueda (no en
  /// cada tecleo). Si se deniega el permiso, la búsqueda sigue
  /// funcionando igual — solo pierde el orden por cercanía y el filtro
  /// de radio, que dependen de coordenadas.
  Future<Position?> _obtenerUbicacion() async {
    if (_ubicacionCacheada != null) return _ubicacionCacheada;
    if (_yaPreguntoUbicacion) return null;
    _yaPreguntoUbicacion = true;

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
      return null;
    }

    try {
      _ubicacionCacheada = await Geolocator.getCurrentPosition();
    } catch (_) {
      _ubicacionCacheada = null;
    }
    return _ubicacionCacheada;
  }

  void actualizarTexto(String texto) {
    state = state.copyWith(filtros: state.filtros.copyWith(query: texto));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _buscar);
  }

  void actualizarCategoria(int? categoryId) {
    state = state.copyWith(
      filtros: state.filtros.copyWith(categoryId: categoryId, limpiarCategoria: categoryId == null),
    );
    _buscar();
  }

  void alternarSoloDisponibles() {
    state = state.copyWith(
      filtros: state.filtros.copyWith(soloDisponibles: !state.filtros.soloDisponibles),
    );
    _buscar();
  }

  void aplicarFiltros({double? minValoracion, double? precioMax, double? radioMetros}) {
    state = state.copyWith(
      filtros: state.filtros.copyWith(
        minValoracion: minValoracion,
        limpiarMinValoracion: minValoracion == null,
        precioMax: precioMax,
        limpiarPrecioMax: precioMax == null,
        radioMetros: radioMetros,
        limpiarRadioMetros: radioMetros == null,
      ),
    );
    _buscar();
  }

  Future<void> _buscar() async {
    state = state.copyWith(resultados: const AsyncValue.loading());
    try {
      final ubicacion = await _obtenerUbicacion();
      final resultados = await _servicio.buscar(
        state.filtros,
        latitud: ubicacion?.latitude,
        longitud: ubicacion?.longitude,
      );
      state = state.copyWith(resultados: AsyncValue.data(resultados));
    } catch (e, st) {
      state = state.copyWith(resultados: AsyncValue.error(e, st));
    }
  }

  void buscarInicial() => _buscar();

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final searchProvider = StateNotifierProvider.autoDispose<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.watch(professionalServiceProvider));
});
