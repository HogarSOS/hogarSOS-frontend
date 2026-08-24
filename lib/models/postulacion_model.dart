import 'tipo_profesional.dart';

/// Un profesional postulado a una solicitud, tal como lo ve el
/// cliente al elegir. No reutiliza ProfessionalSummary (modelo de la
/// búsqueda de profesionales, sin mensaje de disponibilidad ni el
/// número de reseñas real).
class PostulacionCandidate {
  final String id;
  final String profesionalId;
  final String nombre;
  final String? fotoPerfilUrl;
  final double valoracionMedia;
  final int totalValoraciones;
  final double? distanciaMetros;
  final String mensaje;
  final bool estaVerificado;

  final DateTime createdAt;

  /// Situación fiscal declarada (Autónomo/Empresa/Particular) para que
  /// el cliente la vea ANTES de elegir. Nullable a propósito: una API
  /// antigua sin el campo, o un valor desconocido, se queda en null y
  /// la tarjeta simplemente no pinta el chip (TipoProfesional.fromJson
  /// ya devuelve null en ambos casos).
  final TipoProfesional? tipoProfesional;

  PostulacionCandidate({
    required this.id,
    required this.profesionalId,
    required this.nombre,
    this.fotoPerfilUrl,
    required this.valoracionMedia,
    required this.totalValoraciones,
    this.distanciaMetros,
    required this.mensaje,
    required this.estaVerificado,
    required this.createdAt,
    this.tipoProfesional,
  });

  factory PostulacionCandidate.fromJson(Map<String, dynamic> json) {
    return PostulacionCandidate(
      id: json['id'] as String,
      profesionalId: json['profesional_id'] as String,
      nombre: json['nombre'] as String? ?? '',
      fotoPerfilUrl: json['foto_perfil_url'] as String?,
      valoracionMedia: (json['valoracion_media'] as num?)?.toDouble() ?? 0,
      totalValoraciones: (json['total_valoraciones'] as num?)?.toInt() ?? 0,
      distanciaMetros: (json['distancia_metros'] as num?)?.toDouble(),
      mensaje: json['mensaje'] as String? ?? '',
      estaVerificado: json['estado_verificacion'] == 'aprobado',
      createdAt: DateTime.parse(json['created_at'] as String),
      tipoProfesional: TipoProfesional.fromJson(json['tipo_profesional'] as String?),
    );
  }
}
