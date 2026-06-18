// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get navHome => '首页';

  @override
  String get navMap => '地图';

  @override
  String get navSettings => '设置';

  @override
  String get homeGreeting => '寻找医疗资源';

  @override
  String get homeFavorites => '您的收藏';

  @override
  String get homeNoFavorites => '暂无收藏';

  @override
  String get homeNoFavoritesHint => '从地图页面添加收藏即可在此查看';

  @override
  String get mapSearchLocation => '输入邮政编码';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAccount => '账户';

  @override
  String get settingsApp => '应用';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsEligibility => '资格';

  @override
  String get settingsZipCode => '邮政编码';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsTermsOfService => '服务条款';

  @override
  String get settingsSignOut => '退出登录';

  @override
  String get settingsSignOutConfirm => '确定要退出登录吗？';

  @override
  String get profileTitle => '个人资料';

  @override
  String get profileName => '姓名';

  @override
  String get profileEmail => '电子邮箱';

  @override
  String get profileZipCode => '邮政编码';

  @override
  String get profileDateOfBirth => '出生日期';

  @override
  String get profileMonth => '月';

  @override
  String get profileYear => '年';

  @override
  String get profileLanguage => '首选语言';

  @override
  String get profileOptionalInfo => '可选信息';

  @override
  String get profileGender => '性别';

  @override
  String get profileHouseholdSize => '家庭人数';

  @override
  String get profileAnnualIncome => '年收入';

  @override
  String get profileSaveChanges => '保存更改';

  @override
  String get profileChangePassword => '更改密码';

  @override
  String get profilePrivacyPolicy => '隐私政策';

  @override
  String get authContinueWithGoogle => '使用 Google 继续';

  @override
  String get authContinueWithApple => '使用 Apple 继续';

  @override
  String get authContinueAsGuest => '以访客身份继续';

  @override
  String get authOr => '或';

  @override
  String get authTermsPrefix => '点击继续即表示您同意我们的';

  @override
  String get authTermsOfService => '服务条款';

  @override
  String get authAnd => '和';

  @override
  String get authPrivacyPolicy => '隐私政策';

  @override
  String get authSelectLanguage => '选择语言 🌐';

  @override
  String get authSigningIn => '正在登录...';

  @override
  String get authSignInPromptTitle => '请登录以使用此功能';

  @override
  String get authSignInPromptBody => '创建免费账户即可解锁收藏、资格筛选等功能。';

  @override
  String get authSignInError => '登录失败，请重试。';

  @override
  String get locationChoiceTitle => '您希望如何查找资源？';

  @override
  String get locationChoiceSubtitle => '我们将以此向您显示附近的资源。';

  @override
  String get locationChoiceUseLocation => '启用基于位置的搜索';

  @override
  String get locationChoiceUseLocationDesc => '使用 GPS 获得最准确的结果。';

  @override
  String get locationChoiceEnterZip => '输入邮政编码';

  @override
  String get locationChoiceEnterZipDesc => '按美国邮政编码搜索。';

  @override
  String get locationCurrentLocation => '当前位置';

  @override
  String get locationPermissionDenied => '位置访问被拒绝。请在「设置」>「隐私」>「定位服务」中启用。';

  @override
  String get locationPermissionDeniedTitle => '需要位置访问权限';

  @override
  String get locationPermissionDeniedBody =>
      '若要使用基于 GPS 的搜索，请在 iOS「设置」>「隐私」>「定位服务」中为 Beacon 启用位置权限。';

  @override
  String get locationUseMyLocationTooltip => '使用我的位置';

  @override
  String get settingsUseMyLocation => '使用我的位置';

  @override
  String get settingsUseMyLocationDesc => '使用 GPS 而非邮政编码';

  @override
  String get settingsSignOutSuccess => '已退出登录';

  @override
  String get commonCancel => '取消';
}
