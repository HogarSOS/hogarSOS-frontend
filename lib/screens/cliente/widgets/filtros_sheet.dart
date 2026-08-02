import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class FiltrosResultado {
  final double? minValoracion;
  final double? precioMax;
  final double? radioMetros;
  const FiltrosResultado({this.minValoracion, this.precioMax, this.radioMetros});
}

/// Hoja de filtros. Se abre con los valores actuales ya aplicados
/// (para que "abrir filtros" nunca resetee lo que el usuario ya eligió)
/// y devuelve los nuevos valores solo si el usuario pulsa "Aplicar".
Future<FiltrosResultado?> mostrarHojaDeFiltros(
  BuildContext context, {
  required double? minValoracionActual,
  required double? precioMaxActual,
  required double? radioMetrosActual,
}) {
  return showModalBottomSheet<FiltrosResultado>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _HojaFiltros(
      minValoracionInicial: minValoracionActual,
      precioMaxInicial: precioMaxActual,
      radioMetrosInicial: radioMetrosActual,
    ),
  );
}

class _HojaFiltros extends StatefulWidget {
  const _HojaFiltros({this.minValoracionInicial, this.precioMaxInicial, this.radioMetrosInicial});

  final double? minValoracionInicial;
  final double? precioMaxInicial;
  final double? radioMetrosInicial;

  @override
  State<_HojaFiltros> createState() => _HojaFiltrosState();
}

class _HojaFiltrosState extends State<_HojaFiltros> {
  late double _minValoracion;
  late double _precioMax;
  late double _radioKm;

  static const double _precioMaxTope = 300;
  static const double _radioKmTope = 50;

  @override
  void initState() {
    super.initState();
    _minValoracion = widget.minValoracionInicial ?? 0;
    _precioMax = widget.precioMaxInicial ?? _precioMaxTope;
    _radioKm = widget.radioMetrosInicial != null ? widget.radioMetrosInicial! / 1000 : _radioKmTope;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.buscarFiltros, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: () => setState(() {
                  _minValoracion = 0;
                  _precioMax = _precioMaxTope;
                  _radioKm = _radioKmTope;
                }),
                child: Text(t.filtroLimpiar),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(t.filtroValoracionMinima, style: const TextStyle(fontWeight: FontWeight.w600)),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _minValoracion,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  label: _minValoracion == 0 ? t.filtroCualquiera : _minValoracion.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _minValoracion = v),
                ),
              ),
              SizedBox(
                width: 44,
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade700),
                    Text(_minValoracion == 0 ? '–' : _minValoracion.toStringAsFixed(1)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(t.filtroPrecioMaximo, style: const TextStyle(fontWeight: FontWeight.w600)),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _precioMax,
                  min: 10,
                  max: _precioMaxTope,
                  divisions: 29,
                  label: _precioMax >= _precioMaxTope ? t.filtroCualquiera : t.montoConSimbolo(_precioMax.toStringAsFixed(0)),
                  onChanged: (v) => setState(() => _precioMax = v),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  _precioMax >= _precioMaxTope ? '–' : t.montoConSimbolo(_precioMax.toStringAsFixed(0)),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(t.filtroDistanciaMaxima, style: const TextStyle(fontWeight: FontWeight.w600)),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _radioKm,
                  min: 1,
                  max: _radioKmTope,
                  divisions: 49,
                  label: _radioKm >= _radioKmTope ? t.filtroCualquiera : '${_radioKm.toStringAsFixed(0)} km',
                  onChanged: (v) => setState(() => _radioKm = v),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  _radioKm >= _radioKmTope ? '–' : '${_radioKm.toStringAsFixed(0)} km',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              FiltrosResultado(
                minValoracion: _minValoracion > 0 ? _minValoracion : null,
                precioMax: _precioMax < _precioMaxTope ? _precioMax : null,
                radioMetros: _radioKm < _radioKmTope ? _radioKm * 1000 : null,
              ),
            ),
            child: Text(t.filtroAplicar),
          ),
        ],
      ),
    );
  }
}
