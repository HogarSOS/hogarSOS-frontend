class PendingVerification {
  final String userId;
  final String nombre;
  final String email;
  final String? documentoIdentidadUrl;
  final List<String> categorias;

  PendingVerification({
    required this.userId,
    required this.nombre,
    required this.email,
    required this.documentoIdentidadUrl,
    required this.categorias,
  });

  factory PendingVerification.fromJson(Map<String, dynamic> json) {
    return PendingVerification(
      userId: json['userId'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      documentoIdentidadUrl: json['documentoIdentidadUrl'] as String?,
      categorias: List<String>.from(json['categorias'] as List),
    );
  }
}

class DisputeSummary {
  final String id;
  final String motivo;
  final String estado;

  DisputeSummary({required this.id, required this.motivo, required this.estado});

  factory DisputeSummary.fromJson(Map<String, dynamic> json) {
    return DisputeSummary(
      id: json['id'] as String,
      motivo: json['motivo'] as String,
      estado: json['estado'] as String,
    );
  }
}

/// Fila de la cola de pagos atascados (`GET /admin/payments/stuck`) —
/// ver `PagoAtascado` en `payment.service.ts`. `dineroRetenidoEnPlataforma`
/// es la señal de prioridad: `true` significa que el dinero ya salió de
/// la tarjeta del cliente y no ha llegado al profesional.
class StuckPayment {
  final String paymentId;
  final String serviceRequestId;
  final String estado;
  final String estadoSolicitud;
  final String categoria;
  final String clienteNombre;
  final String? profesionalNombre;
  final double montoProfesional;
  final DateTime? capturadoAt;
  final DateTime createdAt;
  final int intentosLiberacion;
  final String? ultimoError;
  final bool dineroRetenidoEnPlataforma;

  StuckPayment({
    required this.paymentId,
    required this.serviceRequestId,
    required this.estado,
    required this.estadoSolicitud,
    required this.categoria,
    required this.clienteNombre,
    required this.profesionalNombre,
    required this.montoProfesional,
    required this.capturadoAt,
    required this.createdAt,
    required this.intentosLiberacion,
    required this.ultimoError,
    required this.dineroRetenidoEnPlataforma,
  });

  factory StuckPayment.fromJson(Map<String, dynamic> json) {
    return StuckPayment(
      paymentId: json['paymentId'] as String,
      serviceRequestId: json['serviceRequestId'] as String,
      estado: json['estado'] as String,
      estadoSolicitud: json['estadoSolicitud'] as String,
      categoria: json['categoria'] as String,
      clienteNombre: json['clienteNombre'] as String,
      profesionalNombre: json['profesionalNombre'] as String?,
      montoProfesional: (json['montoProfesional'] as num).toDouble(),
      capturadoAt: json['capturadoAt'] != null ? DateTime.parse(json['capturadoAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      intentosLiberacion: json['intentosLiberacion'] as int,
      ultimoError: json['ultimoError'] as String?,
      dineroRetenidoEnPlataforma: json['dineroRetenidoEnPlataforma'] as bool,
    );
  }
}

/// Respuesta completa de `GET /admin/payments/stuck` — ver `listStuckPayments`
/// en `admin.controller.ts`.
class StuckPaymentsSummary {
  final int total;
  final double importeRetenidoEnPlataforma;
  final List<StuckPayment> pagos;

  StuckPaymentsSummary({
    required this.total,
    required this.importeRetenidoEnPlataforma,
    required this.pagos,
  });

  factory StuckPaymentsSummary.fromJson(Map<String, dynamic> json) {
    return StuckPaymentsSummary(
      total: json['total'] as int,
      importeRetenidoEnPlataforma: (json['importeRetenidoEnPlataforma'] as num).toDouble(),
      pagos: (json['pagos'] as List)
          .map((p) => StuckPayment.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

