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
  String get homeFavoritesSignInTitle => '登录以保存收藏';

  @override
  String get homeFavoritesSignInHint => '登录即可收藏您喜欢的机构。';

  @override
  String get homeRecentlyViewed => '最近浏览';

  @override
  String get homeNoRecentlyViewed => '暂无最近浏览的机构';

  @override
  String get homeNoRecentlyViewedHint => '在地图上点击机构即可在此查看。';

  @override
  String get mapSearchLocation => '输入邮政编码';

  @override
  String get mapSearchResourcesHint => '搜索资源';

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
  String get mapInvalidZip => '请输入 5 位邮政编码。';

  @override
  String mapZipNotFound(String zipCode) {
    return '找不到邮政编码 $zipCode。';
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
  String get eligProofOfIncome => '收入证明';

  @override
  String get eligProofOfResidency => '住址证明';

  @override
  String get eligInsuranceRequired => '医疗保险';

  @override
  String get eligReferralRequired => '医生转诊单';

  @override
  String get prefAcceptsWalkIns => '接受无预约就诊';

  @override
  String get prefAppointmentOnly => '需要预约';

  @override
  String get prefOpenToImmigrants => '向移民开放';

  @override
  String get prefFreeServices => '提供免费服务';

  @override
  String get prefSlidingScale => '按收入浮动收费';

  @override
  String get prefOtherLanguages => '提供其他语言服务';

  @override
  String get prefTelehealth => '提供远程医疗';

  @override
  String get prefWheelchairAccessible => '设有无障碍通道';

  @override
  String get prefServesOutsideArea => '服务所在地区以外的人群';

  @override
  String get cardHours => '营业时间';

  @override
  String get cardServices => '服务';

  @override
  String get cardServicesAiDisclaimer => '摘要由 AI 撰写，可能有误。';

  @override
  String get cardAtAGlance => '一览';

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
  String get settingsSignInHint => '登录即可保存收藏，并在任何设备上使用。';

  @override
  String get settingsZipUpdated => '邮政编码已更新';

  @override
  String get settingsUpdateZipTitle => '更新邮政编码';

  @override
  String get settingsZipValidation => '请输入 5 位邮政编码。';

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
  String get settingsEligibility => '您能提供的材料';

  @override
  String get settingsZipCode => '邮政编码';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsTermsOfService => '服务条款';

  @override
  String get settingsSignOut => '退出登录';

  @override
  String get settingsSignOutConfirm => '您的收藏和设置会保留在账户中，并从此手机上移除。';

  @override
  String get settingsDeleteAccount => '删除账户';

  @override
  String get deleteAccountTitle => '确定删除账户？';

  @override
  String get deleteAccountBody =>
      '此操作将永久删除您的账户、已保存的收藏、资格信息和设置。您提交的评价和信息更正会保留在目录中，但不再与您关联。此操作无法撤销。';

  @override
  String get deleteAccountConfirm => '删除账户';

  @override
  String get deleteAccountInProgress => '正在删除您的账户…';

  @override
  String get deleteAccountSuccess => '您的账户已删除';

  @override
  String get deleteAccountFailed => '无法删除您的账户，请重试。';

  @override
  String coverageNotice(String states) {
    return 'Beacon 目前收录$states的服务机构，我们会逐步添加更多州。';
  }

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
  String get authTermsPrefix => '继续即表示您同意我们的';

  @override
  String get authTermsOfService => '服务条款';

  @override
  String get authAnd => '和';

  @override
  String get authPrivacyPolicy => '隐私政策';

  @override
  String get authSelectLanguage => '选择语言';

  @override
  String get authSignInPromptTitle => '请登录以使用此功能';

  @override
  String get authSignInPromptBody => '登录即可保存收藏、按偏好筛选并评价机构。';

  @override
  String get authSignInError => '登录失败，请重试。';

  @override
  String get locationChoiceTitle => '您希望如何查找资源？';

  @override
  String get locationChoiceSubtitle => '我们将以此向您显示附近的资源。';

  @override
  String get locationChoiceUseLocation => '使用我的位置';

  @override
  String get locationChoiceUseLocationDesc => '最准确。接下来会请求您的许可。';

  @override
  String get locationChoiceEnterZip => '输入邮政编码';

  @override
  String get locationChoiceEnterZipDesc => '无需共享位置即可搜索某一地区。';

  @override
  String get locationCurrentLocation => '当前位置';

  @override
  String get locationPermissionDenied => '位置访问已关闭。请在手机设置中为 Beacon 开启。';

  @override
  String get locationPermissionDeniedTitle => '需要位置访问权限';

  @override
  String get locationPermissionDeniedBody =>
      '若要按您的位置搜索，请在手机设置中为 Beacon 开启位置访问。';

  @override
  String get locationUseMyLocationTooltip => '使用我的位置';

  @override
  String get settingsUseMyLocation => '使用我的位置';

  @override
  String get settingsUseMyLocationDesc => '代替邮政编码';

  @override
  String get settingsSignOutSuccess => '已退出登录';

  @override
  String get commonCancel => '取消';

  @override
  String get navProfile => '个人资料';

  @override
  String get profileApplyEligibility => '按我能提供的材料筛选';

  @override
  String get profileApplyEligibilityDesc => '隐藏要求提供您未在下方勾选材料的机构。';

  @override
  String get profileSignedIn => '已登录';

  @override
  String profileSignedInThrough(String provider) {
    return '已通过 $provider 登录';
  }

  @override
  String get commonSave => '保存';

  @override
  String get homeCategoryHealthCare => '医疗保健';

  @override
  String get homeCategoryMentalHealth => '心理健康';

  @override
  String get homeCategoryHousing => '住房与庇护';

  @override
  String get homeCategoryBasicNeeds => '基本需求';

  @override
  String get homeCategoryCommunity => '社区资源';

  @override
  String get homeCategorySpecialized => '专项服务';

  @override
  String get commonLinkFailed => '无法打开该链接。';

  @override
  String get onboardingEligibilityTitle => '您能提供哪些材料？';

  @override
  String get onboardingEligibilitySubtitle => '我们会隐藏您无法使用的机构。您可以随时在个人资料中更改。';

  @override
  String get onboardingContinue => '继续';

  @override
  String get onboardingTagline => '查找您附近的免费和低价资源。';

  @override
  String get zipEntryTitle => '您的邮政编码是什么？';

  @override
  String get zipEntrySubtitle => '我们将用它为您显示附近的资源。';

  @override
  String get zipEntryInvalid => '请输入 5 位邮政编码。';

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

  @override
  String zipOutsideCoverage(String states) {
    return 'Beacon 暂未覆盖该地区，目前覆盖$states。';
  }

  @override
  String stateName(String code) {
    String _temp0 = intl.Intl.selectLogic(
      code,
      {
        'AL': '阿拉巴马州',
        'AK': '阿拉斯加州',
        'AZ': '亚利桑那州',
        'AR': '阿肯色州',
        'CA': '加利福尼亚州',
        'CO': '科罗拉多州',
        'CT': '康涅狄格州',
        'DE': '特拉华州',
        'DC': '华盛顿特区',
        'FL': '佛罗里达州',
        'GA': '佐治亚州',
        'GU': '关岛',
        'HI': '夏威夷州',
        'ID': '爱达荷州',
        'IL': '伊利诺伊州',
        'IN': '印第安纳州',
        'IA': '艾奥瓦州',
        'KS': '堪萨斯州',
        'KY': '肯塔基州',
        'LA': '路易斯安那州',
        'ME': '缅因州',
        'MD': '马里兰州',
        'MA': '马萨诸塞州',
        'MI': '密歇根州',
        'MN': '明尼苏达州',
        'MS': '密西西比州',
        'MO': '密苏里州',
        'MT': '蒙大拿州',
        'NE': '内布拉斯加州',
        'NV': '内华达州',
        'NH': '新罕布什尔州',
        'NJ': '新泽西州',
        'NM': '新墨西哥州',
        'NY': '纽约州',
        'NC': '北卡罗来纳州',
        'ND': '北达科他州',
        'OH': '俄亥俄州',
        'OK': '俄克拉荷马州',
        'OR': '俄勒冈州',
        'PA': '宾夕法尼亚州',
        'PR': '波多黎各',
        'RI': '罗得岛州',
        'SC': '南卡罗来纳州',
        'SD': '南达科他州',
        'TN': '田纳西州',
        'TX': '得克萨斯州',
        'UT': '犹他州',
        'VT': '佛蒙特州',
        'VA': '弗吉尼亚州',
        'VI': '美属维尔京群岛',
        'WA': '华盛顿州',
        'WV': '西弗吉尼亚州',
        'WI': '威斯康星州',
        'WY': '怀俄明州',
        'other': '$code',
      },
    );
    return '$_temp0';
  }

  @override
  String listTwo(String first, String second) {
    return '$first和$second';
  }

  @override
  String listTwoBeforeI(String first, String second) {
    return '$first和$second';
  }

  @override
  String listMany(String rest, String last) {
    return '$rest和$last';
  }

  @override
  String listManyBeforeI(String rest, String last) {
    return '$rest和$last';
  }

  @override
  String get listSeparator => '、';

  @override
  String mapResourcesInView(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '此区域有 $count 个资源',
    );
    return '$_temp0';
  }

  @override
  String get mapNothingInView => '地图的这一区域没有资源';

  @override
  String get mapNothingInViewHint => '缩小或移动地图以查看更多。';

  @override
  String get eligAcceptsMedicaid => 'Medicaid（医疗补助）';

  @override
  String get chipMedicaid => 'Medicaid';

  @override
  String get cardIncomeLimit => '收入限制';

  @override
  String get cardServiceArea => '服务区域';

  @override
  String get labelSeparator => '：';

  @override
  String get correctionFieldClosed => '已永久关闭';

  @override
  String get correctionFieldClosedHint => '如果该机构已永久停业，请开启此项。';

  @override
  String get requestTypeClosure => '已报告关闭';

  @override
  String get homeOpenMap => '打开地图';

  @override
  String filterShowResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '显示 $count 个结果',
      zero: '没有结果',
    );
    return '$_temp0';
  }

  @override
  String get filterOnlyShowPlacesThat => '仅显示符合以下条件的机构';

  @override
  String get filterClose => '关闭筛选';

  @override
  String filterCategoriesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个类别',
    );
    return '$_temp0';
  }

  @override
  String get cardDirections => '路线';

  @override
  String get cardCall => '致电';

  @override
  String cardCallNumber(String phone) {
    return '致电 $phone';
  }

  @override
  String get cardWebsite => '网站';

  @override
  String cardSave(String name) {
    return '收藏 $name';
  }

  @override
  String cardUnsave(String name) {
    return '取消收藏 $name';
  }

  @override
  String get cardShowDetails => '显示详情';

  @override
  String get cardHideDetails => '隐藏详情';

  @override
  String get eligProofOfIncomeHint => '工资单、报税表或福利证明信';

  @override
  String get eligProofOfResidencyHint => '身份证件、租约或水电费账单';

  @override
  String get onboardingSkip => '暂时跳过';

  @override
  String onboardingStep(int step, int total) {
    return '第 $step 步，共 $total 步';
  }

  @override
  String get profileSavedOnDevice => '保存在此设备上';

  @override
  String get authTermsSuffix => '。';

  @override
  String authLanguageButton(String language) {
    return '语言：$language。更改语言';
  }

  @override
  String get zipEntryHelper => '5 位数字';

  @override
  String get zipEntryLocationOff => '位置访问已关闭，请改为输入邮政编码。';

  @override
  String get settingsSignOutTitle => '退出登录？';

  @override
  String settingsVersionFooter(String version) {
    return 'Beacon $version';
  }

  @override
  String get settingsAccessibility => '无障碍';

  @override
  String get settingsMapAsList => '以列表形式打开地图';

  @override
  String get settingsMapAsListDesc => '更适合屏幕阅读器';

  @override
  String get settingsLargerPins => '放大地图标记';

  @override
  String get settingsLargerPinsDesc => '放大地图上的标记和名称';

  @override
  String get settingsAppearanceSystem => '跟随设备';

  @override
  String get settingsAppearanceLight => '浅色';

  @override
  String get settingsAppearanceDark => '深色';

  @override
  String get commonNotSet => '未设置';

  @override
  String get navAsk => '提问';

  @override
  String get askTitle => '提问';

  @override
  String get askHeading => '您想找什么帮助？';

  @override
  String get askSuggestionClinic => '附近的免费诊所';

  @override
  String get askSuggestionTalk => '找人倾诉';

  @override
  String get askSuggestionFood => '正在开放的食物银行';

  @override
  String get askSuggestionShelter => '今晚的住处';

  @override
  String get askCrisisNote => '遇到紧急情况请拨打 911。如果您正处于危机中或有自杀念头，请拨打或发短信至 988。';

  @override
  String get askCrisisTitle => '现在就可以获得帮助';

  @override
  String get askCall911 => '拨打 911';

  @override
  String get askCall988 => '拨打或发短信至 988';

  @override
  String get askInputLabel => '输入您需要的帮助';

  @override
  String get askSend => '发送';

  @override
  String get askPrivacyFooter => '在此手机上运行，聊天内容不会发送到任何地方。';

  @override
  String get askNewChat => '新对话';

  @override
  String get askThinking => '正在查找…';

  @override
  String askFoundSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '我找到了 $count 个符合条件的机构，以下是最近的几个。',
    );
    return '$_temp0';
  }

  @override
  String get askAiNote => 'AI 解读了您的请求。请向机构核实详情。';

  @override
  String get askShowOnMap => '在地图上显示';

  @override
  String get askOnlyOpenNow => '仅显示营业中';

  @override
  String get askOpenMap => '打开地图';

  @override
  String get askOpenMapWithFilters => '使用这些筛选条件打开地图';

  @override
  String get askHandoffUnclear => '我没能明白要搜索什么。请试着说出您需要的帮助类型，或自行在地图上搜索。';

  @override
  String get askHandoffNoResults => '我没有在附近找到符合条件的机构。您可以在地图上查看更远的范围或更改筛选条件。';

  @override
  String get askHandoffMedical => '我无法提供医疗建议。我可以帮您找到就诊的地方，您也可以在地图上搜索。';

  @override
  String get askHandoffOffTopic => '我只能帮您在 Beacon 中查找服务。请试着说出您需要的帮助类型，或在地图上搜索。';

  @override
  String askDistanceMiles(String distance) {
    return '$distance 英里';
  }

  @override
  String askDirectionsTo(String name) {
    return '前往 $name 的路线';
  }

  @override
  String get askNotReadyTitle => '助手尚未就绪';

  @override
  String get askNotReadyBody => '您的手机仍在准备，或已在手机设置中关闭。在此期间，您可以在地图上搜索。';

  @override
  String get askLanguageTitle => '助手暂不支持此语言';

  @override
  String get askLanguageBody => '您手机上的助手无法用此语言回答。您可以改为在地图上搜索。';

  @override
  String get askSearchMap => '在地图上搜索';

  @override
  String get chipImmigrants => '向移民开放';

  @override
  String get askCrisisKeywords =>
      '自杀|想死|不想活|轻生|结束生命|伤害自己|自残|服药过量|家暴|被虐待|打我|有危险|紧急情况|急救|无法呼吸|喘不过气|胸痛';

  @override
  String get askSearchedFor => '我搜索的条件';

  @override
  String get askNoneOpenNow => '这些机构目前都未营业。';
}
