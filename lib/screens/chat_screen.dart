import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.serviceRequestId,
  });

  final String serviceRequestId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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
  }

  @override
  void dispose() {
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

    return Scaffold(
      appBar: AppBar(title: Text(t.chatTitulo)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.observarMensajes(widget.serviceRequestId),
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
                    return Align(
                      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: esMio ? colorScheme.primary : colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(esMio ? 18 : 4),
                            bottomRight: Radius.circular(esMio ? 4 : 18),
                          ),
                        ),
                        child: Text(
                          mensaje.texto,
                          style: TextStyle(color: esMio ? colorScheme.onPrimary : colorScheme.onSurface),
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
