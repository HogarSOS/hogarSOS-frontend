import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'l10n/app_localizations.dart';
import 'screens/auth_gate_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Clave PÚBLICA de Stripe (publishable key) — es seguro que viva en el
  // cliente, a diferencia de la clave secreta que solo usa el backend.
  Stripe.publishableKey = const String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '', // TODO: pasar con --dart-define=STRIPE_PUBLISHABLE_KEY=pk_...
  );

  runApp(const ProviderScope(child: HogarSOSApp()));
}

class HogarSOSApp extends StatelessWidget {
  const HogarSOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'hogarSOS',
      debugShowCheckedModeBanner: false,

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
      // restaura sola sin pasar por el login.
      home: const AuthGateScreen(),
    );
  }
}