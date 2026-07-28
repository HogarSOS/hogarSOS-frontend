import 'package:flutter/material.dart';
import '../theme/brand_mark.dart';

/// Pantalla de carga de marca — sustituye el spinner genérico que se
/// veía mientras AuthGateScreen restaura la sesión guardada. Ese hueco
/// dura poco (una comprobación local y, como mucho, un refresco de
/// token) pero es la primera imagen que ve cualquier usuario al abrir
/// la app, así que vale la pena que lleve la marca en vez de un
/// círculo girando sobre fondo en blanco.
class HogarSosSplashScreen extends StatefulWidget {
  const HogarSosSplashScreen({super.key});

  @override
  State<HogarSosSplashScreen> createState() => _HogarSosSplashScreenState();
}

class _HogarSosSplashScreenState extends State<HogarSosSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<double> _scale = Tween(begin: 0.86, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: const HogarSosLogoVertical(markSize: 96, fontSize: 32),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                width: 40,
                height: 3,
                child: LinearProgressIndicator(
                  backgroundColor: colorScheme.primary.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
