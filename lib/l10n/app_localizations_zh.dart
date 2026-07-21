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
  String get homeRecentlyViewed => '最近浏览的机构';

  @override
  String get homeNoRecentlyViewed => '暂无最近浏览的机构';

  @override
  String get homeNoRecentlyViewedHint => '在地图上点击机构即可在此查看。';

  @override
  String get mapSearchLocation => '输入邮政编码';

  @override
  String get mapSearchResourcesHint => '搜索资源...';

  @override
  String get mapAreaLabel => '地图区域';

  @override
  String get mapSearchThisArea => '搜索此区域';

  @override
  String get mapSearching => '搜索中…';

  @override
  String get mapSwipeUpToView => '上滑查看资源';

  @override
  String get mapResourcesNearYou => '附近的资源';

  @override
  String get mapNoFacilitiesInArea => '此区域没有机构';

  @override
  String get mapCantFindFacility => '找不到机构？提交请求以添加。';

  @override
  String get mapRequestFacility => '请求添加机构';

  @override
  String get mapLoadFailed => '加载机构失败，请重试。';

  @override
  String get mapRetry => '重试';

  @override
  String get mapInvalidZip => '请输入有效的 5 位邮政编码（例如 60605）';

  @override
  String mapZipNotFound(String zipCode) {
    return '找不到邮政编码 $zipCode 对应的位置。';
  }

  @override
  String get filterOpenNow => '营业中';

  @override
  String get filterFavorites => '收藏';

  @override
  String get filterCategory => '类别';

  @override
  String get filterPreferences => '偏好';

  @override
  String get filterFilters => '筛选';

  @override
  String get filterClearAll => '全部清除';

  @override
  String get filterApply => '应用';

  @override
  String get commonYes => '是';

  @override
  String get commonNo => '否';

  @override
  String get eligProofOfIncome => '需要收入证明';

  @override
  String get eligProofOfResidency => '需要居住证明';

  @override
  String get eligInsuranceRequired => '需要医疗保险';

  @override
  String get eligReferralRequired => '需要转诊';

  @override
  String get prefAcceptsWalkIns => '接受无预约就诊';

  @override
  String get prefAppointmentOnly => '仅限预约';

  @override
  String get prefOpenToImmigrants => '向移民开放';

  @override
  String get prefFreeServices => '提供免费服务';

  @override
  String get prefSlidingScale => '提供按收入浮动收费';

  @override
  String get prefOtherLanguages => '提供其他语言服务';

  @override
  String get prefTelehealth => '提供远程医疗';

  @override
  String get prefWheelchairAccessible => '无障碍通道';

  @override
  String get prefServesOutsideArea => '服务范围外人群';

  @override
  String get cardNextSteps => '下一步';

  @override
  String get cardHours => '营业时间';

  @override
  String get cardServices => '服务';

  @override
  String get cardAtAGlance => '一览';

  @override
  String get cardVisitWebsite => '访问网站';

  @override
  String get cardWebsiteNotAvailable => '网站不可用';

  @override
  String get cardGetDirections => '获取路线';

  @override
  String get cardContactForHours => '请联系机构了解营业时间';

  @override
  String get cardOpen247 => '24/7 全天开放';

  @override
  String get cardAddressNotAvailable => '该机构的地址信息不可用';

  @override
  String get chipWalkIns => '无需预约';

  @override
  String get chipFree => '免费';

  @override
  String get chipTelehealth => '远程医疗';

  @override
  String get chipAccessible => '无障碍';

  @override
  String get chipSlidingScale => '浮动收费';

  @override
  String get chipOtherLanguages => '其他语言';

  @override
  String get ratingAlreadyRated => '您已评价过 — 在下方更新。';

  @override
  String get ratingDateVisited => '到访日期';

  @override
  String get ratingRemove => '删除';

  @override
  String get ratingSubmit => '提交';

  @override
  String get ratingUpdate => '更新';

  @override
  String get ratingThanks => '感谢您的评价！';

  @override
  String get ratingUpdated => '评价已更新。';

  @override
  String get ratingRemoved => '评价已删除。';

  @override
  String get ratingSendFailed => '评价发送失败，请重试。';

  @override
  String get ratingRemoveFailed => '评价删除失败，请重试。';

  @override
  String get ratingSignInRequired => '请登录后再评价机构。';

  @override
  String get requestDialogTitle => '请求添加机构';

  @override
  String get requestDialogIntro => '告诉我们遗漏的机构，我们的团队会进行审核。';

  @override
  String get requestFieldName => '机构名称 *';

  @override
  String get requestFieldNameError => '请输入机构名称';

  @override
  String get requestSubmitted => '请求已提交 — 我们会尽快审核。谢谢！';

  @override
  String get requestSubmitFailed => '请求提交失败，请重试。';

  @override
  String get requestSignInRequired => '请登录后再提交请求。';

  @override
  String get settingsYourRatings => '您的评价';

  @override
  String get settingsYourRequests => '您的请求';

  @override
  String get settingsDirectionsApp => '导航应用';

  @override
  String get settingsAskEachTime => '每次询问';

  @override
  String get settingsSignInHint => '登录即可保存收藏、按偏好筛选等！';

  @override
  String get settingsZipUpdated => '邮政编码已更新';

  @override
  String get settingsUpdateZipTitle => '更新邮政编码';

  @override
  String get settingsZipValidation => '请输入 5 位邮政编码';

  @override
  String get settingsZipNotFoundError => '找不到该邮政编码，请重试。';

  @override
  String get ratingsEmptyTitle => '您还没有评价任何机构。';

  @override
  String get ratingsEmptyHint => '在地图上或首页的最近浏览中评价机构，您的评价将显示在这里。';

  @override
  String ratingsVisitedOn(String date) {
    return '到访于 $date';
  }

  @override
  String get requestsEmptyTitle => '暂无请求';

  @override
  String get requestsEmptyHint => '知道我们遗漏的机构吗？提交请求，我们会进行审核。';

  @override
  String get directionsOpenWith => '使用以下应用打开路线';

  @override
  String get directionsChangeLater => '您可以稍后在设置中更改。';

  @override
  String get directionsOpenFailed => '无法打开路线。';

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

  @override
  String get navProfile => '个人资料';

  @override
  String get profileApplyEligibility => '将资格条件应用于搜索';

  @override
  String get profileApplyEligibilityDesc => '仅显示符合您资格的机构。';

  @override
  String get commonSave => '保存';

  @override
  String get onboardingEligibilityTitle => '您的资格';

  @override
  String get onboardingEligibilitySubtitle =>
      '告诉我们哪些适用于您，以便显示您符合条件的机构。您可以随时在个人资料中更改。';

  @override
  String get onboardingContinue => '继续';

  @override
  String get requestFieldWebsite => '机构网站 *';

  @override
  String get requestFieldWebsiteError => '请输入机构网站';

  @override
  String get correctionDialogTitle => '提交更正';

  @override
  String get correctionDialogIntro => '更正任何有误的信息，我们的团队会进行审核。';

  @override
  String get correctionFieldName => '名称';

  @override
  String get correctionFieldWebsite => '网站';

  @override
  String get correctionFieldPhone => '电话';

  @override
  String get correctionFieldHours => '营业时间';

  @override
  String get correctionFieldAddress => '地址';

  @override
  String get correctionSubmitted => '更正已提交 — 我们会进行审核。谢谢！';

  @override
  String get correctionSubmitFailed => '更正提交失败，请重试。';

  @override
  String get requestTypeNew => '新机构';

  @override
  String get requestTypeCorrection => '更正';

  @override
  String get cardRatePromptLead => '去过了？';

  @override
  String get cardRatePromptAction => '评价您的体验';

  @override
  String get cardCorrectionPromptLead => '信息有误？';

  @override
  String get cardCorrectionPromptAction => '在此提交更正';
}
