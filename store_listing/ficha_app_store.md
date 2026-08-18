# Ficha del App Store — Hogar SOS

Datos para rellenar en **App Store Connect** al preparar la versión para revisión.
Se copia a mano en cada campo (nada se sube solo). Los textos reutilizan los de
Google Play (`descripcion_larga.txt`) adaptados a los campos y límites de Apple.

Build a enviar: **1.0.1 (38)**, bundle `es.hogarsos.app` (ya subido a TestFlight).

---

## Nombre de la app (máx. 30 car.)
Hogar SOS

## Subtítulo (máx. 30 car.)
Profesionales para tu hogar
*(26 caracteres)*

## Texto promocional (máx. 170 car. — se puede cambiar sin re-revisión)
Publica lo que necesitas, recibe candidaturas de profesionales verificados de tu zona, acuerda un presupuesto y paga seguro: el dinero se libera solo al terminar.
*(~160 caracteres — comprobar en el editor)*

## Palabras clave (máx. 100 car., separadas por comas, SIN espacios)
fontanero,electricista,manitas,limpieza,reformas,jardinero,cerrajero,pintor,presupuesto,profesional
*(99 caracteres. No repetir "hogar"/"sos" — ya están en el nombre. Apple indexa nombre+subtítulo+keywords.)*

## Descripción (máx. 4000 car.)
Reutilizar el texto de `descripcion_larga.txt` tal cual (2.369 car., cabe de sobra).
Apple no usa palabras clave dentro de la descripción para el ranking (a diferencia
de Google), pero el texto sigue siendo válido y claro para el usuario.

## Novedades de esta versión / "What's New"
Notificación de pago confirmado para cliente y profesional. La notificación de pago
abre directamente el Centro de Pagos. Mejoras de rendimiento y estabilidad.

## URLs
- **Soporte:** https://hogarsos.es
- **Marketing (opcional):** https://hogarsos.es
- **Política de privacidad:** https://hogarsos.es/privacidad

## Categoría
- **Principal:** Estilo de vida (Lifestyle)
- **Secundaria (opcional):** Utilidades (Utilities)
*(App Store no tiene "Casa y hogar" como categoría propia; Lifestyle es la más cercana.)*

---

## Capturas de pantalla (PENDIENTE — hay que capturarlas en iPhone)
Apple exige capturas en tamaños concretos, NO valen las de Android:
- **iPhone 6.9"** (p. ej. iPhone 16 Pro Max, 1320×2868) — **obligatorio**.
- **iPhone 6.5"** (p. ej. iPhone 11 Pro Max, 1242×2688) — recomendado/obligatorio según pantallas.
- Se pueden reutilizar las MISMAS pantallas que las 8 de Android (`screenshots/`), pero
  capturadas desde un iPhone (o simulador) a esas resoluciones. Mínimo 3, hasta 10.
- Sugerencia: inicio cliente, publicar solicitud, elegir profesional, presupuesto con
  desglose, chat, Centro de Pagos del profesional.

---

## App Privacy (se rellena como cuestionario en App Store Connect)
Datos que recoge la app (declarar así):
- **Contacto:** nombre, email, teléfono.
- **Ubicación:** para emparejar cliente-profesional por cercanía.
- **Contenido de usuario:** fotos (perfil y del trabajo), mensajes de chat.
- **Identificadores:** cuenta de usuario.
- **Pagos:** procesados por **Stripe**; la app NO almacena números de tarjeta.
- Se comparten con terceros necesarios: **Stripe** (pagos), **Firebase/Google** (auth y
  notificaciones). Declararlo.
- No se usa para publicidad ni tracking de terceros.

## Clasificación por edad
Sin contenido violento/sexual/apuestas → **4+**.

## Export Compliance (cifrado)
La app usa solo **HTTPS/cifrado estándar** (no cifrado propietario). Respuesta típica:
"Usa cifrado" → "Solo cifrado estándar / exento" (exempt). Marcar la exención de exportación.
*(Se puede pre-responder en Info.plist con ITSAppUsesNonExemptEncryption=false para no
tener que contestarlo en cada subida — opcional, mejora futura.)*

## App Review Information (para el revisor de Apple) — PENDIENTE
- **Cuenta demo OBLIGATORIA**: un usuario CLIENTE y, si el revisor debe ver el lado
  profesional, un usuario PROFESIONAL, con email+contraseña que funcionen (ver
  `CUENTAS_DEMO.md`). Sin esto, Apple rechaza por "no podemos acceder".
- **Notas para el revisor**: explicar el flujo (publicar solicitud → candidatura →
  presupuesto → pago retenido con Stripe en modo real; sugerir usar la tarjeta de
  prueba NO aplica en LIVE — indicar que el pago autoriza pero se puede cancelar).
- **Contacto**: soporte@hogarsos.es.

## Precio y disponibilidad
- **Gratis.**
- **Disponibilidad**: España (o los países que se decidan).
- **Publicación**: elegir **"Publicar manualmente esta versión"** para poder soltar el
  lanzamiento el día elegido (28) aunque Apple la apruebe antes.
