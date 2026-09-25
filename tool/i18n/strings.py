# -*- coding: utf-8 -*-
"""Single source of truth for the app's text, in French, English and Arabic.

    python tool/i18n/build_arb.py

writes lib/l10n/app_{fr,en,ar}.arb from this table; `flutter gen-l10n` (run
automatically by `flutter pub get` / build) turns those into Dart.

Each entry: key, French, English, Arabic, then placeholder types. French is the
template. Plurals use ICU syntax; Arabic uses its six plural categories where
the number is shown.
"""

S = []


def e(key, fr, en, ar, **params):
    S.append((key, fr, en, ar, params))


# --------------------------------------------------------------------- general
e('appTitle', 'Alertes RDV', 'Appointment Alerts', 'تنبيهات المواعيد')
e('homeTitle', 'Alertes rendez-vous', 'Appointment alerts', 'تنبيهات المواعيد')
e('today', "Aujourd'hui", 'Today', 'اليوم')
e('tomorrow', 'Demain', 'Tomorrow', 'غدًا')
e('todayShort', "auj.", 'today', 'اليوم')
e('tomorrowShort', 'demain', 'tomorrow', 'غدًا')
e('never', 'jamais', 'never', 'أبدًا')
e('justNow', "à l'instant", 'just now', 'الآن')
e('minutesAgo', 'il y a {n} min', '{n} min ago', 'منذ {n} د', n='int')
e('hoursAgo', 'il y a {n} h', '{n} h ago', 'منذ {n} س', n='int')
e('daysAgo', 'il y a {n} j', '{n} d ago', 'منذ {n} ي', n='int')
e('unitKm', 'km', 'km', 'كم')
e('unitM', 'm', 'm', 'م')
e('minutesShort', '{n} min', '{n} min', '{n} د', n='int')
e('hoursShort', '{n} h', '{n} h', '{n} س', n='int')
e('secondsShort', '{n} s', '{n} s', '{n} ث', n='int')
e('daysShort', '{n} j', '{n} d', '{n} ي', n='int')
e('h24', '24 h', '24 h', '24 س')
e('crowFlies', "à vol d'oiseau", 'as the crow flies', 'في خط مستقيم')
e('cancel', 'Annuler', 'Cancel', 'إلغاء')
e('undo', 'Annuler', 'Undo', 'تراجع')
e('delete', 'Supprimer', 'Delete', 'حذف')
e('edit', 'Modifier', 'Edit', 'تعديل')
e('save', 'Enregistrer', 'Save', 'حفظ')
e('settings', 'Réglages', 'Settings', 'الإعدادات')
e('androidSettings', 'Paramètres', 'Settings', 'الإعدادات')
e('video', 'Vidéo', 'Video', 'فيديو')
e('doctorFallback', 'Praticien', 'Practitioner', 'طبيب')
e('motiveFallback', 'Motif', 'Reason', 'سبب الزيارة')
e('alertFallbackTitle', 'Alerte', 'Alert', 'تنبيه')
e('newBadge', 'NOUVEAU', 'NEW', 'جديد')
e('slotsCount', '{n, plural, =1{1 créneau} other{{n} créneaux}}',
  '{n, plural, =1{1 slot} other{{n} slots}}',
  '{n, plural, =1{موعد واحد} =2{موعدان} few{{n} مواعيد} many{{n} موعدًا} other{{n} موعد}}',
  n='int')
e('requestsCount', '{n, plural, =1{1 requête} other{{n} requêtes}}',
  '{n, plural, =1{1 request} other{{n} requests}}',
  '{n, plural, =1{طلب واحد} =2{طلبان} few{{n} طلبات} many{{n} طلبًا} other{{n} طلب}}',
  n='int')

# ------------------------------------------------------------------ slot tiles
e('cannotOpenDoctolib', "Impossible d'ouvrir Doctolib", 'Could not open Doctolib',
  'تعذر فتح Doctolib')
e('restore', 'Réactiver', 'Restore', 'إعادة التفعيل')
e('more', 'Plus', 'More', 'المزيد')
e('directions', 'Itinéraire', 'Directions', 'الاتجاهات')
e('ignoreSlot', 'Ignorer ce créneau', 'Ignore this slot', 'تجاهل هذا الموعد')
e('ignoreDay', 'Ignorer le {date}', 'Ignore {date}', 'تجاهل يوم {date}', date='String')
e('ignoreDoctor', 'Ignorer {name}', 'Ignore {name}', 'تجاهل {name}', name='String')
e('noMapsApp', 'Aucune application de cartes trouvée', 'No maps app found',
  'لم يتم العثور على تطبيق خرائط')
e('tripMinutes', '~{minutes} min {phrase}', '~{minutes} min {phrase}',
  '~{minutes} د {phrase}', minutes='int', phrase='String')

# --------------------------------------------------------------- travel/zone
e('travelWalk', 'À pied', 'Walking', 'سيرًا')
e('travelBike', 'Vélo', 'Bike', 'دراجة')
e('travelTransit', 'Transports', 'Transit', 'نقل عام')
e('travelCar', 'Voiture', 'Car', 'سيارة')
e('phraseWalk', 'à pied', 'on foot', 'سيرًا على الأقدام')
e('phraseBike', 'à vélo', 'by bike', 'بالدراجة')
e('phraseTransit', 'en transports', 'by public transport', 'بالنقل العام')
e('phraseCar', 'en voiture', 'by car', 'بالسيارة')
e('zoneAround', '{dist} autour de {label}', '{dist} around {label}',
  '{dist} حول {label}', dist='String', label='String')
e('zoneFromTravel', '{minutes} min {phrase} depuis {label}',
  '{minutes} min {phrase} from {label}', '{minutes} د {phrase} من {label}',
  minutes='int', phrase='String', label='String')
e('zoneShortTravel', '{minutes} min {phrase}', '{minutes} min {phrase}',
  '{minutes} د {phrase}', minutes='int', phrase='String')

# ---------------------------------------------------------------- alert styles
e('styleDiscreet', 'Discret', 'Silent', 'صامت')
e('styleNormal', 'Notification', 'Notification', 'إشعار')
e('styleCall', "M'appeler", 'Call me', 'اتصل بي')
e('styleDiscreetDesc', 'Apparaît dans le volet, sans son. Pour les alertes de confort.',
  'Shows in the notification shade, without sound. For nice-to-have alerts.',
  'يظهر في لوحة الإشعارات دون صوت. للتنبيهات غير العاجلة.')
e('styleNormalDesc', 'Notification classique avec le son habituel du téléphone.',
  "A regular notification with the phone's usual sound.",
  'إشعار عادي بصوت الهاتف المعتاد.')
e('styleCallDesc',
  "Sonne comme un appel WhatsApp, au volume de la sonnerie du téléphone, "
  "insiste jusqu'à ce que vous répondiez, et s'affiche sur l'écran verrouillé. "
  "Réservé aux rendez-vous que vous ne voulez surtout pas rater.",
  "Rings like a WhatsApp call, at the phone's ringtone volume, keeps ringing "
  "until you answer, and shows on the lock screen. For appointments you really "
  "cannot miss.",
  "يرن مثل مكالمة واتساب بمستوى صوت رنين الهاتف، ويستمر حتى تجيب، ويظهر على "
  "شاشة القفل. مخصص للمواعيد التي لا تريد تفويتها أبدًا.")
e('ringsLikeCall', 'Sonne comme un appel', 'Rings like a call', 'يرن مثل مكالمة')

# ---------------------------------------------------------------- teleconsult
e('teleAny', 'Peu importe', 'Either', 'لا يهم')
e('teleInPerson', 'Au cabinet', 'In person', 'في العيادة')
e('teleOnline', 'Téléconsultation', 'Video consultation', 'استشارة عن بُعد')
e('teleAnyDesc', 'Sur place ou en vidéo, tout créneau compte.',
  'In person or by video, any slot counts.',
  'حضوريًا أو عبر الفيديو، كل موعد مقبول.')
e('teleInPersonDesc', 'Uniquement des rendez-vous physiques, au cabinet du praticien.',
  "Only in-person appointments, at the practitioner's office.",
  'مواعيد حضورية فقط في عيادة الطبيب.')
e('teleOnlineDesc', 'Uniquement des consultations vidéo, depuis chez vous.',
  'Only video consultations, from home.',
  'استشارات عبر الفيديو فقط، من منزلك.')
e('teleShortInPerson', 'cabinet', 'in person', 'حضوري')
e('teleShortOnline', 'vidéo', 'video', 'فيديو')
e('teleSegInPerson', 'Cabinet', 'In person', 'العيادة')
e('teleSegOnline', 'Vidéo', 'Video', 'فيديو')

# ------------------------------------------------------------------ ringtones
e('soundSystemRingtone', 'Sonnerie du téléphone', 'Phone ringtone', 'نغمة رنين الهاتف')
e('soundSystemAlarm', 'Alarme du téléphone', 'Phone alarm', 'منبّه الهاتف')
e('soundClassic', 'Téléphone classique', 'Classic phone', 'هاتف كلاسيكي')
e('soundDigital', 'Bips numériques', 'Digital beeps', 'صفارات رقمية')
e('soundSoft', 'Carillon doux', 'Soft chime', 'جرس هادئ')
e('soundMarimba', 'Marimba', 'Marimba', 'ماريمبا')
e('soundUrgent', 'Sirène urgente', 'Urgent siren', 'صفارة عاجلة')

# -------------------------------------------------------------------- windows
e('windowRange', 'du {from} au {to}', 'from {from} to {to}', 'من {from} إلى {to}',
  **{'from': 'String', 'to': 'String'})
e('window24h', 'sous 24 h', 'within 24 h', 'خلال 24 ساعة')
e('windowDays', 'sous {n} jours', 'within {n} days',
  '{n, plural, =1{خلال يوم واحد} =2{خلال يومين} few{خلال {n} أيام} many{خلال {n} يومًا} other{خلال {n} يوم}}',
  n='int')
e('filterNewPatients', 'nouveaux patients', 'new patients', 'مرضى جدد')

# ------------------------------------------------------------- settings labels
e('budgetVeryCautious', 'Très prudent', 'Very cautious', 'حذر جدًا')
e('budgetCautious', 'Prudent', 'Cautious', 'حذر')
e('budgetBalanced', 'Équilibré', 'Balanced', 'متوازن')
e('budgetReactive', 'Réactif', 'Responsive', 'سريع')
e('budgetMax', 'Maximum', 'Maximum', 'أقصى')
e('intervalMinutes', 'toutes les {n} minutes', 'every {n} minutes', 'كل {n} دقيقة', n='int')
e('intervalHour', 'toutes les heures', 'every hour', 'كل ساعة')
e('intervalHours', 'toutes les {n} heures', 'every {n} hours', 'كل {n} ساعات', n='int')
e('quietRange', 'silence de {from} à {to}', 'quiet from {from} to {to}',
  'صمت من {from} إلى {to}', **{'from': 'String', 'to': 'String'})
e('quietNone', 'jour et nuit', 'day and night', 'ليلًا ونهارًا')

# ------------------------------------------------------------------ rate guard
e('guardPaused', 'Pause de sécurité encore {m} min', 'Safety pause, {m} min left',
  'توقف أمان، متبقٍّ {m} د', m='int')
e('guardQuota', 'Quota quotidien atteint ({n} requêtes)', 'Daily limit reached ({n} requests)',
  'تم بلوغ الحد اليومي ({n} طلب)', n='int')
e('guardRateLimited', 'Doctolib a limité le débit (429). Pause de {m} min.',
  'Doctolib is rate-limiting (429). Pausing for {m} min.',
  'قيّد Doctolib عدد الطلبات (429). توقف لمدة {m} د.', m='int')
e('guardRefused', 'Doctolib a refusé la requête ({code}). Pause de {m} min.',
  'Doctolib refused the request ({code}). Pausing for {m} min.',
  'رفض Doctolib الطلب ({code}). توقف لمدة {m} د.', code='int', m='int')

# ------------------------------------------------------------------ api errors
e('apiNetwork', 'Réseau indisponible ({error})', 'Network unavailable ({error})',
  'الشبكة غير متاحة ({error})', error='String')
e('apiStatus', 'Doctolib a répondu {code}{reason}', 'Doctolib answered {code}{reason}',
  'ردّ Doctolib بالرمز {code}{reason}', code='String', reason='String')
e('apiCityNotFound', 'Ville introuvable sur Doctolib : {city}',
  'City not found on Doctolib: {city}', 'المدينة غير موجودة على Doctolib: {city}',
  city='String')
e('apiBadProfile', 'Fiche praticien illisible', 'Unreadable practitioner page',
  'صفحة الطبيب غير مقروءة')
e('geoUnavailable', "Service d'adresses indisponible ({code})",
  'Address service unavailable ({code})', 'خدمة العناوين غير متاحة ({code})', code='int')

# ---------------------------------------------------------------------- engine
e('monitoringPaused', 'Surveillance en pause', 'Monitoring paused', 'المراقبة متوقفة')
e('unexpectedError', 'Erreur inattendue : {error}', 'Unexpected error: {error}',
  'خطأ غير متوقع: {error}', error='String')
e('failedStreak',
  'Échec {n} fois de suite, malgré la réparation automatique. Cause : {cause}',
  'Failed {n} times in a row despite automatic repair. Cause: {cause}',
  'فشل {n} مرات متتالية رغم الإصلاح التلقائي. السبب: {cause}', n='int', cause='String')
e('repairing', 'Réparation en cours ({n}/{max}) : {detail}',
  'Repairing ({n}/{max}): {detail}', 'جارٍ الإصلاح ({n}/{max}): {detail}',
  n='int', max='int', detail='String')
e('stateDisabled', 'désactivée', 'disabled', 'معطّل')
e('statePaused', 'en pause', 'paused', 'متوقف مؤقتًا')
e('stateError', 'erreur', 'error', 'خطأ')
e('stateNothing', "rien pour l'instant", 'nothing yet', 'لا شيء حاليًا')
e('incompleteSpeciality', 'Alerte incomplète : spécialité ou ville manquante',
  'Incomplete alert: speciality or city missing', 'تنبيه غير مكتمل: التخصص أو المدينة مفقود')
e('incompleteDoctor', 'Alerte incomplète : praticien manquant',
  'Incomplete alert: practitioner missing', 'تنبيه غير مكتمل: الطبيب مفقود')
e('noMotiveSelected', 'Aucun motif de consultation sélectionné',
  'No consultation reason selected', 'لم يتم اختيار سبب الزيارة')
e('motivesGone', 'Les motifs suivis ne sont plus proposés',
  'The watched reasons are no longer offered', 'أسباب الزيارة المتابَعة لم تعد متاحة')

# --------------------------------------------------------------- notifications
e('chSlots', 'Créneaux disponibles', 'Available slots', 'مواعيد متاحة')
e('chSlotsDesc', 'Un rendez-vous correspondant à une alerte est libre.',
  'An appointment matching an alert is free.', 'موعد مطابق لأحد التنبيهات متاح.')
e('chQuiet', 'Créneaux (discret)', 'Slots (silent)', 'مواعيد (صامت)')
e('chQuietDesc', 'Créneaux signalés sans son.', 'Slots reported without sound.',
  'مواعيد تُعرض دون صوت.')
e('chStatus', 'État de la surveillance', 'Monitoring status', 'حالة المراقبة')
e('chStatusDesc', 'État des alertes, erreurs et pauses de sécurité.',
  'Alert status, errors and safety pauses.', 'حالة التنبيهات والأخطاء وفترات التوقف.')
e('chCall', 'Appel : {label}', 'Call: {label}', 'مكالمة: {label}', label='String')
e('chCallDesc', 'Sonne comme un appel quand un créneau prioritaire se libère.',
  'Rings like a call when a priority slot frees up.', 'يرن مثل مكالمة عندما يتوفر موعد مهم.')
e('slotAvailable', '{title} — créneau disponible', '{title} — slot available',
  '{title} — موعد متاح', title='String')
e('slotsAvailableTitle', '{title} — {slots} disponibles', '{title} — {slots} available',
  '{title} — {slots} متاحة', title='String', slots='String')
e('callTitle', 'Rendez-vous disponible — {when}', 'Appointment available — {when}',
  'موعد متاح — {when}', when='String')
e('moreSlots', '{n, plural, =1{+ 1 autre créneau} other{+ {n} autres créneaux}}',
  '{n, plural, =1{+ 1 more slot} other{+ {n} more slots}}',
  '{n, plural, =1{+ موعد آخر} =2{+ موعدان آخران} few{+ {n} مواعيد أخرى} many{+ {n} موعدًا آخر} other{+ {n} موعد آخر}}',
  n='int')
e('decline', 'Refuser', 'Decline', 'رفض')
e('viewAppointment', 'Voir le RDV', 'Open appointment', 'عرض الموعد')
e('missedCall', 'Appel manqué — {title}', 'Missed call — {title}',
  'مكالمة فائتة — {title}', title='String')
e('sampleTitle', 'Exemple — {label}', 'Sample — {label}', 'مثال — {label}', label='String')
e('sampleDoctor', 'Dr Exemple', 'Dr Example', 'د. مثال')
e('sampleMotive', 'Première consultation', 'First consultation', 'استشارة أولى')
e('sampleSpeciality', 'Médecin généraliste', 'General practitioner', 'طبيب عام')
e('sampleTest', 'Test', 'Test', 'تجربة')
e('statusInterrupted', 'Surveillance interrompue', 'Monitoring interrupted', 'المراقبة متوقفة')
e('statusNoAlerts', 'Aucune alerte configurée', 'No alerts set up', 'لا توجد تنبيهات')
e('statusAllPaused', 'Toutes les alertes sont en pause', 'All alerts are paused',
  'جميع التنبيهات متوقفة')
e('statusSlots', '{n, plural, =1{1 créneau disponible} other{{n} créneaux disponibles}}',
  '{n, plural, =1{1 slot available} other{{n} slots available}}',
  '{n, plural, =1{موعد واحد متاح} =2{موعدان متاحان} few{{n} مواعيد متاحة} many{{n} موعدًا متاحًا} other{{n} موعد متاح}}',
  n='int')
e('statusActive', 'Surveillance active', 'Monitoring active', 'المراقبة نشطة')
e('statusActiveCount', '{active}/{total} alertes actives', '{active}/{total} alerts active',
  '{active}/{total} تنبيهات نشطة', active='int', total='int')
e('statusChecked', 'vérifié {ago}', 'checked {ago}', 'آخر فحص {ago}', ago='String')

# ----------------------------------------------------------------- call screen
e('callAvailable', 'Rendez-vous disponible', 'Appointment available', 'موعد متاح')
e('callWhen', '{day} à {time}', '{day} at {time}', '{day} الساعة {time}',
  day='String', time='String')
e('callRingingLeft', 'Sonne encore {s} s', 'Ringing for {s} more s', 'يرن لمدة {s} ث أخرى',
  s='int')

# ------------------------------------------------------------------------ home
e('checkNow', 'Vérifier maintenant', 'Check now', 'افحص الآن')
e('newAlert', 'Nouvelle alerte', 'New alert', 'تنبيه جديد')
e('noAlerts', 'Aucune alerte', 'No alerts', 'لا توجد تنبيهات')
e('noAlertsBody',
  "Créez une alerte pour une spécialité dans une ville, ou pour un praticien "
  "précis. L'app surveille Doctolib et vous prévient dès qu'un créneau se libère "
  "dans la fenêtre que vous avez choisie.",
  "Create an alert for a speciality in a city, or for a specific practitioner. "
  "The app watches Doctolib and tells you as soon as a slot frees up in the "
  "window you chose.",
  "أنشئ تنبيهًا لتخصص في مدينة، أو لطبيب محدد. يراقب التطبيق Doctolib ويخبرك "
  "فور توفر موعد في الفترة التي اخترتها.")
e('createAlert', 'Créer une alerte', 'Create an alert', 'إنشاء تنبيه')
e('pausedFor', 'Surveillance en pause pour {m} min', 'Monitoring paused for {m} min',
  'المراقبة متوقفة لمدة {m} د', m='int')
e('footerSchedule', 'Je cherche {interval}, {quiet}.', 'I search {interval}, {quiet}.',
  'أبحث {interval}، {quiet}.', interval='String', quiet='String')
e('footerCost',
  'Environ {perRun} question(s) à Doctolib à chaque fois, ~{perDay} par jour sur '
  "une limite de {max}. Aujourd'hui : {today}.",
  'About {perRun} request(s) to Doctolib each time, ~{perDay} a day out of a '
  'limit of {max}. Today: {today}.',
  'حوالي {perRun} طلب إلى Doctolib في كل مرة، ~{perDay} يوميًا من أصل حد '
  '{max}. اليوم: {today}.',
  perRun='int', perDay='int', max='int', today='int')
e('newCount', '{n, plural, =1{1 nouveau} other{{n} nouveaux}}',
  '{n, plural, =1{1 new} other{{n} new}}',
  '{n, plural, =1{جديد واحد} =2{جديدان} few{{n} جديدة} many{{n} جديدًا} other{{n} جديد}}',
  n='int')
e('snoozedUntil', "en pause jusqu'à {time}", 'paused until {time}',
  'متوقف حتى {time}', time='String')
e('snoozedUntilCap', "En pause jusqu'à {time}", 'Paused until {time}',
  'متوقف حتى {time}', time='String')
e('ignoredCount', '{n, plural, =1{1 ignoré} other{{n} ignorés}}',
  '{n, plural, =1{1 ignored} other{{n} ignored}}',
  '{n, plural, =1{واحد متجاهَل} =2{اثنان متجاهَلان} few{{n} متجاهَلة} many{{n} متجاهَلًا} other{{n} متجاهَل}}',
  n='int')
e('earliestOf', '{slots} · le plus tôt {when}', '{slots} · earliest {when}',
  '{slots} · الأقرب {when}', slots='String', when='String')
e('nothingInWindow', "Rien dans la fenêtre pour l'instant", 'Nothing in the window yet',
  'لا شيء ضمن الفترة حاليًا')
e('checkedAgo', 'Vérifié {ago}', 'Checked {ago}', 'آخر فحص {ago}', ago='String')
e('msgNewSlots', '{n, plural, =1{1 nouveau créneau} other{{n} nouveaux créneaux}}',
  '{n, plural, =1{1 new slot} other{{n} new slots}}',
  '{n, plural, =1{موعد جديد} =2{موعدان جديدان} few{{n} مواعيد جديدة} many{{n} موعدًا جديدًا} other{{n} موعد جديد}}',
  n='int')
e('msgNothingNew', '{slots} (rien de nouveau)', '{slots} (nothing new)',
  '{slots} (لا جديد)', slots='String')
e('msgNoSlots', 'Aucun créneau dans la fenêtre', 'No slots in the window',
  'لا مواعيد ضمن الفترة')

# ------------------------------------------------------------------ onboarding
e('later', 'Plus tard', 'Later', 'لاحقًا')
e('start', 'Commencer', 'Get started', 'ابدأ')
e('next', 'Suivant', 'Next', 'التالي')
e('obWelcomeBody',
  "Vous dites ce que vous cherchez et pour quand. L'app surveille Doctolib en "
  "arrière-plan et vous prévient dès qu'un rendez-vous se libère dans cette "
  "fenêtre, pas pour un créneau dans trois mois.\n\nTrois réglages rapides et "
  "c'est prêt.",
  "You say what you need and by when. The app watches Doctolib in the "
  "background and tells you as soon as an appointment frees up in that window, "
  "not for a slot three months away.\n\nThree quick settings and you're done.",
  "تحدد ما تبحث عنه ومتى. يراقب التطبيق Doctolib في الخلفية ويخبرك فور توفر "
  "موعد ضمن تلك الفترة، وليس لموعد بعد ثلاثة أشهر.\n\nثلاثة إعدادات سريعة "
  "وتصبح جاهزًا.")
e('obLanguage', "Langue de l'application", 'App language', 'لغة التطبيق')
e('allowNotifications', 'Autoriser les notifications', 'Allow notifications',
  'السماح بالإشعارات')
e('obNotifBody',
  "C'est par là que l'app vous prévient. Sans cette autorisation, elle continue "
  "de chercher mais ne peut rien vous dire.",
  "This is how the app tells you. Without this permission it keeps searching "
  "but cannot tell you anything.",
  "هكذا يخبرك التطبيق. بدون هذا الإذن يستمر في البحث لكنه لا يستطيع إبلاغك بشيء.")
e('notifGranted', 'Notifications autorisées', 'Notifications allowed', 'الإشعارات مسموحة')
e('notifPending', 'Pas encore autorisées', 'Not allowed yet', 'غير مسموحة بعد')
e('checkAgain', 'Vérifier à nouveau', 'Check again', 'تحقق مجددًا')
e('obBatteryTitle', "Laisser l'app tourner en arrière-plan",
  'Let the app run in the background', 'السماح للتطبيق بالعمل في الخلفية')
e('obBatteryBody',
  "Android met les applications en veille pour économiser la batterie. Si l'app "
  "est mise en veille, elle arrête de vérifier et vous ne recevrez plus rien.\n\n"
  "Autorisez-la à fonctionner sans restriction : c'est la raison numéro un pour "
  "laquelle ce type d'app « arrête de marcher ».",
  "Android puts apps to sleep to save battery. If the app is put to sleep, it "
  "stops checking and you will not receive anything.\n\nLet it run without "
  "restrictions: this is the number one reason apps like this \"stop working\".",
  "يضع أندرويد التطبيقات في وضع السكون لتوفير البطارية. إذا دخل التطبيق في "
  "السكون يتوقف عن الفحص ولن تتلقى أي شيء.\n\nاسمح له بالعمل دون قيود: هذا هو "
  "السبب الأول لتوقف هذا النوع من التطبيقات عن العمل.")
e('batteryGranted', "L'app peut tourner en arrière-plan", 'The app can run in the background',
  'يمكن للتطبيق العمل في الخلفية')
e('batteryPending', 'Encore soumise aux restrictions de batterie',
  'Still restricted by battery saving', 'لا يزال مقيدًا بتوفير البطارية')
e('removeRestrictions', 'Retirer les restrictions', 'Remove restrictions', 'إزالة القيود')
e('openAppSettings', "Ouvrir les paramètres de l'app", 'Open app settings',
  'فتح إعدادات التطبيق')
e('obBatteryOem',
  "Sur Samsung, Xiaomi, Huawei, Oppo ou OnePlus, il faut souvent aussi ajouter "
  "l'app aux « applications protégées » ou la retirer de l'optimisation dans "
  "les réglages du fabricant.",
  "On Samsung, Xiaomi, Huawei, Oppo or OnePlus you often also need to add the "
  "app to the \"protected apps\" or exclude it from optimisation in the "
  "manufacturer's settings.",
  "على هواتف سامسونج وشاومي وهواوي وأوبو ووان بلس، يجب غالبًا أيضًا إضافة "
  "التطبيق إلى «التطبيقات المحمية» أو استثناؤه من التحسين في إعدادات الشركة "
  "المصنعة.")
e('quietHours', 'Heures de silence', 'Quiet hours', 'ساعات الهدوء')
e('obQuietBody',
  "Pendant ces heures, l'app ne vérifie rien et ne sonne pas. Vous dormez "
  "tranquille, et cela réduit d'autant le nombre de requêtes envoyées à Doctolib.",
  "During these hours the app checks nothing and never rings. You sleep in "
  "peace, and it cuts the number of requests sent to Doctolib too.",
  "خلال هذه الساعات لا يفحص التطبيق شيئًا ولا يرن. تنام بهدوء، ويقل أيضًا عدد "
  "الطلبات المرسلة إلى Doctolib.")
e('enableQuietHours', 'Activer les heures de silence', 'Turn on quiet hours',
  'تفعيل ساعات الهدوء')
e('quietFromTo', 'Silence de {from} à {to}', 'Quiet from {from} to {to}',
  'هدوء من {from} إلى {to}', **{'from': 'String', 'to': 'String'})
e('canRingAnytime', "L'app peut sonner à toute heure", 'The app may ring at any time',
  'يمكن للتطبيق أن يرن في أي وقت')
e('quietStart', 'Début du silence : {h}', 'Quiet starts: {h}', 'بداية الهدوء: {h}', h='String')
e('quietEnd', 'Réveil : {h}', 'Wake up: {h}', 'الاستيقاظ: {h}', h='String')
e('changeLater', 'Modifiable à tout moment dans les réglages.',
  'You can change this any time in Settings.', 'يمكنك تغيير ذلك في أي وقت من الإعدادات.')

# ------------------------------------------------------------------ edit alert
e('errNeedSpeciality', 'Choisissez au moins une spécialité', 'Choose at least one speciality',
  'اختر تخصصًا واحدًا على الأقل')
e('errNeedCity', 'Choisissez une ville', 'Choose a city', 'اختر مدينة')
e('errNeedDoctor', 'Choisissez un praticien', 'Choose a practitioner', 'اختر طبيبًا')
e('errNeedMotive', 'Choisissez au moins un motif', 'Choose at least one reason',
  'اختر سببًا واحدًا على الأقل')
e('errNeedWeekday', 'Gardez au moins un jour de la semaine', 'Keep at least one weekday',
  'أبقِ يومًا واحدًا على الأقل من الأسبوع')
e('errEmptyHours', 'La plage horaire est vide', 'The time range is empty', 'النطاق الزمني فارغ')
e('errNeedDates', 'Choisissez des dates', 'Choose dates', 'اختر التواريخ')
e('editAlert', "Modifier l'alerte", 'Edit alert', 'تعديل التنبيه')
e('stepWhere', '1. Où ?', '1. Where?', '1. أين؟')
e('cityHint', 'Ville ou commune', 'City or town', 'المدينة أو البلدة')
e('stepWhat', '2. Que cherchez-vous ?', '2. What are you looking for?', '2. عمّ تبحث؟')
e('searchHint', 'Spécialité, nom du praticien, établissement...',
  'Speciality, practitioner name, clinic...', 'التخصص، اسم الطبيب، المؤسسة...')
e('searchHelperNoCity', "Choisissez d'abord une ville pour filtrer les praticiens",
  'Choose a city first to filter practitioners', 'اختر مدينة أولًا لتصفية الأطباء')
e('searchHelperCity', 'Praticiens de {city} en premier', 'Practitioners in {city} first',
  'أطباء {city} أولًا', city='String')
e('alertName', "Nom de l'alerte", 'Alert name', 'اسم التنبيه')
e('specialities', 'Spécialités', 'Specialities', 'التخصصات')
e('practitionersAndPlaces', 'Praticiens et établissements', 'Practitioners and clinics',
  'الأطباء والمؤسسات')
e('practitionersIn', 'Praticiens à {city}', 'Practitioners in {city}', 'أطباء في {city}',
  city='String')
e('elsewhere', 'Ailleurs', 'Elsewhere', 'أماكن أخرى')
e('specialityChipsHint',
  "L'alerte se déclenche pour n'importe quel praticien de ces spécialités dans "
  "la ville choisie.",
  'The alert fires for any practitioner of these specialities in the chosen city.',
  'يعمل التنبيه لأي طبيب من هذه التخصصات في المدينة المختارة.')
e('noOnlineMotive', 'Aucun motif réservable en ligne pour ce praticien.',
  'No reason bookable online for this practitioner.',
  'لا يوجد سبب زيارة قابل للحجز عبر الإنترنت لهذا الطبيب.')
e('motivesToWatch', 'Motifs à surveiller', 'Reasons to watch', 'أسباب الزيارة المراد متابعتها')
e('whenTitle', 'Quand un créneau vous intéresse-t-il ?', 'When would a slot suit you?',
  'متى يناسبك الموعد؟')
e('whenBody',
  "Seuls les créneaux tombant dans cette fenêtre déclenchent une notification. "
  "C'est le réglage qui évite d'être réveillé pour un rendez-vous dans trois mois.",
  'Only slots inside this window trigger a notification. This is what stops you '
  'being woken up for an appointment three months away.',
  'فقط المواعيد ضمن هذه الفترة تُطلق إشعارًا. هذا ما يمنع إيقاظك من أجل موعد بعد '
  'ثلاثة أشهر.')
e('nextDays', 'Prochains jours', 'Next days', 'الأيام القادمة')
e('exactDates', 'Dates précises', 'Exact dates', 'تواريخ محددة')
e('pickPeriod', 'Choisir une période', 'Choose a period', 'اختر فترة')
e('zoneCardTitle', 'Limiter à une zone autour de moi', 'Limit to an area around me',
  'حصر البحث في منطقة حولي')
e('zoneCardBody',
  'Facultatif. Un rayon en km ou un temps de trajet depuis chez vous, votre '
  'position ou un point sur la carte. Sans zone, toute la ville est surveillée.',
  'Optional. A radius in km or a travel time from your home, your position or a '
  'point on the map. Without an area, the whole city is watched.',
  'اختياري. نصف قطر بالكيلومتر أو مدة تنقل من منزلك أو موقعك أو نقطة على '
  'الخريطة. بدون منطقة تُراقب المدينة كلها.')
e('removeZone', 'Retirer la zone', 'Remove area', 'إزالة المنطقة')
e('zoneFrom', 'Depuis {label}', 'From {label}', 'من {label}', label='String')
e('zoneApprox', "Soit environ {dist} à vol d'oiseau (estimation)",
  'About {dist} as the crow flies (estimate)', 'أي حوالي {dist} في خط مستقيم (تقدير)',
  dist='String')
e('zoneTowns', 'Communes surveillées : {towns}', 'Towns watched: {towns}',
  'البلدات المراقَبة: {towns}', towns='String')
e('teleTitle', 'Au cabinet ou en vidéo ?', 'In person or by video?', 'حضوريًا أم عبر الفيديو؟')
e('teleBody',
  "Beaucoup de praticiens proposent les deux, et une téléconsultation se libère "
  "souvent bien plus vite qu'un rendez-vous sur place.",
  'Many practitioners offer both, and a video slot often frees up much sooner '
  'than an in-person one.',
  'يقدم كثير من الأطباء الخيارين، وغالبًا ما يتوفر موعد الفيديو أسرع بكثير من '
  'الموعد الحضوري.')
e('howToAlert', 'Comment vous prévenir ?', 'How should we tell you?', 'كيف نخبرك؟')
e('howToAlertBody',
  "Propre à cette alerte : un pédiatre pour un enfant malade mérite qu'on vous "
  "sonne dessus, un contrôle de routine non.",
  'Set per alert: a paediatrician for a sick child deserves a ringing phone, a '
  'routine check-up does not.',
  'خاص بكل تنبيه: طبيب أطفال لطفل مريض يستحق رنين الهاتف، أما الفحص الروتيني فلا.')
e('callHint',
  "Bouton vert : ouvre directement le rendez-vous. Bouton rouge ou pas de "
  "réponse : une notification normale reste. La sonnerie et sa durée se "
  "choisissent dans les Réglages. Les heures de silence restent prioritaires : "
  "rien ne sonne la nuit.",
  'Green button: opens the appointment directly. Red button or no answer: a '
  'regular notification stays. The ringtone and its length are set in Settings. '
  'Quiet hours always win: nothing rings at night.',
  'الزر الأخضر: يفتح الموعد مباشرة. الزر الأحمر أو عدم الرد: يبقى إشعار عادي. '
  'تُختار النغمة ومدتها من الإعدادات. ساعات الهدوء لها الأولوية: لا رنين ليلًا.')
e('filters', 'Filtres', 'Filters', 'عوامل التصفية')
e('filtersBody',
  "Doctolib ne propose aucun de ces filtres. Ils sont appliqués dans l'app, sur "
  "les créneaux reçus, pour ne notifier que ce que vous pourriez réellement honorer.",
  'Doctolib offers none of these filters. They are applied in the app to the '
  'slots received, so you only hear about what you could actually attend.',
  'لا يوفر Doctolib أيًا من هذه العوامل. يطبقها التطبيق على المواعيد المستلمة '
  'ليخبرك فقط بما يمكنك حضوره فعلًا.')
e('hourRange', 'Plage horaire : {from} — {to}', 'Time range: {from} — {to}',
  'النطاق الزمني: {from} — {to}', **{'from': 'String', 'to': 'String'})
e('acceptedDays', 'Jours acceptés', 'Accepted days', 'الأيام المقبولة')
e('acceptsNewPatients', 'Accepte les nouveaux patients', 'Accepts new patients',
  'يقبل مرضى جددًا')
e('acceptsNewPatientsBody', 'Ignore les praticiens réservés à leur patientèle',
  'Skips practitioners who only see existing patients',
  'يتجاهل الأطباء الذين يستقبلون مرضاهم الحاليين فقط')

# -------------------------------------------------------------------- settings
e('appearance', 'Apparence', 'Appearance', 'المظهر')
e('language', 'Langue', 'Language', 'اللغة')
e('langSystem', 'Langue du téléphone', 'Phone language', 'لغة الهاتف')
e('theme', 'Thème', 'Theme', 'السمة')
e('themeSystem', 'Automatique', 'Automatic', 'تلقائي')
e('themeLight', 'Clair', 'Light', 'فاتح')
e('themeDark', 'Sombre', 'Dark', 'داكن')
e('frequencyTitle', 'À quelle fréquence chercher ?', 'How often to search?',
  'كم مرة يتم البحث؟')
e('searchEvery', 'Je cherche {interval}', 'I search {interval}', 'أبحث {interval}',
  interval='String')
e('frequencyBody',
  "Android ne lance jamais une vérification plus souvent que toutes les 15 "
  "minutes, et peut la retarder quand le téléphone dort. Plus souvent veut donc "
  "dire « dès que possible », pas « à la seconde près ».",
  'Android never runs a check more often than every 15 minutes, and may delay '
  'it while the phone sleeps. "More often" means "as soon as possible", not "to '
  'the second".',
  'لا يشغّل أندرويد الفحص أكثر من مرة كل 15 دقيقة، وقد يؤخره أثناء سكون الهاتف. '
  '«أكثر تكرارًا» تعني «في أقرب وقت ممكن» وليس «بالثانية».')
e('freq15Advice',
  "Toutes les 15 minutes est le minimum autorisé par Android, pas forcément le "
  "meilleur réglage : cela consomme quatre fois plus de requêtes que 60 minutes "
  "pour un gain réel assez faible, puisque le système retarde de toute façon les "
  "tâches quand le téléphone dort. À garder pour une recherche vraiment urgente, "
  "sur quelques jours.",
  'Every 15 minutes is the minimum Android allows, not necessarily the best: it '
  'uses four times the requests of 60 minutes for a small real gain, since the '
  'system delays tasks while the phone sleeps anyway. Keep it for a truly urgent '
  'search over a few days.',
  'كل 15 دقيقة هو الحد الأدنى الذي يسمح به أندرويد، وليس بالضرورة الأفضل: '
  'يستهلك أربعة أضعاف طلبات الستين دقيقة مقابل فائدة صغيرة، لأن النظام يؤخر '
  'المهام أثناء السكون على أي حال. استخدمه لبحث عاجل فعلًا لبضعة أيام.')
e('freqBalancedAdvice',
  'Bon compromis : assez réactif pour attraper une annulation, assez sobre pour '
  'tenir des semaines.',
  'Good balance: quick enough to catch a cancellation, light enough to run for '
  'weeks.',
  'توازن جيد: سريع بما يكفي لالتقاط إلغاء، وخفيف بما يكفي للعمل أسابيع.')
e('freqSlowAdvice',
  'Très économe. Adapté à une recherche de fond, où les créneaux ne partent pas '
  'en quelques minutes.',
  'Very frugal. Suits a long-running search where slots do not vanish within '
  'minutes.',
  'اقتصادي جدًا. مناسب لبحث طويل لا تختفي فيه المواعيد خلال دقائق.')
e('allowBackground', "Autoriser l'app en arrière-plan", 'Allow the app in the background',
  'السماح للتطبيق بالعمل في الخلفية')
e('allowBackgroundBody',
  "Sans cela, Android met l'app en veille et les vérifications s'arrêtent. "
  "C'est la cause numéro un des alertes qui ne sonnent jamais.",
  'Without it, Android puts the app to sleep and checks stop. It is the number '
  'one cause of alerts that never ring.',
  'بدون ذلك يضع أندرويد التطبيق في السكون وتتوقف الفحوصات. هذا هو السبب الأول '
  'للتنبيهات التي لا ترن أبدًا.')
e('backgroundRestricted', 'Toujours restreinte : ouvrez les paramètres Android',
  'Still restricted: open Android settings', 'لا يزال مقيدًا: افتح إعدادات أندرويد')
e('quietOnBody',
  "Entre {from} et {to}, l'app ne cherche rien et ne sonne pas, même une alerte "
  "« M'appeler » reste muette.",
  'Between {from} and {to} the app searches nothing and never rings, not even a '
  '"Call me" alert.',
  'بين {from} و{to} لا يبحث التطبيق ولا يرن، ولا حتى تنبيه «اتصل بي».',
  **{'from': 'String', 'to': 'String'})
e('quietOffBody', "L'app cherche et peut sonner à toute heure",
  'The app searches and may ring at any time', 'يبحث التطبيق ويمكن أن يرن في أي وقت')
e('fromLabel', 'De', 'From', 'من')
e('toLabel', 'à', 'to', 'إلى')
e('notifications', 'Notifications', 'Notifications', 'الإشعارات')
e('groupByAlert', 'Regrouper par alerte', 'Group by alert', 'التجميع حسب التنبيه')
e('groupByAlertBody',
  "Une seule notification résumant tous les nouveaux créneaux, plutôt qu'une "
  "par créneau.",
  'A single notification summing up all new slots, rather than one per slot.',
  'إشعار واحد يلخص كل المواعيد الجديدة بدلًا من إشعار لكل موعد.')
e('statusBadge', 'Badge permanent de surveillance', 'Permanent monitoring badge',
  'شارة مراقبة دائمة')
e('statusBadgeBody',
  "Garde une ligne silencieuse dans le volet, à la manière d'un antivirus : état "
  "de chaque alerte, nombre de créneaux libres et date de la dernière recherche. "
  "Le meilleur moyen de vérifier d'un coup d'œil que l'app tourne encore.",
  'Keeps a silent line in the notification shade, like an antivirus: each '
  "alert's state, free slots and the time of the last search. The best way to "
  'see at a glance that the app is still running.',
  'يُبقي سطرًا صامتًا في لوحة الإشعارات مثل برامج الحماية: حالة كل تنبيه وعدد '
  'المواعيد المتاحة ووقت آخر بحث. أفضل طريقة للتأكد بنظرة أن التطبيق ما زال يعمل.')
e('needAndroid13', 'Nécessaire sur Android 13 et plus', 'Required on Android 13 and later',
  'مطلوب على أندرويد 13 وما بعده')
e('notifRefused', 'Refusé : activez-les dans les paramètres Android',
  'Denied: turn them on in Android settings', 'مرفوض: فعّلها من إعدادات أندرويد')
e('testAlert', 'Tester une alerte', 'Test an alert', 'تجربة تنبيه')
e('testAlertBody',
  'Entendez ce que chaque style donne avant de lui confier un vrai rendez-vous.',
  'Hear what each style sounds like before trusting it with a real appointment.',
  'استمع إلى كل نمط قبل أن تعتمد عليه لموعد حقيقي.')
e('sampleSent', 'Exemple envoyé : {label}', 'Sample sent: {label}', 'تم إرسال مثال: {label}',
  label='String')
e('callModeTitle', "Mode « M'appeler »", '"Call me" mode', 'وضع «اتصل بي»')
e('callModeBody',
  "Le téléphone sonne jusqu'à ce que vous répondiez. Le bouton vert ouvre "
  "directement le rendez-vous sur Doctolib. Le bouton rouge, ou l'absence de "
  "réponse, arrête la sonnerie et laisse une notification normale : le créneau "
  "reste à un geste.",
  'The phone rings until you answer. The green button opens the appointment on '
  'Doctolib directly. The red button, or no answer, stops the ringing and leaves '
  'a regular notification: the slot stays one tap away.',
  'يرن الهاتف حتى تجيب. الزر الأخضر يفتح الموعد على Doctolib مباشرة. الزر '
  'الأحمر أو عدم الرد يوقف الرنين ويترك إشعارًا عاديًا: يبقى الموعد على بُعد لمسة.')
e('soundBundled', "Fournie avec l'app", 'Bundled with the app', 'مرفقة مع التطبيق')
e('soundSystem', 'Celle réglée sur votre téléphone', 'The one set on your phone',
  'المضبوطة على هاتفك')
e('listen', 'Écouter', 'Listen', 'استماع')
e('testCallSent', 'Appel de test : {label} (12 s, essayez les deux boutons)',
  'Test call: {label} (12 s, try both buttons)',
  'مكالمة تجريبية: {label} (12 ث، جرّب الزرين)', label='String')
e('ringDuration', 'Durée de la sonnerie', 'Ringing duration', 'مدة الرنين')
e('ringDurationBody',
  "Sans réponse après {s} s, l'appel s'arrête et une notification « appel "
  "manqué » le remplace.",
  'With no answer after {s} s, the call stops and a "missed call" notification '
  'replaces it.',
  'إذا لم ترد بعد {s} ث يتوقف الاتصال ويحل محله إشعار «مكالمة فائتة».', s='int')
e('blockTitle', 'Ne pas se faire bloquer', 'Avoid being blocked', 'تجنب الحظر')
e('blockBody',
  "Doctolib surveille les téléphones qui posent trop de questions et finit par "
  "les ignorer pendant un moment. Ces réglages gardent l'app largement sous ce "
  "seuil : peu de questions, bien espacées, et elle se tait d'elle-même si le "
  "site rechigne.",
  'Doctolib watches phones that ask too many questions and ends up ignoring them '
  'for a while. These settings keep the app well below that line: few requests, '
  'well spaced, and it backs off on its own if the site pushes back.',
  'يراقب Doctolib الهواتف التي ترسل طلبات كثيرة ويتجاهلها لفترة. تُبقي هذه '
  'الإعدادات التطبيق أدنى من ذلك بكثير: طلبات قليلة ومتباعدة، ويتوقف من تلقاء '
  'نفسه إذا اعترض الموقع.')
e('frugalTitle', 'Mode économe (recommandé)', 'Frugal mode (recommended)',
  'الوضع الاقتصادي (موصى به)')
e('frugalBody',
  "Ne demande les horaires précis que pour les praticiens pas encore repérés : "
  "une recherche coûte alors 1 à 3 questions au lieu d'une vingtaine. C'est ce "
  "qui protège le plus du blocage.",
  'Only asks for exact times for practitioners not already spotted: a search '
  'then costs 1 to 3 requests instead of about twenty. This is what protects '
  'you most from being blocked.',
  'لا يطلب الأوقات الدقيقة إلا للأطباء غير المكتشفين بعد: يكلف البحث حينها 1 '
  'إلى 3 طلبات بدل عشرين تقريبًا. هذا أكثر ما يحمي من الحظر.')
e('safetyLimit', 'Limite de sécurité : {label}', 'Safety limit: {label}', 'حد الأمان: {label}',
  label='String')
e('safetyLimitBody',
  "Au maximum {max} questions à Doctolib par jour, toutes alertes confondues. "
  "Passé cette limite, l'app s'arrête jusqu'au lendemain plutôt que de risquer "
  "un blocage. Aujourd'hui : {today} utilisées.",
  'At most {max} requests to Doctolib a day, across all alerts. Past this '
  'limit, the app stops until the next day rather than risk a block. Today: '
  '{today} used.',
  'بحد أقصى {max} طلب إلى Doctolib يوميًا لكل التنبيهات. بعد هذا الحد يتوقف '
  'التطبيق حتى اليوم التالي بدل المخاطرة بالحظر. اليوم: {today} مستخدمة.',
  max='int', today='int')
e('estimate', 'Estimation', 'Estimate', 'تقدير')
e('estimateBody',
  'Vous cherchez {interval}, {quiet}. Cela fait environ {perRun} question(s) à '
  'Doctolib à chaque fois, soit à peu près {perDay} par jour sur une limite de {max}.',
  'You search {interval}, {quiet}. That is about {perRun} request(s) to Doctolib '
  'each time, roughly {perDay} a day out of a limit of {max}.',
  'تبحث {interval}، {quiet}. هذا حوالي {perRun} طلب إلى Doctolib في كل مرة، أي '
  'نحو {perDay} يوميًا من أصل حد {max}.',
  interval='String', quiet='String', perRun='int', perDay='int', max='int')
e('overLimit',
  "C'est au-dessus de votre limite : cherchez moins souvent, allongez les heures "
  "de silence, ou gardez moins d'alertes actives.",
  'That is above your limit: search less often, extend quiet hours, or keep '
  'fewer alerts active.',
  'هذا فوق حدك: ابحث بتكرار أقل، أو مدّد ساعات الهدوء، أو أبقِ تنبيهات أقل نشطة.')
e('safetyPause', 'Pause de sécurité', 'Safety pause', 'توقف أمان')
e('resumeIn', 'Reprise dans {m} min.', 'Resuming in {m} min.', 'الاستئناف بعد {m} د.',
  m='int')
e('about', 'À propos', 'About', 'حول التطبيق')
e('howItWorks', 'Comment ça marche', 'How it works', 'كيف يعمل')
e('howItWorksBody',
  "L'app interroge les mêmes points d'entrée JSON que le site doctolib.fr "
  "utilise lui-même quand vous le consultez. Rien ne quitte le téléphone : pas "
  "de compte, pas de serveur, pas de donnée de santé enregistrée. La réservation "
  "se fait sur Doctolib, dans votre navigateur.",
  'The app queries the same JSON endpoints that doctolib.fr itself uses when you '
  'browse it. Nothing leaves the phone: no account, no server, no health data '
  'stored. Booking happens on Doctolib, in your browser.',
  'يستعلم التطبيق من نفس نقاط JSON التي يستخدمها موقع doctolib.fr عند تصفحه. لا '
  'شيء يغادر الهاتف: لا حساب، لا خادم، ولا بيانات صحية محفوظة. يتم الحجز على '
  'Doctolib في متصفحك.')
e('personalUse', 'Usage personnel', 'Personal use', 'استخدام شخصي')
e('personalUseBody',
  "Ces points d'entrée ne sont pas documentés et peuvent changer sans préavis. "
  "Gardez un rythme raisonnable et un usage strictement personnel.",
  'These endpoints are undocumented and may change without notice. Keep a '
  'reasonable pace and strictly personal use.',
  'هذه النقاط غير موثقة وقد تتغير دون إشعار. حافظ على وتيرة معقولة واستخدام شخصي فقط.')

# ---------------------------------------------------------------------- detail
e('alertDeleted', 'Alerte supprimée', 'Alert deleted', 'تم حذف التنبيه')
e('nearestFirst', 'Du plus proche au plus loin', 'Nearest first', 'من الأقرب إلى الأبعد')
e('ignoreAll', 'Tout ignorer', 'Ignore all', 'تجاهل الكل')
e('resumeNow', 'Reprendre maintenant', 'Resume now', 'استئناف الآن')
e('snoozeMenu', 'Mettre en pause…', 'Pause…', 'إيقاف مؤقت…')
e('restoreAll', 'Tout réactiver', 'Restore all', 'إعادة تفعيل الكل')
e('duplicate', 'Dupliquer', 'Duplicate', 'نسخ')
e('renotify', 'Renotifier les créneaux connus', 'Notify known slots again',
  'إعادة الإشعار بالمواعيد المعروفة')
e('check', 'Vérifier', 'Check', 'فحص')
e('earliest', 'Plus tôt', 'Earliest', 'الأبكر')
e('nearest', 'Plus proche', 'Nearest', 'الأقرب')
e('noSlotsWindow', 'Aucun créneau {window}', 'No slots {window}', 'لا مواعيد {window}',
  window='String')
e('allIgnored', "Tout est ignoré pour l'instant", 'Everything is ignored for now',
  'كل شيء متجاهَل حاليًا')
e('keepsChecking',
  "L'app continue de vérifier en arrière-plan et vous préviendra dès qu'un "
  "rendez-vous se libère.",
  'The app keeps checking in the background and will tell you as soon as an '
  'appointment frees up.',
  'يواصل التطبيق الفحص في الخلفية وسيخبرك فور توفر موعد.')
e('ignoredHidden',
  'Les créneaux connus sont masqués. Tout nouveau créneau apparaîtra en rouge et '
  'vous sera notifié.',
  'Known slots are hidden. Any new slot will show in red and be notified.',
  'المواعيد المعروفة مخفية. أي موعد جديد سيظهر باللون الأحمر وسيتم إشعارك به.')
e('ignoredHeader', 'Ignoré ({n})', 'Ignored ({n})', 'متجاهَل ({n})', n='int')
e('slotsWindow', 'Créneaux {window}', 'Slots {window}', 'مواعيد {window}', window='String')
e('lastCheck', 'Dernière vérification {ago}', 'Last check {ago}', 'آخر فحص {ago}',
  ago='String')
e('repairInProgress',
  "Réparation automatique en cours ({n}/{max}) : l'alerte est reconstruite depuis "
  "Doctolib à chaque essai.",
  'Automatic repair in progress ({n}/{max}): the alert is rebuilt from Doctolib '
  'on each attempt.',
  'إصلاح تلقائي جارٍ ({n}/{max}): يُعاد بناء التنبيه من Doctolib في كل محاولة.',
  n='int', max='int')
e('repairedAgo', 'Réparée automatiquement {ago}', 'Automatically repaired {ago}',
  'تم الإصلاح تلقائيًا {ago}', ago='String')
e('alertActive', 'Alerte active', 'Alert active', 'التنبيه نشط')
e('zoneApproxParen', "(environ {dist} à vol d'oiseau)", '(about {dist} as the crow flies)',
  '(حوالي {dist} في خط مستقيم)', dist='String')
e('zoneTownsCount', '{n, plural, =1{1 commune} other{{n} communes}}',
  '{n, plural, =1{1 town} other{{n} towns}}',
  '{n, plural, =1{بلدة واحدة} =2{بلدتان} few{{n} بلدات} many{{n} بلدة} other{{n} بلدة}}',
  n='int')
e('slotIgnored', 'Créneau ignoré', 'Slot ignored', 'تم تجاهل الموعد')
e('dayIgnored', 'Journée du {date} ignorée', '{date} ignored', 'تم تجاهل يوم {date}',
  date='String')
e('doctorIgnored', '{name} ignoré', '{name} ignored', 'تم تجاهل {name}', name='String')
e('ignoredAll', '{slots} ignorés, seuls les nouveaux vous seront signalés',
  '{slots} ignored, only new ones will be reported', 'تم تجاهل {slots}، سيتم إبلاغك بالجديدة فقط',
  slots='String')
e('allRestored', 'Tout a été réactivé', 'Everything restored', 'تمت إعادة تفعيل الكل')
e('snoozeFor', 'Mettre en pause pendant', 'Pause for', 'إيقاف مؤقت لمدة')
e('hoursCount', '{n, plural, =1{1 heure} other{{n} heures}}',
  '{n, plural, =1{1 hour} other{{n} hours}}',
  '{n, plural, =1{ساعة واحدة} =2{ساعتان} few{{n} ساعات} many{{n} ساعة} other{{n} ساعة}}',
  n='int')
e('daysCount', '{n, plural, =1{1 jour} other{{n} jours}}',
  '{n, plural, =1{1 day} other{{n} days}}',
  '{n, plural, =1{يوم واحد} =2{يومان} few{{n} أيام} many{{n} يومًا} other{{n} يوم}}',
  n='int')
e('copyTitle', '{title} (copie)', '{title} (copy)', '{title} (نسخة)', title='String')
e('renotified', 'Les créneaux actuels seront notifiés à nouveau',
  'Current slots will be notified again', 'سيتم الإشعار بالمواعيد الحالية مجددًا')
e('deleteConfirm', 'Supprimer cette alerte ?', 'Delete this alert?', 'حذف هذا التنبيه؟')

# ------------------------------------------------------------------------ zone
e('pointOnMap', 'Point choisi sur la carte', 'Point chosen on the map',
  'نقطة مختارة على الخريطة')
e('locationOff', 'La localisation du téléphone est désactivée.',
  "The phone's location is turned off.", 'خدمة الموقع في الهاتف متوقفة.')
e('locationDeniedForever',
  "Localisation refusée. Autorisez-la dans les paramètres de l'app, ou choisissez "
  "un point sur la carte.",
  'Location denied. Allow it in the app settings, or choose a point on the map.',
  'تم رفض الموقع. اسمح به من إعدادات التطبيق أو اختر نقطة على الخريطة.')
e('locationDenied',
  'Localisation refusée. Vous pouvez choisir un point sur la carte ou taper une '
  'adresse.',
  'Location denied. You can choose a point on the map or type an address.',
  'تم رفض الموقع. يمكنك اختيار نقطة على الخريطة أو كتابة عنوان.')
e('positionNotFound', 'Position introuvable ({error})', 'Position not found ({error})',
  'تعذر تحديد الموقع ({error})', error='String')
e('needPoint', "Choisissez d'abord un point de départ.", 'Choose a starting point first.',
  'اختر نقطة انطلاق أولًا.')
e('findingTowns', 'Recherche des communes de la zone...', 'Finding towns in the area...',
  'جارٍ البحث عن البلدات في المنطقة...')
e('preparingTown', 'Préparation de {name} sur Doctolib ({i}/{n})',
  'Preparing {name} on Doctolib ({i}/{n})', 'تجهيز {name} على Doctolib ({i}/{n})',
  name='String', i='int', n='int')
e('pointChosen', 'Point choisi', 'Chosen point', 'النقطة المختارة')
e('zonePrepFailed', 'Impossible de préparer la zone : {error}',
  'Could not prepare the area: {error}', 'تعذر تجهيز المنطقة: {error}', error='String')
e('zoneTitle', 'Zone de recherche', 'Search area', 'منطقة البحث')
e('addressOptional', 'Adresse (facultatif)', 'Address (optional)', 'العنوان (اختياري)')
e('myPosition', 'Ma position', 'My location', 'موقعي')
e('tapMapHint',
  'Touchez la carte pour placer votre point de départ, ou utilisez « Ma position » '
  'ou une adresse.',
  'Tap the map to place your starting point, or use "My location" or an address.',
  'المس الخريطة لتحديد نقطة الانطلاق، أو استخدم «موقعي» أو عنوانًا.')
e('circle', 'Cercle', 'Circle', 'دائرة')
e('travelTime', 'Temps de trajet', 'Travel time', 'مدة التنقل')
e('radiusLabel', "Rayon : {dist} à vol d'oiseau", 'Radius: {dist} as the crow flies',
  'نصف القطر: {dist} في خط مستقيم', dist='String')
e('atMost', 'Au plus {minutes} min {phrase}', 'At most {minutes} min {phrase}',
  'بحد أقصى {minutes} د {phrase}', minutes='int', phrase='String')
e('travelEstimate',
  "Estimation : environ {dist} à vol d'oiseau. Calculée avec des vitesses "
  "moyennes en ville (attente et marche comprises pour les transports) ; les "
  "horaires réels ne sont pas consultés.",
  'Estimate: about {dist} as the crow flies. Based on average city speeds '
  '(waiting and walking included for public transport); real timetables are '
  'not checked.',
  'تقدير: حوالي {dist} في خط مستقيم. محسوب بمتوسط السرعات في المدينة (مع الانتظار '
  'والمشي للنقل العام)؛ لا يتم الاطلاع على الجداول الفعلية.',
  dist='String')
e('validateZone', 'Valider la zone', 'Confirm area', 'تأكيد المنطقة')
e('showWholeZone', 'Voir toute la zone', 'Show whole area', 'عرض المنطقة كاملة')
e('centerOnPoint', 'Recentrer sur le point', 'Center on point', 'التمركز على النقطة')

# --------------------------------------------------------------------- journal
e('journal', 'Journal', 'Activity log', 'السجل')
e('journalBody',
  "Ce que l'app a fait, vérification par vérification : de quoi s'assurer qu'elle "
  "tourne bien en arrière-plan, et voir à quelle heure les créneaux se libèrent.",
  'What the app did, check by check: a way to confirm it really runs in the '
  'background, and to see at what time slots tend to free up.',
  'ما قام به التطبيق فحصًا بفحص: للتأكد من أنه يعمل فعلًا في الخلفية، ولمعرفة '
  'أوقات توفر المواعيد عادة.')
e('journalEmpty', 'Aucune activité pour le moment.', 'No activity yet.',
  'لا يوجد نشاط بعد.')
e('journalClear', 'Effacer le journal', 'Clear log', 'مسح السجل')
e('journalBackground', 'arrière-plan', 'background', 'في الخلفية')
e('journalManual', 'manuel', 'manual', 'يدوي')
e('journalFound', '{title} : {slots}, dont {fresh} nouveau(x)',
  '{title}: {slots}, {fresh} new', '{title}: {slots}، منها {fresh} جديد',
  title='String', slots='String', fresh='int')
e('journalNothing', '{title} : rien dans la fenêtre', '{title}: nothing in the window',
  '{title}: لا شيء ضمن الفترة', title='String')
e('journalError', '{title} : {error}', '{title}: {error}', '{title}: {error}',
  title='String', error='String')
e('journalBusiestHour',
  'Heure où les nouveaux créneaux apparaissent le plus souvent : {hour}',
  'Hour when new slots show up most often: {hour}',
  'الساعة التي تظهر فيها المواعيد الجديدة غالبًا: {hour}', hour='String')
e('journalCallAccepted', 'Appel accepté', 'Call answered', 'تم الرد على المكالمة')
e('journalCallDeclined', 'Appel refusé', 'Call declined', 'تم رفض المكالمة')
e('journalCallMissed', 'Appel manqué', 'Missed call', 'مكالمة فائتة')
