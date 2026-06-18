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
  String get mapSearchLocation => 'Ingresa código postal';

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
  String get profileName => 'Nombre completo';

  @override
  String get profileEmail => 'Correo electrónico';

  @override
  String get profileZipCode => 'Código postal';

  @override
  String get profileDateOfBirth => 'Fecha de nacimiento';

  @override
  String get profileMonth => 'Mes';

  @override
  String get profileYear => 'Año';

  @override
  String get profileLanguage => 'Idioma preferido';

  @override
  String get profileOptionalInfo => 'Información opcional';

  @override
  String get profileGender => 'Género';

  @override
  String get profileHouseholdSize => 'Tamaño del hogar';

  @override
  String get profileAnnualIncome => 'Ingreso anual';

  @override
  String get profileSaveChanges => 'Guardar cambios';

  @override
  String get profileChangePassword => 'Cambiar contraseña';

  @override
  String get profilePrivacyPolicy => 'Política de privacidad';

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
  String get authSigningIn => 'Iniciando sesión...';

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
}
