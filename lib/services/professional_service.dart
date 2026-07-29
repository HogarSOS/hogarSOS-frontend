import '../models/professional_summary_model.dart';
import 'api_service.dart';

class SearchFilters {
  final int? categoryId;
  final String? query;
  final double? minValoracion;
  final double? precioMax;
  final bool soloDisponibles;
  final double? radioMetros;

  const SearchFilters({
    this.categoryId,
    this.query,
    this.minValoracion,
    this.precioMax,
    this.soloDisponibles = false,
    this.radioMetros,
  });

  bool get tieneFiltrosActivos =>
      categoryId != null ||
      minValoracion != null ||
      precioMax != null ||
      soloDisponibles ||
      radioMetros != null;

  SearchFilters copyWith({
    int? categoryId,
    bool limpiarCategoria = false,
    String? query,
    double? minValoracion,
    bool limpiarMinValoracion = false,
    double? precioMax,
    bool limpiarPrecioMax = false,
    bool? soloDisponibles,
    double? radioMetros,
    bool limpiarRadioMetros = false,
  }) {
    return SearchFilters(
      categoryId: limpiarCategoria ? null : (categoryId ?? this.categoryId),
      query: query ?? this.query,
      minValoracion: limpiarMinValoracion ? null : (minValoracion ?? this.minValoracion),
      precioMax: limpiarPrecioMax ? null : (precioMax ?? this.precioMax),
      soloDisponibles: soloDisponibles ?? this.soloDisponibles,
      radioMetros: limpiarRadioMetros ? null : (radioMetros ?? this.radioMetros),
    );
  }
}

/// Modo de disponibilidad declarado por el profesional. Deliberadamente
/// solo dos valores en esta primera versión (sin calendario ni horarios
/// personalizados) — el enum ya deja la puerta abierta a añadir más
/// variantes en el futuro sin tocar el resto del código que lo usa.
enum ModoDisponibilidad {
  horarioLaboral,
  veinticuatroHoras;

  static ModoDisponibilidad fromJson(String valor) {
    return valor == 'veinticuatro_horas' ? ModoDisponibilidad.veinticuatroHoras : ModoDisponibilidad.horarioLaboral;
  }

  String toJson() => this == ModoDisponibilidad.veinticuatroHoras ? 'veinticuatro_horas' : 'horario_laboral';
}

class MiPerfilProfesional {
  final String nombre;
  final String? telefono;
  final String estadoVerificacion;
  final double tarifaBase;
  final double valoracionMedia;
  final int totalTrabajos;
  final bool disponible;
  final ModoDisponibilidad modoDisponibilidad;
  final String? descripcion;
  final String? fotoPerfilUrl;
  final String? documentoIdentidadUrl;
  final List<String> categorias;
  final bool cuentaStripeConfigurada;
  final List<ProfessionalReview> opiniones;

  MiPerfilProfesional({
    required this.nombre,
    this.telefono,
    required this.estadoVerificacion,
    required this.tarifaBase,
    required this.valoracionMedia,
    required this.totalTrabajos,
    required this.disponible,
    required this.modoDisponibilidad,
    this.descripcion,
    this.fotoPerfilUrl,
    this.documentoIdentidadUrl,
    required this.categorias,
    required this.cuentaStripeConfigurada,
    this.opiniones = const [],
  });

  /// La categoría principal ("oficio") es la primera que el profesional
  /// tiene asignada — no existe un campo "oficio" aparte a propósito,
  /// para no duplicar el sistema de categorías ya existente.
  String? get oficioPrincipal => categorias.isNotEmpty ? categorias.first : null;

  bool get estaVerificado => estadoVerificacion == 'aprobado';

  /// Lo mínimo para que un profesional pueda aparecer en búsquedas de
  /// forma útil: foto (para que el cliente identifique quién viene) y
  /// al menos una categoría (sin ella no aparece en ninguna búsqueda,
  /// literalmente no hay forma de encontrarlo). Se usa tanto para
  /// mostrar el aviso de "completa tu perfil" como para bloquear el
  /// interruptor de disponibilidad hasta que se cumpla.
  bool get perfilCompleto => fotoPerfilUrl != null && categorias.isNotEmpty;

  factory MiPerfilProfesional.fromJson(Map<String, dynamic> json) {
    return MiPerfilProfesional(
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
      estadoVerificacion: json['estadoVerificacion'] as String,
      tarifaBase: (json['tarifaBase'] as num).toDouble(),
      valoracionMedia: (json['valoracionMedia'] as num).toDouble(),
      totalTrabajos: json['totalTrabajos'] as int,
      disponible: json['disponible'] as bool,
      modoDisponibilidad: ModoDisponibilidad.fromJson(json['modoDisponibilidad'] as String? ?? 'horario_laboral'),
      descripcion: json['descripcion'] as String?,
      fotoPerfilUrl: json['fotoPerfilUrl'] as String?,
      documentoIdentidadUrl: json['documentoIdentidadUrl'] as String?,
      categorias: List<String>.from(json['categorias'] as List? ?? []),
      cuentaStripeConfigurada: json['cuentaStripeConfigurada'] as bool,
      opiniones: (json['opiniones'] as List? ?? [])
          .map((r) => ProfessionalReview.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProfessionalService {
  final _api = ApiService.instance.client;

  Future<MiPerfilProfesional> obtenerMiPerfil() async {
    final respuesta = await _api.get('/professionals/me');
    return MiPerfilProfesional.fromJson(respuesta.data as Map<String, dynamic>);
  }

  /// Actualiza si el profesional está aceptando trabajos. Manda también
  /// la ubicación actual cuando se pone disponible — es lo que permite
  /// que la búsqueda por cercanía (ver professional.controller.ts) tenga
  /// datos frescos, igual que hacen apps de reparto/transporte.
  Future<void> actualizarDisponibilidad({
    required bool disponible,
    ModoDisponibilidad? modo,
    double? latitud,
    double? longitud,
  }) async {
    await _api.patch('/professionals/me/availability', data: {
      'disponible': disponible,
      if (modo != null) 'modoDisponibilidad': modo.toJson(),
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
    });
  }

  /// Actualiza descripción, precio por hora y/o foto de perfil.
  Future<void> actualizarPerfil({
    String? descripcion,
    double? tarifaBase,
    String? fotoPerfilUrl,
  }) async {
    await _api.patch('/professionals/me/profile', data: {
      if (descripcion != null) 'descripcion': descripcion,
      if (tarifaBase != null) 'tarifaBase': tarifaBase,
      if (fotoPerfilUrl != null) 'fotoPerfilUrl': fotoPerfilUrl,
    });
  }

  /// Cambia las categorías de servicio del profesional sin pasar por el
  /// flujo de verificación (no reenvía documentos ni toca
  /// estadoVerificacion).
  Future<void> actualizarCategorias(List<int> categoriaIds) async {
    await _api.patch('/professionals/me/categories', data: {'categoriaIds': categoriaIds});
  }

  /// Envía la documentación de verificación para revisión de un admin
  /// (POST /professionals/me/verification). Antes de este método, el
  /// backend tenía este endpoint completo pero ningún sitio del
  /// frontend lo llamaba — un profesional podía completar foto +
  /// categorías y creer que ya estaba listo, sin que se disparara
  /// nunca el envío real de documentación que un admin pudiera aprobar.
  Future<void> enviarVerificacion({
    required String documentoIdentidadUrl,
    required List<int> categoriaIds,
    required double tarifaBase,
  }) async {
    await _api.post('/professionals/me/verification', data: {
      'documentoIdentidadUrl': documentoIdentidadUrl,
      'categoriaIds': categoriaIds,
      'tarifaBase': tarifaBase,
    });
  }

  Future<List<ProfessionalSummary>> buscar(
    SearchFilters filtros, {
    double? latitud,
    double? longitud,
  }) async {
    final respuesta = await _api.get('/professionals/search', queryParameters: {
      if (filtros.categoryId != null) 'categoryId': filtros.categoryId,
      if (filtros.query != null && filtros.query!.isNotEmpty) 'query': filtros.query,
      if (filtros.minValoracion != null) 'minValoracion': filtros.minValoracion,
      if (filtros.precioMax != null) 'precioMax': filtros.precioMax,
      if (filtros.soloDisponibles) 'soloDisponibles': true,
      if (filtros.radioMetros != null) 'radioMetros': filtros.radioMetros,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
    });

    final lista = respuesta.data['resultados'] as List;
    return lista.map((j) => ProfessionalSummary.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<ProfessionalPublicProfile> obtenerPerfilPublico(String userId) async {
    final respuesta = await _api.get('/professionals/$userId');
    return ProfessionalPublicProfile.fromJson(respuesta.data as Map<String, dynamic>);
  }
}
