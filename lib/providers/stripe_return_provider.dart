import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Se incrementa cada vez que la app recibe el deep link de retorno del
/// onboarding de Stripe Connect (`hogarsos://stripe-return/...`, ver
/// deep_link_listener.dart). Pantallas con estado propio que no pueden
/// refrescarse invalidando un provider (ej. CentroPagosScreen, que pide
/// su resumen con estado local) escuchan este contador con `ref.listen`
/// y relanzan su propia carga cuando cambia.
final stripeReturnEventProvider = StateProvider<int>((ref) => 0);
