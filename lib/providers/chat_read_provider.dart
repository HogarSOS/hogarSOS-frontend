import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';

final chatServiceProvider = Provider<ChatServiceBase>((ref) => ChatService());

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
  // valueOrNull, no .value a propósito: si el stream de Firestore de
  // esta conversación falla (p. ej. PERMISSION_DENIED en un chat que
  // nunca llegó a sincronizarse, ver sincronizarChatFirestore), .value
  // RELANZA ese error en vez de devolver null — y como este provider se
  // usa dentro del propio ProfesionalShellScreen/ClienteShellScreen
  // para el punto rojo de la pestaña, ese error tumbaba el panel
  // entero, no solo el chat. Con valueOrNull, un chat roto simplemente
  // no cuenta como "no leído" en vez de romper toda la pantalla.
  final ultimo = ref.watch(_ultimoMensajeProvider(serviceRequestId)).valueOrNull;
  if (ultimo == null || ultimo.autorId == miUid) return false;

  final estado = ref.watch(estadoLecturaProvider(serviceRequestId)).valueOrNull;
  final miLastRead = estado?.miLastRead(miUid);
  if (miLastRead == null) return true;
  return ultimo.enviadoEn.isAfter(miLastRead);
});
