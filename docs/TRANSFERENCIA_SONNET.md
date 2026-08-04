# Transferencia técnica — dónde está el documento completo

El documento oficial de entrega de la fase de cierre pre-lanzamiento (bloqueantes B1–B5)
vive en el **repositorio del backend**, porque cubre los dos repositorios y allí está el
grueso del cambio:

> `HogarSOS/HogarSOS` → `docs/TRANSFERENCIA_SONNET.md`

Se mantiene en un solo sitio a propósito: duplicarlo garantizaría que las dos copias
acabaran divergiendo.

## Lo que afecta a ESTE repositorio (resumen)

- **`lib/main.dart`** — la app de **release** se niega a arrancar si detecta una clave
  `pk_test` de Stripe (muestra una pantalla roja de bloqueo). Antes de publicar hay que
  sustituir el `defaultValue` por la `pk_live`.
- **`android/app/build.gradle.kts`** — el build de release **falla** si falta
  `android/key.properties`. Antes caía en silencio a la clave de *debug* y producía un
  `.aab` que Google Play rechaza.
- **`lib/utils/imagen_autenticada.dart`** (nuevo) — desde B4, `/uploads/:archivo` exige
  autenticación. **Toda imagen que venga del backend debe cargarse con `imagenDeRed()` o
  con `cabecerasImagen()`**; usar `CachedNetworkImageProvider` directamente da 401.
- **`lib/services/token_storage.dart`** — `accessTokenEnMemoria` es un getter *síncrono*
  necesario porque un `ImageProvider` se construye dentro de `build` y no puede esperar a
  leer del almacenamiento seguro.
- **`subirFoto`** exige ahora un `tipo` (`foto_perfil`, `foto_solicitud`, `foto_disputa`,
  `documento_identidad`, `certificado`, `seguro_rc`). **No es informativo: decide quién
  podrá ver el archivo después.**
- **Desglose de comisión del profesional** — se muestra `montoBase − montoProfesional`, no
  `comisionPlataforma` (que incluye la parte del cliente). Ver §4.10 del documento completo.

## Verificación

Flutter 3.44.8 stable. Línea base esperada:

```bash
flutter analyze   # 61 issues, todos `info` de withOpacity, 0 errores, 0 warnings
flutter test      # 9/9
```

Para comparar `flutter analyze` con fiabilidad, volcar la salida **cruda** a fichero y
diferenciar ahí; el conteo autoritativo es la línea `N issues found`.
