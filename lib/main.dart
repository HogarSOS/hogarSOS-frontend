import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'app_keys.dart';
import 'l10n/app_localizations.dart';
import 'screens/auth_gate_screen.dart';
import 'services/deep_link_listener.dart';
import 'theme/app_theme.dart';

/// Clave PÚBLICA de Stripe (publishable key) — es seguro que viva en el
/// cliente, a diferencia de la clave secreta que solo usa el backend.
///
/// Un valor por defecto VACÍO fue lo que causó que "pagar" fallara en
/// silencio en builds donde alguien olvidó pasar el --dart-define (pasó
/// de verdad): la hoja de pago de Stripe nunca llega a abrirse y el
/// error cae en el catch genérico, no en StripeException, así que ni
/// siquiera se ve como un error "de Stripe". Por eso hay un valor por
/// defecto real, no vacío.
///
/// LANZAMIENTO (2026-08-04, auditoría B1): sustituida por la pk_live_...
/// real de la cuenta hogarSOS (acct_1TyVJ9CmpBOiu5cT), ya activada en
/// Stripe. La comprobación de `_claveDeTestEnRelease` de más abajo sigue
/// intacta como red de seguridad para el futuro: si alguna vez se vuelve
/// a poner aquí una pk_test por error, el build de release se niega a
/// arrancar en vez de fingir que cobra.
const String _clavePublicaStripe = String.fromEnvironment(
  'STRIPE_PUBLISHABLE_KEY',
  defaultValue: 'pk_live_51TyVJ9CmpBOiu5cTAMvO5TqICbrYVjLMAo6TNvc87oorXTfK4V61O9vBemaR0wphrwveALXS90Nz5Mwl7KmYYiEQ00OVDUyIth',
);

/// `kReleaseMode` es una constante de compilación, así que en una build
/// de debug esta rama se elimina entera del binario: durante el
/// desarrollo se sigue trabajando con la clave de test sin molestias.
bool get _claveDeTestEnRelease => kReleaseMode && _clavePublicaStripe.startsWith('pk_test');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Una build de release con clave de TEST no debe llegar a los usuarios:
  // el Payment Sheet se abriría con normalidad, el cliente vería "pago
  // correcto" y no se movería dinero real. Fallar de forma visible aquí
  // es infinitamente preferible a descubrirlo cuando un profesional
  // reclame su cobro. Ver validateEnv.ts para el equivalente del backend.
  if (_claveDeTestEnRelease) {
    runApp(const _PantallaClaveStripeInvalida());
    return;
  }

  Stripe.publishableKey = _clavePublicaStripe;

  runApp(const ProviderScope(child: HogarSOSApp()));
}

/// Pantalla de bloqueo deliberadamente fea y en texto plano: no está
/// pensada para un usuario final, sino para que quien compile la release
/// se dé cuenta en el primer arranque. Si esto se ve en un móvil real,
/// la build no debe publicarse.
class _PantallaClaveStripeInvalida extends StatelessWidget {
  const _PantallaClaveStripeInvalida();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF7F1D1D),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('⚠️', style: TextStyle(fontSize: 56)),
                SizedBox(height: 20),
                Text(
                  'Build de release con clave de Stripe de PRUEBAS',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 14),
                Text(
                  'Esta compilación no puede cobrar de verdad. Sustituye la clave por la pk_live en lib/main.dart '
                  '(o pasa --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_...) y vuelve a compilar.\n\n'
                  'NO publiques esta build.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HogarSOSApp extends StatelessWidget {
  const HogarSOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hogar SOS',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,

      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,

      // Español e inglés desde el inicio. Añadir un idioma nuevo en el
      // futuro es: 1) crear lib/l10n/app_XX.arb, 2) añadir Locale('XX')
      // aquí — flutter gen-l10n hace el resto automáticamente.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],

      // El enrutado real (según rol: cliente/profesional/admin) se
      // resuelve en AuthGateScreen: si ya hay sesión guardada, se
      // restaura sola sin pasar por el login. DeepLinkListener envuelve
      // el gate entero (no solo la pantalla profesional) porque el
      // deep link puede llegar con la app recién arrancada, antes de
      // que AuthGateScreen sepa todavía qué rol hay.
      home: const DeepLinkListener(child: AuthGateScreen()),
    );
  }
}