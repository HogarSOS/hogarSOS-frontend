import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brand_colors.dart';

/// Logo de hogarSOS — dibujado a mano con [CustomPainter] (sin
/// dependencias nuevas de renderizado de imágenes) para que quede
/// nítido a cualquier tamaño, desde el ícono de 20px de la barra de
/// navegación hasta la pantalla de login.
///
/// Concepto: un arco de puerta (el "hogar" — acogedor, sencillo) con un
/// punto de acento arriba a la derecha (la "señal" — ayuda solicitada y
/// localizada, el "SOS"). Toda la geometría vive en un lienzo lógico de
/// 100x100 para que sea trivial mantenerla en paridad con los SVG de
/// `assets/branding/` (mismas proporciones, para uso fuera de Flutter:
/// ficha de la tienda de apps, materiales de marketing).
enum HogarSosMarkVariant {
  /// Cuadrado redondeado con degradado de marca + glifo blanco. Uso por
  /// defecto: login, splash, cualquier fondo neutro (claro u oscuro).
  brand,

  /// Sin fondo propio, glifo en blanco — para colocar directamente
  /// sobre una superficie ya oscura (p. ej. un AppBar de marca).
  onDark,

  /// Un solo color plano, sin fondo — para estampar sobre cualquier
  /// color (huella de marca a una tinta).
  mono,
}

class HogarSosMark extends StatelessWidget {
  const HogarSosMark({
    super.key,
    this.size = 48,
    this.variant = HogarSosMarkVariant.brand,
    this.monoColor,
    this.withShadow = false,
  });

  final double size;
  final HogarSosMarkVariant variant;

  /// Solo se usa con [HogarSosMarkVariant.mono] — por defecto
  /// [HogarSosColors.primary].
  final Color? monoColor;

  /// Sombra suave a juego con el radio del cuadrado — pensada para
  /// colocaciones "hero" grandes (login, splash), no para tamaños de
  /// icono pequeños donde una sombra solo ensucia.
  final bool withShadow;

  @override
  Widget build(BuildContext context) {
    final child = CustomPaint(
      size: Size.square(size),
      painter: _HogarSosMarkPainter(variant: variant, monoColor: monoColor),
    );

    if (!withShadow || variant == HogarSosMarkVariant.mono) return child;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: HogarSosColors.primary.withOpacity(0.28),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HogarSosMarkPainter extends CustomPainter {
  const _HogarSosMarkPainter({required this.variant, this.monoColor});

  final HogarSosMarkVariant variant;
  final Color? monoColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    canvas.save();
    canvas.scale(scale);

    final glyphPaint = Paint()..style = PaintingStyle.fill;
    final dotPaint = Paint()..style = PaintingStyle.fill;

    switch (variant) {
      case HogarSosMarkVariant.brand:
        final bgPaint = Paint()
          ..style = PaintingStyle.fill
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [HogarSosColors.primary, HogarSosColors.primaryDeep],
          ).createShader(const Rect.fromLTWH(0, 0, 100, 100));
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 100, 100), const Radius.circular(22)),
          bgPaint,
        );
        glyphPaint.color = Colors.white;
        dotPaint.color = HogarSosColors.accent;
        break;
      case HogarSosMarkVariant.onDark:
        glyphPaint.color = Colors.white;
        dotPaint.color = HogarSosColors.accent;
        break;
      case HogarSosMarkVariant.mono:
        final color = monoColor ?? HogarSosColors.primary;
        glyphPaint.color = color;
        dotPaint.color = color;
        break;
    }

    // Glifo "arco de puerta": un rectángulo con las esquinas inferiores
    // redondeadas, rematado por una cúpula semicircular — la mitad
    // inferior de esa cúpula ya cae dentro del ancho del rectángulo
    // (mismo radio que medio-ancho), así que unir el círculo completo
    // con el rectángulo basta, sin necesidad de recortar a mano un
    // semicírculo con arcos.
    final archRect = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          const Rect.fromLTWH(34, 50, 32, 24),
          bottomLeft: const Radius.circular(3),
          bottomRight: const Radius.circular(3),
        ),
      );
    final archDome = Path()..addOval(Rect.fromCircle(center: const Offset(50, 50), radius: 16));
    final archPath = Path.combine(PathOperation.union, archRect, archDome);
    canvas.drawPath(archPath, glyphPaint);

    // Punto de acento — la "señal" de ayuda localizada.
    canvas.drawCircle(const Offset(74, 28), 7.5, dotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HogarSosMarkPainter oldDelegate) =>
      oldDelegate.variant != variant || oldDelegate.monoColor != monoColor;
}

/// Wordmark tipográfico "hogarSOS" — "hogar" en el tono de texto normal
/// y "SOS" en coral de marca, misma familia y peso, solo un cambio de
/// color: la parte que de verdad importa recordar (que esto es ayuda a
/// domicilio) queda resaltada sin necesitar un icono aparte.
class HogarSosWordmark extends StatelessWidget {
  const HogarSosWordmark({super.key, this.fontSize = 26, this.color, this.accentColor});

  final double fontSize;
  final Color? color;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? Theme.of(context).colorScheme.onSurface;
    final style = GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1,
    );

    return RichText(
      text: TextSpan(
        style: style.copyWith(color: baseColor),
        children: [
          const TextSpan(text: 'hogar'),
          TextSpan(text: 'SOS', style: TextStyle(color: accentColor ?? HogarSosColors.accent)),
        ],
      ),
    );
  }
}

/// Lockup horizontal completo: marca + wordmark en fila — el logo
/// "principal" para la mayoría de contextos (login, cabeceras anchas).
class HogarSosLogo extends StatelessWidget {
  const HogarSosLogo({
    super.key,
    this.markSize = 44,
    this.fontSize = 24,
    this.variant = HogarSosMarkVariant.brand,
    this.textColor,
    this.gap = 12,
  });

  final double markSize;
  final double fontSize;
  final HogarSosMarkVariant variant;
  final Color? textColor;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HogarSosMark(size: markSize, variant: variant),
        SizedBox(width: gap),
        HogarSosWordmark(fontSize: fontSize, color: textColor),
      ],
    );
  }
}

/// Lockup vertical (marca arriba, wordmark debajo, centrados) — para
/// espacios estrechos y altos: splash screen, tarjetas de "acerca de".
class HogarSosLogoVertical extends StatelessWidget {
  const HogarSosLogoVertical({
    super.key,
    this.markSize = 88,
    this.fontSize = 28,
    this.variant = HogarSosMarkVariant.brand,
    this.textColor,
    this.gap = 20,
    this.withShadow = true,
  });

  final double markSize;
  final double fontSize;
  final HogarSosMarkVariant variant;
  final Color? textColor;
  final double gap;
  final bool withShadow;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HogarSosMark(size: markSize, variant: variant, withShadow: withShadow),
        SizedBox(height: gap),
        HogarSosWordmark(fontSize: fontSize, color: textColor),
      ],
    );
  }
}
