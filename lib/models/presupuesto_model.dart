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
