# Capturas de pantalla — Google Play

8 capturas reales, tomadas en el dispositivo de pruebas (Realme RMX3853) sobre una sesión end-to-end real: cliente Ana Sánchez publicando una solicitud de aire acondicionado, José Fernández (profesional verificado, Electricista + Aire acondicionado) postulándose, siendo elegido, enviando presupuesto y el cliente aceptándolo con el desglose de comisión visible.

1. **01_cliente_inicio.jpg** — Inicio del cliente: categorías y "Mis solicitudes".
2. **02_mapa_ubicacion.jpg** — Selector de ubicación con Google Maps renderizando correctamente.
3. **03_perfil_profesional.jpg** — Perfil de un profesional verificado (5.0 ★, categorías).
4. **04_panel_profesional_solicitudes.jpg** — Panel del profesional: solicitudes cercanas cerca + candidaturas.
5. **05_elegir_profesional.jpg** — El cliente elige entre las candidaturas recibidas.
6. **06_trabajos_activos_comision.jpg** — Trabajos activos con desglose de comisión y distintivo "Promoción de lanzamiento".
7. **07_presupuesto_recibido.jpg** — El cliente recibe el presupuesto con el desglose completo antes de pagar.
8. **08_login_email_telefono.jpg** — Pantalla de acceso con el nuevo toggle Email/Teléfono (registro/login alternativo por SMS).

## Nota de calidad

Las originales se compartieron por WhatsApp, que recomprime y reencuentra las imágenes — se recortaron de 931×2048 a 931×1862 (relación 2:1 exacta) porque Play Console **rechaza capturas con una relación de aspecto mayor a 2:1**, y el recorte simétrico (arriba/abajo) no afecta a ningún contenido, solo a franjas de la barra de estado y del margen inferior. Si más adelante se quiere mejor calidad (sin la recompresión de WhatsApp), se pueden volver a sacar directamente del móvil con `adb pull` (ver `project-hogarsos-dev-environment` en memoria) — el contenido sería el mismo, solo cambiaría la nitidez.
