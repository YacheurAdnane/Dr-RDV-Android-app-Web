import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Alertes RDV';

  @override
  String get homeTitle => 'Alertes rendez-vous';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get tomorrow => 'Demain';

  @override
  String get todayShort => 'auj.';

  @override
  String get tomorrowShort => 'demain';

  @override
  String get never => 'jamais';

  @override
  String get justNow => 'à l\'instant';

  @override
  String minutesAgo(int n) {
    return 'il y a $n min';
  }

  @override
  String hoursAgo(int n) {
    return 'il y a $n h';
  }

  @override
  String daysAgo(int n) {
    return 'il y a $n j';
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
    return '$n j';
  }

  @override
  String get h24 => '24 h';

  @override
  String get crowFlies => 'à vol d\'oiseau';

  @override
  String get cancel => 'Annuler';

  @override
  String get undo => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get save => 'Enregistrer';

  @override
  String get settings => 'Réglages';

  @override
  String get androidSettings => 'Paramètres';

  @override
  String get video => 'Vidéo';

  @override
  String get doctorFallback => 'Praticien';

  @override
  String get motiveFallback => 'Motif';

  @override
  String get alertFallbackTitle => 'Alerte';

  @override
  String get newBadge => 'NOUVEAU';

  @override
  String slotsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n créneaux',
      one: '1 créneau',
    );
    return '$_temp0';
  }

  @override
  String requestsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n requêtes',
      one: '1 requête',
    );
    return '$_temp0';
  }

  @override
  String get cannotOpenDoctolib => 'Impossible d\'ouvrir Doctolib';

  @override
  String get restore => 'Réactiver';

  @override
  String get more => 'Plus';

  @override
  String get directions => 'Itinéraire';

  @override
  String get ignoreSlot => 'Ignorer ce créneau';

  @override
  String ignoreDay(String date) {
    return 'Ignorer le $date';
  }

  @override
  String ignoreDoctor(String name) {
    return 'Ignorer $name';
  }

  @override
  String get noMapsApp => 'Aucune application de cartes trouvée';

  @override
  String tripMinutes(int minutes, String phrase) {
    return '~$minutes min $phrase';
  }

  @override
  String get travelWalk => 'À pied';

  @override
  String get travelBike => 'Vélo';

  @override
  String get travelTransit => 'Transports';

  @override
  String get travelCar => 'Voiture';

  @override
  String get phraseWalk => 'à pied';

  @override
  String get phraseBike => 'à vélo';

  @override
  String get phraseTransit => 'en transports';

  @override
  String get phraseCar => 'en voiture';

  @override
  String zoneAround(String dist, String label) {
    return '$dist autour de $label';
  }

  @override
  String zoneFromTravel(int minutes, String phrase, String label) {
    return '$minutes min $phrase depuis $label';
  }

  @override
  String zoneShortTravel(int minutes, String phrase) {
    return '$minutes min $phrase';
  }

  @override
  String get styleDiscreet => 'Discret';

  @override
  String get styleNormal => 'Notification';

  @override
  String get styleCall => 'M\'appeler';

  @override
  String get styleDiscreetDesc => 'Apparaît dans le volet, sans son. Pour les alertes de confort.';

  @override
  String get styleNormalDesc => 'Notification classique avec le son habituel du téléphone.';

  @override
  String get styleCallDesc => 'Sonne comme un appel WhatsApp, au volume de la sonnerie du téléphone, insiste jusqu\'à ce que vous répondiez, et s\'affiche sur l\'écran verrouillé. Réservé aux rendez-vous que vous ne voulez surtout pas rater.';

  @override
  String get ringsLikeCall => 'Sonne comme un appel';

  @override
  String get teleAny => 'Peu importe';

  @override
  String get teleInPerson => 'Au cabinet';

  @override
  String get teleOnline => 'Téléconsultation';

  @override
  String get teleAnyDesc => 'Sur place ou en vidéo, tout créneau compte.';

  @override
  String get teleInPersonDesc => 'Uniquement des rendez-vous physiques, au cabinet du praticien.';

  @override
  String get teleOnlineDesc => 'Uniquement des consultations vidéo, depuis chez vous.';

  @override
  String get teleShortInPerson => 'cabinet';

  @override
  String get teleShortOnline => 'vidéo';

  @override
  String get teleSegInPerson => 'Cabinet';

  @override
  String get teleSegOnline => 'Vidéo';

  @override
  String get soundSystemRingtone => 'Sonnerie du téléphone';

  @override
  String get soundSystemAlarm => 'Alarme du téléphone';

  @override
  String get soundClassic => 'Téléphone classique';

  @override
  String get soundDigital => 'Bips numériques';

  @override
  String get soundSoft => 'Carillon doux';

  @override
  String get soundMarimba => 'Marimba';

  @override
  String get soundUrgent => 'Sirène urgente';

  @override
  String windowRange(String from, String to) {
    return 'du $from au $to';
  }

  @override
  String get window24h => 'sous 24 h';

  @override
  String windowDays(int n) {
    return 'sous $n jours';
  }

  @override
  String get filterNewPatients => 'nouveaux patients';

  @override
  String get budgetVeryCautious => 'Très prudent';

  @override
  String get budgetCautious => 'Prudent';

  @override
  String get budgetBalanced => 'Équilibré';

  @override
  String get budgetReactive => 'Réactif';

  @override
  String get budgetMax => 'Maximum';

  @override
  String intervalMinutes(int n) {
    return 'toutes les $n minutes';
  }

  @override
  String get intervalHour => 'toutes les heures';

  @override
  String intervalHours(int n) {
    return 'toutes les $n heures';
  }

  @override
  String quietRange(String from, String to) {
    return 'silence de $from à $to';
  }

  @override
  String get quietNone => 'jour et nuit';

  @override
  String guardPaused(int m) {
    return 'Pause de sécurité encore $m min';
  }

  @override
  String guardQuota(int n) {
    return 'Quota quotidien atteint ($n requêtes)';
  }

  @override
  String guardRateLimited(int m) {
    return 'Doctolib a limité le débit (429). Pause de $m min.';
  }

  @override
  String guardRefused(int code, int m) {
    return 'Doctolib a refusé la requête ($code). Pause de $m min.';
  }

  @override
  String apiNetwork(String error) {
    return 'Réseau indisponible ($error)';
  }

  @override
  String apiStatus(String code, String reason) {
    return 'Doctolib a répondu $code$reason';
  }

  @override
  String apiCityNotFound(String city) {
    return 'Ville introuvable sur Doctolib : $city';
  }

  @override
  String get apiBadProfile => 'Fiche praticien illisible';

  @override
  String geoUnavailable(int code) {
    return 'Service d\'adresses indisponible ($code)';
  }

  @override
  String get monitoringPaused => 'Surveillance en pause';

  @override
  String unexpectedError(String error) {
    return 'Erreur inattendue : $error';
  }

  @override
  String failedStreak(int n, String cause) {
    return 'Échec $n fois de suite, malgré la réparation automatique. Cause : $cause';
  }

  @override
  String repairing(int n, int max, String detail) {
    return 'Réparation en cours ($n/$max) : $detail';
  }

  @override
  String get stateDisabled => 'désactivée';

  @override
  String get statePaused => 'en pause';

  @override
  String get stateError => 'erreur';

  @override
  String get stateNothing => 'rien pour l\'instant';

  @override
  String get incompleteSpeciality => 'Alerte incomplète : spécialité ou ville manquante';

  @override
  String get incompleteDoctor => 'Alerte incomplète : praticien manquant';

  @override
  String get noMotiveSelected => 'Aucun motif de consultation sélectionné';

  @override
  String get motivesGone => 'Les motifs suivis ne sont plus proposés';

  @override
  String get chSlots => 'Créneaux disponibles';

  @override
  String get chSlotsDesc => 'Un rendez-vous correspondant à une alerte est libre.';

  @override
  String get chQuiet => 'Créneaux (discret)';

  @override
  String get chQuietDesc => 'Créneaux signalés sans son.';

  @override
  String get chStatus => 'État de la surveillance';

  @override
  String get chStatusDesc => 'État des alertes, erreurs et pauses de sécurité.';

  @override
  String chCall(String label) {
    return 'Appel : $label';
  }

  @override
  String get chCallDesc => 'Sonne comme un appel quand un créneau prioritaire se libère.';

  @override
  String slotAvailable(String title) {
    return '$title — créneau disponible';
  }

  @override
  String slotsAvailableTitle(String title, String slots) {
    return '$title — $slots disponibles';
  }

  @override
  String callTitle(String when) {
    return 'Rendez-vous disponible — $when';
  }

  @override
  String moreSlots(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+ $n autres créneaux',
      one: '+ 1 autre créneau',
    );
    return '$_temp0';
  }

  @override
  String get decline => 'Refuser';

  @override
  String get viewAppointment => 'Voir le RDV';

  @override
  String missedCall(String title) {
    return 'Appel manqué — $title';
  }

  @override
  String sampleTitle(String label) {
    return 'Exemple — $label';
  }

  @override
  String get sampleDoctor => 'Dr Exemple';

  @override
  String get sampleMotive => 'Première consultation';

  @override
  String get sampleSpeciality => 'Médecin généraliste';

  @override
  String get sampleTest => 'Test';

  @override
  String get statusInterrupted => 'Surveillance interrompue';

  @override
  String get statusNoAlerts => 'Aucune alerte configurée';

  @override
  String get statusAllPaused => 'Toutes les alertes sont en pause';

  @override
  String statusSlots(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n créneaux disponibles',
      one: '1 créneau disponible',
    );
    return '$_temp0';
  }

  @override
  String get statusActive => 'Surveillance active';

  @override
  String statusActiveCount(int active, int total) {
    return '$active/$total alertes actives';
  }

  @override
  String statusChecked(String ago) {
    return 'vérifié $ago';
  }

  @override
  String get callAvailable => 'Rendez-vous disponible';

  @override
  String callWhen(String day, String time) {
    return '$day à $time';
  }

  @override
  String callRingingLeft(int s) {
    return 'Sonne encore $s s';
  }

  @override
  String get checkNow => 'Vérifier maintenant';

  @override
  String get newAlert => 'Nouvelle alerte';

  @override
  String get noAlerts => 'Aucune alerte';

  @override
  String get noAlertsBody => 'Créez une alerte pour une spécialité dans une ville, ou pour un praticien précis. L\'app surveille Doctolib et vous prévient dès qu\'un créneau se libère dans la fenêtre que vous avez choisie.';

  @override
  String get createAlert => 'Créer une alerte';

  @override
  String pausedFor(int m) {
    return 'Surveillance en pause pour $m min';
  }

  @override
  String footerSchedule(String interval, String quiet) {
    return 'Je cherche $interval, $quiet.';
  }

  @override
  String footerCost(int perRun, int perDay, int max, int today) {
    return 'Environ $perRun question(s) à Doctolib à chaque fois, ~$perDay par jour sur une limite de $max. Aujourd\'hui : $today.';
  }

  @override
  String newCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nouveaux',
      one: '1 nouveau',
    );
    return '$_temp0';
  }

  @override
  String snoozedUntil(String time) {
    return 'en pause jusqu\'à $time';
  }

  @override
  String snoozedUntilCap(String time) {
    return 'En pause jusqu\'à $time';
  }

  @override
  String ignoredCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ignorés',
      one: '1 ignoré',
    );
    return '$_temp0';
  }

  @override
  String earliestOf(String slots, String when) {
    return '$slots · le plus tôt $when';
  }

  @override
  String get nothingInWindow => 'Rien dans la fenêtre pour l\'instant';

  @override
  String checkedAgo(String ago) {
    return 'Vérifié $ago';
  }

  @override
  String msgNewSlots(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nouveaux créneaux',
      one: '1 nouveau créneau',
    );
    return '$_temp0';
  }

  @override
  String msgNothingNew(String slots) {
    return '$slots (rien de nouveau)';
  }

  @override
  String get msgNoSlots => 'Aucun créneau dans la fenêtre';

  @override
  String get later => 'Plus tard';

  @override
  String get start => 'Commencer';

  @override
  String get next => 'Suivant';

  @override
  String get obWelcomeBody => 'Vous dites ce que vous cherchez et pour quand. L\'app surveille Doctolib en arrière-plan et vous prévient dès qu\'un rendez-vous se libère dans cette fenêtre, pas pour un créneau dans trois mois.\n\nTrois réglages rapides et c\'est prêt.';

  @override
  String get obLanguage => 'Langue de l\'application';

  @override
  String get allowNotifications => 'Autoriser les notifications';

  @override
  String get obNotifBody => 'C\'est par là que l\'app vous prévient. Sans cette autorisation, elle continue de chercher mais ne peut rien vous dire.';

  @override
  String get notifGranted => 'Notifications autorisées';

  @override
  String get notifPending => 'Pas encore autorisées';

  @override
  String get checkAgain => 'Vérifier à nouveau';

  @override
  String get obBatteryTitle => 'Laisser l\'app tourner en arrière-plan';

  @override
  String get obBatteryBody => 'Android met les applications en veille pour économiser la batterie. Si l\'app est mise en veille, elle arrête de vérifier et vous ne recevrez plus rien.\n\nAutorisez-la à fonctionner sans restriction : c\'est la raison numéro un pour laquelle ce type d\'app « arrête de marcher ».';

  @override
  String get batteryGranted => 'L\'app peut tourner en arrière-plan';

  @override
  String get batteryPending => 'Encore soumise aux restrictions de batterie';

  @override
  String get removeRestrictions => 'Retirer les restrictions';

  @override
  String get openAppSettings => 'Ouvrir les paramètres de l\'app';

  @override
  String get obBatteryOem => 'Sur Samsung, Xiaomi, Huawei, Oppo ou OnePlus, il faut souvent aussi ajouter l\'app aux « applications protégées » ou la retirer de l\'optimisation dans les réglages du fabricant.';

  @override
  String get quietHours => 'Heures de silence';

  @override
  String get obQuietBody => 'Pendant ces heures, l\'app ne vérifie rien et ne sonne pas. Vous dormez tranquille, et cela réduit d\'autant le nombre de requêtes envoyées à Doctolib.';

  @override
  String get enableQuietHours => 'Activer les heures de silence';

  @override
  String quietFromTo(String from, String to) {
    return 'Silence de $from à $to';
  }

  @override
  String get canRingAnytime => 'L\'app peut sonner à toute heure';

  @override
  String quietStart(String h) {
    return 'Début du silence : $h';
  }

  @override
  String quietEnd(String h) {
    return 'Réveil : $h';
  }

  @override
  String get changeLater => 'Modifiable à tout moment dans les réglages.';

  @override
  String get errNeedSpeciality => 'Choisissez au moins une spécialité';

  @override
  String get errNeedCity => 'Choisissez une ville';

  @override
  String get errNeedDoctor => 'Choisissez un praticien';

  @override
  String get errNeedMotive => 'Choisissez au moins un motif';

  @override
  String get errNeedWeekday => 'Gardez au moins un jour de la semaine';

  @override
  String get errEmptyHours => 'La plage horaire est vide';

  @override
  String get errNeedDates => 'Choisissez des dates';

  @override
  String get editAlert => 'Modifier l\'alerte';

  @override
  String get stepWhere => '1. Où ?';

  @override
  String get cityHint => 'Ville ou commune';

  @override
  String get stepWhat => '2. Que cherchez-vous ?';

  @override
  String get searchHint => 'Spécialité, nom du praticien, établissement...';

  @override
  String get searchHelperNoCity => 'Choisissez d\'abord une ville pour filtrer les praticiens';

  @override
  String searchHelperCity(String city) {
    return 'Praticiens de $city en premier';
  }

  @override
  String get alertName => 'Nom de l\'alerte';

  @override
  String get specialities => 'Spécialités';

  @override
  String get practitionersAndPlaces => 'Praticiens et établissements';

  @override
  String practitionersIn(String city) {
    return 'Praticiens à $city';
  }

  @override
  String get elsewhere => 'Ailleurs';

  @override
  String get specialityChipsHint => 'L\'alerte se déclenche pour n\'importe quel praticien de ces spécialités dans la ville choisie.';

  @override
  String get noOnlineMotive => 'Aucun motif réservable en ligne pour ce praticien.';

  @override
  String get motivesToWatch => 'Motifs à surveiller';

  @override
  String get whenTitle => 'Quand un créneau vous intéresse-t-il ?';

  @override
  String get whenBody => 'Seuls les créneaux tombant dans cette fenêtre déclenchent une notification. C\'est le réglage qui évite d\'être réveillé pour un rendez-vous dans trois mois.';

  @override
  String get nextDays => 'Prochains jours';

  @override
  String get exactDates => 'Dates précises';

  @override
  String get pickPeriod => 'Choisir une période';

  @override
  String get zoneCardTitle => 'Limiter à une zone autour de moi';

  @override
  String get zoneCardBody => 'Facultatif. Un rayon en km ou un temps de trajet depuis chez vous, votre position ou un point sur la carte. Sans zone, toute la ville est surveillée.';

  @override
  String get removeZone => 'Retirer la zone';

  @override
  String zoneFrom(String label) {
    return 'Depuis $label';
  }

  @override
  String zoneApprox(String dist) {
    return 'Soit environ $dist à vol d\'oiseau (estimation)';
  }

  @override
  String zoneTowns(String towns) {
    return 'Communes surveillées : $towns';
  }

  @override
  String get teleTitle => 'Au cabinet ou en vidéo ?';

  @override
  String get teleBody => 'Beaucoup de praticiens proposent les deux, et une téléconsultation se libère souvent bien plus vite qu\'un rendez-vous sur place.';

  @override
  String get howToAlert => 'Comment vous prévenir ?';

  @override
  String get howToAlertBody => 'Propre à cette alerte : un pédiatre pour un enfant malade mérite qu\'on vous sonne dessus, un contrôle de routine non.';

  @override
  String get callHint => 'Bouton vert : ouvre directement le rendez-vous. Bouton rouge ou pas de réponse : une notification normale reste. La sonnerie et sa durée se choisissent dans les Réglages. Les heures de silence restent prioritaires : rien ne sonne la nuit.';

  @override
  String get filters => 'Filtres';

  @override
  String get filtersBody => 'Doctolib ne propose aucun de ces filtres. Ils sont appliqués dans l\'app, sur les créneaux reçus, pour ne notifier que ce que vous pourriez réellement honorer.';

  @override
  String hourRange(String from, String to) {
    return 'Plage horaire : $from — $to';
  }

  @override
  String get acceptedDays => 'Jours acceptés';

  @override
  String get acceptsNewPatients => 'Accepte les nouveaux patients';

  @override
  String get acceptsNewPatientsBody => 'Ignore les praticiens réservés à leur patientèle';

  @override
  String get appearance => 'Apparence';

  @override
  String get language => 'Langue';

  @override
  String get langSystem => 'Langue du téléphone';

  @override
  String get theme => 'Thème';

  @override
  String get themeSystem => 'Automatique';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get frequencyTitle => 'À quelle fréquence chercher ?';

  @override
  String searchEvery(String interval) {
    return 'Je cherche $interval';
  }

  @override
  String get frequencyBody => 'Android ne lance jamais une vérification plus souvent que toutes les 15 minutes, et peut la retarder quand le téléphone dort. Plus souvent veut donc dire « dès que possible », pas « à la seconde près ».';

  @override
  String get freq15Advice => 'Toutes les 15 minutes est le minimum autorisé par Android, pas forcément le meilleur réglage : cela consomme quatre fois plus de requêtes que 60 minutes pour un gain réel assez faible, puisque le système retarde de toute façon les tâches quand le téléphone dort. À garder pour une recherche vraiment urgente, sur quelques jours.';

  @override
  String get freqBalancedAdvice => 'Bon compromis : assez réactif pour attraper une annulation, assez sobre pour tenir des semaines.';

  @override
  String get freqSlowAdvice => 'Très économe. Adapté à une recherche de fond, où les créneaux ne partent pas en quelques minutes.';

  @override
  String get allowBackground => 'Autoriser l\'app en arrière-plan';

  @override
  String get allowBackgroundBody => 'Sans cela, Android met l\'app en veille et les vérifications s\'arrêtent. C\'est la cause numéro un des alertes qui ne sonnent jamais.';

  @override
  String get backgroundRestricted => 'Toujours restreinte : ouvrez les paramètres Android';

  @override
  String quietOnBody(String from, String to) {
    return 'Entre $from et $to, l\'app ne cherche rien et ne sonne pas, même une alerte « M\'appeler » reste muette.';
  }

  @override
  String get quietOffBody => 'L\'app cherche et peut sonner à toute heure';

  @override
  String get fromLabel => 'De';

  @override
  String get toLabel => 'à';

  @override
  String get notifications => 'Notifications';

  @override
  String get groupByAlert => 'Regrouper par alerte';

  @override
  String get groupByAlertBody => 'Une seule notification résumant tous les nouveaux créneaux, plutôt qu\'une par créneau.';

  @override
  String get statusBadge => 'Badge permanent de surveillance';

  @override
  String get statusBadgeBody => 'Garde une ligne silencieuse dans le volet, à la manière d\'un antivirus : état de chaque alerte, nombre de créneaux libres et date de la dernière recherche. Le meilleur moyen de vérifier d\'un coup d\'œil que l\'app tourne encore.';

  @override
  String get needAndroid13 => 'Nécessaire sur Android 13 et plus';

  @override
  String get notifRefused => 'Refusé : activez-les dans les paramètres Android';

  @override
  String get testAlert => 'Tester une alerte';

  @override
  String get testAlertBody => 'Entendez ce que chaque style donne avant de lui confier un vrai rendez-vous.';

  @override
  String sampleSent(String label) {
    return 'Exemple envoyé : $label';
  }

  @override
  String get callModeTitle => 'Mode « M\'appeler »';

  @override
  String get callModeBody => 'Le téléphone sonne jusqu\'à ce que vous répondiez. Le bouton vert ouvre directement le rendez-vous sur Doctolib. Le bouton rouge, ou l\'absence de réponse, arrête la sonnerie et laisse une notification normale : le créneau reste à un geste.';

  @override
  String get soundBundled => 'Fournie avec l\'app';

  @override
  String get soundSystem => 'Celle réglée sur votre téléphone';

  @override
  String get listen => 'Écouter';

  @override
  String testCallSent(String label) {
    return 'Appel de test : $label (12 s, essayez les deux boutons)';
  }

  @override
  String get ringDuration => 'Durée de la sonnerie';

  @override
  String ringDurationBody(int s) {
    return 'Sans réponse après $s s, l\'appel s\'arrête et une notification « appel manqué » le remplace.';
  }

  @override
  String get blockTitle => 'Ne pas se faire bloquer';

  @override
  String get blockBody => 'Doctolib surveille les téléphones qui posent trop de questions et finit par les ignorer pendant un moment. Ces réglages gardent l\'app largement sous ce seuil : peu de questions, bien espacées, et elle se tait d\'elle-même si le site rechigne.';

  @override
  String get frugalTitle => 'Mode économe (recommandé)';

  @override
  String get frugalBody => 'Ne demande les horaires précis que pour les praticiens pas encore repérés : une recherche coûte alors 1 à 3 questions au lieu d\'une vingtaine. C\'est ce qui protège le plus du blocage.';

  @override
  String safetyLimit(String label) {
    return 'Limite de sécurité : $label';
  }

  @override
  String safetyLimitBody(int max, int today) {
    return 'Au maximum $max questions à Doctolib par jour, toutes alertes confondues. Passé cette limite, l\'app s\'arrête jusqu\'au lendemain plutôt que de risquer un blocage. Aujourd\'hui : $today utilisées.';
  }

  @override
  String get estimate => 'Estimation';

  @override
  String estimateBody(String interval, String quiet, int perRun, int perDay, int max) {
    return 'Vous cherchez $interval, $quiet. Cela fait environ $perRun question(s) à Doctolib à chaque fois, soit à peu près $perDay par jour sur une limite de $max.';
  }

  @override
  String get overLimit => 'C\'est au-dessus de votre limite : cherchez moins souvent, allongez les heures de silence, ou gardez moins d\'alertes actives.';

  @override
  String get safetyPause => 'Pause de sécurité';

  @override
  String resumeIn(int m) {
    return 'Reprise dans $m min.';
  }

  @override
  String get about => 'À propos';

  @override
  String get howItWorks => 'Comment ça marche';

  @override
  String get howItWorksBody => 'L\'app interroge les mêmes points d\'entrée JSON que le site doctolib.fr utilise lui-même quand vous le consultez. Rien ne quitte le téléphone : pas de compte, pas de serveur, pas de donnée de santé enregistrée. La réservation se fait sur Doctolib, dans votre navigateur.';

  @override
  String get personalUse => 'Usage personnel';

  @override
  String get personalUseBody => 'Ces points d\'entrée ne sont pas documentés et peuvent changer sans préavis. Gardez un rythme raisonnable et un usage strictement personnel.';

  @override
  String get alertDeleted => 'Alerte supprimée';

  @override
  String get nearestFirst => 'Du plus proche au plus loin';

  @override
  String get ignoreAll => 'Tout ignorer';

  @override
  String get resumeNow => 'Reprendre maintenant';

  @override
  String get snoozeMenu => 'Mettre en pause…';

  @override
  String get restoreAll => 'Tout réactiver';

  @override
  String get duplicate => 'Dupliquer';

  @override
  String get renotify => 'Renotifier les créneaux connus';

  @override
  String get check => 'Vérifier';

  @override
  String get earliest => 'Plus tôt';

  @override
  String get nearest => 'Plus proche';

  @override
  String noSlotsWindow(String window) {
    return 'Aucun créneau $window';
  }

  @override
  String get allIgnored => 'Tout est ignoré pour l\'instant';

  @override
  String get keepsChecking => 'L\'app continue de vérifier en arrière-plan et vous préviendra dès qu\'un rendez-vous se libère.';

  @override
  String get ignoredHidden => 'Les créneaux connus sont masqués. Tout nouveau créneau apparaîtra en rouge et vous sera notifié.';

  @override
  String ignoredHeader(int n) {
    return 'Ignoré ($n)';
  }

  @override
  String slotsWindow(String window) {
    return 'Créneaux $window';
  }

  @override
  String lastCheck(String ago) {
    return 'Dernière vérification $ago';
  }

  @override
  String repairInProgress(int n, int max) {
    return 'Réparation automatique en cours ($n/$max) : l\'alerte est reconstruite depuis Doctolib à chaque essai.';
  }

  @override
  String repairedAgo(String ago) {
    return 'Réparée automatiquement $ago';
  }

  @override
  String get alertActive => 'Alerte active';

  @override
  String zoneApproxParen(String dist) {
    return '(environ $dist à vol d\'oiseau)';
  }

  @override
  String zoneTownsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n communes',
      one: '1 commune',
    );
    return '$_temp0';
  }

  @override
  String get slotIgnored => 'Créneau ignoré';

  @override
  String dayIgnored(String date) {
    return 'Journée du $date ignorée';
  }

  @override
  String doctorIgnored(String name) {
    return '$name ignoré';
  }

  @override
  String ignoredAll(String slots) {
    return '$slots ignorés, seuls les nouveaux vous seront signalés';
  }

  @override
  String get allRestored => 'Tout a été réactivé';

  @override
  String get snoozeFor => 'Mettre en pause pendant';

  @override
  String hoursCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n heures',
      one: '1 heure',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String copyTitle(String title) {
    return '$title (copie)';
  }

  @override
  String get renotified => 'Les créneaux actuels seront notifiés à nouveau';

  @override
  String get deleteConfirm => 'Supprimer cette alerte ?';

  @override
  String get pointOnMap => 'Point choisi sur la carte';

  @override
  String get locationOff => 'La localisation du téléphone est désactivée.';

  @override
  String get locationDeniedForever => 'Localisation refusée. Autorisez-la dans les paramètres de l\'app, ou choisissez un point sur la carte.';

  @override
  String get locationDenied => 'Localisation refusée. Vous pouvez choisir un point sur la carte ou taper une adresse.';

  @override
  String positionNotFound(String error) {
    return 'Position introuvable ($error)';
  }

  @override
  String get needPoint => 'Choisissez d\'abord un point de départ.';

  @override
  String get findingTowns => 'Recherche des communes de la zone...';

  @override
  String preparingTown(String name, int i, int n) {
    return 'Préparation de $name sur Doctolib ($i/$n)';
  }

  @override
  String get pointChosen => 'Point choisi';

  @override
  String zonePrepFailed(String error) {
    return 'Impossible de préparer la zone : $error';
  }

  @override
  String get zoneTitle => 'Zone de recherche';

  @override
  String get addressOptional => 'Adresse (facultatif)';

  @override
  String get myPosition => 'Ma position';

  @override
  String get tapMapHint => 'Touchez la carte pour placer votre point de départ, ou utilisez « Ma position » ou une adresse.';

  @override
  String get circle => 'Cercle';

  @override
  String get travelTime => 'Temps de trajet';

  @override
  String radiusLabel(String dist) {
    return 'Rayon : $dist à vol d\'oiseau';
  }

  @override
  String atMost(int minutes, String phrase) {
    return 'Au plus $minutes min $phrase';
  }

  @override
  String travelEstimate(String dist) {
    return 'Estimation : environ $dist à vol d\'oiseau. Calculée avec des vitesses moyennes en ville (attente et marche comprises pour les transports) ; les horaires réels ne sont pas consultés.';
  }

  @override
  String get validateZone => 'Valider la zone';

  @override
  String get showWholeZone => 'Voir toute la zone';

  @override
  String get centerOnPoint => 'Recentrer sur le point';

  @override
  String get journal => 'Journal';

  @override
  String get journalBody => 'Ce que l\'app a fait, vérification par vérification : de quoi s\'assurer qu\'elle tourne bien en arrière-plan, et voir à quelle heure les créneaux se libèrent.';

  @override
  String get journalEmpty => 'Aucune activité pour le moment.';

  @override
  String get journalClear => 'Effacer le journal';

  @override
  String get journalBackground => 'arrière-plan';

  @override
  String get journalManual => 'manuel';

  @override
  String journalFound(String title, String slots, int fresh) {
    return '$title : $slots, dont $fresh nouveau(x)';
  }

  @override
  String journalNothing(String title) {
    return '$title : rien dans la fenêtre';
  }

  @override
  String journalError(String title, String error) {
    return '$title : $error';
  }

  @override
  String journalBusiestHour(String hour) {
    return 'Heure où les nouveaux créneaux apparaissent le plus souvent : $hour';
  }

  @override
  String get journalCallAccepted => 'Appel accepté';

  @override
  String get journalCallDeclined => 'Appel refusé';

  @override
  String get journalCallMissed => 'Appel manqué';
}
