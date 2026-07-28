import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/professional_summary_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/lista_opiniones.dart';

/// Valoraciones que ha recibido el cliente autenticado, de parte de
/// los profesionales que le han atendido — antes esto no existía en
/// ningún sitio: el cliente podía valorar, pero nunca ver si a ÉL lo
/// habían valorado.
class MisValoracionesScreen extends ConsumerStatefulWidget {
  const MisValoracionesScreen({super.key});

  @override
  ConsumerState<MisValoracionesScreen> createState() => _MisValoracionesScreenState();
}

class _MisValoracionesScreenState extends ConsumerState<MisValoracionesScreen> {
  final _userService = UserService();
  late Future<(AppUser, List<ProfessionalReview>)> _futuro;

  @override
  void initState() {
    super.initState();
    // El AppUser en authProvider viene tal cual de login/registro
    // ({id, nombre, role} — ver user_model.dart) y puede no traer la
    // valoración actualizada, así que aquí se recarga fresco en vez de
    // fiarse del estado global.
    _futuro = _cargar();
  }

  Future<(AppUser, List<ProfessionalReview>)> _cargar() async {
    final resultados = await Future.wait([
      _userService.obtenerMiPerfil(),
      _userService.obtenerMisValoraciones(),
    ]);
    final usuario = resultados[0] as AppUser;
    ref.read(authProvider.notifier).actualizarUsuario(usuario);
    return (usuario, resultados[1] as List<ProfessionalReview>);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.misValoracionesTitulo)),
      body: FutureBuilder<(AppUser, List<ProfessionalReview>)>(
        future: _futuro,
        builder: (context, snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(t.trabajosActivosErrorCargar));
          }
          final (usuario, opiniones) = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ResumenYListaOpiniones(
                valoracionMedia: usuario.valoracionMedia,
                totalValoraciones: usuario.totalValoraciones,
                opiniones: opiniones,
              ),
            ],
          );
        },
      ),
    );
  }
}
