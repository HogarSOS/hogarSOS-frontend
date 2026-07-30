import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Términos de servicio — mismo criterio que privacidad_screen.dart:
/// texto en español, redactado para lo que la app realmente hace, no
/// una plantilla genérica ni un sustituto de revisión legal real.
class TerminosScreen extends StatelessWidget {
  const TerminosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.legalTerminosTitulo)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Seccion(
            titulo: '1. Qué es hogarSOS',
            texto:
                'hogarSOS es una plataforma que conecta a clientes que necesitan un servicio a domicilio '
                '(electricidad, fontanería, limpieza, etc.) con profesionales independientes que los ofrecen. '
                'hogarSOS no presta los servicios directamente ni es empleador de los profesionales — actúa '
                'como intermediario entre ambas partes.',
          ),
          _Seccion(
            titulo: '2. Cuentas de usuario',
            texto:
                'Debes dar información veraz al registrarte. Eres responsable de mantener segura tu cuenta. '
                'Los profesionales deben superar un proceso de verificación (documento de identidad y, si '
                'aplica, certificados/seguro) antes de poder aceptar solicitudes.',
          ),
          _Seccion(
            titulo: '3. Pagos y comisión',
            texto:
                'El pago de un servicio se autoriza a través de Stripe al aceptar el trabajo, pero no se '
                'cobra hasta que el profesional marca el servicio como completado. hogarSOS retiene una '
                'comisión sobre el precio final del servicio; el resto se transfiere al profesional. Los '
                'precios los fija el profesional o se acuerdan entre ambas partes por chat.',
          ),
          _Seccion(
            titulo: '4. Cancelaciones y reembolsos',
            texto:
                'El cliente puede cancelar una solicitud sin coste mientras esté pendiente o recién aceptada '
                'y el trabajo todavía no haya empezado. Si ya se autorizó un pago, se reembolsa automáticamente '
                'al cancelar. Una vez el profesional marca el servicio como "en curso", ya no se puede cancelar '
                'desde la app — en ese caso, contacta con nosotros para resolverlo.',
          ),
          _Seccion(
            titulo: '5. Disputas',
            texto:
                'Si algo no fue como se esperaba, cliente o profesional pueden abrir una disputa. Un '
                'administrador revisa el caso y decide si el pago se libera al profesional o se reembolsa '
                'al cliente.',
          ),
          _Seccion(
            titulo: '6. Responsabilidad',
            texto:
                'hogarSOS facilita el contacto y el pago entre cliente y profesional, pero no supervisa ni '
                'garantiza la calidad del trabajo realizado — la relación de servicio es directamente entre '
                'ambas partes. Recomendamos revisar las valoraciones de un profesional antes de contratarlo.',
          ),
          _Seccion(
            titulo: '7. Conducta de los profesionales',
            texto:
                'Los profesionales verificados deben prestar el servicio con la diligencia y competencia '
                'propias de su oficio. hogarSOS puede suspender o revocar una cuenta que reciba valoraciones '
                'reiteradamente negativas, incumpla estos términos, o cuya verificación resulte fraudulenta.',
          ),
          _Seccion(
            titulo: '8. Cambios en estos términos',
            texto:
                'Podemos actualizar estos términos; los cambios relevantes se notificarán dentro de la app '
                'antes de entrar en vigor. Seguir usando hogarSOS después de un cambio implica aceptarlo.',
          ),
          _Seccion(
            titulo: '9. Ley aplicable',
            texto: 'Estos términos se rigen por la legislación española.',
          ),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.texto});

  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(texto, style: const TextStyle(fontSize: 13.5, height: 1.5)),
        ],
      ),
    );
  }
}
