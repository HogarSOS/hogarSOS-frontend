import 'presupuesto_model.dart';

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
  final double montoBase;
  final double montoTotal;
  final double comisionPlataforma;
  final double montoProfesional;

  PaymentInfo({
    required this.estado,
    required this.montoBase,
    required this.montoTotal,
    required this.comisionPlataforma,
    required this.montoProfesional,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      estado: json['estado'] as String,
      montoBase: (json['montoBase'] as num).toDouble(),
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
  final String? profesionalNombre;
  final List<String> fotosUrls;
  final String? direccionTexto;
  final UrgenciaSolicitud urgencia;
  final DateTime? fechaDeseada;
  final EstadoSolicitud estado;
  final double? precioFinal;
  final DateTime createdAt;
  final PaymentInfo? payment;
  final List<ReviewInfo> reviews;
  final int numCandidatos;
  final PresupuestoInfo? presupuesto;
  final AmpliacionInfo? ampliacion;
  final CierreHorasInfo? cierreHoras;
  final bool pagoPendienteDeAutorizar;

  ServiceRequestModel({
    required this.id,
    required this.categoria,
    required this.descripcion,
    this.profesionalNombre,
    this.fotosUrls = const [],
    this.direccionTexto,
    this.urgencia = UrgenciaSolicitud.loAntesPosible,
    this.fechaDeseada,
    required this.estado,
    this.precioFinal,
    required this.createdAt,
    this.payment,
    this.reviews = const [],
    this.numCandidatos = 0,
    this.presupuesto,
    this.ampliacion,
    this.cierreHoras,
    this.pagoPendienteDeAutorizar = false,
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
      profesionalNombre: json['profesionalNombre'] as String?,
      fotosUrls: List<String>.from(json['fotosUrls'] as List? ?? []),
      direccionTexto: json['direccionTexto'] as String?,
      urgencia: urgenciaFromString(json['urgencia'] as String? ?? 'lo_antes_posible'),
      fechaDeseada: json['fechaDeseada'] != null ? DateTime.parse(json['fechaDeseada'] as String) : null,
      estado: estadoFromString(json['estado'] as String),
      precioFinal: (json['precioFinal'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      payment: json['payment'] != null ? PaymentInfo.fromJson(json['payment'] as Map<String, dynamic>) : null,
      reviews: (json['reviews'] as List? ?? [])
          .map((r) => ReviewInfo.fromJson(r as Map<String, dynamic>))
          .toList(),
      numCandidatos: (json['numCandidatos'] as num?)?.toInt() ?? 0,
      presupuesto:
          json['presupuesto'] != null ? PresupuestoInfo.fromJson(json['presupuesto'] as Map<String, dynamic>) : null,
      ampliacion:
          json['ampliacion'] != null ? AmpliacionInfo.fromJson(json['ampliacion'] as Map<String, dynamic>) : null,
      cierreHoras:
          json['cierreHoras'] != null ? CierreHorasInfo.fromJson(json['cierreHoras'] as Map<String, dynamic>) : null,
      pagoPendienteDeAutorizar: json['pagoPendienteDeAutorizar'] as bool? ?? false,
    );
  }
}

/// Resumen para la lista "Mis solicitudes" (GET /service-requests/mine)
/// — más ligero que ServiceRequestModel, no necesita el detalle del pago.
class MyServiceRequestSummary {
  final String id;
  final String categoria;
  final String descripcion;
  final String? profesionalNombre;
  final EstadoSolicitud estado;
  final UrgenciaSolicitud urgencia;
  final double? precioFinal;
  final DateTime createdAt;
  final bool tienePago;
  final bool tieneValoracion;
  // No trae el presupuesto/ampliación/cierreHoras completo (eso vive en
  // el detalle) — solo si hay algo pendiente de que el cliente confirme,
  // para poder destacarlo en la lista sin entrar a cada solicitud.
  final bool requiereAccion;

  MyServiceRequestSummary({
    required this.id,
    required this.categoria,
    required this.descripcion,
    this.profesionalNombre,
    required this.estado,
    this.urgencia = UrgenciaSolicitud.loAntesPosible,
    this.precioFinal,
    required this.createdAt,
    required this.tienePago,
    required this.tieneValoracion,
    this.requiereAccion = false,
  });

  factory MyServiceRequestSummary.fromJson(Map<String, dynamic> json) {
    return MyServiceRequestSummary(
      id: json['id'] as String,
      categoria: json['categoria'] as String,
      descripcion: json['descripcion'] as String,
      profesionalNombre: json['profesionalNombre'] as String?,
      estado: estadoFromString(json['estado'] as String),
      urgencia: urgenciaFromString(json['urgencia'] as String? ?? 'lo_antes_posible'),
      precioFinal: (json['precioFinal'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      tienePago: json['tienePago'] as bool,
      tieneValoracion: json['tieneValoracion'] as bool,
      requiereAccion: json['requiereAccion'] as bool? ?? false,
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
  final String? clienteFotoUrl;
  final double? precioFinal;
  final DateTime createdAt;
  final bool tienePago;
  final bool tieneValoracion;
  final PresupuestoInfo? presupuesto;
  final AmpliacionInfo? ampliacion;
  final CierreHorasInfo? cierreHoras;
  final PaymentInfo? payment;

  AssignedRequest({
    required this.id,
    required this.categoria,
    required this.descripcion,
    required this.estado,
    this.direccionTexto,
    required this.clienteNombre,
    this.clienteTelefono,
    this.clienteFotoUrl,
    this.precioFinal,
    required this.createdAt,
    required this.tienePago,
    required this.tieneValoracion,
    this.presupuesto,
    this.ampliacion,
    this.cierreHoras,
    this.payment,
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
      clienteFotoUrl: json['clienteFotoUrl'] as String?,
      precioFinal: (json['precioFinal'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      tieneValoracion: json['tieneValoracion'] as bool,
      tienePago: json['tienePago'] as bool,
      presupuesto:
          json['presupuesto'] != null ? PresupuestoInfo.fromJson(json['presupuesto'] as Map<String, dynamic>) : null,
      ampliacion:
          json['ampliacion'] != null ? AmpliacionInfo.fromJson(json['ampliacion'] as Map<String, dynamic>) : null,
      cierreHoras:
          json['cierreHoras'] != null ? CierreHorasInfo.fromJson(json['cierreHoras'] as Map<String, dynamic>) : null,
      payment: json['payment'] != null ? PaymentInfo.fromJson(json['payment'] as Map<String, dynamic>) : null,
    );
  }
}

class NearbyRequest {
  final String id;
  final String descripcion;
  final double distanciaMetros;
  final DateTime createdAt;
  final UrgenciaSolicitud urgencia;
  final String clienteNombre;
  final String? clienteFotoUrl;
  final bool yaPostulado;

  NearbyRequest({
    required this.id,
    required this.descripcion,
    required this.distanciaMetros,
    required this.createdAt,
    this.urgencia = UrgenciaSolicitud.loAntesPosible,
    required this.clienteNombre,
    this.clienteFotoUrl,
    this.yaPostulado = false,
  });

  factory NearbyRequest.fromJson(Map<String, dynamic> json) {
    return NearbyRequest(
      id: json['id'] as String,
      descripcion: json['descripcion'] as String,
      distanciaMetros: (json['distancia_metros'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      urgencia: urgenciaFromString(json['urgencia'] as String? ?? 'lo_antes_posible'),
      clienteNombre: json['cliente_nombre'] as String? ?? '',
      clienteFotoUrl: json['cliente_foto_url'] as String?,
      yaPostulado: json['ya_postulado'] as bool? ?? false,
    );
  }
}
