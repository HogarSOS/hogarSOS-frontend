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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Clave PÚBLICA de Stripe (publishable key) — es seguro que viva en el
  // cliente, a diferencia de la clave secreta que solo usa el backend.
  // Un valor por defecto vacío aquí es lo que causó que "pagar" fallara
  // en silencio en builds donde alguien olvidó pasar el --dart-define
  // (pasó de verdad: un build de esta misma sesión salió sin ella) — la
  // hoja de pago de Stripe nunca llega a abrirse y el error cae en el
  // catch genérico, no en StripeException, así que ni siquiera se ve
  // como un error "de Stripe". Como esta clave NO es secreta (está
  // pensada para vivir en clientes), el valor por defecto real es más
  // seguro que uno vacío: sustituir con --dart-define solo hace falta
  // si se usa una cuenta de Stripe distinta (ej. producción real).
  Stripe.publishableKey = const String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_51TyVJ9CmpBOiu5cTfWAUXrfQYbKtJbb9h9VNnertUMJ4QEXLlMXwe23w5xrZVoEcDHkJVYzISKufifoxRtK4s4ES00AZ8WHSgW',
  );

  runApp(const ProviderScope(child: HogarSOSApp()));
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