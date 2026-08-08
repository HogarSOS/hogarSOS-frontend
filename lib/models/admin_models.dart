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

/// Fila de `GET /admin/jobs` — ver `listJobs` en `admin.controller.ts`.
/// `nombre` es el identificador estable (kebab-case, clave primaria en
/// BD); `descripcion` es el texto legible que ya viene listo del backend
/// para mostrar tal cual. `ultimoResultado`/`ultimoError` son texto
/// libre (el resumen que devuelve `tarea.ejecutar()`, truncado a 500
/// caracteres por el backend) — nunca los dos a la vez: si la última
/// ejecución fue bien, `ultimoError` es null, y viceversa.
class ScheduledJob {
  final String nombre;
  final String descripcion;
  final int intervaloMinutos;
  final DateTime? ultimaEjecucionAt;
  final DateTime? proximaEjecucionAprox;
  final bool enCurso;
  final int ejecuciones;
  final int fallosConsecutivos;
  final String? ultimoResultado;
  final String? ultimoError;

  ScheduledJob({
    required this.nombre,
    required this.descripcion,
    required this.intervaloMinutos,
    required this.ultimaEjecucionAt,
    required this.proximaEjecucionAprox,
    required this.enCurso,
    required this.ejecuciones,
    required this.fallosConsecutivos,
    required this.ultimoResultado,
    required this.ultimoError,
  });

  factory ScheduledJob.fromJson(Map<String, dynamic> json) {
    return ScheduledJob(
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      intervaloMinutos: json['intervaloMinutos'] as int,
      ultimaEjecucionAt: json['ultimaEjecucionAt'] != null
          ? DateTime.parse(json['ultimaEjecucionAt'] as String)
          : null,
      proximaEjecucionAprox: json['proximaEjecucionAprox'] != null
          ? DateTime.parse(json['proximaEjecucionAprox'] as String)
          : null,
      enCurso: json['enCurso'] as bool,
      ejecuciones: json['ejecuciones'] as int,
      fallosConsecutivos: json['fallosConsecutivos'] as int,
      ultimoResultado: json['ultimoResultado'] as String?,
      ultimoError: json['ultimoError'] as String?,
    );
  }
}

