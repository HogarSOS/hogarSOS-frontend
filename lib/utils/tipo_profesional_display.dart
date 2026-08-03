import '../l10n/app_localizations.dart';
import '../models/tipo_profesional.dart';

/// Etiqueta legible del tipo de profesional (Empresa/Autónomo/Persona
/// física) — mismo texto tanto en el selector de "Mi perfil" (roadmap
/// económico punto 4) como en el distintivo que ve el cliente.
String etiquetaTipoProfesional(AppLocalizations t, TipoProfesional tipo) {
  switch (tipo) {
    case TipoProfesional.autonomo:
      return t.tipoProfesionalAutonomo;
    case TipoProfesional.empresa:
      return t.tipoProfesionalEmpresa;
    case TipoProfesional.personaFisica:
      return t.tipoProfesionalPersonaFisica;
  }
}
