# hogarSOS — app (Flutter)

App cliente/profesional de hogarSOS, marketplace de servicios a domicilio
(electricista, fontanero, cerrajero, pintor, limpieza...). Este repositorio
contiene solo el frontend; el backend (API Node.js/Express/Prisma) vive en
su propio repositorio independiente.

## Arranque rápido

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://TU_IP_LOCAL:3000/api \
            --dart-define=STRIPE_PUBLISHABLE_KEY=pk_...
```

Ver `lib/services/api_service.dart` para las distintas URLs según dónde se
esté probando (emulador Android, simulador iOS, móvil físico).

## Stack

- Flutter + Riverpod (estado)
- Firebase Auth + Cloud Firestore (login y chat en tiempo real)
- Dio (cliente HTTP hacia el backend propio)
- Stripe (Payment Sheet, modelo escrow)
- google_fonts (tipografía de marca, Plus Jakarta Sans)

## Identidad visual (Sprint 1)

La marca completa vive en `lib/theme/`:

- `brand_colors.dart` — paleta (azul de confianza + coral de acento).
- `brand_mark.dart` — logo dibujado con `CustomPainter` (`HogarSosMark`,
  `HogarSosWordmark`, `HogarSosLogo`, `HogarSosLogoVertical`), sin
  dependencias de imágenes.
- `app_theme.dart` — esquema de color Material 3 + tipografía + tema de
  cada componente (botones, tarjetas, inputs, navegación...).

Los recursos vectoriales de marca (icono, logotipo horizontal/vertical, en
claro y oscuro) están en `assets/branding/*.svg`. Los iconos reales de la
app (launcher de Android/iOS, favicon, iconos PWA) se generaron a partir de
esa misma geometría — ver el histórico de commits para el script usado.

## Estructura

```
lib/
├── screens/       # cliente/, profesional/, admin/, auth/
├── widgets/        # componentes reutilizables
├── models/         # modelos de datos del cliente
├── services/        # cliente HTTP + Firebase + Stripe
├── providers/        # estado (Riverpod)
├── theme/             # identidad visual
└── l10n/               # es/en
```
