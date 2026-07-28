enum EstadoSolicitud { pendiente, aceptada, en_progreso, completada, cancelada, disputada }

EstadoSolicitud estadoFromString(String value) {
  return EstadoSolicitud.values.firstWhere(
    (e) => e.name == value,
    orElse: () => EstadoSolicitud.pendiente,
  );
}

/// Debe coincidir exactamente con el enum `UrgenciaSolicitud` de
/// prisma/schema.prisma en el backend.
enum UrgenciaSolicitud { loAntesPosible, hoy, manana, fechaEspecifica }

extension UrgenciaSolicitudApi on UrgenciaSolicitud {
  /// Valor tal como lo espera/devuelve la API (snake_case).
  String get valorApi => switch (this) {
        UrgenciaSolicitud.loAntesPosible => 'lo_antes_posible',
        UrgenciaSolicitud.hoy => 'hoy',
        UrgenciaSolicitud.manana => 'manana',
        UrgenciaSolicitud.fechaEspecifica => 'fecha_especifica',
      };
}

UrgenciaSolicitud urgenciaFromString(String value) {
  return switch (value) {
    'hoy' => UrgenciaSolicitud.hoy,
    'manana' => UrgenciaSolicitud.manana,
    'fecha_especifica' => UrgenciaSolicitud.fechaEspecifica,
    _ => UrgenciaSolicitud.loAntesPosible,
  };
}

class PaymentInfo {
  final String estado; // retenido | liberado | reembolsado | fallido
  final double montoTotal;
  final double comisionPlataforma;
  final double montoProfesional;

  PaymentInfo({
    required this.estado,
    required this.montoTotal,
    required this.comisionPlataforma,
    required this.montoProfesional,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      estado: json['estado'] as String,
      montoTotal: (json['montoTotal'] as num).toDouble(),
      comisionPlataforma: (json['comisionPlataforma'] as num).toDouble(),
      montoProfesional: (json['montoProfesional'] as num).toDouble(),
    );
  }
}

/// Una valoración puede venir de cualquiera de los dos lados de la
/// solicitud (cliente->profesional o profesional->cliente) — `autorId`
/// es lo que permite distinguir "¿ya valoré YO?" de "¿ya me valoró el
/// otro?" sin que el backend tenga que adivinar desde qué lado se pide.
class ReviewInfo {
  final String autorId;
  final int puntuacion;
  final String? comentario;

  ReviewInfo({required this.autorId, required this.puntuacion, this.comentario});

  factory ReviewInfo.fromJson(Map<String, dynamic> json) {
    return ReviewInfo(
      autorId: json['autorId'] as String,
      puntuacion: json['puntuacion'] as int,
      comentario: json['comentario'] as String?,
    );
  }
}

class ServiceRequestModel {
  final String id;
  final String categoria;
  final String descripcion;
  final List<String> fotosUrls;
  final String? direccionTexto;
  final UrgenciaSolicitud urgencia;
  final DateTime? fechaDeseada;
  final EstadoSolicitud estado;
  final double? precioEstimado;
  final double? precioFinal;
  final DateTime createdAt;
  final PaymentInfo? payment;
  final List<ReviewInfo> reviews;

  ServiceRequestModel({
    required this.id,
    required this.categoria,
    required this.descripcion,
    this.fotosUrls = const [],
    this.direccionTexto,
    this.urgencia = UrgenciaSolicitud.loAntesPosible,
    this.fechaDeseada,
    required this.estado,
    this.precioEstimado,
    this.precioFinal,
    required this.createdAt,
    this.payment,
    this.reviews = const [],
  });

  /// La valoración que dejó ESTE usuario (no la que recibió) — null si
  /// todavía no ha valorado.
  ReviewInfo? miValoracion(String usuarioId) {
    for (final r in reviews) {
      if (r.autorId == usuarioId) return r;
    }
    return null;
  }

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModel(
      id: json['id'] as String,
      categoria: json['categoria'] as String,
      descripcion: json['descripcion'] as String,
      fotosUrls: List<String>.from(json['fotosUrls'] as List? ?? []),
      direccionTexto: json['direccionTexto'] as String?,
      urgencia: urgenciaFromString(json['urgencia'] as String? ?? 'lo_antes_posible'),
      fechaDeseada: json['fechaDeseada'] != null ? DateTime.parse(json['fechaDeseada'] as String) : null,
      estado: estadoFromString(json['estado'] as String),
      precioEstimado: (json['precioEstimado'] as num?)?.toDouble(),
      precioFinal: (json['precioFinal'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      payment: json['payment'] != null ? PaymentInfo.fromJson(json['payment'] as Map<String, dynamic>) : null,
      reviews: (json['reviews'] as List? ?? [])
          .map((r) => ReviewInfo.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Resumen para la lista "Mis solicitudes" (GET /service-requests/mine)
/// — más ligero que ServiceRequestModel, no necesita el detalle del pago.
class MyServiceRequestSummary {
  final String id;
  final String categoria;
  final String descripcion;
  final EstadoSolicitud estado;
  final UrgenciaSolicitud urgencia;
  final double? precioEstimado;
  final double? precioFinal;
  final DateTime createdAt;
  final bool tienePago;
  final bool tieneValoracion;

  MyServiceRequestSummary({
    required this.id,
    required this.categoria,
    required this.descripcion,
    required this.estado,
    this.urgencia = UrgenciaSolicitud.loAntesPosible,
    this.precioEstimado,
    this.precioFinal,
    required this.createdAt,
    required this.tienePago,
    required this.tieneValoracion,
  });

  factory MyServiceRequestSummary.fromJson(Map<String, dynamic> json) {
    return MyServiceRequestSummary(
      id: json['id'] as String,
      categoria: json['categoria'] as String,
      descripcion: json['descripcion'] as String,
      estado: estadoFromString(json['estado'] as String),
      urgencia: urgenciaFromString(json['urgencia'] as String? ?? 'lo_antes_posible'),
      precioEstimado: (json['precioEstimado'] as num?)?.toDouble(),
      precioFinal: (json['precioFinal'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      tienePago: json['tienePago'] as bool,
      tieneValoracion: json['tieneValoracion'] as bool,
    );
  }
}

/// Trabajo ya aceptado por el profesional autenticado, pendiente de
/// completar (GET /service-requests/assigned/mine).
class AssignedRequest {
  final String id;
  final String categoria;
  final String descripcion;
  final EstadoSolicitud estado;
  final String? direccionTexto;
  final String clienteNombre;
  final String? clienteTelefono;
  final double? precioEstimado;
  final double? precioFinal;
  final DateTime createdAt;
  final bool tienePago;
  final bool tieneValoracion;

  AssignedRequest({
    required this.id,
    required this.categoria,
    required this.descripcion,
    required this.estado,
    this.direccionTexto,
    required this.clienteNombre,
    this.clienteTelefono,
    this.precioEstimado,
    this.precioFinal,
    required this.createdAt,
    required this.tienePago,
    required this.tieneValoracion,
  });

  factory AssignedRequest.fromJson(Map<String, dynamic> json) {
    return AssignedRequest(
      id: json['id'] as String,
      categoria: json['categoria'] as String,
      descripcion: json['descripcion'] as String,
      estado: estadoFromString(json['estado'] as String),
      direccionTexto: json['direccionTexto'] as String?,
      clienteNombre: json['clienteNombre'] as String,
      clienteTelefono: json['clienteTelefono'] as String?,
      precioEstimado: (json['precioEstimado'] as num?)?.toDouble(),
      precioFinal: (json['precioFinal'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      tieneValoracion: json['tieneValoracion'] as bool,
      tienePago: json['tienePago'] as bool,
    );
  }
}

class NearbyRequest {
  final String id;
  final String descripcion;
  final double distanciaMetros;
  final DateTime createdAt;
  final UrgenciaSolicitud urgencia;

  NearbyRequest({
    required this.id,
    required this.descripcion,
    required this.distanciaMetros,
    required this.createdAt,
    this.urgencia = UrgenciaSolicitud.loAntesPosible,
  });

  factory NearbyRequest.fromJson(Map<String, dynamic> json) {
    return NearbyRequest(
      id: json['id'] as String,
      descripcion: json['descripcion'] as String,
      distanciaMetros: (json['distancia_metros'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      urgencia: urgenciaFromString(json['urgencia'] as String? ?? 'lo_antes_posible'),
    );
  }
}
