enum UserRole { cliente, profesional, admin }

UserRole userRoleFromString(String value) {
  return UserRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => UserRole.cliente,
  );
}

class AppUser {
  final String id;
  final String nombre;
  final UserRole role;
  final String? email;
  final String? telefono;
  final String? fotoPerfilUrl;
  final double valoracionMedia;
  final int totalValoraciones;

  AppUser({
    required this.id,
    required this.nombre,
    required this.role,
    this.email,
    this.telefono,
    this.fotoPerfilUrl,
    this.valoracionMedia = 0,
    this.totalValoraciones = 0,
  });

  /// El login/registro solo devuelve {id, nombre, role} (ver
  /// auth.controller.ts) — el resto (email/telefono/foto/valoración)
  /// se carga aparte, con GET /users/me, cuando hace falta mostrarlo o
  /// editarlo. Por eso todos esos campos tienen un valor por defecto
  /// razonable: el AppUser que sale de login/registro los deja vacíos
  /// a propósito, no es un dato incorrecto.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      role: userRoleFromString(json['role'] as String),
      email: json['email'] as String?,
      telefono: json['telefono'] as String?,
      fotoPerfilUrl: json['fotoPerfilUrl'] as String?,
      valoracionMedia: (json['valoracionMedia'] as num?)?.toDouble() ?? 0,
      totalValoraciones: json['totalValoraciones'] as int? ?? 0,
    );
  }

  AppUser copyWith({String? nombre, String? telefono, String? fotoPerfilUrl}) {
    return AppUser(
      id: id,
      nombre: nombre ?? this.nombre,
      role: role,
      email: email,
      telefono: telefono ?? this.telefono,
      fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
      valoracionMedia: valoracionMedia,
      totalValoraciones: totalValoraciones,
    );
  }
}
