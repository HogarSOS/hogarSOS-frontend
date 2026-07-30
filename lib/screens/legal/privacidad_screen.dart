import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Política de privacidad — texto en español únicamente (sin pasar por
/// AppLocalizations párrafo a párrafo): es contenido legal, no UI
/// normal, y el mercado inicial de hogarSOS es España. Redactado para
/// cubrir lo que la app realmente hace (no es una plantilla genérica) —
/// pero no sustituye una revisión legal antes de publicar de verdad.
class PrivacidadScreen extends StatelessWidget {
  const PrivacidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.legalPrivacidadTitulo)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Seccion(
            titulo: '1. Quién trata tus datos',
            texto:
                'hogarSOS es una app que conecta a clientes con profesionales de servicios a domicilio. '
                'Somos responsables del tratamiento de los datos personales que recoge la aplicación, '
                'descritos en esta política.',
          ),
          _Seccion(
            titulo: '2. Qué datos recogemos',
            texto:
                '• Datos de cuenta: nombre, email y teléfono al registrarte.\n'
                '• Ubicación: tu ubicación aproximada o precisa (con tu permiso) para mostrarte '
                'profesionales cercanos, o para que un profesional aparezca en las búsquedas de clientes cerca de él.\n'
                '• Fotos: las que adjuntes a una solicitud de servicio o a tu perfil.\n'
                '• Documentos de verificación (solo profesionales): documento de identidad, certificados '
                'y seguro de responsabilidad civil, usados exclusivamente para verificar tu identidad y aptitud '
                'antes de permitirte operar en la plataforma.\n'
                '• Datos de pago: gestionados directamente por Stripe, nuestro procesador de pagos — '
                'hogarSOS nunca almacena el número completo de tu tarjeta.\n'
                '• Mensajes de chat entre cliente y profesional de una misma solicitud.',
          ),
          _Seccion(
            titulo: '3. Para qué usamos tus datos',
            texto:
                'Para prestar el servicio (conectar clientes con profesionales, procesar pagos, gestionar '
                'solicitudes), para verificar la identidad de los profesionales, para enviarte notificaciones '
                'relacionadas con tus solicitudes, y para prevenir fraude y resolver disputas.',
          ),
          _Seccion(
            titulo: '4. Con quién compartimos tus datos',
            texto:
                'Con el otro participante de una solicitud (el cliente ve el nombre del profesional asignado '
                'y viceversa). Con proveedores que nos ayudan a operar la app: Firebase/Google (autenticación, '
                'notificaciones, chat) y Stripe (pagos). No vendemos tus datos a terceros ni los usamos con '
                'fines publicitarios ajenos a la app.',
          ),
          _Seccion(
            titulo: '5. Cuánto tiempo conservamos tus datos',
            texto:
                'Mientras tu cuenta esté activa. Si la eliminas, borramos o anonimizamos tus datos personales, '
                'salvo lo que debamos conservar por obligación legal (p. ej. registros de pagos).',
          ),
          _Seccion(
            titulo: '6. Tus derechos',
            texto:
                'Puedes acceder, rectificar o solicitar la eliminación de tus datos, y retirar los permisos '
                'de ubicación, cámara o galería en cualquier momento desde los ajustes de tu teléfono. Para '
                'ejercer estos derechos, contacta con nosotros desde la app.',
          ),
          _Seccion(
            titulo: '7. Cambios en esta política',
            texto:
                'Si actualizamos esta política de forma relevante, te lo notificaremos dentro de la app antes '
                'de que entre en vigor.',
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
