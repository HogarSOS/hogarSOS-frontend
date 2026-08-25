# Checklist tiendas — estado real, sin publicar nada

> Estado: 25/8/2026. Solo lectura de lo ya existente en el repo — nada
> inventado. Donde algo depende de mirar un Dashboard externo, se marca
> explícitamente como no verificable desde aquí.

## GOOGLE PLAY

| Elemento | Estado | Fuente |
|---|---|---|
| Ficha (nombre, descripciones, categoría, contacto) | 🟢 lista | `store_listing/ficha_play_store.md` |
| Política de privacidad | 🟢 desplegada | `https://hogarsos.es/privacidad` |
| Capturas de pantalla | 🟢 9 imágenes | `store_listing/screenshots/` |
| Imagen promocional 1024×500 | 🟢 lista | `store_listing/feature_graphic_1024x500.png` |
| Icono 512×512 | 🟢 listo | `assets/branding/play-store-icon-512.png` |
| Data Safety / clasificación de contenido | 🟡 respuestas previstas, formulario sin rellenar | Es un cuestionario dentro de Play Console, no un archivo — respuestas ya redactadas en `ficha_play_store.md` |
| Cuenta demo | 🟢 lista (ver tabla de cuentas) | `store_listing/CUENTAS_DEMO.md` |
| `CHECKLIST_PLAY_STORE.md` (documento histórico) | 🔴 **desactualizado, NO usar** | Fechado 4/8, referencia versión `0.1.0+1` — muy anterior a Build 44 |
| Internal Testing | 🟡 requiere verificar en Dashboard | Builds 40-42 subidos según memoria del proyecto; no verificable desde el repo si sigue activo |
| Ventana de 14 días de prueba cerrada (12 testers) antes de producción | 🟡 requiere verificar en Dashboard | Requisito real de Google documentado en el checklist histórico — no se puede confirmar desde aquí si ya se cumplió |
| Versión objetivo (`versionName`/`versionCode`) | 🟢 `1.0.1+44` en pubspec.yaml | Ver `docs/PROCEDIMIENTO_ANDROID_FINAL.md` |
| Solicitud de producción | 🟡 decisión del usuario, no técnica | No asumir que ya se pidió — confirmar antes de referenciarla como hecha |

## APP STORE

| Elemento | Estado | Fuente |
|---|---|---|
| Ficha (descripción, keywords, categoría) | 🟢 lista | `store_listing/ficha_app_store.md` |
| Capturas de pantalla | 🟢 10 subidas a Media Manager (18/8) | `ficha_app_store.md`, sección capturas |
| Cuenta demo (App Review Information) | 🟢 lista | `store_listing/CUENTAS_DEMO.md` |
| Privacy (cifrado, ITSAppUsesNonExemptEncryption) | 🟢 respondido (HTTPS estándar) | `ficha_app_store.md` |
| Notas para el revisor (flujo Stripe en modo real) | 🟢 redactadas | `ficha_app_store.md` |
| Build number objetivo | 🟢 `44` (supera el último TestFlight, 41) | Ver `ios/docs/PROCEDIMIENTO_IOS_FINAL.md` |
| Ficha enviada a revisión | 🔴 **NO enviada** | Memoria del proyecto (18/8): "preparada, sin enviar" — decisión del usuario |
| `MinimumOSVersion` | 🟡 aviso pendiente, no urgente | iOS 13.0 actual; Apple exigirá 15.0 en primavera 2027 — subirlo antes de esa fecha, no antes del lanzamiento |

## Lo que NO se ha hecho en esta tarea

No se ha publicado nada, no se ha enviado ninguna ficha a revisión, no
se ha tocado ningún Dashboard de Play Console ni App Store Connect. Los
🟡 marcados "requiere verificar en Dashboard" necesitan que alguien con
acceso real confirme el estado — no se ha inventado una respuesta.
