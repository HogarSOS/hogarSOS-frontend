// Cobertura de la feature "Iniciar trabajo" / "En curso".
//
// Las 5 condiciones reales (mostrar "Iniciar trabajo", "Deshacer
// inicio", el chip "En curso", ocultar "Cancelar solicitud" y mostrar
// "Reportar un problema") viven dentro de widgets PRIVADOS
// (_TarjetaTrabajo, _EstadoBanner, _ChipEstado) — la privacidad de Dart
// es por archivo, así que no se pueden importar ni testear directamente
// desde aquí sin hacerlas públicas (cambio de diseño no pedido) o sin
// montar la pantalla pública real con ProviderScope + mocks de
// ServiceRequestService/Dio + delegates de localización, infraestructura
// que este proyecto no tiene hoy (0 usos de ProviderScope en test/, y el
// único pumpWidget existente —widget_test.dart— evita expresamente
// Riverpod/Firebase).
//
// Todas esas 5 condiciones dependen, en el fondo, de una sola cosa: que
// `estado: "en_progreso"` se reconozca correctamente como
// `EstadoSolicitud.en_progreso` al venir del backend. Si eso se rompe
// (typo, reordenar el enum, cambiar el nombre del valor...), las 5
// condiciones fallan a la vez en silencio. Este test protege
// exactamente ese punto — no es un sustituto de un test de widget real,
// es la cobertura mínima razonable sin inventar arquitectura nueva.

import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/models/service_request_model.dart';
import 'package:hogarsos/models/presupuesto_model.dart';

void main() {
  group('EstadoSolicitud.en_progreso', () {
    test('estadoFromString reconoce "en_progreso"', () {
      expect(estadoFromString('en_progreso'), EstadoSolicitud.en_progreso);
    });

    test('el nombre del enum sigue siendo exactamente "en_progreso" (el backend lo manda literal)', () {
      expect(EstadoSolicitud.en_progreso.name, 'en_progreso');
    });

    test('un valor desconocido no cae por error en en_progreso (cae en pendiente, el valor por defecto)', () {
      expect(estadoFromString('algo_que_no_existe'), EstadoSolicitud.pendiente);
    });
  });

  group('AssignedRequest.fromJson con estado "en_progreso"', () {
    Map<String, dynamic> jsonBase({required String estado, Map<String, dynamic>? presupuesto}) => {
          'id': 'sr-1',
          'categoria': 'Fontanero',
          'descripcion': 'Fuga en el baño',
          'estado': estado,
          'clienteNombre': 'Ana',
          'createdAt': '2026-08-13T10:00:00.000Z',
          'tienePago': true,
          'tieneValoracion': false,
          if (presupuesto != null) 'presupuesto': presupuesto,
        };

    test('un trabajo "en_progreso" se parsea con ese estado exacto', () {
      final trabajo = AssignedRequest.fromJson(jsonBase(estado: 'en_progreso'));
      expect(trabajo.estado, EstadoSolicitud.en_progreso);
    });

    /// Condición real usada por el botón "Iniciar trabajo" en
    /// trabajos_activos_profesional_screen.dart: aceptada + presupuesto
    /// aceptado. Se reproduce aquí la misma comparación de enums que usa
    /// el widget, sobre datos parseados de verdad (no simulados a mano),
    /// para que un cambio en cómo se parsea/compara "aceptada" o
    /// "aceptado" se detecte igual que un cambio en "en_progreso".
    test('un trabajo "aceptada" con presupuesto "aceptado" cumple la condición de "Iniciar trabajo"', () {
      final trabajo = AssignedRequest.fromJson(
        jsonBase(
          estado: 'aceptada',
          presupuesto: {
            'id': 'p-1',
            'tipo': 'cerrado',
            'monto': 50.0,
            'incluyeIva': false,
            'estado': 'aceptado',
            'createdAt': '2026-08-13T09:00:00.000Z',
          },
        ),
      );

      final cumpleCondicionIniciar =
          trabajo.estado == EstadoSolicitud.aceptada && trabajo.presupuesto?.estado == EstadoPresupuesto.aceptado;
      expect(cumpleCondicionIniciar, isTrue);
    });

    test('un trabajo "en_progreso" NO cumple la condición de "Iniciar trabajo" (ya no debe mostrarse)', () {
      final trabajo = AssignedRequest.fromJson(
        jsonBase(
          estado: 'en_progreso',
          presupuesto: {
            'id': 'p-1',
            'tipo': 'cerrado',
            'monto': 50.0,
            'incluyeIva': false,
            'estado': 'aceptado',
            'createdAt': '2026-08-13T09:00:00.000Z',
          },
        ),
      );

      final cumpleCondicionIniciar =
          trabajo.estado == EstadoSolicitud.aceptada && trabajo.presupuesto?.estado == EstadoPresupuesto.aceptado;
      expect(cumpleCondicionIniciar, isFalse);
    });
  });
}
