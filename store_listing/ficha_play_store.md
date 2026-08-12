# Ficha de Google Play — Hogar SOS

Datos para rellenar en Play Console cuando la cuenta de desarrollador esté verificada. Nada de esto se sube solo — hay que copiarlo a mano en cada campo.

## Nombre de la app
Hogar SOS
(máx. 30 caracteres — cabe sin recortar)

## Descripción corta (máx. 80 caracteres)
Ver `descripcion_corta.txt` — 74 caracteres.

## Descripción completa (máx. 4000 caracteres)
Ver `descripcion_larga.txt` — 2288 caracteres.

## Categoría
- **Principal:** Casa y hogar (House & Home)
- **Secundaria (opcional):** Estilo de vida (Lifestyle)

## Palabras clave sugeridas
Google Play no tiene un campo de "palabras clave" como App Store — el posicionamiento sale del título + descripción corta + descripción completa. Términos ya incluidos de forma natural en los textos de arriba, para que el buscador de Play los indexe:
fontanero, electricista, limpieza del hogar, manitas, reformas, jardinería, cerrajería, profesionales a domicilio, servicios para el hogar, presupuesto, pago seguro, chat con profesionales.

## Información de contacto
- **Correo de soporte:** soporte@hogarsos.es
- **Sitio web:** https://hogarsos.es
- **Teléfono:** no configurado — campo opcional en Play Console, se puede dejar en blanco.

## Política de privacidad
URL pública ya desplegada: https://hogarsos.es/privacidad
(servida directamente por el backend — `backend_wizard/src/routes/legal.routes.ts` —, mismo contenido que la pantalla in-app `lib/screens/legal/privacidad_screen.dart`)

## Clasificación de contenido y formulario de seguridad de datos
**Pendiente** — estos dos se rellenan como cuestionario dentro de Play Console (no son archivos que yo pueda preparar de antemano), pero puedo adelantar las respuestas previstas cuando llegue el momento:
- Sin contenido violento, sexual ni de apuestas → clasificación esperada: PEGI 3 / Apta para todos los públicos.
- Datos que la app recoge: nombre, email, teléfono, ubicación (para el emparejamiento cliente-profesional), fotos (perfil y del trabajo), datos de pago (procesados por Stripe, la app no almacena tarjetas).
- Estos datos SÍ se comparten con terceros necesarios para el servicio (Stripe para pagos, Firebase para notificaciones/autenticación) — hay que declararlo así en el formulario de seguridad de datos.

## Icono de la ficha (512×512)
Ya existe: `assets/branding/play-store-icon-512.png` (marca verde actual). Si más adelante se decide cambiar el logo (propuesta casa+manos, todavía sin decidir), solo hay que regenerar este archivo — no bloquea el lanzamiento.

## Imagen promocional (1024×500)
Ver `feature_graphic_1024x500.png` en esta misma carpeta.

## Capturas de pantalla
Ver carpeta `screenshots/`.
