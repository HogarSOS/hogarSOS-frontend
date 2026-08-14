import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class ChatMessage {
  // El ID del documento de Firestore — desde la auditoría de duplicación
  // (2026-08-14), es el mismo valor que el "ID de intento" generado por
  // el cliente al componer el mensaje (ver ChatService.nuevoIdIntento):
  // permite reconciliar un mensaje optimista/pendiente con su versión
  // real en el stream sin ambigüedad. NO se serializa en toFirestore()
  // (es el identificador del documento, no un campo dentro de él).
  final String id;
  final String texto;
  final String autorId;
  final DateTime enviadoEn;

  ChatMessage({required this.id, required this.texto, required this.autorId, required this.enviadoEn});

  factory ChatMessage.fromFirestore(String id, Map<String, dynamic> data) {
    // 'enviadoEn' viene como null en la primera versión LOCAL del
    // documento (antes de que el servidor confirme el
    // FieldValue.serverTimestamp()) — esto pasa siempre para el propio
    // remitente justo al enviar. Sin este null-check, lanzaba una
    // excepción real ("null no es un Timestamp") cada vez que alguien
    // enviaba un mensaje.
    final timestamp = data['enviadoEn'] as Timestamp?;
    return ChatMessage(
      id: id,
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

/// Interfaz mínima de ChatService — existe SOLO para poder sustituirlo
/// por un fake en tests (ver chat_screen_duplicacion_test.dart) sin
/// construir nunca un ChatService real: su campo `_firestore` llama a
/// `FirebaseFirestore.instance` en el inicializador, que revienta sin
/// Firebase.initializeApp() aunque una subclase sobrescriba todos los
/// métodos (el inicializador de la superclase se ejecuta igual). Con
/// `implements` en vez de `extends`, el fake nunca construye la clase
/// real, así que ese campo nunca se evalúa.
abstract class ChatServiceBase {
  Stream<List<ChatMessage>> observarMensajes(String serviceRequestId);
  Stream<ChatMessage?> observarUltimoMensaje(String serviceRequestId);
  Stream<EstadoLecturaChat> observarEstadoLectura(String serviceRequestId);
  String nuevoIdIntento(String serviceRequestId);
  Future<void> enviarMensaje({
    required String serviceRequestId,
    required String intentoId,
    required String texto,
    required String autorId,
  });
}

/// Chat en tiempo real con Firestore, separado del backend Node.js a
/// propósito: Firestore ya resuelve la sincronización en tiempo real y
/// el modo offline sin que tengamos que montar websockets propios en
/// la API. Cada solicitud de servicio tiene su propia colección de
/// mensajes bajo /service_requests/{id}/messages.
class ChatService implements ChatServiceBase {
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

  @override
  Stream<List<ChatMessage>> observarMensajes(String serviceRequestId) {
    return _mensajesRef(serviceRequestId)
        .orderBy('enviadoEn', descending: true)
        .limit(_limiteMensajes)
        .snapshots()
        .map((snapshot) => snapshot.docs.reversed
            .map((doc) => ChatMessage.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Solo el último mensaje — usado para el indicador de "mensaje nuevo"
  /// en las listas de conversaciones (mensajes_screen.dart,
  /// trabajos_activos_profesional_screen.dart), donde suscribirse al
  /// historial completo de cada conversación sería mucho más caro que
  /// necesitar solo su último mensaje.
  @override
  Stream<ChatMessage?> observarUltimoMensaje(String serviceRequestId) {
    return _mensajesRef(serviceRequestId)
        .orderBy('enviadoEn', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isEmpty
            ? null
            : ChatMessage.fromFirestore(snapshot.docs.first.id, snapshot.docs.first.data()));
  }

  @override
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

  /// ID de un intento de envío NUEVO — se genera una vez por composición
  /// de mensaje (un tap en "Enviar"), ANTES de llamar a enviarMensaje(),
  /// para poder pintar el mensaje como "pendiente" con el mismo ID que
  /// tendrá el documento real. Reintentar el MISMO intento (p. ej. tras
  /// un fallo, o si la app se cerró antes de confirmar) debe reutilizar
  /// este mismo ID — nunca generar uno nuevo, o se perdería la
  /// idempotencia. Dos mensajes legítimos distintos (aunque el texto sea
  /// idéntico) SIEMPRE deben llamar a este método por separado, cada uno
  /// con su propio ID: la identidad es del intento, no del contenido.
  ///
  /// `.doc().id` genera el ID en el propio dispositivo (mismo algoritmo
  /// que usaba `.add()` antes) sin ningún viaje de red — funciona igual
  /// con o sin conexión.
  @override
  String nuevoIdIntento(String serviceRequestId) => _mensajesRef(serviceRequestId).doc().id;

  /// Envío idempotente: `intentoId` (ver nuevoIdIntento) fija el ID del
  /// documento en vez de dejar que Firestore genere uno nuevo en cada
  /// llamada (lo que hacía `.add()` antes) — así, si esta función se
  /// llama dos veces con el MISMO intentoId (un reintento tras perder la
  /// conexión, o tras cerrar y reabrir la app antes de confirmar), la
  /// segunda llamada nunca crea un segundo mensaje.
  ///
  /// firestore.rules bloquea a propósito CUALQUIER `update` sobre un
  /// mensaje ya creado (son inmutables) — no se abre una vía genérica de
  /// edición solo para permitir este reintento. En vez de eso: si el
  /// documento ya existe (el intento anterior sí llegó a escribirse en
  /// el servidor), Firestore rechaza este segundo `.set()` con
  /// `permission-denied` porque lo evalúa como `update`, no `create`. Se
  /// distingue de un problema de permisos REAL leyendo el documento
  /// (`allow read` sí está permitido a los participantes): si existe, es
  /// el reintento de un envío que ya tuvo éxito → se trata como éxito,
  /// SIN volver a avisar al backend (evita una notificación push
  /// duplicada por el mismo mensaje). Si no existe, el permission-denied
  /// era real (p. ej. ya no eres participante) y se propaga tal cual.
  @override
  Future<void> enviarMensaje({
    required String serviceRequestId,
    required String intentoId,
    required String texto,
    required String autorId,
  }) async {
    final mensaje = ChatMessage(id: intentoId, texto: texto, autorId: autorId, enviadoEn: DateTime.now());
    final ref = _mensajesRef(serviceRequestId).doc(intentoId);

    try {
      await ref.set(mensaje.toFirestore());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        final existente = await ref.get();
        if (existente.exists) {
          // Reintento de un intento que ya se envió con éxito antes —
          // ni el mensaje ni la notificación se repiten.
          return;
        }
      }
      rethrow;
    }

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
