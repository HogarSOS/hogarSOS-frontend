import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../l10n/app_localizations.dart';
import '../../services/review_service.dart';
import '../../widgets/entrada_animada.dart';

class ValoracionScreen extends StatefulWidget {
  const ValoracionScreen({super.key, required this.serviceRequestId});

  final String serviceRequestId;

  @override
  State<ValoracionScreen> createState() => _ValoracionScreenState();
}

class _ValoracionScreenState extends State<ValoracionScreen> {
  final _reviewService = ReviewService();
  final _comentarioController = TextEditingController();
  int _puntuacion = 0;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final t = AppLocalizations.of(context);
    if (_puntuacion == 0) {
      setState(() => _error = t.valoracionErrorSeleccion);
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await _reviewService.valorar(
        serviceRequestId: widget.serviceRequestId,
        puntuacion: _puntuacion,
        comentario: _comentarioController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('[ValoracionScreen] Error al enviar la valoración: $e');
      setState(() => _error = t.valoracionErrorEnviar);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.valoracionTitulo)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EntradaAnimada(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final estrella = index + 1;
                  return IconButton(
                    iconSize: 42,
                    icon: Icon(
                      estrella <= _puntuacion ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber.shade700,
                    ),
                    onPressed: () => setState(() => _puntuacion = estrella),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            EntradaAnimada(
              retraso: const Duration(milliseconds: 80),
              child: TextField(
                controller: _comentarioController,
                maxLines: 3,
                decoration: InputDecoration(labelText: t.valoracionComentarioLabel),
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton(
              onPressed: _enviando ? null : _enviar,
              child: _enviando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.valoracionBtnEnviar),
            ),
          ],
        ),
      ),
    );
  }
}
