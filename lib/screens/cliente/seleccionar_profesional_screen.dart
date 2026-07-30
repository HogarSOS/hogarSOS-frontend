import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/postulacion_model.dart';
import '../../services/service_request_service.dart';
import '../../utils/error_extraction.dart';
import '../../widgets/entrada_animada.dart';
import 'widgets/postulacion_card.dart';

/// Lista de profesionales postulados a una solicitud, para que el
/// cliente elija — sustituye al antiguo "el primero que acepta gana".
/// El orden lo decide el backend (aleatorio en cada carga, ver
/// listPostulaciones), a propósito no se reordena aquí.
class SeleccionarProfesionalScreen extends StatefulWidget {
  const SeleccionarProfesionalScreen({super.key, required this.serviceRequestId});

  final String serviceRequestId;

  @override
  State<SeleccionarProfesionalScreen> createState() => _SeleccionarProfesionalScreenState();
}

class _SeleccionarProfesionalScreenState extends State<SeleccionarProfesionalScreen> {
  final _servicio = ServiceRequestService();
  late Future<List<PostulacionCandidate>> _futuro;
  bool _eligiendo = false;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.listarPostulaciones(widget.serviceRequestId);
  }

  Future<void> _elegir(PostulacionCandidate candidato) async {
    final t = AppLocalizations.of(context);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.seleccionarProfesionalConfirmarTitulo),
        content: Text(t.seleccionarProfesionalConfirmarTexto(candidato.nombre)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.perfilCancelar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.seleccionarProfesionalElegir),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _eligiendo = true);
    try {
      await _servicio.seleccionarProfesional(widget.serviceRequestId, candidato.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.seleccionarProfesionalError, t: t))),
      );
      setState(() {
        _eligiendo = false;
        _futuro = _servicio.listarPostulaciones(widget.serviceRequestId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.seleccionarProfesionalTitulo)),
      body: AbsorbPointer(
        absorbing: _eligiendo,
        child: FutureBuilder<List<PostulacionCandidate>>(
          future: _futuro,
          builder: (context, snapshot) {
            if (!snapshot.hasData && !snapshot.hasError) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(t.seleccionarProfesionalError));
            }
            final candidatos = snapshot.data!;
            if (candidatos.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(t.seleccionarProfesionalVacio, textAlign: TextAlign.center),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: candidatos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final candidato = candidatos[index];
                return EntradaAnimada(
                  retraso: Duration(milliseconds: 40 * index),
                  child: PostulacionCard(candidato: candidato, onElegir: () => _elegir(candidato)),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
