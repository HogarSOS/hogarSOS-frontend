import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String texto;
  final String autorId;
  final DateTime enviadoEn;

  ChatMessage({required this.texto, required this.autorId, required this.enviadoEn});

  factory ChatMessage.fromFirestore(Map<String, dynamic> data) {
    // 'enviadoEn' viene como null en la primera versión LOCAL del
    // documento (antes de que el servidor confirme el
    // FieldValue.serverTimestamp()) — esto pasa siempre para el propio
    // remitente justo al enviar. Sin este null-check, lanzaba una
    // excepción real ("null no es un Timestamp") cada vez que alguien
    // enviaba un mensaje.
    final timestamp = data['enviadoEn'] as Timestamp?;
    return ChatMessage(
      texto: data['texto'] as String,
      autorId: data['autorId'] as String,
      enviadoEn: timestamp?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'texto': texto,
        'autorId': autorId,
        'enviadoEn': FieldValue.serverTimestamp(),
      };
}

/// Chat en tiempo real con Firestore, separado del backend Node.js a
/// propósito: Firestore ya resuelve la sincronización en tiempo real y
/// el modo offline sin que tengamos que montar websockets propios en
/// la API. Cada solicitud de servicio tiene su propia colección de
/// mensajes bajo /service_requests/{id}/messages.
class ChatService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _mensajesRef(String serviceRequestId) {
    return _firestore
        .collection('service_requests')
        .doc(serviceRequestId)
        .collection('messages');
  }

  Stream<List<ChatMessage>> observarMensajes(String serviceRequestId) {
    return _mensajesRef(serviceRequestId)
        .orderBy('enviadoEn', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc.data())).toList());
  }

  Future<void> enviarMensaje({
    required String serviceRequestId,
    required String texto,
    required String autorId,
  }) async {
    final mensaje = ChatMessage(texto: texto, autorId: autorId, enviadoEn: DateTime.now());
    await _mensajesRef(serviceRequestId).add(mensaje.toFirestore());
  }
}
