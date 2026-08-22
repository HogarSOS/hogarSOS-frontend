import 'package:flutter_test/flutter_test.dart';
import 'package:hogarsos/services/professional_service.dart';
import 'package:hogarsos/widgets/wizard_alta.dart';

/// Progreso por hitos del wizard "Completa tu alta" (revisión adversarial
/// 2026-08-22): 25/50/75/100 y NUNCA 100 sin aprobado + Stripe operativa
/// — la regla que evita que el porcentaje transmita una falsa cercanía.
void main() {
  group('WizardAlta.progreso', () {
    test('25% — cuenta creada, perfil sin completar', () {
      expect(
        WizardAlta.progreso(perfilOk: false, detalle: DetalleCuentaStripe.sinIniciar, aprobado: false),
        25,
      );
    });

    test('50% — perfil completo, Stripe sin iniciar', () {
      expect(
        WizardAlta.progreso(perfilOk: true, detalle: DetalleCuentaStripe.sinIniciar, aprobado: false),
        50,
      );
    });

    test('50% — Stripe empezado pero KYC sin entregar sigue en 50', () {
      expect(
        WizardAlta.progreso(perfilOk: true, detalle: DetalleCuentaStripe.enProgreso, aprobado: false),
        50,
      );
    });

    test('75% — KYC entregado, Stripe verificando', () {
      expect(
        WizardAlta.progreso(perfilOk: true, detalle: DetalleCuentaStripe.enVerificacion, aprobado: false),
        75,
      );
    });

    test('75% — Stripe pide un dato más: sigue en 75, nunca retrocede', () {
      expect(
        WizardAlta.progreso(perfilOk: true, detalle: DetalleCuentaStripe.accionNecesaria, aprobado: false),
        75,
      );
    });

    test('75% — Stripe lista pero aprobación de HogarSOS aún resolviéndose: NO es 100', () {
      expect(
        WizardAlta.progreso(perfilOk: true, detalle: DetalleCuentaStripe.configurada, aprobado: false),
        75,
      );
    });

    test('75% — aprobado pero Stripe caída: NUNCA 100 con los cobros no operativos', () {
      expect(
        WizardAlta.progreso(perfilOk: true, detalle: DetalleCuentaStripe.accionNecesaria, aprobado: true),
        75,
      );
    });

    test('100% — exclusivamente aprobado + Stripe configurada', () {
      expect(
        WizardAlta.progreso(perfilOk: true, detalle: DetalleCuentaStripe.configurada, aprobado: true),
        100,
      );
    });
  });

  group('DetalleCuentaStripe', () {
    test('fromJson mapea los cinco estados del backend', () {
      expect(DetalleCuentaStripe.fromJson('sin_iniciar'), DetalleCuentaStripe.sinIniciar);
      expect(DetalleCuentaStripe.fromJson('en_progreso'), DetalleCuentaStripe.enProgreso);
      expect(DetalleCuentaStripe.fromJson('en_verificacion'), DetalleCuentaStripe.enVerificacion);
      expect(DetalleCuentaStripe.fromJson('accion_necesaria'), DetalleCuentaStripe.accionNecesaria);
      expect(DetalleCuentaStripe.fromJson('configurada'), DetalleCuentaStripe.configurada);
    });

    test('backend viejo sin el campo: cae al estado clásico de forma segura', () {
      expect(
        DetalleCuentaStripe.desdeEstadoClasico(EstadoCuentaStripe.requiereActualizacion),
        DetalleCuentaStripe.accionNecesaria,
      );
      expect(
        DetalleCuentaStripe.desdeEstadoClasico(EstadoCuentaStripe.configurada),
        DetalleCuentaStripe.configurada,
      );
      expect(
        DetalleCuentaStripe.desdeEstadoClasico(EstadoCuentaStripe.pendiente),
        DetalleCuentaStripe.sinIniciar,
      );
    });
  });
}
