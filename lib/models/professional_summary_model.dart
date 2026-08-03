import 'tipo_profesional.dart';

class ProfessionalSummary {
  final String userId;
  final String nombre;
  final double tarifaBase;
  final double valoracionMedia;
  final int totalTrabajos;
  final bool disponible;
  final String? fotoPerfilUrl;
  final List<String> categorias;
  final double? distanciaMetros;
  final String? estadoVerificacion;
  final TipoProfesional? tipoProfesional;

  ProfessionalSummary({
    required this.userId,
    required this.nombre,
    required this.tarifaBase,
    required this.valoracionMedia,
    required this.totalTrabajos,
    required this.disponible,
    this.fotoPerfilUrl,
    required this.categorias,
    this.distanciaMetros,
    this.estadoVerificacion,
    this.tipoProfesional,
  });

  /// El distintivo de verificación se basa en lo que confirma el backend,
  /// independientemente de si REQUIRE_PROFESSIONAL_VERIFICATION exige ese
  /// estado para operar.
  bool get estaVerificado => estadoVerificacion == 'aprobado';

  factory ProfessionalSummary.fromJson(Map<String, dynamic> json) {
    return ProfessionalSummary(
      userId: json['userId'] as String,
      nombre: json['nombre'] as String,
      tarifaBase: (json['tarifaBase'] as num).toDouble(),
      valoracionMedia: (json['valoracionMedia'] as num).toDouble(),
      totalTrabajos: json['totalTrabajos'] as int,
      disponible: json['disponible'] as bool,
      fotoPerfilUrl: json['fotoPerfilUrl'] as String?,
      categorias: List<String>.from(json['categorias'] as List? ?? []),
      distanciaMetros: (json['distanciaMetros'] as num?)?.toDouble(),
      estadoVerificacion: json['estadoVerificacion'] as String?,
      tipoProfesional: TipoProfesional.fromJson(json['tipoProfesional'] as String?),
    );
  }
}

class ProfessionalReview {
  final String autor;
  final int puntuacion;
  final String? comentario;
  final DateTime fecha;

  ProfessionalReview({
    required this.autor,
    required this.puntuacion,
    this.comentario,
    required this.fecha,
  });

  factory ProfessionalReview.fromJson(Map<String, dynamic> json) {
    return ProfessionalReview(
      autor: json['autor'] as String,
      puntuacion: json['puntuacion'] as int,
      comentario: json['comentario'] as String?,
      fecha: DateTime.parse(json['fecha'] as String),
    );
  }
}

class ProfessionalPublicProfile {
  final String userId;
  final String nombre;
  final double tarifaBase;
  final double valoracionMedia;
  final int totalTrabajos;
  final bool disponible;
  final String? descripcion;
  final String? fotoPerfilUrl;
  final List<String> categorias;
  final List<ProfessionalReview> reviews;
  final String? estadoVerificacion;
  final TipoProfesional? tipoProfesional;

  ProfessionalPublicProfile({
    required this.userId,
    required this.nombre,
    required this.tarifaBase,
    required this.valoracionMedia,
    required this.totalTrabajos,
    required this.disponible,
    this.descripcion,
    this.fotoPerfilUrl,
    required this.categorias,
    required this.reviews,
    this.estadoVerificacion,
    this.tipoProfesional,
  });

  bool get estaVerificado => estadoVerificacion == 'aprobado';

  factory ProfessionalPublicProfile.fromJson(Map<String, dynamic> json) {
    return ProfessionalPublicProfile(
      userId: json['userId'] as String,
      nombre: json['nombre'] as String,
      tarifaBase: (json['tarifaBase'] as num).toDouble(),
      valoracionMedia: (json['valoracionMedia'] as num).toDouble(),
      totalTrabajos: json['totalTrabajos'] as int,
      disponible: json['disponible'] as bool,
      descripcion: json['descripcion'] as String?,
      fotoPerfilUrl: json['fotoPerfilUrl'] as String?,
      categorias: List<String>.from(json['categorias'] as List? ?? []),
      reviews: (json['reviews'] as List? ?? [])
          .map((r) => ProfessionalReview.fromJson(r as Map<String, dynamic>))
          .toList(),
      estadoVerificacion: json['estadoVerificacion'] as String?,
      tipoProfesional: TipoProfesional.fromJson(json['tipoProfesional'] as String?),
    );
  }
}
