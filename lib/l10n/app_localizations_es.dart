// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'hogarSOS';

  @override
  String get navInicio => 'Inicio';

  @override
  String get navBuscar => 'Buscar';

  @override
  String get navMensajes => 'Mensajes';

  @override
  String get navPerfil => 'Perfil';

  @override
  String get navDisponibilidad => 'Disponibilidad';

  @override
  String get loginTagline => 'Servicios a domicilio de confianza';

  @override
  String get loginFieldNombre => 'Nombre completo';

  @override
  String get loginFieldEmail => 'Email';

  @override
  String get loginFieldPassword => 'Contraseña';

  @override
  String get loginRecordarSesion => 'Mantener sesión iniciada';

  @override
  String get loginRoleCliente => 'Cliente';

  @override
  String get loginRoleProfesional => 'Profesional';

  @override
  String get loginBtnCrearCuenta => 'Crear cuenta';

  @override
  String get loginBtnIniciarSesion => 'Iniciar sesión';

  @override
  String get loginLinkYaTienesCuenta => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get loginLinkNoTienesCuenta => '¿No tienes cuenta? Regístrate';

  @override
  String get loginOlvidasteContrasena => '¿Olvidaste tu contraseña?';

  @override
  String get loginCamposObligatorios => 'Rellena todos los campos';

  @override
  String get loginRecuperarTitulo => 'Recuperar contraseña';

  @override
  String get loginRecuperarEnviar => 'Enviar enlace';

  @override
  String get loginRecuperarExito =>
      'Si existe una cuenta con ese email, te hemos enviado un enlace para restablecer la contraseña';

  @override
  String get errorConexion =>
      'No se pudo conectar con el servidor. Comprueba tu conexión.';

  @override
  String get errorServidorLento => 'El servidor tardó demasiado en responder.';

  @override
  String get errorInesperado => 'Ocurrió un error inesperado.';

  @override
  String homeSaludo(String nombre) {
    return 'Hola, $nombre 👋';
  }

  @override
  String get homeSaludoGenerico => 'Hola 👋';

  @override
  String homeSaludoManana(String nombre) {
    return 'Buenos días, $nombre ☀️';
  }

  @override
  String homeSaludoTarde(String nombre) {
    return 'Buenas tardes, $nombre 👋';
  }

  @override
  String homeSaludoNoche(String nombre) {
    return 'Buenas noches, $nombre 🌙';
  }

  @override
  String get homeAccesoBuscar => 'Buscar';

  @override
  String get homeAccesoMisSolicitudes => 'Mis solicitudes';

  @override
  String get homeAccesoFavoritos => 'Favoritos';

  @override
  String homeResumenActivas(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: 'solicitudes activas',
      one: 'solicitud activa',
    );
    return 'Tienes $cantidad $_temp0';
  }

  @override
  String get homeSubtitulo => '¿Qué necesitas arreglar hoy?';

  @override
  String get homeBuscarPlaceholder => 'Busca un profesional o servicio...';

  @override
  String get homeCategoriasTitulo => 'Categorías';

  @override
  String get homeCategoriasError => 'No se pudieron cargar las categorías';

  @override
  String get homeSolicitarProfesional => '📢 Solicitar un profesional';

  @override
  String get homeSolicitarProfesionalAyuda =>
      'Cuéntanos qué necesitas y te ponemos en contacto';

  @override
  String get homeDescribeProblema => 'Describe el problema';

  @override
  String get homeErrorDescribe => 'Describe brevemente el problema';

  @override
  String get homeErrorUbicacion =>
      'Necesitamos tu ubicación para buscar profesionales cerca';

  @override
  String get homeErrorCrearSolicitud =>
      'No se pudo crear la solicitud. Inténtalo de nuevo.';

  @override
  String get homeBtnBuscarProfesionales => 'Buscar profesionales';

  @override
  String homeSolicitudCreada(String id) {
    return 'Solicitud creada (#$id)';
  }

  @override
  String get homeBusquedaProximamente =>
      'Búsqueda con filtros: disponible en la próxima fase';

  @override
  String get perfilCerrarSesion => 'Cerrar sesión';

  @override
  String get perfilRolCliente => 'Cliente';

  @override
  String get perfilRolProfesional => 'Profesional';

  @override
  String get perfilRolAdmin => 'Administrador';

  @override
  String get perfilMiembroDesde => 'Miembro de hogarSOS';

  @override
  String get perfilConfirmarSalir => '¿Seguro que quieres cerrar sesión?';

  @override
  String get perfilCancelar => 'Cancelar';

  @override
  String get perfilFavoritos => 'Favoritos';

  @override
  String get perfilMisSolicitudes => 'Mis solicitudes';

  @override
  String get perfilConfiguracion => 'Configuración';

  @override
  String get proximamenteTitulo => 'Próximamente';

  @override
  String get buscarProximamenteDescripcion =>
      'La búsqueda avanzada con filtros por precio, distancia y valoración llega en la próxima fase.';

  @override
  String get mensajesProximamenteDescripcion =>
      'Aquí verás todas tus conversaciones con clientes y profesionales.';

  @override
  String get mensajesVacioTitulo => 'Sin conversaciones todavía';

  @override
  String get buscarHint => 'Busca por nombre...';

  @override
  String get buscarFiltros => 'Filtros';

  @override
  String get buscarTodasCategorias => 'Todas';

  @override
  String get buscarSinResultadosTitulo => 'No se encontraron profesionales';

  @override
  String get buscarSinResultadosDescripcion =>
      'Prueba a cambiar los filtros o la búsqueda';

  @override
  String get buscarErrorTitulo => 'No se pudo completar la búsqueda';

  @override
  String buscarDesde(String precio) {
    return 'Desde $precio €';
  }

  @override
  String buscarTrabajos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'trabajos',
      one: 'trabajo',
    );
    return '$n $_temp0';
  }

  @override
  String get buscarDisponibleAhora => 'Disponible ahora';

  @override
  String get buscarNoDisponible => 'No disponible';

  @override
  String get buscarUrgente => 'Urgente';

  @override
  String get buscarUrgenteTitulo => '¿Qué necesitas con urgencia?';

  @override
  String get filtroValoracionMinima => 'Valoración mínima';

  @override
  String get filtroPrecioMaximo => 'Precio máximo';

  @override
  String get filtroDistanciaMaxima => 'Distancia máxima';

  @override
  String get filtroLimpiar => 'Limpiar';

  @override
  String get filtroAplicar => 'Aplicar filtros';

  @override
  String get filtroCualquiera => 'Cualquiera';

  @override
  String get filtroSoloDisponibles => 'Disponible ahora';

  @override
  String get perfilProOpinionesTitulo => 'Opiniones';

  @override
  String opinionesTotal(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'valoraciones',
      one: 'valoración',
    );
    return '$n $_temp0';
  }

  @override
  String get misValoracionesTitulo => 'Mis valoraciones';

  @override
  String get misValoracionesError => 'No se pudieron cargar tus valoraciones';

  @override
  String get perfilProSinOpiniones => 'Aún no tiene opiniones';

  @override
  String get perfilProGaleriaTitulo => 'Galería de trabajos';

  @override
  String get perfilProSinGaleria =>
      'Este profesional aún no ha subido fotos de sus trabajos';

  @override
  String get perfilProServiciosTitulo => 'Servicios que ofrece';

  @override
  String get perfilProSolicitarBtn => 'Solicitar este servicio';

  @override
  String get perfilProCargandoError => 'No se pudo cargar el perfil';

  @override
  String get perfilProSolicitarInfo =>
      'De momento, las solicitudes se envían a los profesionales disponibles cerca de ti desde Inicio, no a uno concreto todavía';

  @override
  String get categoriaElectricista => 'Electricista';

  @override
  String get categoriaFontanero => 'Fontanero';

  @override
  String get categoriaPintor => 'Pintor';

  @override
  String get categoriaManitas => 'Manitas';

  @override
  String get categoriaLimpieza => 'Limpieza';

  @override
  String get categoriaJardineria => 'Jardinería';

  @override
  String get categoriaCerrajeria => 'Cerrajería';

  @override
  String get categoriaReformas => 'Reformas';

  @override
  String get categoriaAireAcondicionado => 'Aire acondicionado y climatización';

  @override
  String get categoriaCarpinteria => 'Carpintería';

  @override
  String get categoriaAlbanileria => 'Albañilería';

  @override
  String get categoriaTejados => 'Tejados y cubiertas';

  @override
  String get categoriaCristaleria => 'Cristalería';

  @override
  String get categoriaCarpinteriaMetalica =>
      'Carpintería metálica / Aluminio y PVC';

  @override
  String get categoriaAntenas => 'Antenas y telecomunicaciones';

  @override
  String get categoriaSeguridad => 'Sistemas de seguridad';

  @override
  String get categoriaMudanzas => 'Mudanzas';

  @override
  String get categoriaLimpiezaCristales => 'Limpieza de cristales';

  @override
  String get categoriaPiscinas => 'Piscinas';

  @override
  String get categoriaControlPlagas => 'Control de plagas';

  @override
  String get categoriaVeterinaria => 'Veterinaria a domicilio';

  @override
  String get wizardEjemploGenerico =>
      'Ej: se ha roto una tubería bajo el fregadero y hay una fuga...';

  @override
  String get wizardEjemploElectricista =>
      'Ej: ha saltado el diferencial y no puedo volver a subirlo...';

  @override
  String get wizardEjemploFontanero =>
      'Ej: tengo una fuga debajo del fregadero...';

  @override
  String get wizardEjemploPintor => 'Ej: quiero pintar el salón, unos 20 m²...';

  @override
  String get wizardEjemploManitas => 'Ej: necesito montar unas estanterías...';

  @override
  String get wizardEjemploLimpieza =>
      'Ej: necesito una limpieza completa de un piso...';

  @override
  String get wizardEjemploJardineria =>
      'Ej: necesito podar el seto y cortar el césped...';

  @override
  String get wizardEjemploCerrajeria =>
      'Ej: he perdido las llaves y no puedo entrar en casa...';

  @override
  String get wizardEjemploReformas => 'Ej: quiero reformar el baño completo...';

  @override
  String get wizardEjemploAireAcondicionado =>
      'Ej: el aire acondicionado no enfría...';

  @override
  String get wizardEjemploCarpinteria =>
      'Ej: necesito una puerta de armario a medida...';

  @override
  String get wizardEjemploAlbanileria =>
      'Ej: tengo una grieta en la pared del salón...';

  @override
  String get wizardEjemploTejados => 'Ej: tengo una gotera en el tejado...';

  @override
  String get wizardEjemploCristaleria =>
      'Ej: se ha roto el cristal de una ventana...';

  @override
  String get wizardEjemploCarpinteriaMetalica =>
      'Ej: necesito reparar una persiana metálica...';

  @override
  String get wizardEjemploAntenas =>
      'Ej: no tengo señal de antena en el televisor...';

  @override
  String get wizardEjemploSeguridad =>
      'Ej: quiero instalar una alarma en casa...';

  @override
  String get wizardEjemploMudanzas =>
      'Ej: necesito ayuda para mudarme a un piso de 2 habitaciones...';

  @override
  String get wizardEjemploLimpiezaCristales =>
      'Ej: necesito limpiar los cristales de un tercer piso...';

  @override
  String get wizardEjemploPiscinas => 'Ej: mi piscina tiene el agua verde...';

  @override
  String get wizardEjemploControlPlagas =>
      'Ej: tengo cucarachas en la cocina...';

  @override
  String get wizardEjemploVeterinaria =>
      'Ej: mi perro necesita una revisión a domicilio...';

  @override
  String get profesionalTituloSolicitudes => 'Solicitudes cerca de ti';

  @override
  String get salirPulsaOtraVez => 'Pulsa atrás otra vez para salir';

  @override
  String get profesionalSinSolicitudes =>
      'No hay solicitudes cerca ahora mismo';

  @override
  String get profesionalErrorCargar => 'No se pudieron cargar las solicitudes';

  @override
  String get profesionalIgnorar => 'Ignorar';

  @override
  String get profesionalAceptar => 'Aceptar';

  @override
  String get profesionalSolicitudAceptada =>
      'Solicitud aceptada. El cliente autorizará el pago.';

  @override
  String get profesionalYaNoDisponible =>
      'No se pudo aceptar — puede que ya no esté disponible';

  @override
  String profesionalDistanciaKm(String km) {
    return 'A $km km';
  }

  @override
  String profesionalTrabajosActivos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'trabajos activos',
      one: 'trabajo activo',
    );
    return 'Tienes $n $_temp0';
  }

  @override
  String get trabajosActivosTitulo => 'Trabajos activos';

  @override
  String get trabajosActivosVacio => 'No tienes trabajos activos ahora mismo';

  @override
  String get trabajosActivosErrorCargar => 'No se pudieron cargar tus trabajos';

  @override
  String get trabajosActivosChat => 'Chat';

  @override
  String get trabajosActivosCompletar => 'Marcar como completado';

  @override
  String get trabajosActivosPrecioFinalTitulo => 'Precio final del servicio';

  @override
  String get trabajosActivosPrecioFinalHint => 'Precio (€)';

  @override
  String get trabajosActivosPrecioFinalConfirmar => 'Confirmar';

  @override
  String get trabajosActivosCompletadoExito =>
      'Servicio marcado como completado';

  @override
  String get trabajosActivosCompletadoError =>
      'No se pudo completar el servicio';

  @override
  String get profesionalErrorDisponibilidad =>
      'No se pudo actualizar tu disponibilidad';

  @override
  String get profesionalDisponibleAyuda =>
      'Recibirás solicitudes cercanas a tu ubicación';

  @override
  String get profesionalNoDisponibleAyuda =>
      'Actívalo para empezar a recibir trabajos';

  @override
  String get disponibilidadTitulo => 'Disponibilidad';

  @override
  String get disponibilidadEnLineaTitulo => 'Estado actual';

  @override
  String get disponibilidadModoTitulo => 'Modo de disponibilidad';

  @override
  String get disponibilidadModoAyuda =>
      'Elige cuándo quieres recibir solicitudes. Podrás cambiarlo cuando quieras.';

  @override
  String get disponibilidadModoHorarioLaboral =>
      'Disponible en horario laboral';

  @override
  String get disponibilidadModoHorarioLaboralAyuda =>
      'Recibes solicitudes en tu horario habitual de trabajo';

  @override
  String get disponibilidadModo24h => 'Servicio 24 horas';

  @override
  String get disponibilidadModo24hAyuda =>
      'Recibes solicitudes a cualquier hora, día y noche';

  @override
  String get disponibilidadModoActualizado =>
      'Modo de disponibilidad actualizado';

  @override
  String get disponibilidadModoError =>
      'No se pudo actualizar el modo de disponibilidad';

  @override
  String get disponibilidadPerfilIncompleto =>
      'Completa tu perfil (foto y al menos una categoría) antes de activarte — así te podrán encontrar los clientes.';

  @override
  String get disponibilidadPendienteVerificacion =>
      'Tu cuenta está pendiente de revisión por un administrador. Podrás activarte en cuanto se apruebe.';

  @override
  String get disponibilidadCompletarPerfil => 'Completar perfil';

  @override
  String get disponibilidadEstadoTitulo => 'Tu disponibilidad';

  @override
  String get disponibilidadEstadoAyuda =>
      'Elige un único estado — determina si y cuándo recibes solicitudes.';

  @override
  String get disponibilidadOpcionNoDisponibleTitulo => 'No disponible';

  @override
  String get disponibilidadOpcionNoDisponibleAyuda =>
      'No recibirás solicitudes nuevas';

  @override
  String get seguimientoTitulo => 'Tu solicitud';

  @override
  String get seguimientoError => 'No se pudo cargar la solicitud';

  @override
  String get seguimientoBuscando => 'Buscando un profesional cerca de ti...';

  @override
  String get seguimientoAceptada => '¡Un profesional ha aceptado tu solicitud!';

  @override
  String get seguimientoEnProgreso =>
      'El profesional está trabajando en tu solicitud';

  @override
  String get seguimientoCompletada => 'Servicio completado';

  @override
  String get seguimientoCancelada => 'Solicitud cancelada';

  @override
  String get seguimientoCancelarTitulo => 'Cancelar solicitud';

  @override
  String get seguimientoCancelarConfirmar =>
      '¿Seguro que quieres cancelar esta solicitud? Esta acción no se puede deshacer.';

  @override
  String get seguimientoCancelarExito => 'Solicitud cancelada correctamente';

  @override
  String get seguimientoCancelarError => 'No se pudo cancelar la solicitud';

  @override
  String get seguimientoDisputada =>
      'En revisión por nuestro equipo de soporte';

  @override
  String get seguimientoAbrirChat => 'Abrir chat';

  @override
  String get editarPerfilTitulo => 'Editar perfil';

  @override
  String get editarPerfilTelefono => 'Teléfono';

  @override
  String get perfilEditar => 'Editar perfil';

  @override
  String get miPerfilTitulo => 'Mi perfil';

  @override
  String get miPerfilIncompletoTitulo => 'Completa tu perfil';

  @override
  String get miPerfilIncompletoAyuda =>
      'No aparecerás en las búsquedas de clientes hasta que añadas:';

  @override
  String get miPerfilFaltaFoto => 'una foto de perfil';

  @override
  String get miPerfilFaltaCategoria => 'al menos una categoría';

  @override
  String get miPerfilCambiarFoto => 'Cambiar foto';

  @override
  String get miPerfilOficio => 'Oficio principal';

  @override
  String get miPerfilOficioSinAsignar => 'Aún sin categoría asignada';

  @override
  String get miPerfilDescripcionLabel => 'Descripción';

  @override
  String get miPerfilDescripcionAyuda => 'Máximo 250 caracteres';

  @override
  String get miPerfilPrecioLabel => 'Precio por hora (€)';

  @override
  String get miPerfilDisponible => 'Disponible';

  @override
  String get miPerfilGuardar => 'Guardar cambios';

  @override
  String get miPerfilExito => 'Perfil actualizado correctamente';

  @override
  String get miPerfilErrorGuardar => 'No se pudieron guardar los cambios';

  @override
  String get miPerfilErrorCargar => 'No se pudo cargar tu perfil';

  @override
  String get miPerfilVerificacionTitulo => 'Verificación';

  @override
  String get miPerfilVerificacionEstadoAprobado =>
      'Verificado — ya puedes aceptar trabajos.';

  @override
  String get miPerfilVerificacionEstadoPendiente =>
      'En revisión. Te avisaremos cuando un administrador la apruebe.';

  @override
  String get miPerfilVerificacionEstadoRechazado =>
      'Verificación rechazada. Corrige el documento o la tarifa y vuelve a enviarla.';

  @override
  String get miPerfilVerificacionEstadoSinEnviar =>
      'Aún no has enviado tu documento de identidad — sin esto no podrás aceptar trabajos.';

  @override
  String get miPerfilDocumentoIdentidadLabel => 'Documento de identidad';

  @override
  String get miPerfilDocumentoSeleccionar => 'Seleccionar documento';

  @override
  String get miPerfilEnviarVerificacion => 'Enviar a verificación';

  @override
  String get miPerfilVerificacionExito =>
      'Documentación enviada. Un administrador la revisará pronto.';

  @override
  String get miPerfilVerificacionErrorFaltaDocumento =>
      'Sube tu documento de identidad primero';

  @override
  String get miPerfilVerificacionErrorFaltaTarifa =>
      'Indica una tarifa base válida';

  @override
  String get miPerfilVerificacionErrorEnvio =>
      'No se pudo enviar la verificación';

  @override
  String get miPerfilStatValoracion => 'Valoración';

  @override
  String get miPerfilStatTrabajos => 'Trabajos';

  @override
  String get miPerfilStatTarifa => 'Tarifa';

  @override
  String get miPerfilStatEstado => 'Estado';

  @override
  String get miPerfilEstadoAprobado => 'Aprobado';

  @override
  String get miPerfilEstadoPendiente => 'Pendiente';

  @override
  String get miPerfilEstadoRechazado => 'Rechazado';

  @override
  String get miPerfilEstadoSinEnviar => 'Sin enviar';

  @override
  String get miPerfilTelefonoVacio => 'Añade tu número de teléfono';

  @override
  String get miPerfilDescripcionVacia =>
      'Añade una breve descripción para que los clientes te conozcan mejor';

  @override
  String get miPerfilCambiar => 'Cambiar';

  @override
  String get miPerfilEditar => 'Editar';

  @override
  String get miPerfilCategoriasTitulo => 'Categorías';

  @override
  String get miPerfilCategoriasEditar => 'Editar categorías';

  @override
  String get miPerfilCategoriasVacia => 'Aún no tienes categorías asignadas';

  @override
  String get miPerfilCategoriasGuardar => 'Guardar';

  @override
  String get miPerfilCategoriasCancelar => 'Cancelar';

  @override
  String get miPerfilCategoriasErrorMinimo =>
      'Selecciona al menos una categoría';

  @override
  String get miPerfilCategoriasExito => 'Categorías actualizadas';

  @override
  String get miPerfilCategoriasError =>
      'No se pudieron actualizar las categorías';

  @override
  String get distintivoVerificado => 'Profesional verificado';

  @override
  String get homeVerTodasCategorias => 'Ver todas las categorías';

  @override
  String get todasCategoriasTitulo => 'Todas las categorías';

  @override
  String get chatTitulo => 'Chat';

  @override
  String get chatSinMensajes => 'Aún no hay mensajes';

  @override
  String get chatErrorCargar => 'No se pudo cargar el chat';

  @override
  String get chatErrorEnviar => 'No se pudo enviar el mensaje';

  @override
  String get chatHint => 'Escribe un mensaje...';

  @override
  String get seguimientoAutorizarPago => 'Autorizar pago';

  @override
  String get seguimientoValorar => 'Valorar servicio';

  @override
  String get seguimientoYaValorado => 'Ya has valorado este servicio';

  @override
  String get seguimientoPagoRetenido =>
      'Pago autorizado, pendiente de completar el servicio';

  @override
  String get seguimientoPagoLiberado => 'Pago completado';

  @override
  String get seguimientoPagoReembolsado => 'Pago reembolsado';

  @override
  String get seguimientoPagoFallido => 'El pago falló';

  @override
  String get pagoTitulo => 'Confirmar y pagar';

  @override
  String get pagoInfo =>
      'El importe se autoriza ahora pero solo se cobra cuando el profesional complete el servicio.';

  @override
  String get pagoBtnAutorizar => 'Autorizar pago';

  @override
  String get pagoExito =>
      'Pago autorizado. Se cobrará cuando el servicio se complete.';

  @override
  String get pagoErrorGenerico =>
      'No se pudo procesar el pago. Inténtalo de nuevo.';

  @override
  String get pagoErrorStripeDefault => 'El pago no se completó';

  @override
  String get valoracionTitulo => '¿Cómo fue el servicio?';

  @override
  String get valoracionErrorSeleccion => 'Selecciona una puntuación';

  @override
  String get valoracionErrorEnviar =>
      'No se pudo enviar la valoración. Inténtalo de nuevo.';

  @override
  String get valoracionComentarioLabel => 'Comentario (opcional)';

  @override
  String get valoracionBtnEnviar => 'Enviar valoración';

  @override
  String get progresoBuscando => 'Buscando profesionales';

  @override
  String get progresoSeleccionado => 'Profesional seleccionado';

  @override
  String get progresoFinalizado => 'Trabajo finalizado';

  @override
  String get misSolicitudesError => 'No se pudieron cargar tus solicitudes';

  @override
  String get misSolicitudesVacio => 'Aún no has hecho ninguna solicitud';

  @override
  String get wizardTitulo => 'Nueva solicitud';

  @override
  String wizardPaso(int actual, int total) {
    return 'Paso $actual de $total';
  }

  @override
  String get wizardSiguiente => 'Siguiente';

  @override
  String get wizardPublicar => 'Publicar solicitud';

  @override
  String get wizardErrorCategoria => 'Elige una categoría para continuar';

  @override
  String get wizardErrorDescripcion =>
      'Describe el trabajo con un poco más de detalle';

  @override
  String get wizardErrorUbicacion => 'Elige dónde necesitas el servicio';

  @override
  String get wizardErrorFecha => 'Elige una fecha';

  @override
  String get wizardErrorFotosSubiendo =>
      'Espera a que terminen de subirse las fotos';

  @override
  String get fotoErrorSubir => 'No se pudo subir la foto. Inténtalo de nuevo.';

  @override
  String get wizardPaso1Titulo => '¿Qué necesitas?';

  @override
  String get wizardCategoriaCambiar => 'Cambiar';

  @override
  String get wizardCategoriaElegirTitulo => 'Elige una categoría';

  @override
  String get wizardPaso2Titulo => 'Describe el trabajo';

  @override
  String get wizardPaso2Ayuda =>
      'Cuanto más detalle des, mejor podrán ayudarte los profesionales';

  @override
  String get wizardPaso3Titulo => 'Añade fotos (opcional)';

  @override
  String get wizardPaso3Ayuda =>
      'Una foto ayuda al profesional a entender el problema antes de llegar';

  @override
  String get wizardFotoCamara => 'Hacer una foto';

  @override
  String get wizardFotoGaleria => 'Elegir de la galería';

  @override
  String get wizardPaso4Titulo => '¿Dónde es el trabajo?';

  @override
  String get wizardPaso4Ayuda =>
      'Usaremos esta ubicación para encontrar profesionales cerca';

  @override
  String get wizardUbicacionElegir => 'Elegir en el mapa';

  @override
  String get wizardUbicacionCambiar => 'Cambiar ubicación';

  @override
  String get wizardPaso5Titulo => '¿Cuándo lo necesitas?';

  @override
  String get wizardUrgenciaAsap => 'Lo antes posible';

  @override
  String get wizardUrgenciaHoy => 'Hoy';

  @override
  String get wizardUrgenciaManana => 'Mañana';

  @override
  String get wizardUrgenciaFecha => 'Elegir una fecha';

  @override
  String get wizardSeleccionarFecha => 'Seleccionar fecha';

  @override
  String get wizardPaso6Titulo => 'Revisa tu solicitud';

  @override
  String get ubicacionTitulo => 'Elegir ubicación';

  @override
  String get ubicacionDireccionOpcional => 'Dirección o referencia (opcional)';

  @override
  String get ubicacionConfirmar => 'Confirmar ubicación';

  @override
  String get adminTituloPanel => 'Panel admin';

  @override
  String get adminTabVerificaciones => 'Verificaciones';

  @override
  String get adminTabDisputas => 'Disputas';

  @override
  String get adminVerificacionesVacio => 'No hay verificaciones pendientes';

  @override
  String get adminVerificacionesError =>
      'No se pudieron cargar las verificaciones';

  @override
  String get adminDisputasVacio => 'No hay disputas abiertas';

  @override
  String get adminDisputasError => 'No se pudieron cargar las disputas';

  @override
  String adminCategoriasLabel(String categorias) {
    return 'Categorías: $categorias';
  }

  @override
  String get adminVerDocumento => 'Ver documento de identidad';

  @override
  String get adminDocumentoSinEnviar => 'Sin documento de identidad enviado';

  @override
  String get adminRechazar => 'Rechazar';

  @override
  String get adminAprobar => 'Aprobar';

  @override
  String get adminFavorCliente => 'A favor del cliente';

  @override
  String get adminFavorProfesional => 'A favor del profesional';

  @override
  String get adminMotivoRechazoTitulo => 'Motivo del rechazo';

  @override
  String get adminMotivoRechazoHint => 'Explica brevemente por qué se rechaza';

  @override
  String get adminMotivoRechazoAyuda =>
      'Mínimo 5 caracteres — el profesional lo verá';

  @override
  String get adminNotasResolucionTitulo => 'Notas de la resolución';

  @override
  String get adminNotasResolucionHint => 'Explica brevemente cómo se resolvió';

  @override
  String get adminNotasResolucionAyuda =>
      'Mínimo 5 caracteres — quedará registrado en la disputa';

  @override
  String get adminConfirmar => 'Confirmar';

  @override
  String get adminDecisionError =>
      'No se pudo registrar la decisión. Inténtalo de nuevo.';

  @override
  String get adminResolucionError =>
      'No se pudo registrar la resolución. Inténtalo de nuevo.';
}
