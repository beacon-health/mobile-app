// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navHome => 'Inicio';

  @override
  String get navMap => 'Mapa';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get homeGreeting => 'Encuentra recursos de salud';

  @override
  String get homeFavorites => 'Tus favoritos';

  @override
  String get homeNoFavorites => 'Aún no tienes favoritos';

  @override
  String get homeNoFavoritesHint =>
      'Agrega favoritos desde el mapa para verlos aquí';

  @override
  String get homeRecentlyViewed => 'Centros vistos recientemente';

  @override
  String get homeNoRecentlyViewed => 'No hay centros vistos recientemente';

  @override
  String get homeNoRecentlyViewedHint =>
      'Toca un centro en el mapa para verlo aquí.';

  @override
  String get mapSearchLocation => 'Ingresa código postal';

  @override
  String get mapSearchResourcesHint => 'Buscar recursos...';

  @override
  String get mapAreaLabel => 'Área del mapa';

  @override
  String get mapSearchThisArea => 'Buscar en esta área';

  @override
  String get mapSearching => 'Buscando…';

  @override
  String get mapSwipeUpToView => 'Desliza hacia arriba para ver recursos';

  @override
  String get mapResourcesNearYou => 'Recursos cerca de ti';

  @override
  String get mapNoFacilitiesInArea => 'No hay centros en esta área';

  @override
  String get mapCantFindFacility =>
      '¿No encuentras un centro? Envía una solicitud para agregarlo.';

  @override
  String get mapRequestFacility => 'Solicitar un centro';

  @override
  String get mapLoadFailed =>
      'No se pudieron cargar los centros. Inténtalo de nuevo.';

  @override
  String get mapRetry => 'Reintentar';

  @override
  String get mapInvalidZip =>
      'Ingresa un código postal válido de 5 dígitos (p. ej., 60605)';

  @override
  String mapZipNotFound(String zipCode) {
    return 'No se encontró la ubicación para el código postal $zipCode.';
  }

  @override
  String get filterOpenNow => 'Abierto ahora';

  @override
  String get filterFavorites => 'Favoritos';

  @override
  String get filterCategory => 'Categoría';

  @override
  String get filterPreferences => 'Preferencias';

  @override
  String get filterFilters => 'Filtros';

  @override
  String get filterClearAll => 'Borrar todo';

  @override
  String get filterApply => 'Aplicar';

  @override
  String get commonYes => 'Sí';

  @override
  String get commonNo => 'No';

  @override
  String get eligProofOfIncome => 'Requiere comprobante de ingresos';

  @override
  String get eligProofOfResidency => 'Requiere comprobante de residencia';

  @override
  String get eligInsuranceRequired => 'Requiere seguro médico';

  @override
  String get eligReferralRequired => 'Requiere referencia médica';

  @override
  String get prefAcceptsWalkIns => 'Acepta visitas sin cita';

  @override
  String get prefAppointmentOnly => 'Solo con cita';

  @override
  String get prefOpenToImmigrants => 'Abierto a inmigrantes';

  @override
  String get prefFreeServices => 'Servicios gratuitos disponibles';

  @override
  String get prefSlidingScale => 'Tarifa según ingresos disponible';

  @override
  String get prefOtherLanguages => 'Otros idiomas disponibles';

  @override
  String get prefTelehealth => 'Telemedicina disponible';

  @override
  String get prefWheelchairAccessible => 'Accesible en silla de ruedas';

  @override
  String get prefServesOutsideArea => 'Atiende fuera del área';

  @override
  String get cardNextSteps => 'Próximos pasos';

  @override
  String get cardHours => 'Horario';

  @override
  String get cardServices => 'Servicios';

  @override
  String get cardAtAGlance => 'De un vistazo';

  @override
  String get cardVisitWebsite => 'Visitar sitio web';

  @override
  String get cardWebsiteNotAvailable => 'Sitio web no disponible';

  @override
  String get cardGetDirections => 'Cómo llegar';

  @override
  String get cardContactForHours =>
      'Contacta al centro para conocer el horario';

  @override
  String get cardOpen247 => 'Abierto 24/7';

  @override
  String get cardAddressNotAvailable =>
      'La dirección de este centro no está disponible';

  @override
  String get chipWalkIns => 'Sin cita';

  @override
  String get chipFree => 'Gratis';

  @override
  String get chipTelehealth => 'Telemedicina';

  @override
  String get chipAccessible => 'Accesible';

  @override
  String get chipSlidingScale => 'Tarifa variable';

  @override
  String get chipOtherLanguages => 'Otros idiomas';

  @override
  String get ratingAlreadyRated =>
      'Ya calificaste este centro — actualízalo abajo.';

  @override
  String get ratingDateVisited => 'Fecha de visita';

  @override
  String get ratingRemove => 'Eliminar';

  @override
  String get ratingSubmit => 'Enviar';

  @override
  String get ratingUpdate => 'Actualizar';

  @override
  String get ratingThanks => '¡Gracias por tu calificación!';

  @override
  String get ratingUpdated => 'Calificación actualizada.';

  @override
  String get ratingRemoved => 'Calificación eliminada.';

  @override
  String get ratingSendFailed =>
      'No se pudo enviar la calificación. Inténtalo de nuevo.';

  @override
  String get ratingRemoveFailed =>
      'No se pudo eliminar la calificación. Inténtalo de nuevo.';

  @override
  String get ratingSignInRequired => 'Inicia sesión para calificar un centro.';

  @override
  String get requestDialogTitle => 'Solicitar un centro';

  @override
  String get requestDialogIntro =>
      'Cuéntanos sobre un centro que nos falte y nuestro equipo lo revisará.';

  @override
  String get requestFieldName => 'Nombre del centro *';

  @override
  String get requestFieldNameError => 'Ingresa el nombre del centro';

  @override
  String get requestSubmitted =>
      'Solicitud enviada — la revisaremos pronto. ¡Gracias!';

  @override
  String get requestSubmitFailed =>
      'No se pudo enviar la solicitud. Inténtalo de nuevo.';

  @override
  String get requestSignInRequired =>
      'Inicia sesión para enviar una solicitud.';

  @override
  String get settingsYourRatings => 'Tus calificaciones';

  @override
  String get settingsYourRequests => 'Tus solicitudes';

  @override
  String get settingsDirectionsApp => 'App de direcciones';

  @override
  String get settingsAskEachTime => 'Preguntar cada vez';

  @override
  String get settingsSignInHint =>
      '¡Inicia sesión para guardar favoritos, filtrar por preferencias y más!';

  @override
  String get settingsZipUpdated => 'Código postal actualizado';

  @override
  String get settingsUpdateZipTitle => 'Actualizar código postal';

  @override
  String get settingsZipValidation => 'Ingresa un código postal de 5 dígitos';

  @override
  String get settingsZipNotFoundError =>
      'No se encontró ese código postal. Inténtalo de nuevo.';

  @override
  String get ratingsEmptyTitle => 'Aún no has calificado ningún centro.';

  @override
  String get ratingsEmptyHint =>
      'Califica un centro desde el mapa o desde Vistos recientemente en Inicio. Tus calificaciones aparecerán aquí.';

  @override
  String ratingsVisitedOn(String date) {
    return 'Visitado el $date';
  }

  @override
  String get requestsEmptyTitle => 'Aún no hay solicitudes';

  @override
  String get requestsEmptyHint =>
      '¿Conoces un centro que nos falte? Envía una solicitud y la revisaremos.';

  @override
  String get directionsOpenWith => 'Abrir direcciones con';

  @override
  String get directionsChangeLater => 'Puedes cambiarlo después en Ajustes.';

  @override
  String get directionsOpenFailed => 'No se pudieron abrir las direcciones.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAccount => 'Cuenta';

  @override
  String get settingsApp => 'Aplicación';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsEligibility => 'Elegibilidad';

  @override
  String get settingsZipCode => 'Código postal';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get settingsPrivacyPolicy => 'Política de privacidad';

  @override
  String get settingsTermsOfService => 'Términos de servicio';

  @override
  String get settingsSignOut => 'Cerrar sesión';

  @override
  String get settingsSignOutConfirm =>
      '¿Estás seguro de que deseas cerrar sesión?';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get authContinueWithGoogle => 'Continuar con Google';

  @override
  String get authContinueWithApple => 'Continuar con Apple';

  @override
  String get authContinueAsGuest => 'Continuar como invitado';

  @override
  String get authOr => 'o';

  @override
  String get authTermsPrefix => 'Al hacer clic en continuar, aceptas nuestros ';

  @override
  String get authTermsOfService => 'Términos de servicio';

  @override
  String get authAnd => ' y ';

  @override
  String get authPrivacyPolicy => 'Política de privacidad';

  @override
  String get authSelectLanguage => 'Seleccionar un idioma 🌐';

  @override
  String get authSignInPromptTitle => 'Inicia sesión para usar esta función';

  @override
  String get authSignInPromptBody =>
      'Crea una cuenta gratuita para desbloquear Favoritos, filtros de elegibilidad y más.';

  @override
  String get authSignInError => 'Error al iniciar sesión. Inténtalo de nuevo.';

  @override
  String get locationChoiceTitle => '¿Cómo quieres encontrar recursos?';

  @override
  String get locationChoiceSubtitle =>
      'Usaremos esto para mostrarte recursos cercanos.';

  @override
  String get locationChoiceUseLocation => 'Activar búsqueda por ubicación';

  @override
  String get locationChoiceUseLocationDesc =>
      'Usa el GPS para obtener los resultados más precisos.';

  @override
  String get locationChoiceEnterZip => 'Ingresar código postal';

  @override
  String get locationChoiceEnterZipDesc =>
      'Buscar por código postal en EE. UU.';

  @override
  String get locationCurrentLocation => 'Ubicación actual';

  @override
  String get locationPermissionDenied =>
      'Acceso a la ubicación denegado. Actívalo en Ajustes > Privacidad > Servicios de ubicación.';

  @override
  String get locationPermissionDeniedTitle =>
      'Se requiere acceso a la ubicación';

  @override
  String get locationPermissionDeniedBody =>
      'Para usar la búsqueda por GPS, activa la ubicación de Beacon en Ajustes de iOS > Privacidad > Servicios de ubicación.';

  @override
  String get locationUseMyLocationTooltip => 'Usar mi ubicación';

  @override
  String get settingsUseMyLocation => 'Usar mi ubicación';

  @override
  String get settingsUseMyLocationDesc => 'Usar GPS en lugar del código postal';

  @override
  String get settingsSignOutSuccess => 'Sesión cerrada';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get navProfile => 'Perfil';

  @override
  String get profileApplyEligibility =>
      'Aplicar criterios de elegibilidad a la búsqueda';

  @override
  String get profileApplyEligibilityDesc =>
      'Mostrar solo centros que coincidan con tu elegibilidad.';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonLinkFailed => 'No se pudo abrir el enlace.';

  @override
  String get onboardingEligibilityTitle => 'Tu elegibilidad';

  @override
  String get onboardingEligibilitySubtitle =>
      'Cuéntanos qué aplica a ti para mostrarte centros para los que calificas. Puedes cambiarlo cuando quieras en tu Perfil.';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String get requestFieldWebsite => 'Sitio web del centro *';

  @override
  String get requestFieldWebsiteError => 'Ingresa el sitio web del centro';

  @override
  String get correctionDialogTitle => 'Enviar correcciones';

  @override
  String get correctionDialogIntro =>
      'Corrige lo que esté mal y nuestro equipo lo revisará.';

  @override
  String get correctionFieldName => 'Nombre';

  @override
  String get correctionFieldWebsite => 'Sitio web';

  @override
  String get correctionFieldPhone => 'Teléfono';

  @override
  String get correctionFieldHours => 'Horario';

  @override
  String get correctionFieldAddress => 'Dirección';

  @override
  String get correctionSubmitted =>
      'Corrección enviada — la revisaremos. ¡Gracias!';

  @override
  String get correctionSubmitFailed =>
      'No se pudo enviar la corrección. Inténtalo de nuevo.';

  @override
  String get requestTypeNew => 'Centro nuevo';

  @override
  String get requestTypeCorrection => 'Corrección';

  @override
  String get cardRatePromptLead => '¿Ya lo visitaste? ';

  @override
  String get cardRatePromptAction => 'Califica tu experiencia';

  @override
  String get cardCorrectionPromptLead => '¿Información incorrecta? ';

  @override
  String get cardCorrectionPromptAction => 'Envía correcciones aquí';
}
