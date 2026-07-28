import 'api_service.dart';

class ReviewService {
  final _api = ApiService.instance.client;

  Future<void> valorar({
    required String serviceRequestId,
    required int puntuacion,
    String? comentario,
  }) async {
    await _api.post('/reviews', data: {
      'serviceRequestId': serviceRequestId,
      'puntuacion': puntuacion,
      if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
    });
  }
}
