import '../models/professional_summary_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// Perfil genérico del usuario autenticado (cualquier rol) — nombre,
/// email, teléfono, foto. El perfil de profesional (oficio, tarifa,
/// categorías...) sigue teniendo su propio servicio aparte
/// (professional_service.dart).
class UserService {
  final _api = ApiService.instance.client;

  Future<AppUser> obtenerMiPerfil() async {
    final respuesta = await _api.get('/users/me');
    return AppUser.fromJson(respuesta.data as Map<String, dynamic>);
  }

  Future<AppUser> actualizarPerfil({String? nombre, String? telefono, String? fotoPerfilUrl}) async {
    final respuesta = await _api.patch('/users/me', data: {
      if (nombre != null) 'nombre': nombre,
      if (telefono != null) 'telefono': telefono,
      if (fotoPerfilUrl != null) 'fotoPerfilUrl': fotoPerfilUrl,
    });
    return AppUser.fromJson(respuesta.data as Map<String, dynamic>);
  }

  /// Elimina la cuenta del usuario autenticado (cualquier rol) — ver
  /// user.controller.ts#deleteMe. Irreversible: borra el usuario de
  /// Firebase Auth y anonimiza los datos personales en nuestra base de
  /// datos. Quien llama a esto debe cerrar la sesión local justo
  /// después (los tokens dejan de servir para nada, pero no hay razón
  /// para conservarlos).
  Future<void> eliminarCuenta() async {
    await _api.delete('/users/me');
  }

  /// Opiniones recibidas por el usuario autenticado (como cliente
  /// contratante, valorado por profesionales). Reutiliza el mismo
  /// modelo ProfessionalReview que ya existe para el perfil público de
  /// profesional — la forma de la opinión (autor, estrellas,
  /// comentario, fecha) es idéntica en ambos sentidos.
  Future<List<ProfessionalReview>> obtenerMisValoraciones() async {
    final respuesta = await _api.get('/users/me/reviews');
    final lista = respuesta.data['opiniones'] as List;
    return lista.map((j) => ProfessionalReview.fromJson(j as Map<String, dynamic>)).toList();
  }
}
