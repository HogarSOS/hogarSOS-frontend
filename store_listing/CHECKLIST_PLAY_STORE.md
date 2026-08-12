# Checklist — qué falta para publicar la beta cerrada en Google Play

## ✅ Actualización 2026-08-04 tarde

- **Verificación de identidad de Google Play Developer: recibida.** Deja de ser el bloqueante externo — ya se puede crear la app en Play Console.
- **`.aab` recompilado desde cero** (el del 1 de agosto ya no existía ni en disco, y estaba desactualizado de todas formas): `build/app/outputs/bundle/release/app-release.aab` (68.8MB), firmado con el keystore de producción. Incluye TODO lo que ha cambiado desde el 1 de agosto: migración de `applicationId` a `es.hogarsos.app`, `pk_live` real de Stripe, verificación de email + login por teléfono, sistema de candidaturas, comisión 5%/0% con término "Gastos de gestión", categorías renombradas, eliminación de cuenta, y el resto de la auditoría B1-B5. Los 2 bugs de Stripe Live encontrados hoy (ver [[project_hogarsos_stripe_live_activacion]]) son solo de backend — no afectan a este `.aab`.
- **`ficha_play_store.md` corregida**: la web/política de privacidad apuntaba a `hogarsos.web.app`, desactualizado — el dominio real y donde vive `/privacidad`, `/terminos`, `/eliminar-cuenta` es `hogarsos.es` (servido por el propio backend).

## ✅ Ya hecho (2026-08-01)

- **Versionado**: `pubspec.yaml` → `0.1.0+1` (primera subida, no hace falta tocarlo).
- **Auditoría de textos temporales**: botón muerto "Configuración" (Próximamente) oculto, mensaje de error con texto de desarrollo ("Firebase Console → Authentication...") corregido, sin más TODO/placeholder visibles al usuario.
- **`usesCleartextTraffic`** ya no viaja en la release (solo en debug) — evita una advertencia de seguridad en el informe previo al lanzamiento de Play Console.
- **SVG de marca desactualizados** (seguían en azul, de antes del rebrand) corregidos al verde actual.
- **Ficha de Play Store redactada**: descripción corta y larga, categoría recomendada, información de contacto, enlace de política de privacidad — todo en `store_listing/`.
- **Imagen promocional 1024×500** generada con la identidad visual actual — `store_listing/feature_graphic_1024x500.png`.
- **Icono 512×512** ya existía — `assets/branding/play-store-icon-512.png`.
- **Datos de ejemplo limpios** insertados en la base de datos de producción para las capturas: una solicitud pendiente ("Se ha ido la luz...", categoría Electricista, cliente Ana Sánchez) y un trabajo ya aceptado con presupuesto cerrado de 85€ (categoría Aire acondicionado, profesional José Fernández).
- **Capturas de pantalla reales**: 7 capturas de una sesión end-to-end real (publicar solicitud, candidatura, elegir profesional, presupuesto con desglose de comisión) — `store_listing/screenshots/`.
- **Botón "Aceptar solicitud" corregido a "Enviar candidatura"**: encontrado al revisar las capturas — era un resto del flujo antiguo ("el primero que acepta gana") que hacía creer al profesional que ya tenía el trabajo asegurado con solo postularse.

## 🚫 Bloqueado en ti (solo tú puedes hacerlo — cuenta de Google, formularios, pagos)

Estos pasos exigen tu propia cuenta de Google/Play Console — no son algo que yo pueda hacer por ti:

1. **Crear la app en Play Console** (ya con la verificación de identidad resuelta).
2. **Subir el `.aab`**: `build/app/outputs/bundle/release/app-release.aab`.
3. **Cuestionario de clasificación de contenido** y **formulario de seguridad de datos** — respuestas ya preparadas en `ficha_play_store.md`.
4. **Rellenar la ficha de la tienda** con los textos de `descripcion_corta.txt`/`descripcion_larga.txt`, subir `feature_graphic_1024x500.png`, `play-store-icon-512.png` y las 7 capturas de `screenshots/`.
5. **Crear la pista de pruebas cerradas** y añadir **12 testers activos por email** (no por teléfono) — Play exige 14 días continuos de prueba cerrada antes de pasar a producción, no se puede saltar ni acelerar.

## Resumen

Todo lo técnico está listo: `.aab` actualizado, ficha, imagen promocional, capturas y textos revisados, verificación de Google ya recibida. Lo que queda es enteramente manual dentro de Play Console (subir, rellenar formularios, invitar testers) — trabajo tuyo, no de código.
