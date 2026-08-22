import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/tipo_profesional.dart';

/// Selector de tipo profesional "¿Cómo trabajas profesionalmente?" —
/// rediseño 2026-08-22 (aprobado tras revisión adversarial):
///
/// - Las tres opciones son tarjetas SELECCIONABLES con estado visible
///   (borde + icono de check, no solo color), en vez de botones que
///   cerraban el diálogo al instante — eso era la causa del bug de
///   "toco y no pasa nada" y además impedía añadir el checkbox.
/// - "Particular" exige marcar una declaración de responsabilidad para
///   poder continuar. Es una confirmación de lectura/aceptación de su
///   responsabilidad, NO una garantía legal para HogarSOS ni una
///   certificación de hechos del usuario. La casilla nace SIEMPRE
///   desmarcada (también al volver a Particular desde otro tipo): nunca
///   hay consentimiento fantasma, ni herencia entre cuentas (el estado
///   vive solo en este State, que muere con el diálogo).
/// - PENDIENTE (decisión futura, tras revisión jurídica): persistir la
///   aceptación + fecha/hora en backend como evidencia. Hoy es solo un
///   gate de UI, a propósito.
/// - Los valores devueltos (TipoProfesional → autonomo/empresa/
///   persona_fisica) son EXACTAMENTE los mismos que antes: nada cambia
///   de cara al backend.
/// - Gancho para la fase de categorías por tipo (aún NO implementada):
///   el diálogo devuelve la selección explícita vía pop; el llamador la
///   guarda en su estado y el futuro filtro de categorías podrá leerla
///   de ahí sin tocar este selector.
class SelectorTipoProfesional extends StatefulWidget {
  const SelectorTipoProfesional({super.key, this.seleccionInicial});

  /// El tipo ya elegido/persistido, para abrir con esa tarjeta marcada.
  final TipoProfesional? seleccionInicial;

  @override
  State<SelectorTipoProfesional> createState() => _SelectorTipoProfesionalState();
}

class _SelectorTipoProfesionalState extends State<SelectorTipoProfesional> {
  TipoProfesional? _seleccion;
  bool _declaracionAceptada = false;

  @override
  void initState() {
    super.initState();
    _seleccion = widget.seleccionInicial;
  }

  void _seleccionar(TipoProfesional tipo) {
    if (_seleccion == tipo) return;
    setState(() {
      _seleccion = tipo;
      // Cada entrada (o vuelta) a Particular re-consiente desde cero.
      _declaracionAceptada = false;
    });
  }

  /// Confirmar como Particular exige la casilla SIEMPRE (también si ya
  /// venía preseleccionado): continuar es re-confirmar. Cancelar nunca
  /// exige ni guarda nada.
  bool get _puedeContinuar =>
      _seleccion != null && (_seleccion != TipoProfesional.personaFisica || _declaracionAceptada);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(t.tipoProfesionalPregunta),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (tipo, etiqueta, descripcion) in [
              (TipoProfesional.autonomo, t.tipoProfesionalAutonomo, t.tipoProfesionalAutonomoDesc),
              (TipoProfesional.empresa, t.tipoProfesionalEmpresa, t.tipoProfesionalEmpresaDesc),
              (TipoProfesional.personaFisica, t.tipoProfesionalPersonaFisica, t.tipoProfesionalPersonaFisicaDesc),
            ]) ...[
              _TarjetaOpcion(
                etiqueta: etiqueta,
                descripcion: descripcion,
                seleccionada: _seleccion == tipo,
                onTap: () => _seleccionar(tipo),
              ),
              // La declaración vive pegada a la tarjeta de Particular,
              // solo cuando está seleccionada — desaparece al cambiar
              // de tipo y reaparece desmarcada al volver.
              if (tipo == TipoProfesional.personaFisica && _seleccion == TipoProfesional.personaFisica)
                _FilaDeclaracion(
                  aceptada: _declaracionAceptada,
                  onCambiar: (valor) => setState(() => _declaracionAceptada = valor),
                ),
              const SizedBox(height: 8),
            ],
            // Aviso general para los TRES tipos (clave independiente de
            // l10n, editable sin tocar lógica). No se añade un segundo
            // texto legal para Particular: su elemento específico es la
            // declaración de arriba — sin duplicar avisos.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                t.tipoProfesionalAvisoLegal,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.35),
              ),
            ),
            const SizedBox(height: 14),
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
                    onPressed: _puedeContinuar ? () => Navigator.of(context).pop(_seleccion) : null,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Text(t.altaBotonContinuar),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta grande seleccionable — estado marcado con borde + icono de
/// check (no solo color), zona táctil de tarjeta completa (≥64dp).
class _TarjetaOpcion extends StatelessWidget {
  const _TarjetaOpcion({
    required this.etiqueta,
    required this.descripcion,
    required this.seleccionada,
    required this.onTap,
  });

  final String etiqueta;
  final String descripcion;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: seleccionada ? colorScheme.primary.withOpacity(0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: seleccionada ? colorScheme.primary : colorScheme.outlineVariant,
              width: seleccionada ? 2 : 1,
            ),
          ),
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                    const SizedBox(height: 2),
                    Text(
                      descripcion,
                      style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                seleccionada ? Icons.check_circle : Icons.radio_button_unchecked,
                color: seleccionada ? colorScheme.primary : colorScheme.outline,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila del checkbox de Particular: fila COMPLETA pulsable, ≥48dp,
/// texto a tamaño legible (13) — pensada para personas mayores.
class _FilaDeclaracion extends StatelessWidget {
  const _FilaDeclaracion({required this.aceptada, required this.onCambiar});

  final bool aceptada;
  final ValueChanged<bool> onCambiar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => onCambiar(!aceptada),
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: aceptada,
                    onChanged: (valor) => onCambiar(valor ?? false),
                  ),
                  Expanded(
                    child: Text(
                      t.tipoProfesionalDeclaracionParticular,
                      style: const TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
