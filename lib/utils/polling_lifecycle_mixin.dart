import 'dart:async';
import 'package:flutter/widgets.dart';

/// Sondeo periódico (Timer.periodic) que se pausa solo mientras la app
/// está en segundo plano y retoma al volver a primer plano (con una
/// recarga inmediata, para no esperar hasta el próximo tick tras
/// volver). Antes, las 4 pantallas con polling de la app (solicitudes
/// del cliente, seguimiento, solicitudes cercanas y trabajos activos
/// del profesional) seguían sondeando cada 5-10s con el móvil en el
/// bolsillo o la app minimizada — puro gasto de batería, datos móviles
/// y carga en el backend sin que nadie estuviera mirando la pantalla.
///
/// Mixin en vez de copiar el mismo WidgetsBindingObserver 4 veces —
/// una sola implementación que las 4 pantallas reutilizan.
mixin PollingLifecycleMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  Timer? _pollingTimer;
  Duration? _pollingInterval;
  FutureOr<void> Function()? _pollingCallback;
  bool _pollingEnPrimerPlano = true;

  /// Llamar desde initState() en vez de crear el Timer.periodic a mano.
  void startPolling(Duration interval, FutureOr<void> Function() onTick) {
    WidgetsBinding.instance.addObserver(this);
    _pollingInterval = interval;
    _pollingCallback = onTick;
    _pollingTimer = Timer.periodic(interval, (_) => onTick());
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final callback = _pollingCallback;
    final interval = _pollingInterval;
    if (callback == null || interval == null) return;

    final ahoraEnPrimerPlano = state == AppLifecycleState.resumed;
    if (ahoraEnPrimerPlano == _pollingEnPrimerPlano) return;
    _pollingEnPrimerPlano = ahoraEnPrimerPlano;

    if (ahoraEnPrimerPlano) {
      callback(); // recarga inmediata al volver, no esperar al próximo tick
      _pollingTimer = Timer.periodic(interval, (_) => callback());
    } else {
      _pollingTimer?.cancel();
    }
  }
}
