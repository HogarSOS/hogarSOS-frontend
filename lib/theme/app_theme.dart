import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brand_colors.dart';

/// Identidad visual de hogarSOS — Sprint 1 de diseño.
///
/// El esquema de color parte de [ColorScheme.fromSeed] sembrado con el
/// azul de marca ([HogarSosColors.primary]) — así se mantienen
/// automáticamente correctas las ~30 combinaciones de contraste que
/// exige Material 3 (contenedores, "on" colors, superficies
/// elevadas...). El coral de marca ([HogarSosColors.accent]) se usa
/// deliberadamente FUERA del esquema generado, solo en los puntos de
/// marca que quieren llamar la atención (el punto del logo, la palabra
/// "SOS" del wordmark) — mezclarlo como color base habría diluido su
/// fuerza como acento.
///
/// La tipografía es Plus Jakarta Sans (vía `google_fonts`): geométrica,
/// cálida y muy legible en pantalla — transmite la "modernidad +
/// cercanía" que pide la marca sin perder seriedad.
class AppTheme {
  AppTheme._();

  /// Mantenido por compatibilidad con el resto del código que aún lo
  /// referencia como "el azul de marca" — usar [HogarSosColors.primary]
  /// en código nuevo.
  static const Color brandSeed = HogarSosColors.primary;

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: HogarSosColors.primary,
      brightness: Brightness.light,
    );

    return _base(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: HogarSosColors.primary,
      brightness: Brightness.dark,
    );

    return _base(colorScheme);
  }

  static TextTheme _textTheme(ColorScheme colorScheme) {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return base
        .apply(bodyColor: colorScheme.onSurface, displayColor: colorScheme.onSurface)
        .copyWith(
          headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1),
        );
  }

  static ThemeData _base(ColorScheme colorScheme) {
    final textTheme = _textTheme(colorScheme);
    final radiusM = BorderRadius.circular(16);
    final radiusL = BorderRadius.circular(20);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 20),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
          );
        }),
        height: 66,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: radiusM),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
        ).copyWith(
          // Sombra sutil teñida de marca en vez de la elevación gris
          // por defecto de Material — el botón principal se siente con
          // más "peso"/intención sin caer en un efecto skeuomórfico.
          shadowColor: WidgetStateProperty.all(colorScheme.primary.withOpacity(0.35)),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? 0 : 3,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: radiusM),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1.4),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          selectedForegroundColor: colorScheme.onPrimaryContainer,
          selectedBackgroundColor: colorScheme.primaryContainer,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.45),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: BorderSide(color: colorScheme.error, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radiusL,
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.35), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: textTheme.labelLarge?.copyWith(fontSize: 13, color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: colorScheme.shadow.withOpacity(0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 19),
        contentTextStyle: textTheme.bodyMedium,
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        iconColor: colorScheme.onSurfaceVariant,
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withOpacity(0.5),
        thickness: 1,
        space: 32,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colorScheme.primary.withOpacity(0.15),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        modalElevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
