import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/utils/contact_filter.dart';

void main() {
  group('razonBloqueoMensaje', () {
    test('detecta un teléfono sin separadores', () {
      expect(razonBloqueoMensaje('llamame al 612345678'), 'telefono');
    });

    test('detecta un teléfono con espacios', () {
      expect(razonBloqueoMensaje('mi numero es 6 12 34 56 78'), 'telefono');
    });

    test('detecta un teléfono con prefijo internacional', () {
      expect(razonBloqueoMensaje('+34 612 345 678'), 'telefono');
    });

    test('detecta un email normal', () {
      expect(razonBloqueoMensaje('escribeme a pepe@gmail.com'), 'email');
    });

    test('detecta un email escrito en palabras', () {
      expect(razonBloqueoMensaje('soy pepe arroba gmail punto com'), 'email');
    });

    test('no bloquea un mensaje normal de disponibilidad', () {
      expect(razonBloqueoMensaje('Puedo ir mañana a las 10:00'), null);
    });

    test('no bloquea una descripción de trabajo con números sueltos', () {
      expect(razonBloqueoMensaje('Necesito cambiar 3 enchufes, son unos 45€'), null);
    });

    test('no bloquea una dirección con código postal', () {
      expect(razonBloqueoMensaje('Calle Mayor 45, 28013 Madrid'), null);
    });
  });
}
