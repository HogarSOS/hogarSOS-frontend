import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';

final chatServiceProvider = Provider((ref) => ChatService());

final _ultimoMensajeProvider = StreamProvider.autoDispose.family<ChatMessage?, String>((ref, serviceRequestId) {
  final servicio = ref.watch(chatServiceProvider);
  return servicio.observarUltimoMensaje(serviceRequestId);
});

/// Estado de lectura (Firestore, sincronizado vía backend — ver
/// mark-chat-read) de una conversación. Público porque chat_screen.dart
/// también lo usa para pintar los checks de "leído" por mensaje, no solo
/// para el indicador de "mensaje nuevo" de las listas.
final estadoLecturaProvider = StreamProvider.autoDispose.family<EstadoLecturaChat, String>((ref, serviceRequestId) {
  final servicio = ref.watch(chatServiceProvider);
  return servicio.observarEstadoLectura(serviceRequestId);
});

/// true si el último mensaje de esta conversación es de la otra persona
/// y todavía no está cubierto por mi propio "leído hasta" en Firestore.
/// Combina dos streams ya vivos (último mensaje + estado de lectura) en
/// vez de mantener su propio estado — se recalcula solo cuando
/// cualquiera de los dos cambia.
final unreadChatProvider = Provider.autoDispose.family<bool, String>((ref, serviceRequestId) {
  final miUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final ultimo = ref.watch(_ultimoMensajeProvider(serviceRequestId)).value;
  if (ultimo == null || ultimo.autorId == miUid) return false;

  final estado = ref.watch(estadoLecturaProvider(serviceRequestId)).value;
  final miLastRead = estado?.miLastRead(miUid);
  if (miLastRead == null) return true;
  return ultimo.enviadoEn.isAfter(miLastRead);
});
