# Checklist — qué falta para publicar la beta cerrada en Google Play

## ✅ Ya hecho (2026-08-01)

- **`.aab` de release compilado**: `build/app/outputs/bundle/release/app-release.aab` (67.8MB), firmado con el keystore de producción, con `API_BASE_URL` y `STRIPE_PUBLISHABLE_KEY` correctos.
- **Versionado**: `pubspec.yaml` → `0.1.0+1`.
- **Auditoría de textos temporales**: botón muerto "Configuración" (Próximamente) oculto, mensaje de error con texto de desarrollo ("Firebase Console → Authentication...") corregido, sin más TODO/placeholder visibles al usuario.
- **`usesCleartextTraffic`** ya no viaja en la release (solo en debug) — evita una advertencia de seguridad en el informe previo al lanzamiento de Play Console.
- **SVG de marca desactualizados** (seguían en azul, de antes del rebrand) corregidos al verde actual.
- **Ficha de Play Store redactada**: descripción corta y larga, categoría recomendada, información de contacto, enlace de política de privacidad — todo en `store_listing/`.
- **Imagen promocional 1024×500** generada con la identidad visual actual — `store_listing/feature_graphic_1024x500.png`.
- **Icono 512×512** ya existía — `assets/branding/play-store-icon-512.png`.
- **Datos de ejemplo limpios** insertados en la base de datos de producción para las capturas: una solicitud pendiente ("Se ha ido la luz...", categoría Electricista, cliente Ana Sánchez) y un trabajo ya aceptado con presupuesto cerrado de 85€ (categoría Aire acondicionado, profesional José Fernández).
- **Capturas de pantalla reales**: 7 capturas de una sesión end-to-end real (publicar solicitud, candidatura, elegir profesional, presupuesto con desglose de comisión) — `store_listing/screenshots/`.
- **Botón "Aceptar solicitud" corregido a "Enviar candidatura"**: encontrado al revisar las capturas — era un resto del flujo antiguo ("el primero que acepta gana") que hacía creer al profesional que ya tenía el trabajo asegurado con solo postularse.

## 🚫 Bloqueado en Google (nadie lo puede acelerar)

- **Verificación de identidad de Google Play Developer** — sigue en trámite por parte de Google, sin fecha. Bloquea crear la cuenta y, por tanto, subir nada de lo anterior.
- Una vez creada la cuenta y subida la ficha: **prueba cerrada obligatoria de 12 testers activos durante 14 días continuos** antes de pasar a producción — no se puede saltar ni acelerar.

## 🚫 Bloqueado en ti (decisiones pendientes, no urgentes)

- **Cuestionario de clasificación de contenido** y **formulario de seguridad de datos** — se rellenan dentro de Play Console (no son archivos que se puedan preparar de antemano), pero ya tengo las respuestas previstas anotadas en `ficha_play_store.md`.
- **Logo**: sigues usando la marca verde actual — las 7 propuestas casa+manos siguen sin decidir, pero por tu indicación esto no bloquea el lanzamiento. Si más adelante cambias de opinión, es una actualización sencilla (solo el icono 512×512 y la imagen promocional).

## Resumen

Con la cuenta de Play Developer ya verificada, todo lo técnico está listo para subir la beta cerrada: `.aab`, ficha, imagen promocional, capturas y textos revisados. Solo falta rellenar el cuestionario de clasificación de contenido y el formulario de seguridad de datos dentro de Play Console (las respuestas ya están anotadas), y crear la cuenta en cuanto Google complete la verificación.
