// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Beacon';

  @override
  String get navHome => 'Inicio';

  @override
  String get navMap => 'Mapa';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get homeGreeting => 'Encuentra Recursos de Salud';

  @override
  String get homeFavorites => 'Tus Favoritos';

  @override
  String get homeNoFavorites => 'Aún no tienes favoritos';

  @override
  String get homeNoFavoritesHint =>
      'Agrega favoritos desde el mapa para verlos aquí';

  @override
  String get homeNearby => 'Recursos Cercanos';

  @override
  String get homeQuickFind => 'Búsqueda Rápida';

  @override
  String get homeUrgentCare => 'Urgencias';

  @override
  String get homeHousing => 'Refugios';

  @override
  String get homeFreeClinics => 'Clínicas Gratuitas';

  @override
  String get homeFoodPantry => 'Banco de Alimentos';

  @override
  String get mapResourcesNearYou => 'Recursos cerca de ti';

  @override
  String get mapSwipeUp => 'Desliza hacia arriba para ver recursos';

  @override
  String get mapSearchFacilities => 'Buscar centros...';

  @override
  String get mapSearchLocation => 'Ingresa código postal';

  @override
  String get mapLoading => 'Cargando centros...';

  @override
  String get mapNoResults => 'No se encontraron centros en esta área';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAccount => 'Cuenta';

  @override
  String settingsSignedInWith(String provider) {
    return 'Sesión iniciada con $provider';
  }

  @override
  String get settingsApp => 'Aplicación';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsEligibility => 'Elegibilidad';

  @override
  String get settingsZipCode => 'Código Postal';

  @override
  String get settingsWheelchair => 'Accesible para silla de ruedas';

  @override
  String get settingsProofOfIncome => 'Comprobante de ingresos disponible';

  @override
  String get settingsInsurance => 'Estado del seguro';

  @override
  String get settingsWalkIns => 'Acepta sin cita';

  @override
  String get settingsTelehealth => 'Preferencia de telesalud';

  @override
  String get settingsHouseholdSize => 'Tamaño del hogar';

  @override
  String get settingsAnnualIncome => 'Ingreso anual';

  @override
  String get settingsEmployment => 'Estado laboral';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get settingsPrivacyPolicy => 'Política de Privacidad';

  @override
  String get settingsTermsOfService => 'Términos de Servicio';

  @override
  String get settingsDeveloper => 'Desarrollador';

  @override
  String get settingsDemoMode => 'Modo Demo';

  @override
  String get settingsDemoModeDesc =>
      'Usar datos simulados y omitir autenticación';

  @override
  String get settingsDemoModeConfirm =>
      'Cambiar el modo demo reiniciará la aplicación. ¿Continuar?';

  @override
  String get settingsSignOut => 'Cerrar Sesión';

  @override
  String get settingsSignOutConfirm =>
      '¿Estás seguro de que deseas cerrar sesión?';

  @override
  String get settingsSaved => 'Ajustes guardados';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileName => 'Nombre Completo';

  @override
  String get profileEmail => 'Correo Electrónico';

  @override
  String get profileZipCode => 'Código Postal';

  @override
  String get profileDateOfBirth => 'Fecha de Nacimiento';

  @override
  String get profileMonth => 'Mes';

  @override
  String get profileYear => 'Año';

  @override
  String get profileLanguage => 'Idioma Preferido';

  @override
  String get profileOptionalInfo => 'Información Opcional';

  @override
  String get profileGender => 'Género';

  @override
  String get profileHouseholdSize => 'Tamaño del Hogar';

  @override
  String get profileAnnualIncome => 'Ingreso Anual';

  @override
  String get profileSaveChanges => 'Guardar Cambios';

  @override
  String get profileSaved => 'Perfil guardado';

  @override
  String get profileChangePassword => 'Cambiar Contraseña';

  @override
  String get profilePrivacyPolicy => 'Política de Privacidad';

  @override
  String get profileCreateAccount => 'Crear una Cuenta';

  @override
  String get authContinueWithGoogle => 'Continuar con Google';

  @override
  String get authContinueWithApple => 'Continuar con Apple';

  @override
  String get authContinueAsGuest => 'Continuar como Invitado';

  @override
  String get authOr => 'o';

  @override
  String get authTermsPrefix => 'Al hacer clic en continuar, aceptas nuestros ';

  @override
  String get authTermsOfService => 'Términos de Servicio';

  @override
  String get authAnd => ' y ';

  @override
  String get authPrivacyPolicy => 'Política de Privacidad';

  @override
  String get authSelectLanguage => 'Seleccionar un idioma 🌐';

  @override
  String get authSigningIn => 'Iniciando sesión...';

  @override
  String get authSignIn => 'Iniciar Sesión';

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
  String get commonContinue => 'Continuar';

  @override
  String get commonSave => 'Guardar';

  @override
  String commonYesPerYear(String amount) {
    return '$amount/año';
  }

  @override
  String get filterCategories => 'Categorías';

  @override
  String get filterDistance => 'Distancia';

  @override
  String get filterOpenNow => 'Abierto Ahora';

  @override
  String get filterFavorites => 'Favoritos';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterApply => 'Aplicar Filtros';

  @override
  String get filterReset => 'Restablecer';
}
