import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_request_service.dart';
import '../../services/user_service.dart';
import '../../utils/error_extraction.dart';
import '../../utils/imagen_autenticada.dart';

/// Edición del perfil genérico (nombre, teléfono, foto) — antes solo
/// existía para el profesional (mi_perfil_profesional_screen.dart); el
/// cliente podía VER su nombre en Perfil pero no editar nada.
class EditarPerfilScreen extends ConsumerStatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  ConsumerState<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends ConsumerState<EditarPerfilScreen> {
  final _userService = UserService();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();

  String? _fotoPerfilUrlActual;
  File? _fotoLocalSeleccionada;
  bool _cargando = true;
  bool _guardando = false;
  bool _subiendoFoto = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final perfil = await _userService.obtenerMiPerfil();
      if (!mounted) return;
      setState(() {
        _nombreController.text = perfil.nombre;
        _telefonoController.text = perfil.telefono ?? '';
        _fotoPerfilUrlActual = perfil.fotoPerfilUrl;
        _cargando = false;
      });
    } catch (e) {
      debugPrint('[EditarPerfilScreen] Error al cargar el perfil: $e');
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  Future<void> _elegirFoto() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (imagen == null) return;

    setState(() {
      _fotoLocalSeleccionada = File(imagen.path);
      _subiendoFoto = true;
    });

    try {
      final url = await ServiceRequestService().subirFoto(_fotoLocalSeleccionada!, tipo: 'foto_perfil');
      if (!mounted) return;
      setState(() => _fotoPerfilUrlActual = url);
    } catch (e) {
      debugPrint('[EditarPerfilScreen] Error al subir la foto: $e');
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      setState(() => _fotoLocalSeleccionada = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.fotoErrorSubir)),
      );
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  Future<void> _guardar() async {
    final t = AppLocalizations.of(context);
    setState(() => _guardando = true);
    try {
      final actualizado = await _userService.actualizarPerfil(
        nombre: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        fotoPerfilUrl: _fotoPerfilUrlActual,
      );
      ref.read(authProvider.notifier).actualizarUsuario(actualizado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.miPerfilExito)),
      );
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('[EditarPerfilScreen] Error al guardar: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e, contexto: t.miPerfilErrorGuardar, t: t))),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.editarPerfilTitulo)),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage: _fotoLocalSeleccionada != null
                            ? FileImage(_fotoLocalSeleccionada!)
                            : (_fotoPerfilUrlActual != null
                                ? imagenDeRed(_fotoPerfilUrlActual!, maxWidth: 320, maxHeight: 320)
                                : null) as ImageProvider?,
                        child: (_fotoLocalSeleccionada == null && _fotoPerfilUrlActual == null)
                            ? Text(
                                _nombreController.text.isNotEmpty
                                    ? _nombreController.text[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                      if (_subiendoFoto)
                        Positioned.fill(
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.black45,
                            child: const CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: colorScheme.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _subiendoFoto ? null : _elegirFoto,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(Icons.camera_alt, size: 18, color: colorScheme.onPrimary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _nombreController,
                  decoration: InputDecoration(labelText: t.loginFieldNombre),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: t.editarPerfilTelefono),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(t.miPerfilGuardar),
                ),
              ],
            ),
    );
  }
}
