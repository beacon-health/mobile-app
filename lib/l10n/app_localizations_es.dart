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
  String get homeFavoritesSignInTitle => 'Inicia sesión para guardar favoritos';

  @override
  String get homeFavoritesSignInHint =>
      'Inicia sesión para guardar tus centros favoritos.';

  @override
  String get homeRecentlyViewed => 'Vistos recientemente';

  @override
  String get homeNoRecentlyViewed => 'No hay centros vistos recientemente';

  @override
  String get homeNoRecentlyViewedHint =>
      'Toca un centro en el mapa para verlo aquí.';

  @override
  String get mapSearchLocation => 'Ingresa código postal';

  @override
  String get mapSearchResourcesHint => 'Buscar recursos';

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
  String get mapInvalidZip => 'Ingresa un código postal de 5 dígitos.';

  @override
  String mapZipNotFound(String zipCode) {
    return 'No encontramos el código postal $zipCode.';
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
  String get eligProofOfIncome => 'Comprobante de ingresos';

  @override
  String get eligProofOfResidency => 'Comprobante de domicilio';

  @override
  String get eligInsuranceRequired => 'Seguro médico';

  @override
  String get eligReferralRequired => 'Una referencia médica';

  @override
  String get prefAcceptsWalkIns => 'Atienden sin cita';

  @override
  String get prefAppointmentOnly => 'Requieren cita';

  @override
  String get prefOpenToImmigrants => 'Atienden a inmigrantes';

  @override
  String get prefFreeServices => 'Ofrecen servicios gratuitos';

  @override
  String get prefSlidingScale => 'Cobran según tus ingresos';

  @override
  String get prefOtherLanguages => 'Atienden en otros idiomas';

  @override
  String get prefTelehealth => 'Ofrecen telemedicina';

  @override
  String get prefWheelchairAccessible => 'Son accesibles en silla de ruedas';

  @override
  String get prefServesOutsideArea => 'Atienden a personas de fuera de su zona';

  @override
  String get cardHours => 'Horario';

  @override
  String get cardServices => 'Servicios';

  @override
  String get cardServicesAiDisclaimer =>
      'Resumen escrito por IA. Puede contener errores.';

  @override
  String get cardAtAGlance => 'De un vistazo';

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
      'Inicia sesión para guardar favoritos y usarlos en cualquier dispositivo.';

  @override
  String get settingsZipUpdated => 'Código postal actualizado';

  @override
  String get settingsUpdateZipTitle => 'Actualizar código postal';

  @override
  String get settingsZipValidation => 'Ingresa un código postal de 5 dígitos.';

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
  String get settingsEligibility => 'Lo que puedes presentar';

  @override
  String get settingsZipCode => 'Código postal';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsPrivacyPolicy => 'Política de privacidad';

  @override
  String get settingsTermsOfService => 'Términos de servicio';

  @override
  String get settingsSignOut => 'Cerrar sesión';

  @override
  String get settingsSignOutConfirm =>
      'Tus favoritos y ajustes se quedan en tu cuenta. Se quitarán de este teléfono.';

  @override
  String get settingsDeleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountTitle => '¿Eliminar tu cuenta?';

  @override
  String get deleteAccountBody =>
      'Esto elimina permanentemente tu cuenta, tus favoritos guardados, tus respuestas de elegibilidad y tu configuración. Las valoraciones y correcciones que enviaste permanecen en el directorio, pero ya no estarán vinculadas a ti. Esta acción no se puede deshacer.';

  @override
  String get deleteAccountConfirm => 'Eliminar cuenta';

  @override
  String get deleteAccountInProgress => 'Eliminando tu cuenta…';

  @override
  String get deleteAccountSuccess => 'Tu cuenta ha sido eliminada';

  @override
  String get deleteAccountFailed =>
      'No se pudo eliminar tu cuenta. Inténtalo de nuevo.';

  @override
  String coverageNotice(String states) {
    return 'Beacon muestra actualmente centros en $states. Estamos añadiendo más estados con el tiempo.';
  }

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
  String get authTermsPrefix => 'Al continuar, aceptas nuestros ';

  @override
  String get authTermsOfService => 'Términos de servicio';

  @override
  String get authAnd => ' y ';

  @override
  String get authPrivacyPolicy => 'Política de privacidad';

  @override
  String get authSelectLanguage => 'Seleccionar un idioma';

  @override
  String get authSignInPromptTitle => 'Inicia sesión para usar esta función';

  @override
  String get authSignInPromptBody =>
      'Inicia sesión para guardar favoritos, filtrar por preferencias y calificar lugares.';

  @override
  String get authSignInError => 'Error al iniciar sesión. Inténtalo de nuevo.';

  @override
  String get locationChoiceTitle => '¿Cómo quieres encontrar recursos?';

  @override
  String get locationChoiceSubtitle =>
      'Usaremos esto para mostrarte recursos cercanos.';

  @override
  String get locationChoiceUseLocation => 'Usar mi ubicación';

  @override
  String get locationChoiceUseLocationDesc =>
      'Lo más preciso. Te pediremos permiso a continuación.';

  @override
  String get locationChoiceEnterZip => 'Ingresar un código postal';

  @override
  String get locationChoiceEnterZipDesc =>
      'Busca en una zona sin compartir tu ubicación.';

  @override
  String get locationCurrentLocation => 'Ubicación actual';

  @override
  String get locationPermissionDenied =>
      'El acceso a la ubicación está desactivado. Actívalo para Beacon en los ajustes de tu teléfono.';

  @override
  String get locationPermissionDeniedTitle =>
      'Se necesita acceso a la ubicación';

  @override
  String get locationPermissionDeniedBody =>
      'Para buscar por tu ubicación, activa el acceso a la ubicación para Beacon en los ajustes de tu teléfono.';

  @override
  String get locationUseMyLocationTooltip => 'Usar mi ubicación';

  @override
  String get settingsUseMyLocation => 'Usar mi ubicación';

  @override
  String get settingsUseMyLocationDesc => 'En lugar de un código postal';

  @override
  String get settingsSignOutSuccess => 'Sesión cerrada';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get navProfile => 'Perfil';

  @override
  String get profileApplyEligibility => 'Filtrar por lo que puedo presentar';

  @override
  String get profileApplyEligibilityDesc =>
      'Oculta los lugares que piden algo que no has marcado abajo.';

  @override
  String get profileSignedIn => 'Sesión iniciada';

  @override
  String profileSignedInThrough(String provider) {
    return 'Sesión iniciada con $provider';
  }

  @override
  String get commonSave => 'Guardar';

  @override
  String get homeCategoryHealthCare => 'Atención médica';

  @override
  String get homeCategoryMentalHealth => 'Salud mental';

  @override
  String get homeCategoryHousing => 'Vivienda y refugio';

  @override
  String get homeCategoryBasicNeeds => 'Necesidades básicas';

  @override
  String get homeCategoryCommunity => 'Recursos comunitarios';

  @override
  String get homeCategorySpecialized => 'Servicios especializados';

  @override
  String get commonLinkFailed => 'No se pudo abrir el enlace.';

  @override
  String get onboardingEligibilityTitle => '¿Qué puedes presentar?';

  @override
  String get onboardingEligibilitySubtitle =>
      'Ocultaremos los lugares que no podrías usar. Puedes cambiarlo cuando quieras en Perfil.';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String get onboardingTagline =>
      'Encuentra recursos gratuitos y de bajo costo cerca de ti.';

  @override
  String get zipEntryTitle => '¿Cuál es tu código postal?';

  @override
  String get zipEntrySubtitle =>
      'Lo usaremos para mostrarte recursos cercanos.';

  @override
  String get zipEntryInvalid => 'Ingresa un código postal de 5 dígitos.';

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

  @override
  String zipOutsideCoverage(String states) {
    return 'Beacon aún no está disponible en esa zona. Por ahora cubre $states.';
  }

  @override
  String stateName(String code) {
    String _temp0 = intl.Intl.selectLogic(
      code,
      {
        'AL': 'Alabama',
        'AK': 'Alaska',
        'AZ': 'Arizona',
        'AR': 'Arkansas',
        'CA': 'California',
        'CO': 'Colorado',
        'CT': 'Connecticut',
        'DE': 'Delaware',
        'DC': 'Washington D. C.',
        'FL': 'Florida',
        'GA': 'Georgia',
        'GU': 'Guam',
        'HI': 'Hawái',
        'ID': 'Idaho',
        'IL': 'Illinois',
        'IN': 'Indiana',
        'IA': 'Iowa',
        'KS': 'Kansas',
        'KY': 'Kentucky',
        'LA': 'Luisiana',
        'ME': 'Maine',
        'MD': 'Maryland',
        'MA': 'Massachusetts',
        'MI': 'Míchigan',
        'MN': 'Minnesota',
        'MS': 'Misisipi',
        'MO': 'Misuri',
        'MT': 'Montana',
        'NE': 'Nebraska',
        'NV': 'Nevada',
        'NH': 'Nuevo Hampshire',
        'NJ': 'Nueva Jersey',
        'NM': 'Nuevo México',
        'NY': 'Nueva York',
        'NC': 'Carolina del Norte',
        'ND': 'Dakota del Norte',
        'OH': 'Ohio',
        'OK': 'Oklahoma',
        'OR': 'Oregón',
        'PA': 'Pensilvania',
        'PR': 'Puerto Rico',
        'RI': 'Rhode Island',
        'SC': 'Carolina del Sur',
        'SD': 'Dakota del Sur',
        'TN': 'Tennessee',
        'TX': 'Texas',
        'UT': 'Utah',
        'VT': 'Vermont',
        'VA': 'Virginia',
        'VI': 'Islas Vírgenes de EE. UU.',
        'WA': 'Washington',
        'WV': 'Virginia Occidental',
        'WI': 'Wisconsin',
        'WY': 'Wyoming',
        'other': '$code',
      },
    );
    return '$_temp0';
  }

  @override
  String listTwo(String first, String second) {
    return '$first y $second';
  }

  @override
  String listTwoBeforeI(String first, String second) {
    return '$first e $second';
  }

  @override
  String listMany(String rest, String last) {
    return '$rest y $last';
  }

  @override
  String listManyBeforeI(String rest, String last) {
    return '$rest e $last';
  }

  @override
  String get listSeparator => ', ';

  @override
  String mapResourcesInView(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recursos en esta zona',
      one: '1 recurso en esta zona',
    );
    return '$_temp0';
  }

  @override
  String get mapNothingInView => 'Nada en esta parte del mapa';

  @override
  String get mapNothingInViewHint => 'Aleja o mueve el mapa para ver más.';

  @override
  String get eligAcceptsMedicaid => 'Medicaid';

  @override
  String get chipMedicaid => 'Medicaid';

  @override
  String get cardIncomeLimit => 'Límite de ingresos';

  @override
  String get cardServiceArea => 'Área de servicio';

  @override
  String get labelSeparator => ': ';

  @override
  String get correctionFieldClosed => 'Cerrado permanentemente';

  @override
  String get correctionFieldClosedHint =>
      'Actívalo si el lugar cerró definitivamente.';

  @override
  String get requestTypeClosure => 'Cierre reportado';

  @override
  String get homeOpenMap => 'Abrir mapa';

  @override
  String filterShowResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ver $count resultados',
      one: 'Ver 1 resultado',
      zero: 'Sin resultados',
    );
    return '$_temp0';
  }

  @override
  String get filterOnlyShowPlacesThat => 'Mostrar solo lugares que';

  @override
  String get filterClose => 'Cerrar filtros';

  @override
  String filterCategoriesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categorías',
      one: '1 categoría',
    );
    return '$_temp0';
  }

  @override
  String get cardDirections => 'Cómo llegar';

  @override
  String get cardCall => 'Llamar';

  @override
  String cardCallNumber(String phone) {
    return 'Llamar al $phone';
  }

  @override
  String get cardWebsite => 'Sitio web';

  @override
  String cardSave(String name) {
    return 'Guardar $name';
  }

  @override
  String cardUnsave(String name) {
    return 'Quitar $name de favoritos';
  }

  @override
  String get cardShowDetails => 'Ver detalles';

  @override
  String get cardHideDetails => 'Ocultar detalles';

  @override
  String get eligProofOfIncomeHint =>
      'Recibo de sueldo, declaración de impuestos o carta de beneficios';

  @override
  String get eligProofOfResidencyHint =>
      'Identificación, contrato de alquiler o factura de servicios';

  @override
  String get onboardingSkip => 'Omitir por ahora';

  @override
  String onboardingStep(int step, int total) {
    return 'Paso $step de $total';
  }

  @override
  String get authTermsSuffix => '.';

  @override
  String authLanguageButton(String language) {
    return 'Idioma: $language. Cambiar idioma';
  }

  @override
  String get zipEntryHelper => '5 dígitos';

  @override
  String get zipEntryLocationOff =>
      'El acceso a la ubicación está desactivado; ingresa un código postal.';

  @override
  String get settingsSignOutTitle => '¿Cerrar sesión?';

  @override
  String settingsVersionFooter(String version) {
    return 'Beacon $version';
  }

  @override
  String get settingsAccessibility => 'Accesibilidad';

  @override
  String get settingsMapAsList => 'Abrir el mapa como lista';

  @override
  String get settingsMapAsListDesc => 'Más fácil con lectores de pantalla';

  @override
  String get settingsLargerPins => 'Marcadores más grandes';

  @override
  String get settingsLargerPinsDesc =>
      'Marcadores y nombres más grandes en el mapa';

  @override
  String get settingsAppearanceSystem => 'Igual que el dispositivo';

  @override
  String get settingsAppearanceLight => 'Claro';

  @override
  String get settingsAppearanceDark => 'Oscuro';

  @override
  String get commonNotSet => 'Sin definir';

  @override
  String get brandTagline => 'Atención médica más llevadera.';

  @override
  String get cardHoursClosed => 'Cerrado';

  @override
  String get cardHoursUnknown => 'Sin datos';
}
