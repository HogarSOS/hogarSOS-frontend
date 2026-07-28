import 'package:flutter/material.dart';

/// Envoltorio de animación de entrada reutilizable en toda la app:
/// fundido + desplazamiento suave hacia arriba, con retraso configurable.
/// Es el mismo lenguaje visual usado en HomeClienteScreen y en
/// ProfessionalCard — centralizado aquí para que las demás pantallas
/// del rediseño lo compartan sin duplicar la clase.
class EntradaAnimada extends StatefulWidget {
  const EntradaAnimada({super.key, required this.child, this.retraso = Duration.zero});

  final Widget child;
  final Duration retraso;

  @override
  State<EntradaAnimada> createState() => _EntradaAnimadaState();
}

class _EntradaAnimadaState extends State<EntradaAnimada> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacidad;
  late final Animation<Offset> _desplazamiento;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _opacidad = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _desplazamiento = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(widget.retraso, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacidad,
      child: SlideTransition(position: _desplazamiento, child: widget.child),
    );
  }
}
