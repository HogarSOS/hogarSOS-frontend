class ServiceCategory {
  final int id;
  final String nombre;
  final String? iconoUrl;

  ServiceCategory({required this.id, required this.nombre, this.iconoUrl});

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      iconoUrl: json['icono_url'] as String?,
    );
  }
}
