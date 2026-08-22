import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/l10n/app_localizations.dart';
import 'package:hogarsos/services/professional_service.dart';
import 'package:hogarsos/widgets/wizard_alta.dart';

/// Estados visibles del wizard "Completa tu alta" tras la reestructura
/// Perfil/Pagos (2026-08-22). Fija sobre todo la REGLA CRÍTICA F: si
/// Stripe deja de estar operativa DESPUÉS de la aprobación, el aviso
/// con acción debe reaparecer en Perfil — el profesional nunca puede
/// quedarse sin ruta para arreglar su cuenta de cobro.
void main() {
  Widget montar({
    bool fotoOk = true,
    bool categoriaOk = true,
    bool tipoOk = true,
    bool aprobado = false,
    DetalleCuentaStripe detalle = DetalleCuentaStripe.sinIniciar,
    bool disponible = false,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: WizardAlta(
            fotoOk: fotoOk,
            categoriaOk: categoriaOk,
            tipoOk: tipoOk,
            aprobado: aprobado,
            detalle: detalle,
            disponible: disponible,
            activando: false,
            onFoto: () {},
            onCategorias: () {},
            onTipo: () {},
            onStripe: () {},
            onActivarme: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('aprobado + Stripe configurada + disponible → el wizard desaparece por completo', (tester) async {
    await tester.pumpWidget(montar(
      aprobado: true,
      detalle: DetalleCuentaStripe.configurada,
      disponible: true,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Completa tu alta'), findsNothing);
    expect(find.textContaining('Activarme'), findsNothing);
  });

  testWidgets('aprobado + configurada pero fuera de línea → banner con "Activarme ahora"', (tester) async {
    await tester.pumpWidget(montar(
      aprobado: true,
      detalle: DetalleCuentaStripe.configurada,
      disponible: false,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Activarme ahora'), findsOneWidget);
    expect(find.text('Completa tu alta'), findsNothing);
  });

  testWidgets('REGLA F: aprobado pero Stripe deja de estar operativa → reaparece el aviso con acción', (tester) async {
    await tester.pumpWidget(montar(
      aprobado: true,
      detalle: DetalleCuentaStripe.accionNecesaria,
      disponible: true, // incluso estando disponible: el aviso manda
    ));
    await tester.pumpAndSettle();

    expect(find.text('Completa tu alta'), findsOneWidget);
    expect(find.textContaining('necesitan una actualización'), findsOneWidget);
    // Con botón: el profesional siempre tiene una ruta para arreglarlo.
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('profesional nuevo → wizard al 25% con los subpasos del perfil', (tester) async {
    await tester.pumpWidget(montar(fotoOk: false, categoriaOk: false, tipoOk: false));
    await tester.pumpAndSettle();

    expect(find.text('Completa tu alta'), findsOneWidget);
    expect(find.textContaining('25%'), findsOneWidget);
    expect(find.text('Añade tu foto'), findsOneWidget);
    expect(find.text('Elige una categoría'), findsOneWidget);
    expect(find.text('Indica cómo trabajas'), findsOneWidget);
  });

  testWidgets('Stripe verificando (pura espera) → CERRADO por defecto con resumen; al desplegar, mensaje sin botón', (tester) async {
    await tester.pumpWidget(montar(detalle: DetalleCuentaStripe.enVerificacion));
    await tester.pumpAndSettle();

    // Cerrado: % + barra + resumen; el detalle no está.
    expect(find.textContaining('75%'), findsOneWidget);
    expect(find.textContaining('pendiente'), findsOneWidget);
    expect(find.textContaining('verificando tu identidad'), findsNothing);

    // La cabecera entera es la zona táctil de despliegue.
    await tester.tap(find.text('Completa tu alta'));
    await tester.pumpAndSettle();

    expect(find.textContaining('verificando tu identidad'), findsOneWidget);
    expect(find.text('Continuar'), findsNothing);
  });

  testWidgets('perfil completo + Stripe sin iniciar → ABIERTO por defecto (hay acción), 50% y botón Continuar', (tester) async {
    await tester.pumpWidget(montar());
    await tester.pumpAndSettle();

    expect(find.textContaining('50%'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('abrir/cerrar no cambia el progreso y los subpasos vuelven intactos', (tester) async {
    await tester.pumpWidget(montar(fotoOk: false, categoriaOk: false, tipoOk: false));
    await tester.pumpAndSettle();

    expect(find.textContaining('25%'), findsOneWidget);
    expect(find.text('Añade tu foto'), findsOneWidget);

    // Cerrar: queda el resumen con el paso y el nº de subpasos.
    await tester.tap(find.text('Completa tu alta'));
    await tester.pumpAndSettle();
    expect(find.textContaining('25%'), findsOneWidget);
    expect(find.text('Añade tu foto'), findsNothing);
    expect(find.textContaining('3 pasos'), findsOneWidget);

    // Reabrir: todo vuelve tal cual.
    await tester.tap(find.text('Completa tu alta'));
    await tester.pumpAndSettle();
    expect(find.textContaining('25%'), findsOneWidget);
    expect(find.text('Añade tu foto'), findsOneWidget);
  });

  testWidgets('en atención (REGLA F) no hay chevron: no se puede plegar la advertencia', (tester) async {
    await tester.pumpWidget(montar(aprobado: true, detalle: DetalleCuentaStripe.accionNecesaria));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.expand_more), findsNothing);
    expect(find.byIcon(Icons.expand_less), findsNothing);
    // Tocar la cabecera no la cierra.
    await tester.tap(find.text('Completa tu alta'));
    await tester.pumpAndSettle();
    expect(find.textContaining('necesitan una actualización'), findsOneWidget);
  });
}
