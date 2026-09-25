import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تنبيهات المواعيد';

  @override
  String get homeTitle => 'تنبيهات المواعيد';

  @override
  String get today => 'اليوم';

  @override
  String get tomorrow => 'غدًا';

  @override
  String get todayShort => 'اليوم';

  @override
  String get tomorrowShort => 'غدًا';

  @override
  String get never => 'أبدًا';

  @override
  String get justNow => 'الآن';

  @override
  String minutesAgo(int n) {
    return 'منذ $n د';
  }

  @override
  String hoursAgo(int n) {
    return 'منذ $n س';
  }

  @override
  String daysAgo(int n) {
    return 'منذ $n ي';
  }

  @override
  String get unitKm => 'كم';

  @override
  String get unitM => 'م';

  @override
  String minutesShort(int n) {
    return '$n د';
  }

  @override
  String hoursShort(int n) {
    return '$n س';
  }

  @override
  String secondsShort(int n) {
    return '$n ث';
  }

  @override
  String daysShort(int n) {
    return '$n ي';
  }

  @override
  String get h24 => '24 س';

  @override
  String get crowFlies => 'في خط مستقيم';

  @override
  String get cancel => 'إلغاء';

  @override
  String get undo => 'تراجع';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get save => 'حفظ';

  @override
  String get settings => 'الإعدادات';

  @override
  String get androidSettings => 'الإعدادات';

  @override
  String get video => 'فيديو';

  @override
  String get doctorFallback => 'طبيب';

  @override
  String get motiveFallback => 'سبب الزيارة';

  @override
  String get alertFallbackTitle => 'تنبيه';

  @override
  String get newBadge => 'جديد';

  @override
  String slotsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n موعد',
      many: '$n موعدًا',
      few: '$n مواعيد',
      two: 'موعدان',
      one: 'موعد واحد',
    );
    return '$_temp0';
  }

  @override
  String requestsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n طلب',
      many: '$n طلبًا',
      few: '$n طلبات',
      two: 'طلبان',
      one: 'طلب واحد',
    );
    return '$_temp0';
  }

  @override
  String get cannotOpenDoctolib => 'تعذر فتح Doctolib';

  @override
  String get restore => 'إعادة التفعيل';

  @override
  String get more => 'المزيد';

  @override
  String get directions => 'الاتجاهات';

  @override
  String get ignoreSlot => 'تجاهل هذا الموعد';

  @override
  String ignoreDay(String date) {
    return 'تجاهل يوم $date';
  }

  @override
  String ignoreDoctor(String name) {
    return 'تجاهل $name';
  }

  @override
  String get noMapsApp => 'لم يتم العثور على تطبيق خرائط';

  @override
  String tripMinutes(int minutes, String phrase) {
    return '~$minutes د $phrase';
  }

  @override
  String get travelWalk => 'سيرًا';

  @override
  String get travelBike => 'دراجة';

  @override
  String get travelTransit => 'نقل عام';

  @override
  String get travelCar => 'سيارة';

  @override
  String get phraseWalk => 'سيرًا على الأقدام';

  @override
  String get phraseBike => 'بالدراجة';

  @override
  String get phraseTransit => 'بالنقل العام';

  @override
  String get phraseCar => 'بالسيارة';

  @override
  String zoneAround(String dist, String label) {
    return '$dist حول $label';
  }

  @override
  String zoneFromTravel(int minutes, String phrase, String label) {
    return '$minutes د $phrase من $label';
  }

  @override
  String zoneShortTravel(int minutes, String phrase) {
    return '$minutes د $phrase';
  }

  @override
  String get styleDiscreet => 'صامت';

  @override
  String get styleNormal => 'إشعار';

  @override
  String get styleCall => 'اتصل بي';

  @override
  String get styleDiscreetDesc => 'يظهر في لوحة الإشعارات دون صوت. للتنبيهات غير العاجلة.';

  @override
  String get styleNormalDesc => 'إشعار عادي بصوت الهاتف المعتاد.';

  @override
  String get styleCallDesc => 'يرن مثل مكالمة واتساب بمستوى صوت رنين الهاتف، ويستمر حتى تجيب، ويظهر على شاشة القفل. مخصص للمواعيد التي لا تريد تفويتها أبدًا.';

  @override
  String get ringsLikeCall => 'يرن مثل مكالمة';

  @override
  String get teleAny => 'لا يهم';

  @override
  String get teleInPerson => 'في العيادة';

  @override
  String get teleOnline => 'استشارة عن بُعد';

  @override
  String get teleAnyDesc => 'حضوريًا أو عبر الفيديو، كل موعد مقبول.';

  @override
  String get teleInPersonDesc => 'مواعيد حضورية فقط في عيادة الطبيب.';

  @override
  String get teleOnlineDesc => 'استشارات عبر الفيديو فقط، من منزلك.';

  @override
  String get teleShortInPerson => 'حضوري';

  @override
  String get teleShortOnline => 'فيديو';

  @override
  String get teleSegInPerson => 'العيادة';

  @override
  String get teleSegOnline => 'فيديو';

  @override
  String get soundSystemRingtone => 'نغمة رنين الهاتف';

  @override
  String get soundSystemAlarm => 'منبّه الهاتف';

  @override
  String get soundClassic => 'هاتف كلاسيكي';

  @override
  String get soundDigital => 'صفارات رقمية';

  @override
  String get soundSoft => 'جرس هادئ';

  @override
  String get soundMarimba => 'ماريمبا';

  @override
  String get soundUrgent => 'صفارة عاجلة';

  @override
  String windowRange(String from, String to) {
    return 'من $from إلى $to';
  }

  @override
  String get window24h => 'خلال 24 ساعة';

  @override
  String windowDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'خلال $n يوم',
      many: 'خلال $n يومًا',
      few: 'خلال $n أيام',
      two: 'خلال يومين',
      one: 'خلال يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get filterNewPatients => 'مرضى جدد';

  @override
  String get budgetVeryCautious => 'حذر جدًا';

  @override
  String get budgetCautious => 'حذر';

  @override
  String get budgetBalanced => 'متوازن';

  @override
  String get budgetReactive => 'سريع';

  @override
  String get budgetMax => 'أقصى';

  @override
  String intervalMinutes(int n) {
    return 'كل $n دقيقة';
  }

  @override
  String get intervalHour => 'كل ساعة';

  @override
  String intervalHours(int n) {
    return 'كل $n ساعات';
  }

  @override
  String quietRange(String from, String to) {
    return 'صمت من $from إلى $to';
  }

  @override
  String get quietNone => 'ليلًا ونهارًا';

  @override
  String guardPaused(int m) {
    return 'توقف أمان، متبقٍّ $m د';
  }

  @override
  String guardQuota(int n) {
    return 'تم بلوغ الحد اليومي ($n طلب)';
  }

  @override
  String guardRateLimited(int m) {
    return 'قيّد Doctolib عدد الطلبات (429). توقف لمدة $m د.';
  }

  @override
  String guardRefused(int code, int m) {
    return 'رفض Doctolib الطلب ($code). توقف لمدة $m د.';
  }

  @override
  String apiNetwork(String error) {
    return 'الشبكة غير متاحة ($error)';
  }

  @override
  String apiStatus(String code, String reason) {
    return 'ردّ Doctolib بالرمز $code$reason';
  }

  @override
  String apiCityNotFound(String city) {
    return 'المدينة غير موجودة على Doctolib: $city';
  }

  @override
  String get apiBadProfile => 'صفحة الطبيب غير مقروءة';

  @override
  String geoUnavailable(int code) {
    return 'خدمة العناوين غير متاحة ($code)';
  }

  @override
  String get monitoringPaused => 'المراقبة متوقفة';

  @override
  String unexpectedError(String error) {
    return 'خطأ غير متوقع: $error';
  }

  @override
  String failedStreak(int n, String cause) {
    return 'فشل $n مرات متتالية رغم الإصلاح التلقائي. السبب: $cause';
  }

  @override
  String repairing(int n, int max, String detail) {
    return 'جارٍ الإصلاح ($n/$max): $detail';
  }

  @override
  String get stateDisabled => 'معطّل';

  @override
  String get statePaused => 'متوقف مؤقتًا';

  @override
  String get stateError => 'خطأ';

  @override
  String get stateNothing => 'لا شيء حاليًا';

  @override
  String get incompleteSpeciality => 'تنبيه غير مكتمل: التخصص أو المدينة مفقود';

  @override
  String get incompleteDoctor => 'تنبيه غير مكتمل: الطبيب مفقود';

  @override
  String get noMotiveSelected => 'لم يتم اختيار سبب الزيارة';

  @override
  String get motivesGone => 'أسباب الزيارة المتابَعة لم تعد متاحة';

  @override
  String get chSlots => 'مواعيد متاحة';

  @override
  String get chSlotsDesc => 'موعد مطابق لأحد التنبيهات متاح.';

  @override
  String get chQuiet => 'مواعيد (صامت)';

  @override
  String get chQuietDesc => 'مواعيد تُعرض دون صوت.';

  @override
  String get chStatus => 'حالة المراقبة';

  @override
  String get chStatusDesc => 'حالة التنبيهات والأخطاء وفترات التوقف.';

  @override
  String chCall(String label) {
    return 'مكالمة: $label';
  }

  @override
  String get chCallDesc => 'يرن مثل مكالمة عندما يتوفر موعد مهم.';

  @override
  String slotAvailable(String title) {
    return '$title — موعد متاح';
  }

  @override
  String slotsAvailableTitle(String title, String slots) {
    return '$title — $slots متاحة';
  }

  @override
  String callTitle(String when) {
    return 'موعد متاح — $when';
  }

  @override
  String moreSlots(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+ $n موعد آخر',
      many: '+ $n موعدًا آخر',
      few: '+ $n مواعيد أخرى',
      two: '+ موعدان آخران',
      one: '+ موعد آخر',
    );
    return '$_temp0';
  }

  @override
  String get decline => 'رفض';

  @override
  String get viewAppointment => 'عرض الموعد';

  @override
  String missedCall(String title) {
    return 'مكالمة فائتة — $title';
  }

  @override
  String sampleTitle(String label) {
    return 'مثال — $label';
  }

  @override
  String get sampleDoctor => 'د. مثال';

  @override
  String get sampleMotive => 'استشارة أولى';

  @override
  String get sampleSpeciality => 'طبيب عام';

  @override
  String get sampleTest => 'تجربة';

  @override
  String get statusInterrupted => 'المراقبة متوقفة';

  @override
  String get statusNoAlerts => 'لا توجد تنبيهات';

  @override
  String get statusAllPaused => 'جميع التنبيهات متوقفة';

  @override
  String statusSlots(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n موعد متاح',
      many: '$n موعدًا متاحًا',
      few: '$n مواعيد متاحة',
      two: 'موعدان متاحان',
      one: 'موعد واحد متاح',
    );
    return '$_temp0';
  }

  @override
  String get statusActive => 'المراقبة نشطة';

  @override
  String statusActiveCount(int active, int total) {
    return '$active/$total تنبيهات نشطة';
  }

  @override
  String statusChecked(String ago) {
    return 'آخر فحص $ago';
  }

  @override
  String get callAvailable => 'موعد متاح';

  @override
  String callWhen(String day, String time) {
    return '$day الساعة $time';
  }

  @override
  String callRingingLeft(int s) {
    return 'يرن لمدة $s ث أخرى';
  }

  @override
  String get checkNow => 'افحص الآن';

  @override
  String get newAlert => 'تنبيه جديد';

  @override
  String get noAlerts => 'لا توجد تنبيهات';

  @override
  String get noAlertsBody => 'أنشئ تنبيهًا لتخصص في مدينة، أو لطبيب محدد. يراقب التطبيق Doctolib ويخبرك فور توفر موعد في الفترة التي اخترتها.';

  @override
  String get createAlert => 'إنشاء تنبيه';

  @override
  String pausedFor(int m) {
    return 'المراقبة متوقفة لمدة $m د';
  }

  @override
  String footerSchedule(String interval, String quiet) {
    return 'أبحث $interval، $quiet.';
  }

  @override
  String footerCost(int perRun, int perDay, int max, int today) {
    return 'حوالي $perRun طلب إلى Doctolib في كل مرة، ~$perDay يوميًا من أصل حد $max. اليوم: $today.';
  }

  @override
  String newCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n جديد',
      many: '$n جديدًا',
      few: '$n جديدة',
      two: 'جديدان',
      one: 'جديد واحد',
    );
    return '$_temp0';
  }

  @override
  String snoozedUntil(String time) {
    return 'متوقف حتى $time';
  }

  @override
  String snoozedUntilCap(String time) {
    return 'متوقف حتى $time';
  }

  @override
  String ignoredCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n متجاهَل',
      many: '$n متجاهَلًا',
      few: '$n متجاهَلة',
      two: 'اثنان متجاهَلان',
      one: 'واحد متجاهَل',
    );
    return '$_temp0';
  }

  @override
  String earliestOf(String slots, String when) {
    return '$slots · الأقرب $when';
  }

  @override
  String get nothingInWindow => 'لا شيء ضمن الفترة حاليًا';

  @override
  String checkedAgo(String ago) {
    return 'آخر فحص $ago';
  }

  @override
  String msgNewSlots(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n موعد جديد',
      many: '$n موعدًا جديدًا',
      few: '$n مواعيد جديدة',
      two: 'موعدان جديدان',
      one: 'موعد جديد',
    );
    return '$_temp0';
  }

  @override
  String msgNothingNew(String slots) {
    return '$slots (لا جديد)';
  }

  @override
  String get msgNoSlots => 'لا مواعيد ضمن الفترة';

  @override
  String get later => 'لاحقًا';

  @override
  String get start => 'ابدأ';

  @override
  String get next => 'التالي';

  @override
  String get obWelcomeBody => 'تحدد ما تبحث عنه ومتى. يراقب التطبيق Doctolib في الخلفية ويخبرك فور توفر موعد ضمن تلك الفترة، وليس لموعد بعد ثلاثة أشهر.\n\nثلاثة إعدادات سريعة وتصبح جاهزًا.';

  @override
  String get obLanguage => 'لغة التطبيق';

  @override
  String get allowNotifications => 'السماح بالإشعارات';

  @override
  String get obNotifBody => 'هكذا يخبرك التطبيق. بدون هذا الإذن يستمر في البحث لكنه لا يستطيع إبلاغك بشيء.';

  @override
  String get notifGranted => 'الإشعارات مسموحة';

  @override
  String get notifPending => 'غير مسموحة بعد';

  @override
  String get checkAgain => 'تحقق مجددًا';

  @override
  String get obBatteryTitle => 'السماح للتطبيق بالعمل في الخلفية';

  @override
  String get obBatteryBody => 'يضع أندرويد التطبيقات في وضع السكون لتوفير البطارية. إذا دخل التطبيق في السكون يتوقف عن الفحص ولن تتلقى أي شيء.\n\nاسمح له بالعمل دون قيود: هذا هو السبب الأول لتوقف هذا النوع من التطبيقات عن العمل.';

  @override
  String get batteryGranted => 'يمكن للتطبيق العمل في الخلفية';

  @override
  String get batteryPending => 'لا يزال مقيدًا بتوفير البطارية';

  @override
  String get removeRestrictions => 'إزالة القيود';

  @override
  String get openAppSettings => 'فتح إعدادات التطبيق';

  @override
  String get obBatteryOem => 'على هواتف سامسونج وشاومي وهواوي وأوبو ووان بلس، يجب غالبًا أيضًا إضافة التطبيق إلى «التطبيقات المحمية» أو استثناؤه من التحسين في إعدادات الشركة المصنعة.';

  @override
  String get quietHours => 'ساعات الهدوء';

  @override
  String get obQuietBody => 'خلال هذه الساعات لا يفحص التطبيق شيئًا ولا يرن. تنام بهدوء، ويقل أيضًا عدد الطلبات المرسلة إلى Doctolib.';

  @override
  String get enableQuietHours => 'تفعيل ساعات الهدوء';

  @override
  String quietFromTo(String from, String to) {
    return 'هدوء من $from إلى $to';
  }

  @override
  String get canRingAnytime => 'يمكن للتطبيق أن يرن في أي وقت';

  @override
  String quietStart(String h) {
    return 'بداية الهدوء: $h';
  }

  @override
  String quietEnd(String h) {
    return 'الاستيقاظ: $h';
  }

  @override
  String get changeLater => 'يمكنك تغيير ذلك في أي وقت من الإعدادات.';

  @override
  String get errNeedSpeciality => 'اختر تخصصًا واحدًا على الأقل';

  @override
  String get errNeedCity => 'اختر مدينة';

  @override
  String get errNeedDoctor => 'اختر طبيبًا';

  @override
  String get errNeedMotive => 'اختر سببًا واحدًا على الأقل';

  @override
  String get errNeedWeekday => 'أبقِ يومًا واحدًا على الأقل من الأسبوع';

  @override
  String get errEmptyHours => 'النطاق الزمني فارغ';

  @override
  String get errNeedDates => 'اختر التواريخ';

  @override
  String get editAlert => 'تعديل التنبيه';

  @override
  String get stepWhere => '1. أين؟';

  @override
  String get cityHint => 'المدينة أو البلدة';

  @override
  String get stepWhat => '2. عمّ تبحث؟';

  @override
  String get searchHint => 'التخصص، اسم الطبيب، المؤسسة...';

  @override
  String get searchHelperNoCity => 'اختر مدينة أولًا لتصفية الأطباء';

  @override
  String searchHelperCity(String city) {
    return 'أطباء $city أولًا';
  }

  @override
  String get alertName => 'اسم التنبيه';

  @override
  String get specialities => 'التخصصات';

  @override
  String get practitionersAndPlaces => 'الأطباء والمؤسسات';

  @override
  String practitionersIn(String city) {
    return 'أطباء في $city';
  }

  @override
  String get elsewhere => 'أماكن أخرى';

  @override
  String get specialityChipsHint => 'يعمل التنبيه لأي طبيب من هذه التخصصات في المدينة المختارة.';

  @override
  String get noOnlineMotive => 'لا يوجد سبب زيارة قابل للحجز عبر الإنترنت لهذا الطبيب.';

  @override
  String get motivesToWatch => 'أسباب الزيارة المراد متابعتها';

  @override
  String get whenTitle => 'متى يناسبك الموعد؟';

  @override
  String get whenBody => 'فقط المواعيد ضمن هذه الفترة تُطلق إشعارًا. هذا ما يمنع إيقاظك من أجل موعد بعد ثلاثة أشهر.';

  @override
  String get nextDays => 'الأيام القادمة';

  @override
  String get exactDates => 'تواريخ محددة';

  @override
  String get pickPeriod => 'اختر فترة';

  @override
  String get zoneCardTitle => 'حصر البحث في منطقة حولي';

  @override
  String get zoneCardBody => 'اختياري. نصف قطر بالكيلومتر أو مدة تنقل من منزلك أو موقعك أو نقطة على الخريطة. بدون منطقة تُراقب المدينة كلها.';

  @override
  String get removeZone => 'إزالة المنطقة';

  @override
  String zoneFrom(String label) {
    return 'من $label';
  }

  @override
  String zoneApprox(String dist) {
    return 'أي حوالي $dist في خط مستقيم (تقدير)';
  }

  @override
  String zoneTowns(String towns) {
    return 'البلدات المراقَبة: $towns';
  }

  @override
  String get teleTitle => 'حضوريًا أم عبر الفيديو؟';

  @override
  String get teleBody => 'يقدم كثير من الأطباء الخيارين، وغالبًا ما يتوفر موعد الفيديو أسرع بكثير من الموعد الحضوري.';

  @override
  String get howToAlert => 'كيف نخبرك؟';

  @override
  String get howToAlertBody => 'خاص بكل تنبيه: طبيب أطفال لطفل مريض يستحق رنين الهاتف، أما الفحص الروتيني فلا.';

  @override
  String get callHint => 'الزر الأخضر: يفتح الموعد مباشرة. الزر الأحمر أو عدم الرد: يبقى إشعار عادي. تُختار النغمة ومدتها من الإعدادات. ساعات الهدوء لها الأولوية: لا رنين ليلًا.';

  @override
  String get filters => 'عوامل التصفية';

  @override
  String get filtersBody => 'لا يوفر Doctolib أيًا من هذه العوامل. يطبقها التطبيق على المواعيد المستلمة ليخبرك فقط بما يمكنك حضوره فعلًا.';

  @override
  String hourRange(String from, String to) {
    return 'النطاق الزمني: $from — $to';
  }

  @override
  String get acceptedDays => 'الأيام المقبولة';

  @override
  String get acceptsNewPatients => 'يقبل مرضى جددًا';

  @override
  String get acceptsNewPatientsBody => 'يتجاهل الأطباء الذين يستقبلون مرضاهم الحاليين فقط';

  @override
  String get appearance => 'المظهر';

  @override
  String get language => 'اللغة';

  @override
  String get langSystem => 'لغة الهاتف';

  @override
  String get theme => 'السمة';

  @override
  String get themeSystem => 'تلقائي';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get frequencyTitle => 'كم مرة يتم البحث؟';

  @override
  String searchEvery(String interval) {
    return 'أبحث $interval';
  }

  @override
  String get frequencyBody => 'لا يشغّل أندرويد الفحص أكثر من مرة كل 15 دقيقة، وقد يؤخره أثناء سكون الهاتف. «أكثر تكرارًا» تعني «في أقرب وقت ممكن» وليس «بالثانية».';

  @override
  String get freq15Advice => 'كل 15 دقيقة هو الحد الأدنى الذي يسمح به أندرويد، وليس بالضرورة الأفضل: يستهلك أربعة أضعاف طلبات الستين دقيقة مقابل فائدة صغيرة، لأن النظام يؤخر المهام أثناء السكون على أي حال. استخدمه لبحث عاجل فعلًا لبضعة أيام.';

  @override
  String get freqBalancedAdvice => 'توازن جيد: سريع بما يكفي لالتقاط إلغاء، وخفيف بما يكفي للعمل أسابيع.';

  @override
  String get freqSlowAdvice => 'اقتصادي جدًا. مناسب لبحث طويل لا تختفي فيه المواعيد خلال دقائق.';

  @override
  String get allowBackground => 'السماح للتطبيق بالعمل في الخلفية';

  @override
  String get allowBackgroundBody => 'بدون ذلك يضع أندرويد التطبيق في السكون وتتوقف الفحوصات. هذا هو السبب الأول للتنبيهات التي لا ترن أبدًا.';

  @override
  String get backgroundRestricted => 'لا يزال مقيدًا: افتح إعدادات أندرويد';

  @override
  String quietOnBody(String from, String to) {
    return 'بين $from و$to لا يبحث التطبيق ولا يرن، ولا حتى تنبيه «اتصل بي».';
  }

  @override
  String get quietOffBody => 'يبحث التطبيق ويمكن أن يرن في أي وقت';

  @override
  String get fromLabel => 'من';

  @override
  String get toLabel => 'إلى';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get groupByAlert => 'التجميع حسب التنبيه';

  @override
  String get groupByAlertBody => 'إشعار واحد يلخص كل المواعيد الجديدة بدلًا من إشعار لكل موعد.';

  @override
  String get statusBadge => 'شارة مراقبة دائمة';

  @override
  String get statusBadgeBody => 'يُبقي سطرًا صامتًا في لوحة الإشعارات مثل برامج الحماية: حالة كل تنبيه وعدد المواعيد المتاحة ووقت آخر بحث. أفضل طريقة للتأكد بنظرة أن التطبيق ما زال يعمل.';

  @override
  String get needAndroid13 => 'مطلوب على أندرويد 13 وما بعده';

  @override
  String get notifRefused => 'مرفوض: فعّلها من إعدادات أندرويد';

  @override
  String get testAlert => 'تجربة تنبيه';

  @override
  String get testAlertBody => 'استمع إلى كل نمط قبل أن تعتمد عليه لموعد حقيقي.';

  @override
  String sampleSent(String label) {
    return 'تم إرسال مثال: $label';
  }

  @override
  String get callModeTitle => 'وضع «اتصل بي»';

  @override
  String get callModeBody => 'يرن الهاتف حتى تجيب. الزر الأخضر يفتح الموعد على Doctolib مباشرة. الزر الأحمر أو عدم الرد يوقف الرنين ويترك إشعارًا عاديًا: يبقى الموعد على بُعد لمسة.';

  @override
  String get soundBundled => 'مرفقة مع التطبيق';

  @override
  String get soundSystem => 'المضبوطة على هاتفك';

  @override
  String get listen => 'استماع';

  @override
  String testCallSent(String label) {
    return 'مكالمة تجريبية: $label (12 ث، جرّب الزرين)';
  }

  @override
  String get ringDuration => 'مدة الرنين';

  @override
  String ringDurationBody(int s) {
    return 'إذا لم ترد بعد $s ث يتوقف الاتصال ويحل محله إشعار «مكالمة فائتة».';
  }

  @override
  String get blockTitle => 'تجنب الحظر';

  @override
  String get blockBody => 'يراقب Doctolib الهواتف التي ترسل طلبات كثيرة ويتجاهلها لفترة. تُبقي هذه الإعدادات التطبيق أدنى من ذلك بكثير: طلبات قليلة ومتباعدة، ويتوقف من تلقاء نفسه إذا اعترض الموقع.';

  @override
  String get frugalTitle => 'الوضع الاقتصادي (موصى به)';

  @override
  String get frugalBody => 'لا يطلب الأوقات الدقيقة إلا للأطباء غير المكتشفين بعد: يكلف البحث حينها 1 إلى 3 طلبات بدل عشرين تقريبًا. هذا أكثر ما يحمي من الحظر.';

  @override
  String safetyLimit(String label) {
    return 'حد الأمان: $label';
  }

  @override
  String safetyLimitBody(int max, int today) {
    return 'بحد أقصى $max طلب إلى Doctolib يوميًا لكل التنبيهات. بعد هذا الحد يتوقف التطبيق حتى اليوم التالي بدل المخاطرة بالحظر. اليوم: $today مستخدمة.';
  }

  @override
  String get estimate => 'تقدير';

  @override
  String estimateBody(String interval, String quiet, int perRun, int perDay, int max) {
    return 'تبحث $interval، $quiet. هذا حوالي $perRun طلب إلى Doctolib في كل مرة، أي نحو $perDay يوميًا من أصل حد $max.';
  }

  @override
  String get overLimit => 'هذا فوق حدك: ابحث بتكرار أقل، أو مدّد ساعات الهدوء، أو أبقِ تنبيهات أقل نشطة.';

  @override
  String get safetyPause => 'توقف أمان';

  @override
  String resumeIn(int m) {
    return 'الاستئناف بعد $m د.';
  }

  @override
  String get about => 'حول التطبيق';

  @override
  String get howItWorks => 'كيف يعمل';

  @override
  String get howItWorksBody => 'يستعلم التطبيق من نفس نقاط JSON التي يستخدمها موقع doctolib.fr عند تصفحه. لا شيء يغادر الهاتف: لا حساب، لا خادم، ولا بيانات صحية محفوظة. يتم الحجز على Doctolib في متصفحك.';

  @override
  String get personalUse => 'استخدام شخصي';

  @override
  String get personalUseBody => 'هذه النقاط غير موثقة وقد تتغير دون إشعار. حافظ على وتيرة معقولة واستخدام شخصي فقط.';

  @override
  String get alertDeleted => 'تم حذف التنبيه';

  @override
  String get nearestFirst => 'من الأقرب إلى الأبعد';

  @override
  String get ignoreAll => 'تجاهل الكل';

  @override
  String get resumeNow => 'استئناف الآن';

  @override
  String get snoozeMenu => 'إيقاف مؤقت…';

  @override
  String get restoreAll => 'إعادة تفعيل الكل';

  @override
  String get duplicate => 'نسخ';

  @override
  String get renotify => 'إعادة الإشعار بالمواعيد المعروفة';

  @override
  String get check => 'فحص';

  @override
  String get earliest => 'الأبكر';

  @override
  String get nearest => 'الأقرب';

  @override
  String noSlotsWindow(String window) {
    return 'لا مواعيد $window';
  }

  @override
  String get allIgnored => 'كل شيء متجاهَل حاليًا';

  @override
  String get keepsChecking => 'يواصل التطبيق الفحص في الخلفية وسيخبرك فور توفر موعد.';

  @override
  String get ignoredHidden => 'المواعيد المعروفة مخفية. أي موعد جديد سيظهر باللون الأحمر وسيتم إشعارك به.';

  @override
  String ignoredHeader(int n) {
    return 'متجاهَل ($n)';
  }

  @override
  String slotsWindow(String window) {
    return 'مواعيد $window';
  }

  @override
  String lastCheck(String ago) {
    return 'آخر فحص $ago';
  }

  @override
  String repairInProgress(int n, int max) {
    return 'إصلاح تلقائي جارٍ ($n/$max): يُعاد بناء التنبيه من Doctolib في كل محاولة.';
  }

  @override
  String repairedAgo(String ago) {
    return 'تم الإصلاح تلقائيًا $ago';
  }

  @override
  String get alertActive => 'التنبيه نشط';

  @override
  String zoneApproxParen(String dist) {
    return '(حوالي $dist في خط مستقيم)';
  }

  @override
  String zoneTownsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n بلدة',
      many: '$n بلدة',
      few: '$n بلدات',
      two: 'بلدتان',
      one: 'بلدة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get slotIgnored => 'تم تجاهل الموعد';

  @override
  String dayIgnored(String date) {
    return 'تم تجاهل يوم $date';
  }

  @override
  String doctorIgnored(String name) {
    return 'تم تجاهل $name';
  }

  @override
  String ignoredAll(String slots) {
    return 'تم تجاهل $slots، سيتم إبلاغك بالجديدة فقط';
  }

  @override
  String get allRestored => 'تمت إعادة تفعيل الكل';

  @override
  String get snoozeFor => 'إيقاف مؤقت لمدة';

  @override
  String hoursCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ساعة',
      many: '$n ساعة',
      few: '$n ساعات',
      two: 'ساعتان',
      one: 'ساعة واحدة',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n يوم',
      many: '$n يومًا',
      few: '$n أيام',
      two: 'يومان',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String copyTitle(String title) {
    return '$title (نسخة)';
  }

  @override
  String get renotified => 'سيتم الإشعار بالمواعيد الحالية مجددًا';

  @override
  String get deleteConfirm => 'حذف هذا التنبيه؟';

  @override
  String get pointOnMap => 'نقطة مختارة على الخريطة';

  @override
  String get locationOff => 'خدمة الموقع في الهاتف متوقفة.';

  @override
  String get locationDeniedForever => 'تم رفض الموقع. اسمح به من إعدادات التطبيق أو اختر نقطة على الخريطة.';

  @override
  String get locationDenied => 'تم رفض الموقع. يمكنك اختيار نقطة على الخريطة أو كتابة عنوان.';

  @override
  String positionNotFound(String error) {
    return 'تعذر تحديد الموقع ($error)';
  }

  @override
  String get needPoint => 'اختر نقطة انطلاق أولًا.';

  @override
  String get findingTowns => 'جارٍ البحث عن البلدات في المنطقة...';

  @override
  String preparingTown(String name, int i, int n) {
    return 'تجهيز $name على Doctolib ($i/$n)';
  }

  @override
  String get pointChosen => 'النقطة المختارة';

  @override
  String zonePrepFailed(String error) {
    return 'تعذر تجهيز المنطقة: $error';
  }

  @override
  String get zoneTitle => 'منطقة البحث';

  @override
  String get addressOptional => 'العنوان (اختياري)';

  @override
  String get myPosition => 'موقعي';

  @override
  String get tapMapHint => 'المس الخريطة لتحديد نقطة الانطلاق، أو استخدم «موقعي» أو عنوانًا.';

  @override
  String get circle => 'دائرة';

  @override
  String get travelTime => 'مدة التنقل';

  @override
  String radiusLabel(String dist) {
    return 'نصف القطر: $dist في خط مستقيم';
  }

  @override
  String atMost(int minutes, String phrase) {
    return 'بحد أقصى $minutes د $phrase';
  }

  @override
  String travelEstimate(String dist) {
    return 'تقدير: حوالي $dist في خط مستقيم. محسوب بمتوسط السرعات في المدينة (مع الانتظار والمشي للنقل العام)؛ لا يتم الاطلاع على الجداول الفعلية.';
  }

  @override
  String get validateZone => 'تأكيد المنطقة';

  @override
  String get showWholeZone => 'عرض المنطقة كاملة';

  @override
  String get centerOnPoint => 'التمركز على النقطة';

  @override
  String get journal => 'السجل';

  @override
  String get journalBody => 'ما قام به التطبيق فحصًا بفحص: للتأكد من أنه يعمل فعلًا في الخلفية، ولمعرفة أوقات توفر المواعيد عادة.';

  @override
  String get journalEmpty => 'لا يوجد نشاط بعد.';

  @override
  String get journalClear => 'مسح السجل';

  @override
  String get journalBackground => 'في الخلفية';

  @override
  String get journalManual => 'يدوي';

  @override
  String journalFound(String title, String slots, int fresh) {
    return '$title: $slots، منها $fresh جديد';
  }

  @override
  String journalNothing(String title) {
    return '$title: لا شيء ضمن الفترة';
  }

  @override
  String journalError(String title, String error) {
    return '$title: $error';
  }

  @override
  String journalBusiestHour(String hour) {
    return 'الساعة التي تظهر فيها المواعيد الجديدة غالبًا: $hour';
  }

  @override
  String get journalCallAccepted => 'تم الرد على المكالمة';

  @override
  String get journalCallDeclined => 'تم رفض المكالمة';

  @override
  String get journalCallMissed => 'مكالمة فائتة';
}
