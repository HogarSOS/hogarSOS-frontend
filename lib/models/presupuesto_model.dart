enum TipoPresupuesto { cerrado, porHoras }

TipoPresupuesto tipoPresupuestoFromString(String value) {
  return value == 'por_horas' ? TipoPresupuesto.porHoras : TipoPresupuesto.cerrado;
}

String tipoPresupuestoToApi(TipoPresupuesto tipo) {
  return tipo == TipoPresupuesto.porHoras ? 'por_horas' : 'cerrado';
}

enum EstadoPresupuesto { pendiente, aceptado, rechazado }

EstadoPresupuesto estadoPresupuestoFromString(String value) {
  return EstadoPresupuesto.values.firstWhere(
    (e) => e.name == value,
    orElse: () => EstadoPresupuesto.pendiente,
  );
}

/// Presupuesto real que el profesional envía tras ser elegido —
/// sustituye al antiguo precioEstimado adivinado por el cliente. Dos
/// modalidades: cerrado (monto fijo) o por horas (tarifaHora ×
/// horasEstimadas es el importe que se autoriza en Stripe al aceptar).
class PresupuestoInfo {
  final String id;
  final TipoPresupuesto tipo;
  final double? monto;
  final double? tarifaHora;
  final double? horasEstimadas;
  final String? mensaje;
  final EstadoPresupuesto estado;
  final DateTime createdAt;

  PresupuestoInfo({
    required this.id,
    required this.tipo,
    this.monto,
    this.tarifaHora,
    this.horasEstimadas,
    this.mensaje,
    required this.estado,
    required this.createdAt,
  });

  /// Importe a autorizar/pagar: el monto fijo, o el techo tarifa×horas.
  double get importeTotal => tipo == TipoPresupuesto.cerrado ? (monto ?? 0) : (tarifaHora ?? 0) * (horasEstimadas ?? 0);

  factory PresupuestoInfo.fromJson(Map<String, dynamic> json) {
    return PresupuestoInfo(
      id: json['id'] as String,
      tipo: tipoPresupuestoFromString(json['tipo'] as String),
      monto: (json['monto'] as num?)?.toDouble(),
      tarifaHora: (json['tarifaHora'] as num?)?.toDouble(),
      horasEstimadas: (json['horasEstimadas'] as num?)?.toDouble(),
      mensaje: json['mensaje'] as String?,
      estado: estadoPresupuestoFromString(json['estado'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Petición del profesional para sumar margen a un presupuesto ya
/// aceptado, cuando el trabajo se complica más de lo previsto — nunca
/// se cobra el exceso fuera de la app, hay que pasar por aquí y que el
/// cliente lo acepte. Dos modalidades, igual que PresupuestoInfo: por
/// horas (presupuesto "por_horas") o monto directo (presupuesto
/// "cerrado", ej. "+40€, hay que sustituir una válvula").
class AmpliacionInfo {
  final String id;
  final double? horasAdicionales;
  final double? montoAdicional;
  final String? mensaje;
  final EstadoPresupuesto estado;
  final DateTime createdAt;

  AmpliacionInfo({
    required this.id,
    this.horasAdicionales,
    this.montoAdicional,
    this.mensaje,
    required this.estado,
    required this.createdAt,
  });

  bool get esPorHoras => horasAdicionales != null;

  /// Importe adicional a autorizar: el monto directo, o horas × tarifaHora
  /// (la tarifa no vive en esta clase — hay que pasarla desde el
  /// presupuesto al que pertenece esta ampliación).
  double importeAdicional(double? tarifaHora) =>
      montoAdicional ?? (horasAdicionales ?? 0) * (tarifaHora ?? 0);

  factory AmpliacionInfo.fromJson(Map<String, dynamic> json) {
    return AmpliacionInfo(
      id: json['id'] as String,
      horasAdicionales: (json['horasAdicionales'] as num?)?.toDouble(),
      montoAdicional: (json['montoAdicional'] as num?)?.toDouble(),
      mensaje: json['mensaje'] as String?,
      estado: estadoPresupuestoFromString(json['estado'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Cierre de un trabajo "por_horas": el profesional declara las horas
/// reales, pero el pago no se libera hasta que el cliente lo confirma.
class CierreHorasInfo {
  final String id;
  final double horasReales;
  final EstadoPresupuesto estado;
  final DateTime createdAt;

  CierreHorasInfo({required this.id, required this.horasReales, required this.estado, required this.createdAt});

  factory CierreHorasInfo.fromJson(Map<String, dynamic> json) {
    return CierreHorasInfo(
      id: json['id'] as String,
      horasReales: (json['horasReales'] as num).toDouble(),
      estado: estadoPresupuestoFromString(json['estado'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
