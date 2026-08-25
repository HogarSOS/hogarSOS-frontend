import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/utils/imagen_autenticada.dart';

/// Reproduce el mecanismo EXACTO del bug de Crashlytics (auditoría 25/8,
/// issue `MultiImageStreamCompleter`/`ImageStreamCompleter.reportError`)
/// sin tocar red: `OneFrameImageStreamCompleter` reporta sus errores con
/// el mismo `ImageStreamCompleter.reportError` que usa
/// `CachedNetworkImageProvider` — así el test es fiel al fallo real
/// (ClientException al cargar `/uploads/<uuid>.jpg`) sin depender de
/// que un host concreto esté caído o accesible al ejecutar el test.
class _ImagenQueSiempreFalla extends ImageProvider<_ImagenQueSiempreFalla> {
  const _ImagenQueSiempreFalla();

  @override
  Future<_ImagenQueSiempreFalla> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_ImagenQueSiempreFalla>(this);

  @override
  ImageStreamCompleter loadImage(_ImagenQueSiempreFalla key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(
        Exception('ClientException with SocketException: Connection refused (simulado)'),
      ),
    );
  }
}

void main() {
  group('urlDeImagenValida', () {
    test('null → false', () {
      expect(urlDeImagenValida(null), isFalse);
    });

    test('cadena vacía → false', () {
      expect(urlDeImagenValida(''), isFalse);
    });

    test('solo espacios → false', () {
      expect(urlDeImagenValida('   '), isFalse);
    });

    test('URL con contenido → true (incluida una URL vieja/localhost: la validez de', () {
      // formato no es lo mismo que la validez de host — eso lo cubre el
      // backend (Fase 5), no el cliente.
      expect(urlDeImagenValida('https://hogarsos.es/uploads/x.jpg'), isTrue);
      expect(urlDeImagenValida('http://localhost:3000/uploads/x.jpg'), isTrue);
    });
  });

  group('onErrorImagenDeRed', () {
    test('no lanza excepción al invocarse (modo debug: no toca Crashlytics)', () {
      expect(() => onErrorImagenDeRed(Exception('fallo de prueba'), StackTrace.current), returnsNormally);
    });

    test('acepta stackTrace nulo (algunos callers de cached_network_image no lo dan)', () {
      expect(() => onErrorImagenDeRed(Exception('fallo de prueba'), null), returnsNormally);
    });
  });

  group('CircleAvatar.onBackgroundImageError — la protección real', () {
    testWidgets(
      'SIN onBackgroundImageError, un fallo de imagen se reporta a FlutterError.onError '
      '(este es el comportamiento roto: 9 eventos "Fatal" en Crashlytics build 43/44)',
      (tester) async {
        Object? errorCapturado;
        final onErrorOriginal = FlutterError.onError;
        FlutterError.onError = (details) => errorCapturado = details.exception;

        await tester.pumpWidget(
          const MaterialApp(
            home: Material(
              child: CircleAvatar(backgroundImage: _ImagenQueSiempreFalla()),
            ),
          ),
        );
        await tester.pump();

        FlutterError.onError = onErrorOriginal;
        expect(errorCapturado, isNotNull, reason: 'sin listener de error, Flutter cae en FlutterError.onError');
      },
    );

    testWidgets(
      'CON onBackgroundImageError: onErrorImagenDeRed, el fallo NO llega a FlutterError.onError '
      '(el fix: se entrega al callback, la app sigue funcionando, no se marca "Fatal")',
      (tester) async {
        Object? errorEnFlutterOnError;
        Object? errorEnCallback;
        final onErrorOriginal = FlutterError.onError;
        FlutterError.onError = (details) => errorEnFlutterOnError = details.exception;

        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: CircleAvatar(
                backgroundImage: const _ImagenQueSiempreFalla(),
                onBackgroundImageError: (error, stackTrace) {
                  errorEnCallback = error;
                  onErrorImagenDeRed(error, stackTrace);
                },
              ),
            ),
          ),
        );
        await tester.pump();

        FlutterError.onError = onErrorOriginal;
        expect(errorEnCallback, isNotNull, reason: 'el callback SÍ debe recibir el error (para poder registrarlo no-fatal)');
        expect(errorEnFlutterOnError, isNull, reason: 'con el callback puesto, NO debe caer en el handler global fatal');
      },
    );

    testWidgets(
      'la pantalla sigue construyéndose con normalidad tras el fallo — no deja un hueco '
      'roto ni tira la pantalla abajo',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundImage: const _ImagenQueSiempreFalla(),
                    onBackgroundImageError: onErrorImagenDeRed,
                    child: const Text('X'),
                  ),
                  const Text('Contenido después del avatar'),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Contenido después del avatar'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('un fallo de build NO relacionado con imágenes sigue siendo fatal', () {
    testWidgets(
      'un error normal de widget (no de imagen) sigue llegando a FlutterError.onError sin cambios — '
      'la protección es específica de imágenes, no un silenciador global',
      (tester) async {
        Object? errorCapturado;
        final onErrorOriginal = FlutterError.onError;
        FlutterError.onError = (details) => errorCapturado = details.exception;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => throw Exception('crash real de build, no relacionado con imágenes'),
            ),
          ),
        );
        await tester.pump();

        FlutterError.onError = onErrorOriginal;
        expect(errorCapturado, isNotNull, reason: 'un crash de framework real debe seguir siendo fatal');
      },
    );
  });

  group('limpiarCacheDeImagenes — logout entre cuentas (auditoría seguridad 25/8)', () {
    // `DefaultCacheManager` depende de `path_provider` (canal de
    // plataforma) para encontrar el directorio de caché — se mockea aquí
    // (sin ninguna dependencia nueva, solo flutter/services.dart) para
    // poder ejercitar el caso real de verdad, en vez de solo comprobar
    // que no lanza.
    late Directory dirTemporal;

    setUp(() async {
      dirTemporal = await Directory.systemTemp.createTemp('imagen_cache_test_');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall call) async {
          switch (call.method) {
            case 'getTemporaryDirectory':
            case 'getApplicationSupportDirectory':
            case 'getApplicationDocumentsDirectory':
              return dirTemporal.path;
            default:
              return null;
          }
        },
      );
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
      if (await dirTemporal.exists()) {
        await dirTemporal.delete(recursive: true);
      }
    });

    test(
      'cuenta A cachea una imagen → logout limpia la caché → cuenta B ya no la encuentra ahí',
      () async {
        const url = 'https://hogarsos.es/uploads/foto-de-A.jpg';
        final bytes = Uint8List.fromList(List.generate(64, (i) => i));

        // Cuenta A "ve" la imagen — cached_network_image la habría puesto
        // aquí tras la primera carga con éxito.
        await DefaultCacheManager().putFile(url, bytes, fileExtension: 'jpg');
        final antesDelLogout = await DefaultCacheManager().getFileFromCache(url);
        expect(antesDelLogout, isNotNull, reason: 'la imagen debe estar cacheada antes del logout');

        // Logout de A.
        await limpiarCacheDeImagenes();

        // Cuenta B entra al mismo dispositivo y llega a la misma URL (p.
        // ej. el mismo profesional público) — ya NO debe encontrarla en
        // caché, así que cached_network_image tendría que volver a
        // pedirla con la sesión (y cabecera de autorización) de B.
        final despuesDelLogout = await DefaultCacheManager().getFileFromCache(url);
        expect(despuesDelLogout, isNull, reason: 'cuenta B no debe poder reutilizar la imagen cacheada por A');
      },
    );

    test('no lanza si el cache manager no puede inicializarse (canal sin mockear)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
      await expectLater(limpiarCacheDeImagenes(), completes);
    });
  });
}
