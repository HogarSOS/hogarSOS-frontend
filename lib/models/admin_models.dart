class PendingVerification {
  final String userId;
  final String nombre;
  final String email;
  final String documentoIdentidadUrl;
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
      documentoIdentidadUrl: json['documentoIdentidadUrl'] as String,
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
