import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Appointment Alerts';

  @override
  String get homeTitle => 'Appointment alerts';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get todayShort => 'today';

  @override
  String get tomorrowShort => 'tomorrow';

  @override
  String get never => 'never';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int n) {
    return '$n min ago';
  }

  @override
  String hoursAgo(int n) {
    return '$n h ago';
  }

  @override
  String daysAgo(int n) {
    return '$n d ago';
  }

  @override
  String get unitKm => 'km';

  @override
  String get unitM => 'm';

  @override
  String minutesShort(int n) {
    return '$n min';
  }

  @override
  String hoursShort(int n) {
    return '$n h';
  }

  @override
  String secondsShort(int n) {
    return '$n s';
  }

  @override
  String daysShort(int n) {
    return '$n d';
  }

  @override
  String get h24 => '24 h';

  @override
  String get crowFlies => 'as the crow flies';

  @override
  String get cancel => 'Cancel';

  @override
  String get undo => 'Undo';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get settings => 'Settings';

  @override
  String get androidSettings => 'Settings';

  @override
  String get video => 'Video';

  @override
  String get doctorFallback => 'Practitioner';

  @override
  String get motiveFallback => 'Reason';

  @override
  String get alertFallbackTitle => 'Alert';

  @override
  String get newBadge => 'NEW';

  @override
  String slotsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n slots',
      one: '1 slot',
    );
    return '$_temp0';
  }

  @override
  String requestsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n requests',
      one: '1 request',
    );
    return '$_temp0';
  }

  @override
  String get cannotOpenDoctolib => 'Could not open Doctolib';

  @override
  String get restore => 'Restore';

  @override
  String get more => 'More';

  @override
  String get directions => 'Directions';

  @override
  String get ignoreSlot => 'Ignore this slot';

  @override
  String ignoreDay(String date) {
    return 'Ignore $date';
  }

  @override
  String ignoreDoctor(String name) {
    return 'Ignore $name';
  }

  @override
  String get noMapsApp => 'No maps app found';

  @override
  String tripMinutes(int minutes, String phrase) {
    return '~$minutes min $phrase';
  }

  @override
  String get travelWalk => 'Walking';

  @override
  String get travelBike => 'Bike';

  @override
  String get travelTransit => 'Transit';

  @override
  String get travelCar => 'Car';

  @override
  String get phraseWalk => 'on foot';

  @override
  String get phraseBike => 'by bike';

  @override
  String get phraseTransit => 'by public transport';

  @override
  String get phraseCar => 'by car';

  @override
  String zoneAround(String dist, String label) {
    return '$dist around $label';
  }

  @override
  String zoneFromTravel(int minutes, String phrase, String label) {
    return '$minutes min $phrase from $label';
  }

  @override
  String zoneShortTravel(int minutes, String phrase) {
    return '$minutes min $phrase';
  }

  @override
  String get styleDiscreet => 'Silent';

  @override
  String get styleNormal => 'Notification';

  @override
  String get styleCall => 'Call me';

  @override
  String get styleDiscreetDesc => 'Shows in the notification shade, without sound. For nice-to-have alerts.';

  @override
  String get styleNormalDesc => 'A regular notification with the phone\'s usual sound.';

  @override
  String get styleCallDesc => 'Rings like a WhatsApp call, at the phone\'s ringtone volume, keeps ringing until you answer, and shows on the lock screen. For appointments you really cannot miss.';

  @override
  String get ringsLikeCall => 'Rings like a call';

  @override
  String get teleAny => 'Either';

  @override
  String get teleInPerson => 'In person';

  @override
  String get teleOnline => 'Video consultation';

  @override
  String get teleAnyDesc => 'In person or by video, any slot counts.';

  @override
  String get teleInPersonDesc => 'Only in-person appointments, at the practitioner\'s office.';

  @override
  String get teleOnlineDesc => 'Only video consultations, from home.';

  @override
  String get teleShortInPerson => 'in person';

  @override
  String get teleShortOnline => 'video';

  @override
  String get teleSegInPerson => 'In person';

  @override
  String get teleSegOnline => 'Video';

  @override
  String get soundSystemRingtone => 'Phone ringtone';

  @override
  String get soundSystemAlarm => 'Phone alarm';

  @override
  String get soundClassic => 'Classic phone';

  @override
  String get soundDigital => 'Digital beeps';

  @override
  String get soundSoft => 'Soft chime';

  @override
  String get soundMarimba => 'Marimba';

  @override
  String get soundUrgent => 'Urgent siren';

  @override
  String windowRange(String from, String to) {
    return 'from $from to $to';
  }

  @override
  String get window24h => 'within 24 h';

  @override
  String windowDays(int n) {
    return 'within $n days';
  }

  @override
  String get filterNewPatients => 'new patients';

  @override
  String get budgetVeryCautious => 'Very cautious';

  @override
  String get budgetCautious => 'Cautious';

  @override
  String get budgetBalanced => 'Balanced';

  @override
  String get budgetReactive => 'Responsive';

  @override
  String get budgetMax => 'Maximum';

  @override
  String intervalMinutes(int n) {
    return 'every $n minutes';
  }

  @override
  String get intervalHour => 'every hour';

  @override
  String intervalHours(int n) {
    return 'every $n hours';
  }

  @override
  String quietRange(String from, String to) {
    return 'quiet from $from to $to';
  }

  @override
  String get quietNone => 'day and night';

  @override
  String guardPaused(int m) {
    return 'Safety pause, $m min left';
  }

  @override
  String guardQuota(int n) {
    return 'Daily limit reached ($n requests)';
  }

  @override
  String guardRateLimited(int m) {
    return 'Doctolib is rate-limiting (429). Pausing for $m min.';
  }

  @override
  String guardRefused(int code, int m) {
    return 'Doctolib refused the request ($code). Pausing for $m min.';
  }

  @override
  String apiNetwork(String error) {
    return 'Network unavailable ($error)';
  }

  @override
  String apiStatus(String code, String reason) {
    return 'Doctolib answered $code$reason';
  }

  @override
  String apiCityNotFound(String city) {
    return 'City not found on Doctolib: $city';
  }

  @override
  String get apiBadProfile => 'Unreadable practitioner page';

  @override
  String geoUnavailable(int code) {
    return 'Address service unavailable ($code)';
  }

  @override
  String get monitoringPaused => 'Monitoring paused';

  @override
  String unexpectedError(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String failedStreak(int n, String cause) {
    return 'Failed $n times in a row despite automatic repair. Cause: $cause';
  }

  @override
  String repairing(int n, int max, String detail) {
    return 'Repairing ($n/$max): $detail';
  }

  @override
  String get stateDisabled => 'disabled';

  @override
  String get statePaused => 'paused';

  @override
  String get stateError => 'error';

  @override
  String get stateNothing => 'nothing yet';

  @override
  String get incompleteSpeciality => 'Incomplete alert: speciality or city missing';

  @override
  String get incompleteDoctor => 'Incomplete alert: practitioner missing';

  @override
  String get noMotiveSelected => 'No consultation reason selected';

  @override
  String get motivesGone => 'The watched reasons are no longer offered';

  @override
  String get chSlots => 'Available slots';

  @override
  String get chSlotsDesc => 'An appointment matching an alert is free.';

  @override
  String get chQuiet => 'Slots (silent)';

  @override
  String get chQuietDesc => 'Slots reported without sound.';

  @override
  String get chStatus => 'Monitoring status';

  @override
  String get chStatusDesc => 'Alert status, errors and safety pauses.';

  @override
  String chCall(String label) {
    return 'Call: $label';
  }

  @override
  String get chCallDesc => 'Rings like a call when a priority slot frees up.';

  @override
  String slotAvailable(String title) {
    return '$title — slot available';
  }

  @override
  String slotsAvailableTitle(String title, String slots) {
    return '$title — $slots available';
  }

  @override
  String callTitle(String when) {
    return 'Appointment available — $when';
  }

  @override
  String moreSlots(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+ $n more slots',
      one: '+ 1 more slot',
    );
    return '$_temp0';
  }

  @override
  String get decline => 'Decline';

  @override
  String get viewAppointment => 'Open appointment';

  @override
  String missedCall(String title) {
    return 'Missed call — $title';
  }

  @override
  String sampleTitle(String label) {
    return 'Sample — $label';
  }

  @override
  String get sampleDoctor => 'Dr Example';

  @override
  String get sampleMotive => 'First consultation';

  @override
  String get sampleSpeciality => 'General practitioner';

  @override
  String get sampleTest => 'Test';

  @override
  String get statusInterrupted => 'Monitoring interrupted';

  @override
  String get statusNoAlerts => 'No alerts set up';

  @override
  String get statusAllPaused => 'All alerts are paused';

  @override
  String statusSlots(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n slots available',
      one: '1 slot available',
    );
    return '$_temp0';
  }

  @override
  String get statusActive => 'Monitoring active';

  @override
  String statusActiveCount(int active, int total) {
    return '$active/$total alerts active';
  }

  @override
  String statusChecked(String ago) {
    return 'checked $ago';
  }

  @override
  String get callAvailable => 'Appointment available';

  @override
  String callWhen(String day, String time) {
    return '$day at $time';
  }

  @override
  String callRingingLeft(int s) {
    return 'Ringing for $s more s';
  }

  @override
  String get checkNow => 'Check now';

  @override
  String get newAlert => 'New alert';

  @override
  String get noAlerts => 'No alerts';

  @override
  String get noAlertsBody => 'Create an alert for a speciality in a city, or for a specific practitioner. The app watches Doctolib and tells you as soon as a slot frees up in the window you chose.';

  @override
  String get createAlert => 'Create an alert';

  @override
  String pausedFor(int m) {
    return 'Monitoring paused for $m min';
  }

  @override
  String footerSchedule(String interval, String quiet) {
    return 'I search $interval, $quiet.';
  }

  @override
  String footerCost(int perRun, int perDay, int max, int today) {
    return 'About $perRun request(s) to Doctolib each time, ~$perDay a day out of a limit of $max. Today: $today.';
  }

  @override
  String newCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n new',
      one: '1 new',
    );
    return '$_temp0';
  }

  @override
  String snoozedUntil(String time) {
    return 'paused until $time';
  }

  @override
  String snoozedUntilCap(String time) {
    return 'Paused until $time';
  }

  @override
  String ignoredCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ignored',
      one: '1 ignored',
    );
    return '$_temp0';
  }

  @override
  String earliestOf(String slots, String when) {
    return '$slots · earliest $when';
  }

  @override
  String get nothingInWindow => 'Nothing in the window yet';

  @override
  String checkedAgo(String ago) {
    return 'Checked $ago';
  }

  @override
  String msgNewSlots(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n new slots',
      one: '1 new slot',
    );
    return '$_temp0';
  }

  @override
  String msgNothingNew(String slots) {
    return '$slots (nothing new)';
  }

  @override
  String get msgNoSlots => 'No slots in the window';

  @override
  String get later => 'Later';

  @override
  String get start => 'Get started';

  @override
  String get next => 'Next';

  @override
  String get obWelcomeBody => 'You say what you need and by when. The app watches Doctolib in the background and tells you as soon as an appointment frees up in that window, not for a slot three months away.\n\nThree quick settings and you\'re done.';

  @override
  String get obLanguage => 'App language';

  @override
  String get allowNotifications => 'Allow notifications';

  @override
  String get obNotifBody => 'This is how the app tells you. Without this permission it keeps searching but cannot tell you anything.';

  @override
  String get notifGranted => 'Notifications allowed';

  @override
  String get notifPending => 'Not allowed yet';

  @override
  String get checkAgain => 'Check again';

  @override
  String get obBatteryTitle => 'Let the app run in the background';

  @override
  String get obBatteryBody => 'Android puts apps to sleep to save battery. If the app is put to sleep, it stops checking and you will not receive anything.\n\nLet it run without restrictions: this is the number one reason apps like this \"stop working\".';

  @override
  String get batteryGranted => 'The app can run in the background';

  @override
  String get batteryPending => 'Still restricted by battery saving';

  @override
  String get removeRestrictions => 'Remove restrictions';

  @override
  String get openAppSettings => 'Open app settings';

  @override
  String get obBatteryOem => 'On Samsung, Xiaomi, Huawei, Oppo or OnePlus you often also need to add the app to the \"protected apps\" or exclude it from optimisation in the manufacturer\'s settings.';

  @override
  String get quietHours => 'Quiet hours';

  @override
  String get obQuietBody => 'During these hours the app checks nothing and never rings. You sleep in peace, and it cuts the number of requests sent to Doctolib too.';

  @override
  String get enableQuietHours => 'Turn on quiet hours';

  @override
  String quietFromTo(String from, String to) {
    return 'Quiet from $from to $to';
  }

  @override
  String get canRingAnytime => 'The app may ring at any time';

  @override
  String quietStart(String h) {
    return 'Quiet starts: $h';
  }

  @override
  String quietEnd(String h) {
    return 'Wake up: $h';
  }

  @override
  String get changeLater => 'You can change this any time in Settings.';

  @override
  String get errNeedSpeciality => 'Choose at least one speciality';

  @override
  String get errNeedCity => 'Choose a city';

  @override
  String get errNeedDoctor => 'Choose a practitioner';

  @override
  String get errNeedMotive => 'Choose at least one reason';

  @override
  String get errNeedWeekday => 'Keep at least one weekday';

  @override
  String get errEmptyHours => 'The time range is empty';

  @override
  String get errNeedDates => 'Choose dates';

  @override
  String get editAlert => 'Edit alert';

  @override
  String get stepWhere => '1. Where?';

  @override
  String get cityHint => 'City or town';

  @override
  String get stepWhat => '2. What are you looking for?';

  @override
  String get searchHint => 'Speciality, practitioner name, clinic...';

  @override
  String get searchHelperNoCity => 'Choose a city first to filter practitioners';

  @override
  String searchHelperCity(String city) {
    return 'Practitioners in $city first';
  }

  @override
  String get alertName => 'Alert name';

  @override
  String get specialities => 'Specialities';

  @override
  String get practitionersAndPlaces => 'Practitioners and clinics';

  @override
  String practitionersIn(String city) {
    return 'Practitioners in $city';
  }

  @override
  String get elsewhere => 'Elsewhere';

  @override
  String get specialityChipsHint => 'The alert fires for any practitioner of these specialities in the chosen city.';

  @override
  String get noOnlineMotive => 'No reason bookable online for this practitioner.';

  @override
  String get motivesToWatch => 'Reasons to watch';

  @override
  String get whenTitle => 'When would a slot suit you?';

  @override
  String get whenBody => 'Only slots inside this window trigger a notification. This is what stops you being woken up for an appointment three months away.';

  @override
  String get nextDays => 'Next days';

  @override
  String get exactDates => 'Exact dates';

  @override
  String get pickPeriod => 'Choose a period';

  @override
  String get zoneCardTitle => 'Limit to an area around me';

  @override
  String get zoneCardBody => 'Optional. A radius in km or a travel time from your home, your position or a point on the map. Without an area, the whole city is watched.';

  @override
  String get removeZone => 'Remove area';

  @override
  String zoneFrom(String label) {
    return 'From $label';
  }

  @override
  String zoneApprox(String dist) {
    return 'About $dist as the crow flies (estimate)';
  }

  @override
  String zoneTowns(String towns) {
    return 'Towns watched: $towns';
  }

  @override
  String get teleTitle => 'In person or by video?';

  @override
  String get teleBody => 'Many practitioners offer both, and a video slot often frees up much sooner than an in-person one.';

  @override
  String get howToAlert => 'How should we tell you?';

  @override
  String get howToAlertBody => 'Set per alert: a paediatrician for a sick child deserves a ringing phone, a routine check-up does not.';

  @override
  String get callHint => 'Green button: opens the appointment directly. Red button or no answer: a regular notification stays. The ringtone and its length are set in Settings. Quiet hours always win: nothing rings at night.';

  @override
  String get filters => 'Filters';

  @override
  String get filtersBody => 'Doctolib offers none of these filters. They are applied in the app to the slots received, so you only hear about what you could actually attend.';

  @override
  String hourRange(String from, String to) {
    return 'Time range: $from — $to';
  }

  @override
  String get acceptedDays => 'Accepted days';

  @override
  String get acceptsNewPatients => 'Accepts new patients';

  @override
  String get acceptsNewPatientsBody => 'Skips practitioners who only see existing patients';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get langSystem => 'Phone language';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'Automatic';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get frequencyTitle => 'How often to search?';

  @override
  String searchEvery(String interval) {
    return 'I search $interval';
  }

  @override
  String get frequencyBody => 'Android never runs a check more often than every 15 minutes, and may delay it while the phone sleeps. \"More often\" means \"as soon as possible\", not \"to the second\".';

  @override
  String get freq15Advice => 'Every 15 minutes is the minimum Android allows, not necessarily the best: it uses four times the requests of 60 minutes for a small real gain, since the system delays tasks while the phone sleeps anyway. Keep it for a truly urgent search over a few days.';

  @override
  String get freqBalancedAdvice => 'Good balance: quick enough to catch a cancellation, light enough to run for weeks.';

  @override
  String get freqSlowAdvice => 'Very frugal. Suits a long-running search where slots do not vanish within minutes.';

  @override
  String get allowBackground => 'Allow the app in the background';

  @override
  String get allowBackgroundBody => 'Without it, Android puts the app to sleep and checks stop. It is the number one cause of alerts that never ring.';

  @override
  String get backgroundRestricted => 'Still restricted: open Android settings';

  @override
  String quietOnBody(String from, String to) {
    return 'Between $from and $to the app searches nothing and never rings, not even a \"Call me\" alert.';
  }

  @override
  String get quietOffBody => 'The app searches and may ring at any time';

  @override
  String get fromLabel => 'From';

  @override
  String get toLabel => 'to';

  @override
  String get notifications => 'Notifications';

  @override
  String get groupByAlert => 'Group by alert';

  @override
  String get groupByAlertBody => 'A single notification summing up all new slots, rather than one per slot.';

  @override
  String get statusBadge => 'Permanent monitoring badge';

  @override
  String get statusBadgeBody => 'Keeps a silent line in the notification shade, like an antivirus: each alert\'s state, free slots and the time of the last search. The best way to see at a glance that the app is still running.';

  @override
  String get needAndroid13 => 'Required on Android 13 and later';

  @override
  String get notifRefused => 'Denied: turn them on in Android settings';

  @override
  String get testAlert => 'Test an alert';

  @override
  String get testAlertBody => 'Hear what each style sounds like before trusting it with a real appointment.';

  @override
  String sampleSent(String label) {
    return 'Sample sent: $label';
  }

  @override
  String get callModeTitle => '\"Call me\" mode';

  @override
  String get callModeBody => 'The phone rings until you answer. The green button opens the appointment on Doctolib directly. The red button, or no answer, stops the ringing and leaves a regular notification: the slot stays one tap away.';

  @override
  String get soundBundled => 'Bundled with the app';

  @override
  String get soundSystem => 'The one set on your phone';

  @override
  String get listen => 'Listen';

  @override
  String testCallSent(String label) {
    return 'Test call: $label (12 s, try both buttons)';
  }

  @override
  String get ringDuration => 'Ringing duration';

  @override
  String ringDurationBody(int s) {
    return 'With no answer after $s s, the call stops and a \"missed call\" notification replaces it.';
  }

  @override
  String get blockTitle => 'Avoid being blocked';

  @override
  String get blockBody => 'Doctolib watches phones that ask too many questions and ends up ignoring them for a while. These settings keep the app well below that line: few requests, well spaced, and it backs off on its own if the site pushes back.';

  @override
  String get frugalTitle => 'Frugal mode (recommended)';

  @override
  String get frugalBody => 'Only asks for exact times for practitioners not already spotted: a search then costs 1 to 3 requests instead of about twenty. This is what protects you most from being blocked.';

  @override
  String safetyLimit(String label) {
    return 'Safety limit: $label';
  }

  @override
  String safetyLimitBody(int max, int today) {
    return 'At most $max requests to Doctolib a day, across all alerts. Past this limit, the app stops until the next day rather than risk a block. Today: $today used.';
  }

  @override
  String get estimate => 'Estimate';

  @override
  String estimateBody(String interval, String quiet, int perRun, int perDay, int max) {
    return 'You search $interval, $quiet. That is about $perRun request(s) to Doctolib each time, roughly $perDay a day out of a limit of $max.';
  }

  @override
  String get overLimit => 'That is above your limit: search less often, extend quiet hours, or keep fewer alerts active.';

  @override
  String get safetyPause => 'Safety pause';

  @override
  String resumeIn(int m) {
    return 'Resuming in $m min.';
  }

  @override
  String get about => 'About';

  @override
  String get howItWorks => 'How it works';

  @override
  String get howItWorksBody => 'The app queries the same JSON endpoints that doctolib.fr itself uses when you browse it. Nothing leaves the phone: no account, no server, no health data stored. Booking happens on Doctolib, in your browser.';

  @override
  String get personalUse => 'Personal use';

  @override
  String get personalUseBody => 'These endpoints are undocumented and may change without notice. Keep a reasonable pace and strictly personal use.';

  @override
  String get alertDeleted => 'Alert deleted';

  @override
  String get nearestFirst => 'Nearest first';

  @override
  String get ignoreAll => 'Ignore all';

  @override
  String get resumeNow => 'Resume now';

  @override
  String get snoozeMenu => 'Pause…';

  @override
  String get restoreAll => 'Restore all';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get renotify => 'Notify known slots again';

  @override
  String get check => 'Check';

  @override
  String get earliest => 'Earliest';

  @override
  String get nearest => 'Nearest';

  @override
  String noSlotsWindow(String window) {
    return 'No slots $window';
  }

  @override
  String get allIgnored => 'Everything is ignored for now';

  @override
  String get keepsChecking => 'The app keeps checking in the background and will tell you as soon as an appointment frees up.';

  @override
  String get ignoredHidden => 'Known slots are hidden. Any new slot will show in red and be notified.';

  @override
  String ignoredHeader(int n) {
    return 'Ignored ($n)';
  }

  @override
  String slotsWindow(String window) {
    return 'Slots $window';
  }

  @override
  String lastCheck(String ago) {
    return 'Last check $ago';
  }

  @override
  String repairInProgress(int n, int max) {
    return 'Automatic repair in progress ($n/$max): the alert is rebuilt from Doctolib on each attempt.';
  }

  @override
  String repairedAgo(String ago) {
    return 'Automatically repaired $ago';
  }

  @override
  String get alertActive => 'Alert active';

  @override
  String zoneApproxParen(String dist) {
    return '(about $dist as the crow flies)';
  }

  @override
  String zoneTownsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n towns',
      one: '1 town',
    );
    return '$_temp0';
  }

  @override
  String get slotIgnored => 'Slot ignored';

  @override
  String dayIgnored(String date) {
    return '$date ignored';
  }

  @override
  String doctorIgnored(String name) {
    return '$name ignored';
  }

  @override
  String ignoredAll(String slots) {
    return '$slots ignored, only new ones will be reported';
  }

  @override
  String get allRestored => 'Everything restored';

  @override
  String get snoozeFor => 'Pause for';

  @override
  String hoursCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String copyTitle(String title) {
    return '$title (copy)';
  }

  @override
  String get renotified => 'Current slots will be notified again';

  @override
  String get deleteConfirm => 'Delete this alert?';

  @override
  String get pointOnMap => 'Point chosen on the map';

  @override
  String get locationOff => 'The phone\'s location is turned off.';

  @override
  String get locationDeniedForever => 'Location denied. Allow it in the app settings, or choose a point on the map.';

  @override
  String get locationDenied => 'Location denied. You can choose a point on the map or type an address.';

  @override
  String positionNotFound(String error) {
    return 'Position not found ($error)';
  }

  @override
  String get needPoint => 'Choose a starting point first.';

  @override
  String get findingTowns => 'Finding towns in the area...';

  @override
  String preparingTown(String name, int i, int n) {
    return 'Preparing $name on Doctolib ($i/$n)';
  }

  @override
  String get pointChosen => 'Chosen point';

  @override
  String zonePrepFailed(String error) {
    return 'Could not prepare the area: $error';
  }

  @override
  String get zoneTitle => 'Search area';

  @override
  String get addressOptional => 'Address (optional)';

  @override
  String get myPosition => 'My location';

  @override
  String get tapMapHint => 'Tap the map to place your starting point, or use \"My location\" or an address.';

  @override
  String get circle => 'Circle';

  @override
  String get travelTime => 'Travel time';

  @override
  String radiusLabel(String dist) {
    return 'Radius: $dist as the crow flies';
  }

  @override
  String atMost(int minutes, String phrase) {
    return 'At most $minutes min $phrase';
  }

  @override
  String travelEstimate(String dist) {
    return 'Estimate: about $dist as the crow flies. Based on average city speeds (waiting and walking included for public transport); real timetables are not checked.';
  }

  @override
  String get validateZone => 'Confirm area';

  @override
  String get showWholeZone => 'Show whole area';

  @override
  String get centerOnPoint => 'Center on point';

  @override
  String get journal => 'Activity log';

  @override
  String get journalBody => 'What the app did, check by check: a way to confirm it really runs in the background, and to see at what time slots tend to free up.';

  @override
  String get journalEmpty => 'No activity yet.';

  @override
  String get journalClear => 'Clear log';

  @override
  String get journalBackground => 'background';

  @override
  String get journalManual => 'manual';

  @override
  String journalFound(String title, String slots, int fresh) {
    return '$title: $slots, $fresh new';
  }

  @override
  String journalNothing(String title) {
    return '$title: nothing in the window';
  }

  @override
  String journalError(String title, String error) {
    return '$title: $error';
  }

  @override
  String journalBusiestHour(String hour) {
    return 'Hour when new slots show up most often: $hour';
  }

  @override
  String get journalCallAccepted => 'Call answered';

  @override
  String get journalCallDeclined => 'Call declined';

  @override
  String get journalCallMissed => 'Missed call';
}
