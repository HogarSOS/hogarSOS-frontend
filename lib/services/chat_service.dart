import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

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

/// Hasta dónde ha leído cada parte el chat de una solicitud — vive en el
/// propio documento service_requests/{id} de Firestore (mismo documento
/// que ya sincroniza el backend con clienteFirebaseUid/
/// profesionalFirebaseUid), no en los mensajes. Solo el backend puede
/// ESCRIBIR aquí (ver POST /:id/mark-chat-read): las reglas de Firestore
/// desplegadas solo dan `allow read` al cliente Flutter sobre este
/// documento.
class EstadoLecturaChat {
  final String? clienteFirebaseUid;
  final String? profesionalFirebaseUid;
  final DateTime? lastReadCliente;
  final DateTime? lastReadProfesional;

  const EstadoLecturaChat({
    this.clienteFirebaseUid,
    this.profesionalFirebaseUid,
    this.lastReadCliente,
    this.lastReadProfesional,
  });

  static const vacio = EstadoLecturaChat();

  bool _esCliente(String miUid) => miUid.isNotEmpty && miUid == clienteFirebaseUid;

  /// Hasta cuándo ha leído la OTRA persona — para marcar mis propios
  /// mensajes enviados como leídos (✓✓) o no (✓).
  DateTime? otroLastRead(String miUid) => _esCliente(miUid) ? lastReadProfesional : lastReadCliente;

  /// Hasta cuándo he leído YO — para el indicador de "mensaje nuevo" en
  /// las listas de conversaciones.
  DateTime? miLastRead(String miUid) => _esCliente(miUid) ? lastReadCliente : lastReadProfesional;
}

/// Chat en tiempo real con Firestore, separado del backend Node.js a
/// propósito: Firestore ya resuelve la sincronización en tiempo real y
/// el modo offline sin que tengamos que montar websockets propios en
/// la API. Cada solicitud de servicio tiene su propia colección de
/// mensajes bajo /service_requests/{id}/messages.
class ChatService {
  final _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _solicitudRef(String serviceRequestId) {
    return _firestore.collection('service_requests').doc(serviceRequestId);
  }

  CollectionReference<Map<String, dynamic>> _mensajesRef(String serviceRequestId) {
    return _solicitudRef(serviceRequestId).collection('messages');
  }

  // Límite de rendimiento (auditoría pre-lanzamiento): sin tope, un
  // trabajo recurrente con meses de conversación descargaría y
  // mantendría en memoria el historial completo cada vez que se abre el
  // chat. Se pide descendente + limit (los últimos N) y se invierte en
  // memoria para seguir devolviendo el orden ascendente que espera la
  // pantalla — con menos de _limiteMensajes mensajes en la conversación
  // (el caso normal hoy) esto no cambia nada visible.
  static const _limiteMensajes = 200;

  Stream<List<ChatMessage>> observarMensajes(String serviceRequestId) {
    return _mensajesRef(serviceRequestId)
        .orderBy('enviadoEn', descending: true)
        .limit(_limiteMensajes)
        .snapshots()
        .map((snapshot) => snapshot.docs.reversed
            .map((doc) => ChatMessage.fromFirestore(doc.data()))
            .toList());
  }

  /// Solo el último mensaje — usado para el indicador de "mensaje nuevo"
  /// en las listas de conversaciones (mensajes_screen.dart,
  /// trabajos_activos_profesional_screen.dart), donde suscribirse al
  /// historial completo de cada conversación sería mucho más caro que
  /// necesitar solo su último mensaje.
  Stream<ChatMessage?> observarUltimoMensaje(String serviceRequestId) {
    return _mensajesRef(serviceRequestId)
        .orderBy('enviadoEn', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isEmpty ? null : ChatMessage.fromFirestore(snapshot.docs.first.data()));
  }

  Stream<EstadoLecturaChat> observarEstadoLectura(String serviceRequestId) {
    return _solicitudRef(serviceRequestId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return EstadoLecturaChat.vacio;
      return EstadoLecturaChat(
        clienteFirebaseUid: data['clienteFirebaseUid'] as String?,
        profesionalFirebaseUid: data['profesionalFirebaseUid'] as String?,
        lastReadCliente: (data['lastReadCliente'] as Timestamp?)?.toDate(),
        lastReadProfesional: (data['lastReadProfesional'] as Timestamp?)?.toDate(),
      );
    });
  }

  Future<void> enviarMensaje({
    required String serviceRequestId,
    required String texto,
    required String autorId,
  }) async {
    final mensaje = ChatMessage(texto: texto, autorId: autorId, enviadoEn: DateTime.now());
    await _mensajesRef(serviceRequestId).add(mensaje.toFirestore());

    // El chat vive 100% en Firestore (ver comentario de la clase) — el
    // backend nunca se entera por su cuenta de que se envió un mensaje,
    // así que sin este aviso nunca se disparaba una notificación push
    // por chat, aunque el resto del pipeline de FCM funcionara bien.
    // De verdad fire-and-forget (sin await): el mensaje ya quedó
    // guardado en Firestore arriba, y esperar aquí a que responda el
    // backend (que puede tardar si Render está "dormido") no debe
    // retrasar que enviarMensaje() dé por terminado el envío.
    unawaited(_notificarChat(serviceRequestId, texto));
  }

  Future<void> _notificarChat(String serviceRequestId, String texto) async {
    try {
      await ApiService.instance.client.post(
        '/service-requests/$serviceRequestId/notify-chat',
        data: {'texto': texto},
      );
    } catch (e) {
      debugPrint('[ChatService] No se pudo notificar el mensaje al backend: $e');
    }
  }
}
