# Cuentas demo para los revisores (Apple y Google)

**Las dos tiendas exigen credenciales que funcionen** para que su revisor entre y
pruebe la app. Sin esto, rechazan por "no pudimos acceder / iniciar sesión".

Se pueden reutilizar las cuentas de prueba ya existentes y en buen estado (login por
**email + contraseña**, que es lo que el revisor puede usar — el login por SMS NO le
sirve porque no recibe el código).

---

## Cuenta CLIENTE (demo)
- **Email:** demo.cliente@hogarsos.es
- **Contraseña:** Revisor-HogarSOS26
- Estado: activa, cuenta NUEVA creada 2026-08-18 específicamente para revisores (nombre
  "Revisor Demo"). Verificado con login real contra Firebase, HTTP 200.
- **Por qué no la cuenta de Ana** (`ana.prueba.sprint3@example.co`, la que se usaba antes):
  tiene una tarjeta/Google Pay REAL del propio desarrollador guardada en el Payment Sheet de
  Stripe (`stripeCustomerId` con método de pago por defecto). Dar esas credenciales a un
  revisor externo expondría ese medio de pago real a un tercero. La cuenta de Ana sigue
  existiendo y activa (uso normal de pruebas), simplemente ya NO se usa como demo de tienda.
  No hace falta tocarla ni quitarle la tarjeta para esto.

## Cuenta PROFESIONAL (demo)
- **Email:** pedro.prof.sprint3@example.com
- **Contraseña:** Prueba1234
- Estado: activa, **verificación "aprobado"**, categorías Electricista y Aire
  acondicionado. Login de Firebase. Nombre visible: José Fernández. Verificado
  2026-08-18 (login real contra Firebase, HTTP 200).
- Nota: su cuenta de cobro Stripe **no** está completada (charges/payouts off), así que
  el flujo de "recibir dinero" no llega hasta el final — pero el revisor puede ver todo
  el lado profesional (solicitudes cercanas, postularse, presupuestos, chat, Centro de
  Pagos). Suficiente para revisar.

## Cuenta PROFESIONAL 2 (para el vídeo anuncio, NO es para revisores de tienda)
- **Email:** javier.demo@hogarsos.es
- **Contraseña:** HogarSOS-Javier26
- Nombre visible: Javier. Creada 2026-08-19 porque el video ad necesita 2 personas
  usando la app como profesionales a la vez (con la misma cuenta de Pedro se pisaban).
- Estado: activa, **verificación "aprobado"**, categorías Electricista, Fontanero y
  Aire acondicionado (las mismas 3 que se pidieron para el vídeo).
- Sin foto de perfil ni valoraciones todavía (cuenta nueva, 0 trabajos) — si el vídeo
  necesita foto, subirla desde la app al grabar es más natural que ponerla a mano.
- `disponible = true` (activado 2026-08-19 directamente en BD, saltando el candado de
  Stripe — ver nota de abajo). Ubicación puesta cerca de Pedro (Garrucha) como
  placeholder; si se graba en otro sitio, basta con mover el mapa/GPS desde la app
  normalmente, no hace falta tocar la BD otra vez.
- Sin cuenta de Stripe Connect creada. La app exige Stripe Connect "configurada"
  (cobros y transferencias habilitados) para poder ponerse disponible — es el mismo
  candado que ya sorteaba Pedro. Se saltó a mano en BD porque el vídeo no necesita
  cobrar de verdad. Si el vídeo SÍ necesita mostrar el lado de "cobrar", hay que
  completar el onboarding real de Stripe Connect desde el Centro de Pagos (no se
  puede simular sin ese paso).

---

## Qué poner en las notas para el revisor (App Store Connect y Play Console)
- Con la cuenta CLIENTE: publicar una solicitud → recibir/ver candidaturas → aceptar un
  presupuesto → el pago se **autoriza** (retención) con Stripe en modo real; se puede
  cancelar sin coste. Chat con el profesional.
- Con la cuenta PROFESIONAL: ver solicitudes cercanas, postularse, enviar presupuesto,
  chatear, y el Centro de Pagos.
- Idiomas: es/en según el idioma del dispositivo.
- Contacto de soporte: soporte@hogarsos.es

## Recomendación
Estas cuentas `@example.co/.com` funcionan para revisión. Si se prefiere algo más
"limpio" para el futuro, se pueden crear cuentas demo con dominio propio
(demo.cliente@hogarsos.es / demo.pro@hogarsos.es) — pero NO es bloqueante para lanzar;
las actuales sirven perfectamente.

**IMPORTANTE:** antes de enviar cada tienda a revisión, comprobar que la contraseña de
cada cuenta es correcta iniciando sesión una vez (para no dar al revisor una credencial
que no entra).
