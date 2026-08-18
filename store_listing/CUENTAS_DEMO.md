# Cuentas demo para los revisores (Apple y Google)

**Las dos tiendas exigen credenciales que funcionen** para que su revisor entre y
pruebe la app. Sin esto, rechazan por "no pudimos acceder / iniciar sesión".

Se pueden reutilizar las cuentas de prueba ya existentes y en buen estado (login por
**email + contraseña**, que es lo que el revisor puede usar — el login por SMS NO le
sirve porque no recibe el código).

---

## Cuenta CLIENTE (demo)
- **Email:** ana.prueba.sprint3@example.co
- **Contraseña:** _(la sabe el usuario — rellenar aquí antes de enviar a revisión)_
- Estado: activa, con login de Firebase. Nombre visible: Ana Sánchez.

## Cuenta PROFESIONAL (demo)
- **Email:** pedro.prof.sprint3@example.com
- **Contraseña:** _(la sabe el usuario — rellenar aquí)_
- Estado: activa, **verificación "aprobado"**, categorías Electricista y Aire
  acondicionado. Login de Firebase. Nombre visible: José Fernández.
- Nota: su cuenta de cobro Stripe **no** está completada (charges/payouts off), así que
  el flujo de "recibir dinero" no llega hasta el final — pero el revisor puede ver todo
  el lado profesional (solicitudes cercanas, postularse, presupuestos, chat, Centro de
  Pagos). Suficiente para revisar.

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
