# Procedimiento iOS final — Archive / TestFlight

> Estado: **preparado, NO ejecutado**. Actualiza y sustituye como
> referencia principal a `PROCEDIMIENTO_ARCHIVE_TESTFLIGHT.md` (ese
> documento sigue siendo válido en el detalle, este resume el estado
> ACTUAL tras la verificación real en Mac del 25/8). No hacer Archive
> sin GO explícito.

## Estado verificado hoy (25/8, sesión real en MacinCloud EU477)

| Elemento | Estado | Evidencia |
|---|---|---|
| `pod install` | 🟢 **ya ejecutado** — 84 pods, `FirebaseCrashlytics` confirmado en disco | Verificado en Mac, no solo en código |
| Podfile.lock | 🟡 actualizado y comiteado (`f7eb35c`) pero **solo en el Mac, sin pushear** | Sin credenciales de push en esa máquina — probado, falló limpio |
| Crashlytics (build phase) | 🟢 añadida y verificada | `xcodebuild -showBuildSettings` confirma rutas de dSYM correctas |
| dSYM | 🟢 preparado (confirmación 100% solo con Archive real) | `DEBUG_INFORMATION_FORMAT=dwarf-with-dsym`, rutas resueltas |
| Signing | 🟢 manual, perfil nombrado | `CODE_SIGN_IDENTITY=iPhone Distribution`, `PROVISIONING_PROFILE_SPECIFIER=HogarSOS AppStore Distribution` |
| Build number | 🟢 `44` (supera el último TestFlight, 41) | `CURRENT_PROJECT_VERSION=44` |
| Bundle ID | 🟢 `es.hogarsos.app` | Confirmado en `project.pbxproj` |
| Team | 🟢 `4VYW68LNH3` | Confirmado en `project.pbxproj` y en la clave APNs de Firebase Console (mismo Team ID) |
| Firebase | 🟢 correcto | `GoogleService-Info.plist`, Analytics OFF |
| OAuth | 🟢 correcto | `REVERSED_CLIENT_ID` coincide con `Info.plist` |
| Phone Auth | 🟢 config completa | Clave APNs de producción subida (Key ID `UTGB34F58J`), `aps-environment=production` |
| Stripe deep link | 🟢 correcto | `hogarsos://` en `Info.plist`, sin duplicados |

## Runbook (cuando llegue el GO — no antes)

### 1. Sincronizar Podfile.lock
```bash
cd ~/hogarsos-clean   # o el checkout real del Mac en ese momento
git fetch origin feature/alta-profesionales
git merge --ff-only origin/feature/alta-profesionales
```
Si el commit `f7eb35c` (pod install verificado) no se ha pusheado
todavía desde ninguna máquina con credenciales, este paso solo trae lo
que SÍ está en GitHub — reconfirmar con `git log -3` antes de seguir, y
si falta, correr `pod install` de nuevo aquí mismo (es idempotente,
volverá a dar 84 pods).

### 2. Abrir Runner.xcworkspace
```bash
cd ios && open Runner.xcworkspace
```
**Nunca** `Runner.xcodeproj` directamente — sin el workspace, CocoaPods
no se enlaza.

### 3. `pod install` si hace falta
Solo si el paso 1 trajo cambios al `Podfile` o si `Podfile.lock` no
coincide con lo ya verificado hoy:
```bash
cd ios && pod install
```

### 4. Comprobar Pods
```bash
find ios/Pods/FirebaseCrashlytics/run -maxdepth 0   # debe existir
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
  -configuration Release -showBuildSettings | grep -i CODE_SIGN
```

### 5. Archive
Desde Xcode: Product → Archive (con el scheme Runner, dispositivo
"Any iOS Device"). Alternativa CLI ya usada en builds anteriores:
```bash
../flutter/bin/flutter build ipa --release --build-number=44
```
Si el export a IPA falla por el perfil manual (ya ocurrió en builds
28/40/41) — es un problema conocido, no repetir intentos con
`xcodebuild -exportArchive`, ir directo al paso 6.

### 6. Organizer
```bash
open build/ios/archive/Runner.xcarchive
```
Confirmar en la pestaña de símbolos que el dSYM está presente en el
archive.

### 7. Upload TestFlight
Organizer → Distribute App → App Store Connect → Upload. Cumplimiento
de exportación: "Ninguno de los algoritmos" (mismo patrón que builds
anteriores). Grupo interno con distribución automática.

### 8. Verificar build
- App Store Connect: estado "Procesando" → "Listo para probar".
- Confirmar que el crash reporting real funciona (forzar un crash de
  prueba NO es necesario si el pod ya está verificado — solo confirmar
  que el build aparece con dSYM asociado en Crashlytics, no en
  "missing dSYMs").
- Phone Auth y deep link de Stripe: probar en el iPhone real del
  usuario antes de pasar a testers externos.

## Lo que NO cambia respecto al procedimiento anterior

`PROCEDIMIENTO_ARCHIVE_TESTFLIGHT.md` sigue teniendo el detalle de los
problemas conocidos del visor de MacinCloud (teclado, resolución,
foco de ventana) — consultarlo si hace falta interactuar con la GUI de
Xcode directamente en vez de por terminal.
