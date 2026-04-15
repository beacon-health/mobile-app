// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Beacon';

  @override
  String get navHome => '首页';

  @override
  String get navMap => '地图';

  @override
  String get navProfile => '个人资料';

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
  String get homeNearby => '附近资源';

  @override
  String get homeQuickFind => '快速查找';

  @override
  String get homeUrgentCare => '急诊护理';

  @override
  String get homeHousing => '住房庇护所';

  @override
  String get homeFreeClinics => '免费诊所';

  @override
  String get homeFoodPantry => '食物银行';

  @override
  String get mapResourcesNearYou => '您附近的资源';

  @override
  String get mapSwipeUp => '向上滑动查看资源';

  @override
  String get mapSearchFacilities => '搜索机构...';

  @override
  String get mapSearchLocation => '输入邮政编码';

  @override
  String get mapLoading => '正在加载机构...';

  @override
  String get mapNoResults => '该区域未找到机构';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAccount => '账户';

  @override
  String settingsSignedInWith(String provider) {
    return '已通过 $provider 登录';
  }

  @override
  String get settingsApp => '应用';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsEligibility => '资格偏好';

  @override
  String get settingsZipCode => '邮政编码';

  @override
  String get settingsWheelchair => '无障碍设施';

  @override
  String get settingsProofOfIncome => '可提供收入证明';

  @override
  String get settingsInsurance => '保险状态';

  @override
  String get settingsWalkIns => '接受无预约就诊';

  @override
  String get settingsTelehealth => '远程医疗偏好';

  @override
  String get settingsHouseholdSize => '家庭人数';

  @override
  String get settingsAnnualIncome => '年收入';

  @override
  String get settingsEmployment => '就业状况';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsTermsOfService => '服务条款';

  @override
  String get settingsDeveloper => '开发者';

  @override
  String get settingsDemoMode => '演示模式';

  @override
  String get settingsDemoModeDesc => '使用模拟数据并跳过身份验证';

  @override
  String get settingsDemoModeConfirm => '切换演示模式将重启应用流程。是否继续？';

  @override
  String get settingsSignOut => '退出登录';

  @override
  String get settingsSignOutConfirm => '确定要退出登录吗？';

  @override
  String get settingsSaved => '设置已保存';

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
  String get profileSaved => '个人资料已保存';

  @override
  String get profileChangePassword => '更改密码';

  @override
  String get profilePrivacyPolicy => '隐私政策';

  @override
  String get profileCreateAccount => '创建账户';

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
  String get commonCancel => '取消';

  @override
  String get commonContinue => '继续';

  @override
  String get commonSave => '保存';

  @override
  String commonYesPerYear(String amount) {
    return '$amount/年';
  }

  @override
  String get filterCategories => '类别';

  @override
  String get filterDistance => '距离';

  @override
  String get filterOpenNow => '现在营业';

  @override
  String get filterFavorites => '收藏';

  @override
  String get filterAll => '全部';

  @override
  String get filterApply => '应用筛选';

  @override
  String get filterReset => '重置';
}
