# Procedimiento Archive / TestFlight — candidato iOS pre-build-final

> Estado: **preparado, NO ejecutado**. Escrito 25/8/2026 tras la auditoría
> de paridad iOS↔Android. No ejecutar nada de esto sin un GO explícito
> del usuario — ni siquiera el paso 1 (`pod install`) sin confirmar antes
> que la fecha/estado de esta rama sigue siendo la candidata real.

## Qué contiene esta rama (`feature/alta-profesionales`, frontend)

Build 44 Android (`42f0a8d`) + fix imágenes/Crashlytics (no-fatal, cache
en logout) + build phase de dSYM de Crashlytics para iOS
(`87fca4c`) + guard localhost solo aplica al backend (no toca frontend).
Versión: `1.0.1+44` en `pubspec.yaml` — ya supera el último build de
TestFlight (41), no hace falta tocar el número.

**NO contiene**: comisión por tramos, IVA, facturación, cambios de
Términos.

## Único bloqueador real confirmado: `pod install` sin ejecutar

`ios/Podfile.lock` no tiene NINGÚN pod de Crashlytics (ni
`FirebaseCrashlytics` ni `firebase_crashlytics`) — confirmado con grep,
0 coincidencias en 1633 líneas. Esto es normal (Windows no puede correr
CocoaPods) pero significa que hasta que alguien corra `pod install` en
Mac, la build phase de dSYM añadida en `87fca4c` no tiene qué ejecutar
(el script `${PODS_ROOT}/FirebaseCrashlytics/run` no existirá hasta
entonces).

## Paso 0 — SOLO en Mac/MacinCloud, cuando se autorice

```bash
cd ~/hogarsos-clean   # o donde viva el checkout en el Mac (ver memoria del proyecto)
git fetch origin
git checkout feature/alta-profesionales
git pull

cd ios
pod install
# Verificar en el output que aparece "Installing FirebaseCrashlytics" o
# similar, y que Podfile.lock queda con ese pod tras esto.
grep -i crashlytics Podfile.lock   # debe dejar de estar vacío
```

Abrir `Runner.xcworkspace` (NO `.xcodeproj`) en Xcode y comprobar:

- [ ] El proyecto abre sin errores de "missing file"/"red" en el
      navegador de ficheros.
- [ ] Target Runner → Build Phases → debe aparecer
      **"[Firebase] Upload dSYM to Crashlytics"** como última fase.
- [ ] Seleccionar el scheme Runner, `Product → Build For → Running`
      (o `xcodebuild ... -configuration Release -showBuildSettings`,
      SIN Archive) para confirmar que compila con el pod ya enlazado.
- [ ] Confirmar que Debug sigue sin `CODE_SIGN_ENTITLEMENTS` (no debe
      haber cambiado) y sigue compilando normal.

## Paso 1 — Archive (SOLO con GO explícito, no antes)

```bash
../flutter/bin/flutter build ipa --release --build-number=44
```

(o vía Xcode: Product → Archive). Si el export a IPA falla por el
perfil manual "HogarSOS AppStore Distribution" — problema YA conocido
de builds anteriores (28/40/41) — subir siempre vía Organizer:
`open build/ios/archive/Runner.xcarchive` → Distribute App → App Store
Connect → Upload. No usar `xcodebuild -exportArchive` en este proyecto
(exporta mal el perfil manual, ver memoria de builds anteriores).

## Paso 2 — Verificación post-Archive (antes de subir a TestFlight)

- [ ] El log de Archive no debe mostrar error de firma ni de
      provisioning.
- [ ] Confirmar en el Organizer que el archive incluye el dSYM (Xcode
      lo muestra en la pestaña de symbols/dSYMs del archive).
- [ ] SHA-256 del binario Runner, igual que en builds anteriores (para
      poder verificar después que TestFlight recibió exactamente este
      build).

## Paso 3 — TestFlight (SOLO con GO explícito, no antes)

Subir vía Organizer → Distribute App → App Store Connect → Upload.
Cumplimiento de exportación: "Ninguno de los algoritmos" (mismo patrón
que builds anteriores). Grupo interno con distribución automática.

## Pendiente de probar en dispositivo real (no se puede verificar desde código)

- Phone Auth (login SMS+OTP) — configuración confirmada completa
  (Teléfono habilitado en Firebase, clave APNs de producción subida,
  `aps-environment=production`, REVERSED_CLIENT_ID presente como
  fallback reCAPTCHA), pero la confirmación de una prueba real en
  iPhone con este build concreto no está registrada — probarlo antes de
  pasar a testers externos.
- Deep link de vuelta del onboarding de Stripe Connect (`hogarsos://`).
- Push en primer plano/segundo plano/frío (AppDelegate.swift ya tiene
  el fix de timing documentado, pero conviene una pasada real).
