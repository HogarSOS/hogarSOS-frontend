import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../providers/chat_read_provider.dart';
import '../services/chat_service.dart';
import '../services/service_request_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.serviceRequestId,
    this.nombreContraparte,
  });

  final String serviceRequestId;

  /// Nombre de con quién se está hablando (el otro cliente/profesional
  /// de esta solicitud) — antes el AppBar solo mostraba el título
  /// genérico "Chat" sin decir con quién, en las tres pantallas que
  /// abren ChatScreen. Opcional: si no se pasa (o el backend no lo
  /// devolvió todavía, p. ej. una solicitud sin profesional asignado),
  /// cae al título genérico en vez de mostrar un hueco en blanco.
  final String? nombreContraparte;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _chatService = ChatService();
  final _mensajeController = TextEditingController();
  final _scrollController = ScrollController();
  final _campoFocusNode = FocusNode();

  // El "autor" del mensaje SIEMPRE debe ser el UID de Firebase Auth, no
  // el id de Postgres (AppUser.id) — es el único identificador que
  // firestore.rules conoce (clienteFirebaseUid/profesionalFirebaseUid),
  // y usar el otro dejaba el chat con una identidad de autor que nadie
  // podía validar y que se rompería en cuanto las reglas exigieran
  // request.resource.data.autorId == request.auth.uid.
  String get _miUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // Cuenta de mensajes del build anterior — permite distinguir "llegó un
  // mensaje nuevo" (hay que bajar el scroll) de un rebuild cualquiera del
  // StreamBuilder que no cambia el contenido (no hay que tocar el scroll).
  int _mensajesPrevios = 0;

  // La sincronización a Firestore de acceptServiceRequest puede haber
  // fallado en silencio del lado del backend (ver
  // serviceRequest.controller.ts::sincronizarChatFirestore) — sin
  // reintentarla aquí, esa solicitud se queda con el chat roto para
  // siempre, con un PERMISSION_DENIED en cuanto se intenta leer o
  // escribir. Se espera a que termine (con éxito o no) ANTES de
  // suscribirse a observarMensajes: un listener de Firestore que ya
  // recibió un permission-denied no se reintenta solo aunque los
  // permisos cambien después.
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    // Si el teclado tapa el último mensaje al enfocar el campo de texto,
    // bajamos el scroll para que quede visible.
    _campoFocusNode.addListener(() {
      if (_campoFocusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollAlFinal());
      }
    });
    _prepararChat();
  }

  Future<void> _prepararChat() async {
    try {
      // Timeout corto a propósito: esta llamada es una red de
      // seguridad para el caso raro de un chat que quedó sin
      // sincronizar (ver el comentario de más arriba), no algo que
      // deba bloquear abrir un chat que ya funciona bien — sin este
      // límite, un backend "dormido" (plan gratuito de Render, cold
      // start de hasta ~50s) dejaba CUALQUIER chat tardando ese mismo
      // tiempo en mostrar el primer mensaje, aunque no hiciera falta
      // ninguna reparación. Si se agota el timeout, se sigue
      // igualmente (la sincronización real sigue en marcha en el
      // backend en segundo plano) — mismo comportamiento que cualquier
      // otro fallo de esta llamada, ya tolerado más abajo.
      await ServiceRequestService()
          .sincronizarChat(widget.serviceRequestId)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[ChatScreen] No se pudo sincronizar el chat, se intenta igualmente: $e');
    }
    // Marca la conversación como leída ya al entrar (no solo al salir) —
    // así si alguien abre el chat, mira brevemente y sale sin llegar a
    // mandar mensaje, igual queda como "leído" en vez de seguir marcando
    // "nuevo" en la lista de conversaciones.
    unawaited(ServiceRequestService().marcarChatLeido(widget.serviceRequestId));
    if (!mounted) return;
    setState(() => _listo = true);
  }

  @override
  void dispose() {
    // Vuelve a marcar como leído al salir: cubre los mensajes que
    // hayan llegado mientras la pantalla estaba abierta (la primera
    // marca, en _prepararChat, solo cubre el momento de entrar). No
    // hace falta invalidar ningún provider a mano: el estado de lectura
    // vive en Firestore (ver chat_read_provider.dart), así que en
    // cuanto este POST escribe el campo, el stream ya activo en la
    // lista de conversaciones/badge se actualiza solo.
    unawaited(ServiceRequestService().marcarChatLeido(widget.serviceRequestId));
    _mensajeController.dispose();
    _scrollController.dispose();
    _campoFocusNode.dispose();
    super.dispose();
  }

  void _scrollAlFinal({bool animado = true}) {
    if (!_scrollController.hasClients) return;
    final destino = _scrollController.position.maxScrollExtent;
    if (animado) {
      _scrollController.animateTo(
        destino,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(destino);
    }
  }

  /// Decide si hay que bajar el scroll al llegar mensajes nuevos: siempre
  /// en la carga inicial, siempre si el mensaje nuevo es propio (lo acabo
  /// de enviar yo), y si no, solo cuando ya estaba viendo el final de la
  /// conversación — así no se interrumpe a quien subió a leer mensajes
  /// antiguos cada vez que llega un mensaje nuevo.
  void _procesarMensajesActualizados(List<ChatMessage> mensajes) {
    if (mensajes.length <= _mensajesPrevios) {
      _mensajesPrevios = mensajes.length;
      return;
    }

    final esPrimeraCarga = _mensajesPrevios == 0;
    final ultimoEsMio = mensajes.last.autorId == _miUid;
    final estabaAlFinal = !_scrollController.hasClients ||
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 80;
    _mensajesPrevios = mensajes.length;

    if (esPrimeraCarga || ultimoEsMio || estabaAlFinal) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollAlFinal(animado: !esPrimeraCarga),
      );
    }
  }

  Future<void> _enviar() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    _mensajeController.clear();
    try {
      await _chatService.enviarMensaje(
        serviceRequestId: widget.serviceRequestId,
        texto: texto,
        autorId: _miUid,
      );
    } catch (e) {
      debugPrint('[ChatScreen] Error al enviar mensaje: $e');
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.chatErrorEnviar)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    // Hasta cuándo ha leído la OTRA persona — para pintar ✓ (enviado) o
    // ✓✓ (leído) en mis propios mensajes. Mientras no hay dato todavía
    // (primer frame, antes de que llegue el primer snapshot del
    // documento), se trata como "nadie ha leído nada aún" — un mensaje
    // recién enviado empieza en ✓, no en ✓✓, que es el estado correcto.
    final otroLastRead =
        ref.watch(estadoLecturaProvider(widget.serviceRequestId)).value?.otroLastRead(_miUid);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombreContraparte?.isNotEmpty == true ? widget.nombreContraparte! : t.chatTitulo),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              // stream: null mientras _prepararChat() no ha terminado —
              // StreamBuilder se queda en la rama "sin datos todavía"
              // (el mismo spinner que ya mostraba mientras cargaban los
              // primeros mensajes), sin suscribirse todavía a Firestore.
              stream: _listo ? _chatService.observarMensajes(widget.serviceRequestId) : null,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('[ChatScreen] Error en el stream de mensajes: ${snapshot.error}');
                  return Center(child: Text(t.chatErrorCargar));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final mensajes = snapshot.data!;
                if (mensajes.isEmpty) {
                  _mensajesPrevios = 0;
                  return Center(
                    child: Text(t.chatSinMensajes, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  );
                }
                _procesarMensajesActualizados(mensajes);
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: mensajes.length,
                  itemBuilder: (context, index) {
                    final mensaje = mensajes[index];
                    final esMio = mensaje.autorId == _miUid;
                    // Leído por la otra persona: solo tiene sentido para
                    // mis propios mensajes (nunca pinto un check en los
                    // mensajes ajenos, como en cualquier app de chat).
                    final leido = esMio && otroLastRead != null && !mensaje.enviadoEn.isAfter(otroLastRead);
                    return Align(
                      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          // Un color para "lo mío", otro claramente
                          // distinto para "lo del otro" — antes la
                          // burbuja ajena usaba un gris neutro sin
                          // identidad propia, ahora un segundo color de
                          // marca en vez de un simple "no-color".
                          color: esMio ? colorScheme.primary : colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(esMio ? 18 : 4),
                            bottomRight: Radius.circular(esMio ? 4 : 18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              mensaje.texto,
                              style: TextStyle(
                                color: esMio ? colorScheme.onPrimary : colorScheme.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('HH:mm').format(mensaje.enviadoEn),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: (esMio ? colorScheme.onPrimary : colorScheme.onSecondaryContainer)
                                        .withOpacity(0.75),
                                  ),
                                ),
                                if (esMio) ...[
                                  const SizedBox(width: 3),
                                  Icon(
                                    leido ? Icons.done_all : Icons.done,
                                    size: 14,
                                    color: leido
                                        ? colorScheme.onPrimary
                                        : colorScheme.onPrimary.withOpacity(0.75),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mensajeController,
                      focusNode: _campoFocusNode,
                      decoration: InputDecoration(hintText: t.chatHint),
                      onSubmitted: (_) => _enviar(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _enviar,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
