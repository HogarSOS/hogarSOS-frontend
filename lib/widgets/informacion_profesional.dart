import 'package:flutter/material.dart';
import '../config/soporte.dart';
import '../l10n/app_localizations.dart';
import 'soporte_sheet.dart';

/// Sección "Información profesional" (simplificación de Mi perfil,
/// 2026-08-22): descripción + teléfono + precio por hora dejan de ser
/// tres bloques sueltos y se editan juntos en una única hoja. En la
/// pantalla principal solo queda visible la DESCRIPCIÓN (resumida a 2
/// líneas) porque es el único de los tres datos que el cliente ve.
///
/// Los tres campos siguen siendo independientes y estructurados — nunca
/// se mezclan en el texto libre — y cada uno conserva su endpoint:
/// teléfono → PATCH /users/me; descripción y tarifa →
/// PATCH /professionals/me/profile. El guardado envía SOLO lo que
/// cambió y, si un endpoint falla, el mensaje dice exactamente qué se
/// guardó y qué no (ver componerMensajeGuardadoInfoProfesional).

/// Detección de datos de contacto externo en la DESCRIPCIÓN pública
/// (ajuste 2026-08-22): la ve el cliente antes de contratar — sin
/// teléfonos, WhatsApp/Telegram ni emails; la comunicación va por la
/// mensajería de HogarSOS. El campo Teléfono del editor NO pasa por
/// aquí (es interno y legítimo). Réplica exacta del criterio del
/// backend (utils/descripcionSinContacto.ts), que es quien impide el
/// bypass por API — esto solo da el feedback inmediato.
bool contieneContactoExterno(String texto) {
  final normalizado = texto.toLowerCase();

  if (RegExp(r'(whats\s?app|wasap|guasap|telegram|t\.me/|wa\.me/)').hasMatch(normalizado)) return true;
  if (RegExp(r'[\w.+-]+@[\w-]+\.[a-z]{2,}').hasMatch(normalizado)) return true;

  final compacto = texto.replaceAll(RegExp(r'[\s.\-()]'), '');
  return RegExp(r'\+?\d{7,}').hasMatch(compacto);
}

/// Lo que el usuario dejó escrito al pulsar Guardar en la hoja.
class InformacionProfesionalResultado {
  const InformacionProfesionalResultado({
    required this.descripcion,
    required this.telefono,
    required this.tarifa,
  });

  final String descripcion;
  final String telefono;

  /// null cuando el campo quedó vacío (= sin cambio; la tarifa es
  /// opcional pero el backend no admite "borrarla", solo actualizarla).
  final double? tarifa;
}

/// Qué hay que mandar a cada endpoint. Campo vacío = sin cambio —
/// misma semántica que tenían los diálogos individuales de antes
/// (dejar la descripción en blanco nunca borraba la existente).
class PlanGuardadoInfoProfesional {
  const PlanGuardadoInfoProfesional({
    required this.guardarDescripcion,
    required this.guardarTelefono,
    required this.guardarTarifa,
  });

  final bool guardarDescripcion;
  final bool guardarTelefono;
  final bool guardarTarifa;

  bool get guardarDatosProfesionales => guardarDescripcion || guardarTarifa;
  bool get hayCambios => guardarDescripcion || guardarTelefono || guardarTarifa;
}

PlanGuardadoInfoProfesional planGuardadoInfoProfesional({
  required String descripcionActual,
  required String telefonoActual,
  required double tarifaActual,
  required InformacionProfesionalResultado resultado,
}) {
  final descripcion = resultado.descripcion.trim();
  final telefono = resultado.telefono.trim();

  return PlanGuardadoInfoProfesional(
    guardarDescripcion: descripcion.isNotEmpty && descripcion != descripcionActual.trim(),
    guardarTelefono: telefono.isNotEmpty && telefono != telefonoActual.trim(),
    guardarTarifa: resultado.tarifa != null && resultado.tarifa != tarifaActual,
  );
}

/// Mensaje del resultado del guardado. Regla fijada en la revisión
/// adversarial: si un endpoint falla, decir EXACTAMENTE qué no se pudo
/// guardar — jamás un error genérico que haga creer que se perdió todo.
/// Devuelve null cuando todo fue bien (el llamador muestra su éxito).
String? componerMensajeGuardadoInfoProfesional({
  required bool intentoDatos,
  required bool okDatos,
  required bool intentoTelefono,
  required bool okTelefono,
  required String falloDatos,
  required String falloTelefono,
  required String restoGuardado,
}) {
  final falloEnDatos = intentoDatos && !okDatos;
  final falloEnTelefono = intentoTelefono && !okTelefono;

  if (!falloEnDatos && !falloEnTelefono) return null;
  if (falloEnDatos && falloEnTelefono) return '$falloDatos $falloTelefono';

  final fallo = falloEnDatos ? falloDatos : falloTelefono;
  final otroGuardado = falloEnDatos ? (intentoTelefono && okTelefono) : (intentoDatos && okDatos);
  return otroGuardado ? '$fallo $restoGuardado' : fallo;
}

/// Contenido visible de la sección en Mi perfil: el resumen de la
/// descripción (máx. 2 líneas) o la llamada a completarla. Público y en
/// su propio widget para poder testearlo sin montar la pantalla entera.
class DescripcionResumen extends StatelessWidget {
  const DescripcionResumen({super.key, required this.descripcion});

  final String descripcion;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final tieneDescripcion = descripcion.trim().isNotEmpty;

    return Text(
      tieneDescripcion ? descripcion : t.infoProfDescripcionCta,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14.5,
        height: 1.4,
        color: tieneDescripcion ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Resumen compacto de la sección "Información profesional" en Mi
/// perfil (ajuste 2026-08-22): cuatro filas de una línea. El teléfono
/// aparece SIN el número (solo uso interno de HogarSOS — el número se
/// ve únicamente dentro del editor y el cliente jamás lo recibe, con
/// test de backend que lo fija). El tipo profesional sí es público.
class InformacionProfesionalResumen extends StatelessWidget {
  const InformacionProfesionalResumen({
    super.key,
    required this.tipoEtiqueta,
    required this.descripcion,
    required this.tarifaBase,
  });

  /// Etiqueta legible del tipo (Autónomo/Empresa/Particular) o null.
  final String? tipoEtiqueta;
  final String descripcion;
  final double tarifaBase;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    Widget fila(String etiqueta, String valor, {bool atenuado = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$etiqueta: ',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant),
            ),
            Expanded(
              child: Text(
                valor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.3,
                  color: atenuado ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final tieneDescripcion = descripcion.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fila(t.infoProfComoTrabajas, tipoEtiqueta ?? t.infoProfSinIndicar, atenuado: tipoEtiqueta == null),
        fila(
          t.miPerfilDescripcionLabel,
          tieneDescripcion ? descripcion : t.infoProfDescripcionCta,
          atenuado: !tieneDescripcion,
        ),
        // Sin el número, a propósito.
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            t.infoProfTelefonoResumen,
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
        ),
        fila(
          t.infoProfPrecio,
          tarifaBase > 0 ? '${tarifaBase.toStringAsFixed(2)} €/h' : t.infoProfPrecioOpcional,
          atenuado: tarifaBase <= 0,
        ),
      ],
    );
  }
}

/// Hoja de edición "Información profesional" — tres campos
/// independientes con sus validaciones de siempre. Solo recoge valores
/// y valida en local; el guardado (y sus dos endpoints) es del llamador.
class EditorInformacionProfesional extends StatefulWidget {
  const EditorInformacionProfesional({
    super.key,
    required this.descripcionInicial,
    required this.telefonoInicial,
    required this.tarifaInicial,
    this.tipoEtiqueta,
    this.tipoBloqueado = false,
  });

  final String descripcionInicial;
  final String telefonoInicial;

  /// null = sin tarifa establecida.
  final double? tarifaInicial;

  /// Etiqueta legible del tipo profesional actual (Autónomo/Empresa/
  /// Particular) — SOLO informativa: el tipo se elige durante el alta
  /// desde el wizard, no desde este editor.
  final String? tipoEtiqueta;

  /// true cuando el profesional ya está aprobado con Stripe operativa:
  /// el tipo queda fijado (el business_type de la cuenta Connect no
  /// puede seguir a un cambio) y se muestra la vía de soporte.
  final bool tipoBloqueado;

  @override
  State<EditorInformacionProfesional> createState() => _EditorInformacionProfesionalState();
}

class _EditorInformacionProfesionalState extends State<EditorInformacionProfesional> {
  late final TextEditingController _descripcionController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _tarifaController;
  String? _errorTarifa;
  String? _errorDescripcion;

  @override
  void initState() {
    super.initState();
    _descripcionController = TextEditingController(text: widget.descripcionInicial);
    _telefonoController = TextEditingController(text: widget.telefonoInicial);
    _tarifaController = TextEditingController(
      text: widget.tarifaInicial != null ? widget.tarifaInicial!.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _telefonoController.dispose();
    _tarifaController.dispose();
    super.dispose();
  }

  void _guardar() {
    final t = AppLocalizations.of(context);

    // La descripción es pública: sin teléfonos ni contactos externos.
    // Error en línea, sin borrar el texto — el usuario corrige y sigue.
    final descripcion = _descripcionController.text.trim();
    if (descripcion.isNotEmpty && contieneContactoExterno(descripcion)) {
      setState(() => _errorDescripcion = t.infoProfDescripcionContactoError);
      return;
    }

    // Tarifa: opcional, pero si se escribe algo tiene que ser un número
    // positivo (misma validación que tenía su diálogo individual).
    final tarifaTexto = _tarifaController.text.trim().replaceAll(',', '.');
    double? tarifa;
    if (tarifaTexto.isNotEmpty) {
      tarifa = double.tryParse(tarifaTexto);
      if (tarifa == null || tarifa <= 0) {
        setState(() => _errorTarifa = t.miPerfilVerificacionErrorFaltaTarifa);
        return;
      }
    }

    Navigator.of(context).pop(InformacionProfesionalResultado(
      descripcion: _descripcionController.text.trim(),
      telefono: _telefonoController.text.trim(),
      tarifa: tarifa,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        // Mismo patrón que _EditorCategoriasSheet: con el teclado abierto
        // el contenido debe subir, no quedar tapado.
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.infoProfTitulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              // "Cómo trabajas" — SOLO informativo aquí: durante el alta
              // se elige desde el wizard; una vez aprobado con Stripe
              // operativa queda fijado (la cuenta Connect no puede
              // seguir a un cambio de tipo) y el camino es soporte.
              if (widget.tipoEtiqueta != null || widget.tipoBloqueado) ...[
                Row(
                  children: [
                    Text(
                      '${t.infoProfComoTrabajas}: ',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    Expanded(
                      child: Text(
                        widget.tipoEtiqueta ?? t.infoProfSinIndicar,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (widget.tipoBloqueado) ...[
                  const SizedBox(height: 2),
                  // Acción real, no un callejón sin salida (auditoría de
                  // soporte 2026-08-22): abre el centro de ayuda con el
                  // contexto ya preparado — el usuario no tiene que ir a
                  // buscar el soporte a mano. Fila completa pulsable.
                  InkWell(
                    onTap: () => mostrarSoporte(context, contexto: ContextoSoporte.tipoProfesional),
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 40),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.tipoProfesionalCambioSoporte,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _descripcionController,
                maxLines: 4,
                maxLength: 250,
                onChanged: (_) {
                  if (_errorDescripcion != null) setState(() => _errorDescripcion = null);
                },
                decoration: InputDecoration(
                  labelText: t.miPerfilDescripcionLabel,
                  errorText: _errorDescripcion,
                  errorMaxLines: 3,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: t.editarPerfilTelefono,
                  // La nota "uso interno" vive AQUÍ (decisión de la
                  // revisión adversarial): es donde el profesional
                  // piensa en el dato — en la pantalla principal ya no
                  // ocupa una línea permanente.
                  helperText: t.miPerfilTelefonoAyudaInterno,
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tarifaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) {
                  if (_errorTarifa != null) setState(() => _errorTarifa = null);
                },
                decoration: InputDecoration(
                  labelText: t.miPerfilPrecioLabel,
                  helperText: t.miPerfilPrecioAyuda,
                  helperMaxLines: 3,
                  errorText: _errorTarifa,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(t.perfilCancelar),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _guardar,
                      child: Text(t.miPerfilGuardar),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
