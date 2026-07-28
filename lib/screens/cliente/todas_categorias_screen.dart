import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/service_category_model.dart';
import '../../providers/service_request_provider.dart';
import '../../utils/category_display.dart';
import '../../widgets/entrada_animada.dart';
import 'wizard/solicitar_wizard_screen.dart';

class TodasCategoriasScreen extends ConsumerWidget {
  const TodasCategoriasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final categoriasAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.todasCategoriasTitulo)),
      body: categoriasAsync.when(
        data: (categorias) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: categorias.length,
          itemBuilder: (context, index) {
            final categoria = categorias[index];
            return EntradaAnimada(
              retraso: Duration(milliseconds: 20 * index),
              child: _TarjetaCategoria(
                categoria: categoria,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SolicitarWizardScreen(categoriaInicial: categoria),
                  ),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(t.homeCategoriasError)),
      ),
    );
  }
}

class _TarjetaCategoria extends StatefulWidget {
  const _TarjetaCategoria({required this.categoria, required this.onTap});

  final ServiceCategory categoria;
  final VoidCallback onTap;

  @override
  State<_TarjetaCategoria> createState() => _TarjetaCategoriaState();
}

class _TarjetaCategoriaState extends State<_TarjetaCategoria> {
  bool _presionada = false;

  @override
  Widget build(BuildContext context) {
    final color = colorParaCategoria(widget.categoria.nombre);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _presionada = true),
      onTapUp: (_) => setState(() => _presionada = false),
      onTapCancel: () => setState(() => _presionada = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _presionada ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                  child: Icon(iconoParaCategoria(widget.categoria.nombre), size: 24, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  nombreLocalizadoCategoria(context, widget.categoria.nombre),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
