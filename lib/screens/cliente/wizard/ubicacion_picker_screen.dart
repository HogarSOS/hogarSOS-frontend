import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../l10n/app_localizations.dart';

class UbicacionSeleccionada {
  final double latitud;
  final double longitud;
  final String? direccionTexto;
  const UbicacionSeleccionada({required this.latitud, required this.longitud, this.direccionTexto});
}

class UbicacionPickerScreen extends StatefulWidget {
  const UbicacionPickerScreen({super.key, this.ubicacionInicial});

  final UbicacionSeleccionada? ubicacionInicial;

  @override
  State<UbicacionPickerScreen> createState() => _UbicacionPickerScreenState();
}

class _UbicacionPickerScreenState extends State<UbicacionPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _centro = const LatLng(40.4168, -3.7038); // Madrid, como fallback razonable antes de tener el GPS
  final _direccionController = TextEditingController();
  bool _cargandoUbicacionInicial = true;

  @override
  void initState() {
    super.initState();
    _direccionController.text = widget.ubicacionInicial?.direccionTexto ?? '';
    if (widget.ubicacionInicial != null) {
      _centro = LatLng(widget.ubicacionInicial!.latitud, widget.ubicacionInicial!.longitud);
      _cargandoUbicacionInicial = false;
    } else {
      _obtenerUbicacionActual();
    }
  }

  @override
  void dispose() {
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacionActual() async {
    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso != LocationPermission.denied && permiso != LocationPermission.deniedForever) {
        final posicion = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() => _centro = LatLng(posicion.latitude, posicion.longitude));
          _mapController?.animateCamera(CameraUpdate.newLatLng(_centro));
        }
      }
    } catch (_) {
      // Si falla, se queda con el fallback — el usuario siempre puede
      // mover el mapa manualmente a su ubicación real.
    } finally {
      if (mounted) setState(() => _cargandoUbicacionInicial = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.ubicacionTitulo)),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_cargandoUbicacionInicial)
                  const Center(child: CircularProgressIndicator())
                else
                  GoogleMap(
                    initialCameraPosition: CameraPosition(target: _centro, zoom: 16),
                    onMapCreated: (controller) => _mapController = controller,
                    onCameraMove: (posicion) => _centro = posicion.target,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                  ),
                // Pin central fijo — el mapa se mueve debajo. Evita la
                // complejidad de un marcador arrastrable y es el patrón
                // que ya reconocen los usuarios de Uber/Airbnb/Glovo.
                if (!_cargandoUbicacionInicial)
                  const IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.location_pin, size: 44, color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _direccionController,
                  decoration: InputDecoration(
                    labelText: t.ubicacionDireccionOpcional,
                    prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      UbicacionSeleccionada(
                        latitud: _centro.latitude,
                        longitud: _centro.longitude,
                        direccionTexto: _direccionController.text.trim().isEmpty
                            ? null
                            : _direccionController.text.trim(),
                      ),
                    );
                  },
                  child: Text(t.ubicacionConfirmar),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
