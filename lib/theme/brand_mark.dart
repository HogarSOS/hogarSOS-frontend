import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brand_colors.dart';

/// Logo de hogarSOS — dibujado a mano con [CustomPainter] (sin
/// dependencias nuevas de renderizado de imágenes) para que quede
/// nítido a cualquier tamaño, desde el ícono de 20px de la barra de
/// navegación hasta la pantalla de login.
///
/// Concepto: una silueta de casa geométrica y redondeada (el "hogar" —
/// inmediatamente reconocible incluso a tamaño de icono de app) con un
/// punto de acento arriba a la derecha (la "señal" — ayuda solicitada y
/// localizada, el "SOS"). El tejado es deliberadamente más ancho que el
/// cuerpo (alero) — es lo que hace que la silueta se lea como "casa" y
/// no como un triángulo genérico incluso a 20-30px. Toda la geometría
/// vive en un lienzo lógico de 100x100 para que sea trivial mantenerla
/// en paridad con los SVG de `assets/branding/` (mismas proporciones,
/// para uso fuera de Flutter: ficha de la tienda de apps, materiales de
/// marketing).
///
/// Elegido tras comparar 4 propuestas (casa+alero, pin-casa, casa
/// esbelta tipo flecha, tejado+barra flotante) renderizadas a 512/96/32
/// px — esta es la única que seguía leyéndose sin ambigüedad como
/// "casa" en el tamaño más pequeño.
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

/// Construye un [Path] cerrado a partir de una lista de vértices,
/// redondeando cada esquina: en vez de un radio fijo (que exige que el
/// vértice sea realmente un arco de círculo), cada esquina se "corta" a
/// una distancia `radii[i]` a lo largo de sus dos aristas y se une con
/// una curva cuadrática usando el vértice original como punto de
/// control — funciona igual de bien en ángulos agudos (el pico del
/// tejado) que en obtusos, sin necesitar geometría de intersección de
/// arcos. `radii[i]` debe ser menor que la mitad de las dos aristas que
/// tocan ese vértice o las curvas vecinas se solapan.
Path _roundedPolygon(List<Offset> points, List<double> radii) {
  final path = Path();
  final n = points.length;

  Offset towards(Offset from, Offset to, double d) {
    final v = to - from;
    final len = v.distance;
    if (len <= 0) return from;
    return from + v * (d / len);
  }

  final firstOut = towards(points[0], points[1 % n], radii[0]);
  path.moveTo(firstOut.dx, firstOut.dy);
  for (int i = 1; i <= n; i++) {
    final cur = points[i % n];
    final prev = points[(i - 1) % n];
    final next = points[(i + 1) % n];
    final r = radii[i % n];
    final pIn = towards(cur, prev, r);
    final pOut = towards(cur, next, r);
    path.lineTo(pIn.dx, pIn.dy);
    path.quadraticBezierTo(cur.dx, cur.dy, pOut.dx, pOut.dy);
  }
  path.close();
  return path;
}

/// Dibuja el isotipo de hogarSOS en un lienzo lógico de 100x100 sobre
/// `canvas` ya escalado por quien llama. Función pública (no un método
/// de [CustomPainter]) a propósito: así una herramienta de generación
/// de assets (ver `tool/render_brand_assets.dart`) puede producir los
/// iconos reales de la app con paridad de píxel exacta con lo que
/// pinta el propio [HogarSosMark] en producción, sin duplicar la
/// geometría en dos sitios.
void paintHogarSosMark(Canvas canvas, HogarSosMarkVariant variant, {Color? monoColor}) {
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

  // Glifo "casa": tejado triangular (esquinas redondeadas mediante
  // _roundedPolygon) unido a un cuerpo con las esquinas inferiores
  // redondeadas — el tejado es más ancho que el cuerpo a propósito
  // (alero), que es la señal visual que hace leer "casa" en vez de
  // "triángulo" incluso a tamaños muy pequeños.
  final roofPoints = [
    const Offset(50, 20),
    const Offset(80, 52),
    const Offset(20, 52),
  ];
  final roofRadii = [10.0, 7.0, 7.0];
  final roof = _roundedPolygon(roofPoints, roofRadii);
  final body = Path()
    ..addRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(30, 52, 40, 28),
        bottomLeft: const Radius.circular(6),
        bottomRight: const Radius.circular(6),
      ),
    );
  final housePath = Path.combine(PathOperation.union, roof, body);
  canvas.drawPath(housePath, glyphPaint);

  // Punto de acento — la "señal" de ayuda localizada.
  canvas.drawCircle(const Offset(74, 28), 7, dotPaint);
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
    paintHogarSosMark(canvas, variant, monoColor: monoColor);
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
