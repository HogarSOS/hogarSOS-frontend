# Procedimiento Android — build final

> Estado: **preparado, NO ejecutado**. No generar AAB sin GO explícito.
> Este documento es solo verificación de configuración y el comando
> exacto a usar cuando llegue el momento.

## Verificación de configuración (hecha, sin generar build)

| Elemento | Estado | Evidencia |
|---|---|---|
| `versionName` actual | `1.0.1` | `pubspec.yaml` |
| `versionCode` (build number) actual | `44` (candidato, sin publicar) | `pubspec.yaml` → `1.0.1+44` |
| Próximo `versionCode` | `44` mismo, o el que corresponda si se integran más cambios antes del GO | Reconfirmar con `grep "^version:" pubspec.yaml` justo antes del build |
| Firma release | Obligatoria, sin fallback a debug | `android/app/build.gradle.kts` — falla explícitamente si falta `key.properties`, con mensaje claro |
| Keystore | Presente en esta máquina | `C:/Users/y_yon/hogarSOS-keystore/hogarsos-release.jks`, referenciado desde `android/key.properties` (gitignored) |
| Firebase | Correcto | `google-services.json` con `applicationId` `es.hogarsos.app`, proyecto `hogarsos` |
| Crashlytics | Integrado (capa Dart, compartida con iOS) | `imagen_autenticada.dart` — no-fatal para errores de imagen, fatal real intacto |
| Clave Stripe (`pk_live`) | Por defecto en release, con guardia anti-`pk_test` | `lib/main.dart` — bloquea la UI si detecta `pk_test` en modo release |
| API de producción | Por defecto, sin código de localhost funcional | `lib/services/api_service.dart` → `https://hogarsos.es/api`; único `localhost` en comentarios de documentación |
| Permisos declarados | Cámara, ubicación, notificaciones — todos con uso real | `AndroidManifest.xml` |
| `allowBackup` | `false`, con `dataExtractionRules` (cubre Android 12+) | `AndroidManifest.xml` |
| ProGuard/R8 | `minifyEnabled=true`, `shrinkResources=true` | `android/app/build.gradle.kts` |
| Lint en release | Desactivado a propósito (dependencia de Stripe no resoluble sin acceso restringido, no usada por la app) | `android/app/build.gradle.kts`, comentario explícito — no es un riesgo de seguridad |

## Comando exacto a ejecutar (cuando se dé el GO — NO antes)

```bash
export FLUTTER_BIN="C:/Users/y_yon/Desktop/flutter_windows_3.44.8-stable/flutter/bin"
cd frontend_wizard   # o el checkout que sea la base final integrada
"$FLUTTER_BIN/flutter.bat" clean
"$FLUTTER_BIN/flutter.bat" pub get
"$FLUTTER_BIN/flutter.bat" build appbundle --release \
  --dart-define=API_BASE_URL=https://hogarsos.es/api
```

Salida esperada: `build/app/outputs/bundle/release/app-release.aab`.

## Verificación post-build (antes de subir a Play)

```bash
# SHA-256 del AAB, para poder confirmar después que Play recibió exactamente este archivo
shasum -a 256 build/app/outputs/bundle/release/app-release.aab

# Confirmar versionCode/versionName embebidos
"$FLUTTER_BIN/flutter.bat" build appbundle --release --analyze-size 2>&1 | head -20
```

Subida manual a Play Console → Internal Testing primero, nunca directo
a producción — mismo patrón que builds 40-42.
