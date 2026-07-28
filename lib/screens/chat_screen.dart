import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../l10n/app_localizations.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.serviceRequestId,
    required this.usuarioActualId,
  });

  final String serviceRequestId;
  final String usuarioActualId; // para distinguir "mis mensajes" de los del otro

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _mensajeController = TextEditingController();

  @override
  void dispose() {
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    _mensajeController.clear();
    try {
      await _chatService.enviarMensaje(
        serviceRequestId: widget.serviceRequestId,
        texto: texto,
        autorId: widget.usuarioActualId,
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
                  return Center(
                    child: Text(t.chatSinMensajes, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: mensajes.length,
                  itemBuilder: (context, index) {
                    final mensaje = mensajes[index];
                    final esMio = mensaje.autorId == widget.usuarioActualId;
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
