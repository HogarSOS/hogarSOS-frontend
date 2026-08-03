/// Situación fiscal/legal que el propio profesional declara al enviar
/// su verificación (roadmap económico, punto 4). HogarSOS no la valida
/// ni la determina — solo la registra; ver texto legal en
/// `t.tipoProfesionalTextoLegal`. Enum cerrado a las 3 opciones
/// aprobadas para la versión inicial en España — ampliarlo a futuro
/// solo añade un valor aquí y en el backend, sin tocar el resto del
/// flujo de verificación.
///
/// Vive en su propio archivo (no en professional_service.dart, que lo
/// re-exporta) porque tanto professional_service.dart como
/// professional_summary_model.dart necesitan el tipo — evita un import
/// circular entre ambos.
enum TipoProfesional {
  autonomo,
  empresa,
  personaFisica;

  static TipoProfesional? fromJson(String? valor) {
    switch (valor) {
      case 'autonomo':
        return TipoProfesional.autonomo;
      case 'empresa':
        return TipoProfesional.empresa;
      case 'persona_fisica':
        return TipoProfesional.personaFisica;
      default:
        return null;
    }
  }

  String toJson() {
    switch (this) {
      case TipoProfesional.autonomo:
        return 'autonomo';
      case TipoProfesional.empresa:
        return 'empresa';
      case TipoProfesional.personaFisica:
        return 'persona_fisica';
    }
  }
}
