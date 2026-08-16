// Revisión arquitectónica 2026-08-16 — causa real del crash "Cannot use
// ref after the widget was disposed" que aparecía cada 10s en Release,
// en el sondeo de trabajos nuevos del profesional.
//
// Causa confirmada por trazado del código (no una suposición): al hacer
// login, DOS caminos independientes construían su propia instancia de
// ProfesionalShellScreen/ClienteShellScreen para el MISMO evento
// (authProvider pasando a tener usuario autenticado):
//   1. AuthGateScreen (raíz de la app) — reactivo, ref.watch(authProvider).
//   2. LoginScreen._enviar() / _enviarPorTelefono().onAutoVerificado /
//      VerificarCodigoScreen._confirmar() / _reenviar().onAutoVerificado
//      — imperativo, Navigator.pushReplacement/pushAndRemoveUntil.
// Mismo patrón duplicado en logout (4 sitios: eliminar_cuenta.dart,
// mi_perfil_profesional_screen.dart, cliente/perfil_screen.dart,
// admin_screen.dart) construyendo LoginScreen además de que
// AuthGateScreen ya vuelve a él solo al ver usuario == null.
//
// Antes esto era inofensivo (ninguna de las dos instancias hacía nada
// de larga duración al montar). El sondeo de assignedRequestsProvider +
// ref.listenManual añadido al shell esta misma sesión es lo que lo
// convirtió en un crash real y repetido: la instancia "perdedora" de la
// carrera quedaba con su Timer/listener vivo sobre un ref ya inválido.
//
// Fix: AuthGateScreen (vía construirPantallaSegunAuth, función pura
// extraída para poder probarla sin un authProvider real — su primer uso
// construye AuthNotifier, que en su constructor toca FirebaseAuth.instance,
// fuera del alcance de esta suite, ver deep_link_stripe_pendiente_test.dart)
// es ahora la ÚNICA fuente de verdad. LoginScreen/VerificarCodigoScreen ya
// no construyen ninguna de estas pantallas — VerificarCodigoScreen (que sí
// está empujada ENCIMA de la ruta base, a diferencia de LoginScreen) hace
// popUntil((route) => route.isFirst) en vez de empujar una pantalla nueva,
// ver test/verificar_codigo_pop_test.dart para ese mecanismo en concreto.
//
// Esta suite prueba dos cosas complementarias:
// A. La decisión pura de AuthGateScreen (construirPantallaSegunAuth) es
//    correcta para cada estado posible — sin BuildContext/ref/Firebase.
// B. Por inspección REAL del código fuente (no una afirmación en un
//    comentario): ninguna de las 4 pantallas destino se construye en
//    ningún archivo de lib/ salvo en auth_gate_screen.dart — la garantía
//    estructural de que no puede haber una segunda instancia compitiendo,
//    verificada de forma que un futuro PR que reintroduzca un
//    Navigator.push(...ShellScreen()) donde sea haga fallar el test.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/models/user_model.dart';
import 'package:hogarsos/providers/auth_provider.dart';
import 'package:hogarsos/screens/admin/admin_screen.dart';
import 'package:hogarsos/screens/auth/login_screen.dart';
import 'package:hogarsos/screens/auth_gate_screen.dart';
import 'package:hogarsos/screens/cliente_shell_screen.dart';
import 'package:hogarsos/screens/profesional_shell_screen.dart';
import 'package:hogarsos/screens/splash_screen.dart';

AppUser _usuario(UserRole role) {
  return AppUser(id: 'u1', nombre: 'Test', role: role, email: 'test@hogarsos.es');
}

void main() {
  group('construirPantallaSegunAuth (función pura de AuthGateScreen)', () {
    test('restaurando sesión → splash, sin importar el resto del estado', () {
      final widget = construirPantallaSegunAuth(
        const AuthState(restaurando: true),
      );
      expect(widget, isA<HogarSosSplashScreen>());
    });

    test('sin usuario, restaurando terminado → LoginScreen', () {
      final widget = construirPantallaSegunAuth(
        const AuthState(restaurando: false),
      );
      expect(widget, isA<LoginScreen>());
    });

    test('usuario profesional → ProfesionalShellScreen (exactamente ese tipo)', () {
      final widget = construirPantallaSegunAuth(
        AuthState(restaurando: false, usuario: _usuario(UserRole.profesional)),
      );
      expect(widget, isA<ProfesionalShellScreen>());
      expect(widget, isNot(isA<ClienteShellScreen>()));
      expect(widget, isNot(isA<AdminScreen>()));
    });

    test('usuario cliente → ClienteShellScreen (exactamente ese tipo)', () {
      final widget = construirPantallaSegunAuth(
        AuthState(restaurando: false, usuario: _usuario(UserRole.cliente)),
      );
      expect(widget, isA<ClienteShellScreen>());
      expect(widget, isNot(isA<ProfesionalShellScreen>()));
    });

    test('usuario admin → AdminScreen (exactamente ese tipo)', () {
      final widget = construirPantallaSegunAuth(
        AuthState(restaurando: false, usuario: _usuario(UserRole.admin)),
      );
      expect(widget, isA<AdminScreen>());
    });
  });

  group('fuente única de verdad — verificado contra el código fuente real de lib/', () {
    // Todas las rutas son relativas a la raíz del paquete (donde `flutter
    // test` se ejecuta), igual que pubspec.yaml.
    const rutaGate = 'lib/screens/auth_gate_screen.dart';

    Iterable<File> archivosDart() sync* {
      final dir = Directory('lib');
      for (final entidad in dir.listSync(recursive: true)) {
        if (entidad is File && entidad.path.endsWith('.dart')) yield entidad;
      }
    }

    /// Todas las líneas de todo lib/ que contienen `patron(` (construcción
    /// real, no la declaración de la propia clase) — excluyendo el o los
    /// archivo(s) donde vive la declaración de la clase, que
    /// inevitablemente contienen su propio constructor
    /// (`const NombreClase({...})`), indistinguible de una invocación por
    /// simple búsqueda de texto.
    List<String> archivosQueConstruyen(String patron, Set<String> archivosDeclaracion) {
      final encontrados = <String>[];
      for (final archivo in archivosDart()) {
        final rutaNormalizada = archivo.path.replaceAll('\\', '/');
        if (archivosDeclaracion.any((decl) => rutaNormalizada.endsWith(decl))) continue;
        final contenido = archivo.readAsStringSync();
        if (contenido.contains('$patron(')) encontrados.add(rutaNormalizada);
      }
      return encontrados;
    }

    test('ProfesionalShellScreen solo se construye en auth_gate_screen.dart', () {
      final sitios = archivosQueConstruyen(
        'ProfesionalShellScreen',
        {'lib/screens/profesional_shell_screen.dart'},
      );
      expect(sitios, everyElement(endsWith(rutaGate)),
          reason: 'ProfesionalShellScreen se está construyendo fuera de AuthGateScreen en: $sitios');
      expect(sitios, isNotEmpty, reason: 'sanity check: el propio auth_gate_screen.dart debe aparecer');
    });

    test('ClienteShellScreen solo se construye en auth_gate_screen.dart', () {
      final sitios = archivosQueConstruyen(
        'ClienteShellScreen',
        {'lib/screens/cliente_shell_screen.dart'},
      );
      expect(sitios, everyElement(endsWith(rutaGate)),
          reason: 'ClienteShellScreen se está construyendo fuera de AuthGateScreen en: $sitios');
      expect(sitios, isNotEmpty);
    });

    test('AdminScreen (como destino de autenticación) solo se construye en auth_gate_screen.dart', () {
      final sitios = archivosQueConstruyen(
        'AdminScreen',
        {'lib/screens/admin/admin_screen.dart'},
      );
      expect(sitios, everyElement(endsWith(rutaGate)),
          reason: 'AdminScreen se está construyendo fuera de AuthGateScreen en: $sitios');
      expect(sitios, isNotEmpty);
    });

    test('LoginScreen solo se construye en auth_gate_screen.dart (logout no navega por su cuenta)', () {
      final sitios = archivosQueConstruyen(
        'LoginScreen',
        {'lib/screens/auth/login_screen.dart'},
      );
      expect(sitios, everyElement(endsWith(rutaGate)),
          reason: 'LoginScreen se está construyendo fuera de AuthGateScreen en: $sitios');
      expect(sitios, isNotEmpty);
    });

    test('VerificarCodigoScreen y LoginScreen ya no importan ninguna pantalla de Shell', () {
      // Si algún día alguien reintroduce la navegación imperativa, el
      // import volvería primero — se comprueba aparte del test de
      // construcción para dar un fallo más claro sobre CUÁL de las dos
      // cosas (import sin uso vs. construcción real) se reintrodujo.
      for (final ruta in [
        'lib/screens/auth/login_screen.dart',
        'lib/screens/auth/verificar_codigo_screen.dart',
      ]) {
        final contenido = File(ruta).readAsStringSync();
        expect(contenido.contains("profesional_shell_screen.dart'"), isFalse, reason: '$ruta no debería importar ProfesionalShellScreen');
        expect(contenido.contains("cliente_shell_screen.dart'"), isFalse, reason: '$ruta no debería importar ClienteShellScreen');
        expect(contenido.contains("admin/admin_screen.dart'"), isFalse, reason: '$ruta no debería importar AdminScreen');
      }
    });
  });
}
