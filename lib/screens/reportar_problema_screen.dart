import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../services/dispute_service.dart';
import '../utils/error_extraction.dart';

enum _EstadoFotoReclamacion { subiendo, lista, error }

class _FotoReclamacion {
  _FotoReclamacion(this.archivo);
  final File archivo;
  _EstadoFotoReclamacion estado = _EstadoFotoReclamacion.subiendo;
  String? url;
}

/// Pantalla compartida entre cliente y profesional — ambos pueden
/// reportar un problema sobre el mismo trabajo ya aceptado, por eso
/// vive en `screens/` a secas y no bajo `cliente/`/`profesional/`
/// (mismo motivo que `chat_screen.dart`).
class ReportarProblemaScreen extends StatefulWidget {
  const ReportarProblemaScreen({super.key, required this.serviceRequestId});

  final String serviceRequestId;

  @override
  State<ReportarProblemaScreen> createState() => _ReportarProblemaScreenState();
}

class _ReportarProblemaScreenState extends State<ReportarProblemaScreen> {
  final _servicio = DisputeService();
  final _descripcionController = TextEditingController();
  final List<_FotoReclamacion> _fotos = [];
  String _motivo = 'otro';
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _agregarFoto() async {
    if (_fotos.length >= 6) return;
    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
    if (imagen == null) return;

    final foto = _FotoReclamacion(File(imagen.path));
    setState(() => _fotos.add(foto));

    try {
      final url = await _servicio.subirFoto(foto.archivo);
      if (!mounted) return;
      setState(() {
        foto.estado = _EstadoFotoReclamacion.lista;
        foto.url = url;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => foto.estado = _EstadoFotoReclamacion.error);
    }
  }

  Future<void> _enviar() async {
    final t = AppLocalizations.of(context);
    if (_descripcionController.text.trim().length < 5) {
      setState(() => _error = t.reportarProblemaDescripcionHint);
      return;
    }
    if (_fotos.any((f) => f.estado == _EstadoFotoReclamacion.subiendo)) return;

    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final urls = _fotos.where((f) => f.url != null).map((f) => f.url!).toList();
      await _servicio.crearReclamacion(
        widget.serviceRequestId,
        motivo: _motivo,
        descripcion: _descripcionController.text.trim(),
        fotosUrls: urls,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.reportarProblemaExito)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = mensajeDeError(e, contexto: t.reportarProblemaError, t: t));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final motivos = <String, String>{
      'profesional_no_presento': t.reportarProblemaMotivoProfesionalNoPresento,
      'cliente_ausente': t.reportarProblemaMotivoClienteAusente,
      'trabajo_cancelado': t.reportarProblemaMotivoTrabajoCancelado,
      'problema_pago': t.reportarProblemaMotivoProblemaPago,
      'comportamiento_inapropiado': t.reportarProblemaMotivoComportamiento,
      'otro': t.reportarProblemaMotivoOtro,
    };

    return Scaffold(
      appBar: AppBar(title: Text(t.reportarProblemaTitulo)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(t.reportarProblemaMotivoLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _motivo,
            items: motivos.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (valor) => setState(() => _motivo = valor ?? 'otro'),
          ),
          const SizedBox(height: 20),
          Text(t.reportarProblemaDescripcionLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _descripcionController,
            maxLines: 5,
            minLines: 3,
            decoration: InputDecoration(hintText: t.reportarProblemaDescripcionHint),
          ),
          const SizedBox(height: 20),
          Text(t.reportarProblemaFotosLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ..._fotos.map((foto) => _MiniaturaFoto(foto: foto)),
              if (_fotos.length < 6)
                InkWell(
                  onTap: _agregarFoto,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add_a_photo_outlined, color: colorScheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _enviando ? null : _enviar,
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: _enviando
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(t.reportarProblemaEnviar),
          ),
        ],
      ),
    );
  }
}

class _MiniaturaFoto extends StatelessWidget {
  const _MiniaturaFoto({required this.foto});

  final _FotoReclamacion foto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(image: FileImage(foto.archivo), fit: BoxFit.cover),
      ),
      child: foto.estado == _EstadoFotoReclamacion.subiendo
          ? const Center(
              child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : foto.estado == _EstadoFotoReclamacion.error
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.error_outline, color: Colors.white),
                )
              : null,
    );
  }
}
