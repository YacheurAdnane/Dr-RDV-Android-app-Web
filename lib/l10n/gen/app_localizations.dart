import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Alertes RDV'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Alertes rendez-vous'**
  String get homeTitle;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get tomorrow;

  /// No description provided for @todayShort.
  ///
  /// In fr, this message translates to:
  /// **'auj.'**
  String get todayShort;

  /// No description provided for @tomorrowShort.
  ///
  /// In fr, this message translates to:
  /// **'demain'**
  String get tomorrowShort;

  /// No description provided for @never.
  ///
  /// In fr, this message translates to:
  /// **'jamais'**
  String get never;

  /// No description provided for @justNow.
  ///
  /// In fr, this message translates to:
  /// **'à l\'instant'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {n} min'**
  String minutesAgo(int n);

  /// No description provided for @hoursAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {n} h'**
  String hoursAgo(int n);

  /// No description provided for @daysAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {n} j'**
  String daysAgo(int n);

  /// No description provided for @unitKm.
  ///
  /// In fr, this message translates to:
  /// **'km'**
  String get unitKm;

  /// No description provided for @unitM.
  ///
  /// In fr, this message translates to:
  /// **'m'**
  String get unitM;

  /// No description provided for @minutesShort.
  ///
  /// In fr, this message translates to:
  /// **'{n} min'**
  String minutesShort(int n);

  /// No description provided for @hoursShort.
  ///
  /// In fr, this message translates to:
  /// **'{n} h'**
  String hoursShort(int n);

  /// No description provided for @secondsShort.
  ///
  /// In fr, this message translates to:
  /// **'{n} s'**
  String secondsShort(int n);

  /// No description provided for @daysShort.
  ///
  /// In fr, this message translates to:
  /// **'{n} j'**
  String daysShort(int n);

  /// No description provided for @h24.
  ///
  /// In fr, this message translates to:
  /// **'24 h'**
  String get h24;

  /// No description provided for @crowFlies.
  ///
  /// In fr, this message translates to:
  /// **'à vol d\'oiseau'**
  String get crowFlies;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @undo.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get undo;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settings;

  /// No description provided for @androidSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get androidSettings;

  /// No description provided for @video.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo'**
  String get video;

  /// No description provided for @doctorFallback.
  ///
  /// In fr, this message translates to:
  /// **'Praticien'**
  String get doctorFallback;

  /// No description provided for @motiveFallback.
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get motiveFallback;

  /// No description provided for @alertFallbackTitle.
  ///
  /// In fr, this message translates to:
  /// **'Alerte'**
  String get alertFallbackTitle;

  /// No description provided for @newBadge.
  ///
  /// In fr, this message translates to:
  /// **'NOUVEAU'**
  String get newBadge;

  /// No description provided for @slotsCount.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 créneau} other{{n} créneaux}}'**
  String slotsCount(int n);

  /// No description provided for @requestsCount.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 requête} other{{n} requêtes}}'**
  String requestsCount(int n);

  /// No description provided for @cannotOpenDoctolib.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir Doctolib'**
  String get cannotOpenDoctolib;

  /// No description provided for @restore.
  ///
  /// In fr, this message translates to:
  /// **'Réactiver'**
  String get restore;

  /// No description provided for @more.
  ///
  /// In fr, this message translates to:
  /// **'Plus'**
  String get more;

  /// No description provided for @directions.
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire'**
  String get directions;

  /// No description provided for @ignoreSlot.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer ce créneau'**
  String get ignoreSlot;

  /// No description provided for @ignoreDay.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer le {date}'**
  String ignoreDay(String date);

  /// No description provided for @ignoreDoctor.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer {name}'**
  String ignoreDoctor(String name);

  /// No description provided for @noMapsApp.
  ///
  /// In fr, this message translates to:
  /// **'Aucune application de cartes trouvée'**
  String get noMapsApp;

  /// No description provided for @tripMinutes.
  ///
  /// In fr, this message translates to:
  /// **'~{minutes} min {phrase}'**
  String tripMinutes(int minutes, String phrase);

  /// No description provided for @travelWalk.
  ///
  /// In fr, this message translates to:
  /// **'À pied'**
  String get travelWalk;

  /// No description provided for @travelBike.
  ///
  /// In fr, this message translates to:
  /// **'Vélo'**
  String get travelBike;

  /// No description provided for @travelTransit.
  ///
  /// In fr, this message translates to:
  /// **'Transports'**
  String get travelTransit;

  /// No description provided for @travelCar.
  ///
  /// In fr, this message translates to:
  /// **'Voiture'**
  String get travelCar;

  /// No description provided for @phraseWalk.
  ///
  /// In fr, this message translates to:
  /// **'à pied'**
  String get phraseWalk;

  /// No description provided for @phraseBike.
  ///
  /// In fr, this message translates to:
  /// **'à vélo'**
  String get phraseBike;

  /// No description provided for @phraseTransit.
  ///
  /// In fr, this message translates to:
  /// **'en transports'**
  String get phraseTransit;

  /// No description provided for @phraseCar.
  ///
  /// In fr, this message translates to:
  /// **'en voiture'**
  String get phraseCar;

  /// No description provided for @zoneAround.
  ///
  /// In fr, this message translates to:
  /// **'{dist} autour de {label}'**
  String zoneAround(String dist, String label);

  /// No description provided for @zoneFromTravel.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min {phrase} depuis {label}'**
  String zoneFromTravel(int minutes, String phrase, String label);

  /// No description provided for @zoneShortTravel.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min {phrase}'**
  String zoneShortTravel(int minutes, String phrase);

  /// No description provided for @styleDiscreet.
  ///
  /// In fr, this message translates to:
  /// **'Discret'**
  String get styleDiscreet;

  /// No description provided for @styleNormal.
  ///
  /// In fr, this message translates to:
  /// **'Notification'**
  String get styleNormal;

  /// No description provided for @styleCall.
  ///
  /// In fr, this message translates to:
  /// **'M\'appeler'**
  String get styleCall;

  /// No description provided for @styleDiscreetDesc.
  ///
  /// In fr, this message translates to:
  /// **'Apparaît dans le volet, sans son. Pour les alertes de confort.'**
  String get styleDiscreetDesc;

  /// No description provided for @styleNormalDesc.
  ///
  /// In fr, this message translates to:
  /// **'Notification classique avec le son habituel du téléphone.'**
  String get styleNormalDesc;

  /// No description provided for @styleCallDesc.
  ///
  /// In fr, this message translates to:
  /// **'Sonne comme un appel WhatsApp, au volume de la sonnerie du téléphone, insiste jusqu\'à ce que vous répondiez, et s\'affiche sur l\'écran verrouillé. Réservé aux rendez-vous que vous ne voulez surtout pas rater.'**
  String get styleCallDesc;

  /// No description provided for @ringsLikeCall.
  ///
  /// In fr, this message translates to:
  /// **'Sonne comme un appel'**
  String get ringsLikeCall;

  /// No description provided for @teleAny.
  ///
  /// In fr, this message translates to:
  /// **'Peu importe'**
  String get teleAny;

  /// No description provided for @teleInPerson.
  ///
  /// In fr, this message translates to:
  /// **'Au cabinet'**
  String get teleInPerson;

  /// No description provided for @teleOnline.
  ///
  /// In fr, this message translates to:
  /// **'Téléconsultation'**
  String get teleOnline;

  /// No description provided for @teleAnyDesc.
  ///
  /// In fr, this message translates to:
  /// **'Sur place ou en vidéo, tout créneau compte.'**
  String get teleAnyDesc;

  /// No description provided for @teleInPersonDesc.
  ///
  /// In fr, this message translates to:
  /// **'Uniquement des rendez-vous physiques, au cabinet du praticien.'**
  String get teleInPersonDesc;

  /// No description provided for @teleOnlineDesc.
  ///
  /// In fr, this message translates to:
  /// **'Uniquement des consultations vidéo, depuis chez vous.'**
  String get teleOnlineDesc;

  /// No description provided for @teleShortInPerson.
  ///
  /// In fr, this message translates to:
  /// **'cabinet'**
  String get teleShortInPerson;

  /// No description provided for @teleShortOnline.
  ///
  /// In fr, this message translates to:
  /// **'vidéo'**
  String get teleShortOnline;

  /// No description provided for @teleSegInPerson.
  ///
  /// In fr, this message translates to:
  /// **'Cabinet'**
  String get teleSegInPerson;

  /// No description provided for @teleSegOnline.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo'**
  String get teleSegOnline;

  /// No description provided for @soundSystemRingtone.
  ///
  /// In fr, this message translates to:
  /// **'Sonnerie du téléphone'**
  String get soundSystemRingtone;

  /// No description provided for @soundSystemAlarm.
  ///
  /// In fr, this message translates to:
  /// **'Alarme du téléphone'**
  String get soundSystemAlarm;

  /// No description provided for @soundClassic.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone classique'**
  String get soundClassic;

  /// No description provided for @soundDigital.
  ///
  /// In fr, this message translates to:
  /// **'Bips numériques'**
  String get soundDigital;

  /// No description provided for @soundSoft.
  ///
  /// In fr, this message translates to:
  /// **'Carillon doux'**
  String get soundSoft;

  /// No description provided for @soundMarimba.
  ///
  /// In fr, this message translates to:
  /// **'Marimba'**
  String get soundMarimba;

  /// No description provided for @soundUrgent.
  ///
  /// In fr, this message translates to:
  /// **'Sirène urgente'**
  String get soundUrgent;

  /// No description provided for @windowRange.
  ///
  /// In fr, this message translates to:
  /// **'du {from} au {to}'**
  String windowRange(String from, String to);

  /// No description provided for @window24h.
  ///
  /// In fr, this message translates to:
  /// **'sous 24 h'**
  String get window24h;

  /// No description provided for @windowDays.
  ///
  /// In fr, this message translates to:
  /// **'sous {n} jours'**
  String windowDays(int n);

  /// No description provided for @filterNewPatients.
  ///
  /// In fr, this message translates to:
  /// **'nouveaux patients'**
  String get filterNewPatients;

  /// No description provided for @budgetVeryCautious.
  ///
  /// In fr, this message translates to:
  /// **'Très prudent'**
  String get budgetVeryCautious;

  /// No description provided for @budgetCautious.
  ///
  /// In fr, this message translates to:
  /// **'Prudent'**
  String get budgetCautious;

  /// No description provided for @budgetBalanced.
  ///
  /// In fr, this message translates to:
  /// **'Équilibré'**
  String get budgetBalanced;

  /// No description provided for @budgetReactive.
  ///
  /// In fr, this message translates to:
  /// **'Réactif'**
  String get budgetReactive;

  /// No description provided for @budgetMax.
  ///
  /// In fr, this message translates to:
  /// **'Maximum'**
  String get budgetMax;

  /// No description provided for @intervalMinutes.
  ///
  /// In fr, this message translates to:
  /// **'toutes les {n} minutes'**
  String intervalMinutes(int n);

  /// No description provided for @intervalHour.
  ///
  /// In fr, this message translates to:
  /// **'toutes les heures'**
  String get intervalHour;

  /// No description provided for @intervalHours.
  ///
  /// In fr, this message translates to:
  /// **'toutes les {n} heures'**
  String intervalHours(int n);

  /// No description provided for @quietRange.
  ///
  /// In fr, this message translates to:
  /// **'silence de {from} à {to}'**
  String quietRange(String from, String to);

  /// No description provided for @quietNone.
  ///
  /// In fr, this message translates to:
  /// **'jour et nuit'**
  String get quietNone;

  /// No description provided for @guardPaused.
  ///
  /// In fr, this message translates to:
  /// **'Pause de sécurité encore {m} min'**
  String guardPaused(int m);

  /// No description provided for @guardQuota.
  ///
  /// In fr, this message translates to:
  /// **'Quota quotidien atteint ({n} requêtes)'**
  String guardQuota(int n);

  /// No description provided for @guardRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Doctolib a limité le débit (429). Pause de {m} min.'**
  String guardRateLimited(int m);

  /// No description provided for @guardRefused.
  ///
  /// In fr, this message translates to:
  /// **'Doctolib a refusé la requête ({code}). Pause de {m} min.'**
  String guardRefused(int code, int m);

  /// No description provided for @apiNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Réseau indisponible ({error})'**
  String apiNetwork(String error);

  /// No description provided for @apiStatus.
  ///
  /// In fr, this message translates to:
  /// **'Doctolib a répondu {code}{reason}'**
  String apiStatus(String code, String reason);

  /// No description provided for @apiCityNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ville introuvable sur Doctolib : {city}'**
  String apiCityNotFound(String city);

  /// No description provided for @apiBadProfile.
  ///
  /// In fr, this message translates to:
  /// **'Fiche praticien illisible'**
  String get apiBadProfile;

  /// No description provided for @geoUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Service d\'adresses indisponible ({code})'**
  String geoUnavailable(int code);

  /// No description provided for @monitoringPaused.
  ///
  /// In fr, this message translates to:
  /// **'Surveillance en pause'**
  String get monitoringPaused;

  /// No description provided for @unexpectedError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur inattendue : {error}'**
  String unexpectedError(String error);

  /// No description provided for @failedStreak.
  ///
  /// In fr, this message translates to:
  /// **'Échec {n} fois de suite, malgré la réparation automatique. Cause : {cause}'**
  String failedStreak(int n, String cause);

  /// No description provided for @repairing.
  ///
  /// In fr, this message translates to:
  /// **'Réparation en cours ({n}/{max}) : {detail}'**
  String repairing(int n, int max, String detail);

  /// No description provided for @stateDisabled.
  ///
  /// In fr, this message translates to:
  /// **'désactivée'**
  String get stateDisabled;

  /// No description provided for @statePaused.
  ///
  /// In fr, this message translates to:
  /// **'en pause'**
  String get statePaused;

  /// No description provided for @stateError.
  ///
  /// In fr, this message translates to:
  /// **'erreur'**
  String get stateError;

  /// No description provided for @stateNothing.
  ///
  /// In fr, this message translates to:
  /// **'rien pour l\'instant'**
  String get stateNothing;

  /// No description provided for @incompleteSpeciality.
  ///
  /// In fr, this message translates to:
  /// **'Alerte incomplète : spécialité ou ville manquante'**
  String get incompleteSpeciality;

  /// No description provided for @incompleteDoctor.
  ///
  /// In fr, this message translates to:
  /// **'Alerte incomplète : praticien manquant'**
  String get incompleteDoctor;

  /// No description provided for @noMotiveSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun motif de consultation sélectionné'**
  String get noMotiveSelected;

  /// No description provided for @motivesGone.
  ///
  /// In fr, this message translates to:
  /// **'Les motifs suivis ne sont plus proposés'**
  String get motivesGone;

  /// No description provided for @chSlots.
  ///
  /// In fr, this message translates to:
  /// **'Créneaux disponibles'**
  String get chSlots;

  /// No description provided for @chSlotsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Un rendez-vous correspondant à une alerte est libre.'**
  String get chSlotsDesc;

  /// No description provided for @chQuiet.
  ///
  /// In fr, this message translates to:
  /// **'Créneaux (discret)'**
  String get chQuiet;

  /// No description provided for @chQuietDesc.
  ///
  /// In fr, this message translates to:
  /// **'Créneaux signalés sans son.'**
  String get chQuietDesc;

  /// No description provided for @chStatus.
  ///
  /// In fr, this message translates to:
  /// **'État de la surveillance'**
  String get chStatus;

  /// No description provided for @chStatusDesc.
  ///
  /// In fr, this message translates to:
  /// **'État des alertes, erreurs et pauses de sécurité.'**
  String get chStatusDesc;

  /// No description provided for @chCall.
  ///
  /// In fr, this message translates to:
  /// **'Appel : {label}'**
  String chCall(String label);

  /// No description provided for @chCallDesc.
  ///
  /// In fr, this message translates to:
  /// **'Sonne comme un appel quand un créneau prioritaire se libère.'**
  String get chCallDesc;

  /// No description provided for @slotAvailable.
  ///
  /// In fr, this message translates to:
  /// **'{title} — créneau disponible'**
  String slotAvailable(String title);

  /// No description provided for @slotsAvailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'{title} — {slots} disponibles'**
  String slotsAvailableTitle(String title, String slots);

  /// No description provided for @callTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rendez-vous disponible — {when}'**
  String callTitle(String when);

  /// No description provided for @moreSlots.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{+ 1 autre créneau} other{+ {n} autres créneaux}}'**
  String moreSlots(int n);

  /// No description provided for @decline.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get decline;

  /// No description provided for @viewAppointment.
  ///
  /// In fr, this message translates to:
  /// **'Voir le RDV'**
  String get viewAppointment;

  /// No description provided for @missedCall.
  ///
  /// In fr, this message translates to:
  /// **'Appel manqué — {title}'**
  String missedCall(String title);

  /// No description provided for @sampleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Exemple — {label}'**
  String sampleTitle(String label);

  /// No description provided for @sampleDoctor.
  ///
  /// In fr, this message translates to:
  /// **'Dr Exemple'**
  String get sampleDoctor;

  /// No description provided for @sampleMotive.
  ///
  /// In fr, this message translates to:
  /// **'Première consultation'**
  String get sampleMotive;

  /// No description provided for @sampleSpeciality.
  ///
  /// In fr, this message translates to:
  /// **'Médecin généraliste'**
  String get sampleSpeciality;

  /// No description provided for @sampleTest.
  ///
  /// In fr, this message translates to:
  /// **'Test'**
  String get sampleTest;

  /// No description provided for @statusInterrupted.
  ///
  /// In fr, this message translates to:
  /// **'Surveillance interrompue'**
  String get statusInterrupted;

  /// No description provided for @statusNoAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Aucune alerte configurée'**
  String get statusNoAlerts;

  /// No description provided for @statusAllPaused.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les alertes sont en pause'**
  String get statusAllPaused;

  /// No description provided for @statusSlots.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 créneau disponible} other{{n} créneaux disponibles}}'**
  String statusSlots(int n);

  /// No description provided for @statusActive.
  ///
  /// In fr, this message translates to:
  /// **'Surveillance active'**
  String get statusActive;

  /// No description provided for @statusActiveCount.
  ///
  /// In fr, this message translates to:
  /// **'{active}/{total} alertes actives'**
  String statusActiveCount(int active, int total);

  /// No description provided for @statusChecked.
  ///
  /// In fr, this message translates to:
  /// **'vérifié {ago}'**
  String statusChecked(String ago);

  /// No description provided for @callAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Rendez-vous disponible'**
  String get callAvailable;

  /// No description provided for @callWhen.
  ///
  /// In fr, this message translates to:
  /// **'{day} à {time}'**
  String callWhen(String day, String time);

  /// No description provided for @callRingingLeft.
  ///
  /// In fr, this message translates to:
  /// **'Sonne encore {s} s'**
  String callRingingLeft(int s);

  /// No description provided for @checkNow.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier maintenant'**
  String get checkNow;

  /// No description provided for @newAlert.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle alerte'**
  String get newAlert;

  /// No description provided for @noAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Aucune alerte'**
  String get noAlerts;

  /// No description provided for @noAlertsBody.
  ///
  /// In fr, this message translates to:
  /// **'Créez une alerte pour une spécialité dans une ville, ou pour un praticien précis. L\'app surveille Doctolib et vous prévient dès qu\'un créneau se libère dans la fenêtre que vous avez choisie.'**
  String get noAlertsBody;

  /// No description provided for @createAlert.
  ///
  /// In fr, this message translates to:
  /// **'Créer une alerte'**
  String get createAlert;

  /// No description provided for @pausedFor.
  ///
  /// In fr, this message translates to:
  /// **'Surveillance en pause pour {m} min'**
  String pausedFor(int m);

  /// No description provided for @footerSchedule.
  ///
  /// In fr, this message translates to:
  /// **'Je cherche {interval}, {quiet}.'**
  String footerSchedule(String interval, String quiet);

  /// No description provided for @footerCost.
  ///
  /// In fr, this message translates to:
  /// **'Environ {perRun} question(s) à Doctolib à chaque fois, ~{perDay} par jour sur une limite de {max}. Aujourd\'hui : {today}.'**
  String footerCost(int perRun, int perDay, int max, int today);

  /// No description provided for @newCount.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 nouveau} other{{n} nouveaux}}'**
  String newCount(int n);

  /// No description provided for @snoozedUntil.
  ///
  /// In fr, this message translates to:
  /// **'en pause jusqu\'à {time}'**
  String snoozedUntil(String time);

  /// No description provided for @snoozedUntilCap.
  ///
  /// In fr, this message translates to:
  /// **'En pause jusqu\'à {time}'**
  String snoozedUntilCap(String time);

  /// No description provided for @ignoredCount.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 ignoré} other{{n} ignorés}}'**
  String ignoredCount(int n);

  /// No description provided for @earliestOf.
  ///
  /// In fr, this message translates to:
  /// **'{slots} · le plus tôt {when}'**
  String earliestOf(String slots, String when);

  /// No description provided for @nothingInWindow.
  ///
  /// In fr, this message translates to:
  /// **'Rien dans la fenêtre pour l\'instant'**
  String get nothingInWindow;

  /// No description provided for @checkedAgo.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié {ago}'**
  String checkedAgo(String ago);

  /// No description provided for @msgNewSlots.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 nouveau créneau} other{{n} nouveaux créneaux}}'**
  String msgNewSlots(int n);

  /// No description provided for @msgNothingNew.
  ///
  /// In fr, this message translates to:
  /// **'{slots} (rien de nouveau)'**
  String msgNothingNew(String slots);

  /// No description provided for @msgNoSlots.
  ///
  /// In fr, this message translates to:
  /// **'Aucun créneau dans la fenêtre'**
  String get msgNoSlots;

  /// No description provided for @later.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get later;

  /// No description provided for @start.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get start;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @obWelcomeBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous dites ce que vous cherchez et pour quand. L\'app surveille Doctolib en arrière-plan et vous prévient dès qu\'un rendez-vous se libère dans cette fenêtre, pas pour un créneau dans trois mois.\n\nTrois réglages rapides et c\'est prêt.'**
  String get obWelcomeBody;

  /// No description provided for @obLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'application'**
  String get obLanguage;

  /// No description provided for @allowNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser les notifications'**
  String get allowNotifications;

  /// No description provided for @obNotifBody.
  ///
  /// In fr, this message translates to:
  /// **'C\'est par là que l\'app vous prévient. Sans cette autorisation, elle continue de chercher mais ne peut rien vous dire.'**
  String get obNotifBody;

  /// No description provided for @notifGranted.
  ///
  /// In fr, this message translates to:
  /// **'Notifications autorisées'**
  String get notifGranted;

  /// No description provided for @notifPending.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore autorisées'**
  String get notifPending;

  /// No description provided for @checkAgain.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier à nouveau'**
  String get checkAgain;

  /// No description provided for @obBatteryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Laisser l\'app tourner en arrière-plan'**
  String get obBatteryTitle;

  /// No description provided for @obBatteryBody.
  ///
  /// In fr, this message translates to:
  /// **'Android met les applications en veille pour économiser la batterie. Si l\'app est mise en veille, elle arrête de vérifier et vous ne recevrez plus rien.\n\nAutorisez-la à fonctionner sans restriction : c\'est la raison numéro un pour laquelle ce type d\'app « arrête de marcher ».'**
  String get obBatteryBody;

  /// No description provided for @batteryGranted.
  ///
  /// In fr, this message translates to:
  /// **'L\'app peut tourner en arrière-plan'**
  String get batteryGranted;

  /// No description provided for @batteryPending.
  ///
  /// In fr, this message translates to:
  /// **'Encore soumise aux restrictions de batterie'**
  String get batteryPending;

  /// No description provided for @removeRestrictions.
  ///
  /// In fr, this message translates to:
  /// **'Retirer les restrictions'**
  String get removeRestrictions;

  /// No description provided for @openAppSettings.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les paramètres de l\'app'**
  String get openAppSettings;

  /// No description provided for @obBatteryOem.
  ///
  /// In fr, this message translates to:
  /// **'Sur Samsung, Xiaomi, Huawei, Oppo ou OnePlus, il faut souvent aussi ajouter l\'app aux « applications protégées » ou la retirer de l\'optimisation dans les réglages du fabricant.'**
  String get obBatteryOem;

  /// No description provided for @quietHours.
  ///
  /// In fr, this message translates to:
  /// **'Heures de silence'**
  String get quietHours;

  /// No description provided for @obQuietBody.
  ///
  /// In fr, this message translates to:
  /// **'Pendant ces heures, l\'app ne vérifie rien et ne sonne pas. Vous dormez tranquille, et cela réduit d\'autant le nombre de requêtes envoyées à Doctolib.'**
  String get obQuietBody;

  /// No description provided for @enableQuietHours.
  ///
  /// In fr, this message translates to:
  /// **'Activer les heures de silence'**
  String get enableQuietHours;

  /// No description provided for @quietFromTo.
  ///
  /// In fr, this message translates to:
  /// **'Silence de {from} à {to}'**
  String quietFromTo(String from, String to);

  /// No description provided for @canRingAnytime.
  ///
  /// In fr, this message translates to:
  /// **'L\'app peut sonner à toute heure'**
  String get canRingAnytime;

  /// No description provided for @quietStart.
  ///
  /// In fr, this message translates to:
  /// **'Début du silence : {h}'**
  String quietStart(String h);

  /// No description provided for @quietEnd.
  ///
  /// In fr, this message translates to:
  /// **'Réveil : {h}'**
  String quietEnd(String h);

  /// No description provided for @changeLater.
  ///
  /// In fr, this message translates to:
  /// **'Modifiable à tout moment dans les réglages.'**
  String get changeLater;

  /// No description provided for @errNeedSpeciality.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez au moins une spécialité'**
  String get errNeedSpeciality;

  /// No description provided for @errNeedCity.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une ville'**
  String get errNeedCity;

  /// No description provided for @errNeedDoctor.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un praticien'**
  String get errNeedDoctor;

  /// No description provided for @errNeedMotive.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez au moins un motif'**
  String get errNeedMotive;

  /// No description provided for @errNeedWeekday.
  ///
  /// In fr, this message translates to:
  /// **'Gardez au moins un jour de la semaine'**
  String get errNeedWeekday;

  /// No description provided for @errEmptyHours.
  ///
  /// In fr, this message translates to:
  /// **'La plage horaire est vide'**
  String get errEmptyHours;

  /// No description provided for @errNeedDates.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez des dates'**
  String get errNeedDates;

  /// No description provided for @editAlert.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'alerte'**
  String get editAlert;

  /// No description provided for @stepWhere.
  ///
  /// In fr, this message translates to:
  /// **'1. Où ?'**
  String get stepWhere;

  /// No description provided for @cityHint.
  ///
  /// In fr, this message translates to:
  /// **'Ville ou commune'**
  String get cityHint;

  /// No description provided for @stepWhat.
  ///
  /// In fr, this message translates to:
  /// **'2. Que cherchez-vous ?'**
  String get stepWhat;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Spécialité, nom du praticien, établissement...'**
  String get searchHint;

  /// No description provided for @searchHelperNoCity.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez d\'abord une ville pour filtrer les praticiens'**
  String get searchHelperNoCity;

  /// No description provided for @searchHelperCity.
  ///
  /// In fr, this message translates to:
  /// **'Praticiens de {city} en premier'**
  String searchHelperCity(String city);

  /// No description provided for @alertName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'alerte'**
  String get alertName;

  /// No description provided for @specialities.
  ///
  /// In fr, this message translates to:
  /// **'Spécialités'**
  String get specialities;

  /// No description provided for @practitionersAndPlaces.
  ///
  /// In fr, this message translates to:
  /// **'Praticiens et établissements'**
  String get practitionersAndPlaces;

  /// No description provided for @practitionersIn.
  ///
  /// In fr, this message translates to:
  /// **'Praticiens à {city}'**
  String practitionersIn(String city);

  /// No description provided for @elsewhere.
  ///
  /// In fr, this message translates to:
  /// **'Ailleurs'**
  String get elsewhere;

  /// No description provided for @specialityChipsHint.
  ///
  /// In fr, this message translates to:
  /// **'L\'alerte se déclenche pour n\'importe quel praticien de ces spécialités dans la ville choisie.'**
  String get specialityChipsHint;

  /// No description provided for @noOnlineMotive.
  ///
  /// In fr, this message translates to:
  /// **'Aucun motif réservable en ligne pour ce praticien.'**
  String get noOnlineMotive;

  /// No description provided for @motivesToWatch.
  ///
  /// In fr, this message translates to:
  /// **'Motifs à surveiller'**
  String get motivesToWatch;

  /// No description provided for @whenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quand un créneau vous intéresse-t-il ?'**
  String get whenTitle;

  /// No description provided for @whenBody.
  ///
  /// In fr, this message translates to:
  /// **'Seuls les créneaux tombant dans cette fenêtre déclenchent une notification. C\'est le réglage qui évite d\'être réveillé pour un rendez-vous dans trois mois.'**
  String get whenBody;

  /// No description provided for @nextDays.
  ///
  /// In fr, this message translates to:
  /// **'Prochains jours'**
  String get nextDays;

  /// No description provided for @exactDates.
  ///
  /// In fr, this message translates to:
  /// **'Dates précises'**
  String get exactDates;

  /// No description provided for @pickPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une période'**
  String get pickPeriod;

  /// No description provided for @zoneCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Limiter à une zone autour de moi'**
  String get zoneCardTitle;

  /// No description provided for @zoneCardBody.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif. Un rayon en km ou un temps de trajet depuis chez vous, votre position ou un point sur la carte. Sans zone, toute la ville est surveillée.'**
  String get zoneCardBody;

  /// No description provided for @removeZone.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la zone'**
  String get removeZone;

  /// No description provided for @zoneFrom.
  ///
  /// In fr, this message translates to:
  /// **'Depuis {label}'**
  String zoneFrom(String label);

  /// No description provided for @zoneApprox.
  ///
  /// In fr, this message translates to:
  /// **'Soit environ {dist} à vol d\'oiseau (estimation)'**
  String zoneApprox(String dist);

  /// No description provided for @zoneTowns.
  ///
  /// In fr, this message translates to:
  /// **'Communes surveillées : {towns}'**
  String zoneTowns(String towns);

  /// No description provided for @teleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Au cabinet ou en vidéo ?'**
  String get teleTitle;

  /// No description provided for @teleBody.
  ///
  /// In fr, this message translates to:
  /// **'Beaucoup de praticiens proposent les deux, et une téléconsultation se libère souvent bien plus vite qu\'un rendez-vous sur place.'**
  String get teleBody;

  /// No description provided for @howToAlert.
  ///
  /// In fr, this message translates to:
  /// **'Comment vous prévenir ?'**
  String get howToAlert;

  /// No description provided for @howToAlertBody.
  ///
  /// In fr, this message translates to:
  /// **'Propre à cette alerte : un pédiatre pour un enfant malade mérite qu\'on vous sonne dessus, un contrôle de routine non.'**
  String get howToAlertBody;

  /// No description provided for @callHint.
  ///
  /// In fr, this message translates to:
  /// **'Bouton vert : ouvre directement le rendez-vous. Bouton rouge ou pas de réponse : une notification normale reste. La sonnerie et sa durée se choisissent dans les Réglages. Les heures de silence restent prioritaires : rien ne sonne la nuit.'**
  String get callHint;

  /// No description provided for @filters.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filters;

  /// No description provided for @filtersBody.
  ///
  /// In fr, this message translates to:
  /// **'Doctolib ne propose aucun de ces filtres. Ils sont appliqués dans l\'app, sur les créneaux reçus, pour ne notifier que ce que vous pourriez réellement honorer.'**
  String get filtersBody;

  /// No description provided for @hourRange.
  ///
  /// In fr, this message translates to:
  /// **'Plage horaire : {from} — {to}'**
  String hourRange(String from, String to);

  /// No description provided for @acceptedDays.
  ///
  /// In fr, this message translates to:
  /// **'Jours acceptés'**
  String get acceptedDays;

  /// No description provided for @acceptsNewPatients.
  ///
  /// In fr, this message translates to:
  /// **'Accepte les nouveaux patients'**
  String get acceptsNewPatients;

  /// No description provided for @acceptsNewPatientsBody.
  ///
  /// In fr, this message translates to:
  /// **'Ignore les praticiens réservés à leur patientèle'**
  String get acceptsNewPatientsBody;

  /// No description provided for @appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @langSystem.
  ///
  /// In fr, this message translates to:
  /// **'Langue du téléphone'**
  String get langSystem;

  /// No description provided for @theme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Automatique'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @frequencyTitle.
  ///
  /// In fr, this message translates to:
  /// **'À quelle fréquence chercher ?'**
  String get frequencyTitle;

  /// No description provided for @searchEvery.
  ///
  /// In fr, this message translates to:
  /// **'Je cherche {interval}'**
  String searchEvery(String interval);

  /// No description provided for @frequencyBody.
  ///
  /// In fr, this message translates to:
  /// **'Android ne lance jamais une vérification plus souvent que toutes les 15 minutes, et peut la retarder quand le téléphone dort. Plus souvent veut donc dire « dès que possible », pas « à la seconde près ».'**
  String get frequencyBody;

  /// No description provided for @freq15Advice.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les 15 minutes est le minimum autorisé par Android, pas forcément le meilleur réglage : cela consomme quatre fois plus de requêtes que 60 minutes pour un gain réel assez faible, puisque le système retarde de toute façon les tâches quand le téléphone dort. À garder pour une recherche vraiment urgente, sur quelques jours.'**
  String get freq15Advice;

  /// No description provided for @freqBalancedAdvice.
  ///
  /// In fr, this message translates to:
  /// **'Bon compromis : assez réactif pour attraper une annulation, assez sobre pour tenir des semaines.'**
  String get freqBalancedAdvice;

  /// No description provided for @freqSlowAdvice.
  ///
  /// In fr, this message translates to:
  /// **'Très économe. Adapté à une recherche de fond, où les créneaux ne partent pas en quelques minutes.'**
  String get freqSlowAdvice;

  /// No description provided for @allowBackground.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser l\'app en arrière-plan'**
  String get allowBackground;

  /// No description provided for @allowBackgroundBody.
  ///
  /// In fr, this message translates to:
  /// **'Sans cela, Android met l\'app en veille et les vérifications s\'arrêtent. C\'est la cause numéro un des alertes qui ne sonnent jamais.'**
  String get allowBackgroundBody;

  /// No description provided for @backgroundRestricted.
  ///
  /// In fr, this message translates to:
  /// **'Toujours restreinte : ouvrez les paramètres Android'**
  String get backgroundRestricted;

  /// No description provided for @quietOnBody.
  ///
  /// In fr, this message translates to:
  /// **'Entre {from} et {to}, l\'app ne cherche rien et ne sonne pas, même une alerte « M\'appeler » reste muette.'**
  String quietOnBody(String from, String to);

  /// No description provided for @quietOffBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'app cherche et peut sonner à toute heure'**
  String get quietOffBody;

  /// No description provided for @fromLabel.
  ///
  /// In fr, this message translates to:
  /// **'De'**
  String get fromLabel;

  /// No description provided for @toLabel.
  ///
  /// In fr, this message translates to:
  /// **'à'**
  String get toLabel;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @groupByAlert.
  ///
  /// In fr, this message translates to:
  /// **'Regrouper par alerte'**
  String get groupByAlert;

  /// No description provided for @groupByAlertBody.
  ///
  /// In fr, this message translates to:
  /// **'Une seule notification résumant tous les nouveaux créneaux, plutôt qu\'une par créneau.'**
  String get groupByAlertBody;

  /// No description provided for @statusBadge.
  ///
  /// In fr, this message translates to:
  /// **'Badge permanent de surveillance'**
  String get statusBadge;

  /// No description provided for @statusBadgeBody.
  ///
  /// In fr, this message translates to:
  /// **'Garde une ligne silencieuse dans le volet, à la manière d\'un antivirus : état de chaque alerte, nombre de créneaux libres et date de la dernière recherche. Le meilleur moyen de vérifier d\'un coup d\'œil que l\'app tourne encore.'**
  String get statusBadgeBody;

  /// No description provided for @needAndroid13.
  ///
  /// In fr, this message translates to:
  /// **'Nécessaire sur Android 13 et plus'**
  String get needAndroid13;

  /// No description provided for @notifRefused.
  ///
  /// In fr, this message translates to:
  /// **'Refusé : activez-les dans les paramètres Android'**
  String get notifRefused;

  /// No description provided for @testAlert.
  ///
  /// In fr, this message translates to:
  /// **'Tester une alerte'**
  String get testAlert;

  /// No description provided for @testAlertBody.
  ///
  /// In fr, this message translates to:
  /// **'Entendez ce que chaque style donne avant de lui confier un vrai rendez-vous.'**
  String get testAlertBody;

  /// No description provided for @sampleSent.
  ///
  /// In fr, this message translates to:
  /// **'Exemple envoyé : {label}'**
  String sampleSent(String label);

  /// No description provided for @callModeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mode « M\'appeler »'**
  String get callModeTitle;

  /// No description provided for @callModeBody.
  ///
  /// In fr, this message translates to:
  /// **'Le téléphone sonne jusqu\'à ce que vous répondiez. Le bouton vert ouvre directement le rendez-vous sur Doctolib. Le bouton rouge, ou l\'absence de réponse, arrête la sonnerie et laisse une notification normale : le créneau reste à un geste.'**
  String get callModeBody;

  /// No description provided for @soundBundled.
  ///
  /// In fr, this message translates to:
  /// **'Fournie avec l\'app'**
  String get soundBundled;

  /// No description provided for @soundSystem.
  ///
  /// In fr, this message translates to:
  /// **'Celle réglée sur votre téléphone'**
  String get soundSystem;

  /// No description provided for @listen.
  ///
  /// In fr, this message translates to:
  /// **'Écouter'**
  String get listen;

  /// No description provided for @testCallSent.
  ///
  /// In fr, this message translates to:
  /// **'Appel de test : {label} (12 s, essayez les deux boutons)'**
  String testCallSent(String label);

  /// No description provided for @ringDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée de la sonnerie'**
  String get ringDuration;

  /// No description provided for @ringDurationBody.
  ///
  /// In fr, this message translates to:
  /// **'Sans réponse après {s} s, l\'appel s\'arrête et une notification « appel manqué » le remplace.'**
  String ringDurationBody(int s);

  /// No description provided for @blockTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ne pas se faire bloquer'**
  String get blockTitle;

  /// No description provided for @blockBody.
  ///
  /// In fr, this message translates to:
  /// **'Doctolib surveille les téléphones qui posent trop de questions et finit par les ignorer pendant un moment. Ces réglages gardent l\'app largement sous ce seuil : peu de questions, bien espacées, et elle se tait d\'elle-même si le site rechigne.'**
  String get blockBody;

  /// No description provided for @frugalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mode économe (recommandé)'**
  String get frugalTitle;

  /// No description provided for @frugalBody.
  ///
  /// In fr, this message translates to:
  /// **'Ne demande les horaires précis que pour les praticiens pas encore repérés : une recherche coûte alors 1 à 3 questions au lieu d\'une vingtaine. C\'est ce qui protège le plus du blocage.'**
  String get frugalBody;

  /// No description provided for @safetyLimit.
  ///
  /// In fr, this message translates to:
  /// **'Limite de sécurité : {label}'**
  String safetyLimit(String label);

  /// No description provided for @safetyLimitBody.
  ///
  /// In fr, this message translates to:
  /// **'Au maximum {max} questions à Doctolib par jour, toutes alertes confondues. Passé cette limite, l\'app s\'arrête jusqu\'au lendemain plutôt que de risquer un blocage. Aujourd\'hui : {today} utilisées.'**
  String safetyLimitBody(int max, int today);

  /// No description provided for @estimate.
  ///
  /// In fr, this message translates to:
  /// **'Estimation'**
  String get estimate;

  /// No description provided for @estimateBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous cherchez {interval}, {quiet}. Cela fait environ {perRun} question(s) à Doctolib à chaque fois, soit à peu près {perDay} par jour sur une limite de {max}.'**
  String estimateBody(String interval, String quiet, int perRun, int perDay, int max);

  /// No description provided for @overLimit.
  ///
  /// In fr, this message translates to:
  /// **'C\'est au-dessus de votre limite : cherchez moins souvent, allongez les heures de silence, ou gardez moins d\'alertes actives.'**
  String get overLimit;

  /// No description provided for @safetyPause.
  ///
  /// In fr, this message translates to:
  /// **'Pause de sécurité'**
  String get safetyPause;

  /// No description provided for @resumeIn.
  ///
  /// In fr, this message translates to:
  /// **'Reprise dans {m} min.'**
  String resumeIn(int m);

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get about;

  /// No description provided for @howItWorks.
  ///
  /// In fr, this message translates to:
  /// **'Comment ça marche'**
  String get howItWorks;

  /// No description provided for @howItWorksBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'app interroge les mêmes points d\'entrée JSON que le site doctolib.fr utilise lui-même quand vous le consultez. Rien ne quitte le téléphone : pas de compte, pas de serveur, pas de donnée de santé enregistrée. La réservation se fait sur Doctolib, dans votre navigateur.'**
  String get howItWorksBody;

  /// No description provided for @personalUse.
  ///
  /// In fr, this message translates to:
  /// **'Usage personnel'**
  String get personalUse;

  /// No description provided for @personalUseBody.
  ///
  /// In fr, this message translates to:
  /// **'Ces points d\'entrée ne sont pas documentés et peuvent changer sans préavis. Gardez un rythme raisonnable et un usage strictement personnel.'**
  String get personalUseBody;

  /// No description provided for @alertDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Alerte supprimée'**
  String get alertDeleted;

  /// No description provided for @nearestFirst.
  ///
  /// In fr, this message translates to:
  /// **'Du plus proche au plus loin'**
  String get nearestFirst;

  /// No description provided for @ignoreAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout ignorer'**
  String get ignoreAll;

  /// No description provided for @resumeNow.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre maintenant'**
  String get resumeNow;

  /// No description provided for @snoozeMenu.
  ///
  /// In fr, this message translates to:
  /// **'Mettre en pause…'**
  String get snoozeMenu;

  /// No description provided for @restoreAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout réactiver'**
  String get restoreAll;

  /// No description provided for @duplicate.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer'**
  String get duplicate;

  /// No description provided for @renotify.
  ///
  /// In fr, this message translates to:
  /// **'Renotifier les créneaux connus'**
  String get renotify;

  /// No description provided for @check.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get check;

  /// No description provided for @earliest.
  ///
  /// In fr, this message translates to:
  /// **'Plus tôt'**
  String get earliest;

  /// No description provided for @nearest.
  ///
  /// In fr, this message translates to:
  /// **'Plus proche'**
  String get nearest;

  /// No description provided for @noSlotsWindow.
  ///
  /// In fr, this message translates to:
  /// **'Aucun créneau {window}'**
  String noSlotsWindow(String window);

  /// No description provided for @allIgnored.
  ///
  /// In fr, this message translates to:
  /// **'Tout est ignoré pour l\'instant'**
  String get allIgnored;

  /// No description provided for @keepsChecking.
  ///
  /// In fr, this message translates to:
  /// **'L\'app continue de vérifier en arrière-plan et vous préviendra dès qu\'un rendez-vous se libère.'**
  String get keepsChecking;

  /// No description provided for @ignoredHidden.
  ///
  /// In fr, this message translates to:
  /// **'Les créneaux connus sont masqués. Tout nouveau créneau apparaîtra en rouge et vous sera notifié.'**
  String get ignoredHidden;

  /// No description provided for @ignoredHeader.
  ///
  /// In fr, this message translates to:
  /// **'Ignoré ({n})'**
  String ignoredHeader(int n);

  /// No description provided for @slotsWindow.
  ///
  /// In fr, this message translates to:
  /// **'Créneaux {window}'**
  String slotsWindow(String window);

  /// No description provided for @lastCheck.
  ///
  /// In fr, this message translates to:
  /// **'Dernière vérification {ago}'**
  String lastCheck(String ago);

  /// No description provided for @repairInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Réparation automatique en cours ({n}/{max}) : l\'alerte est reconstruite depuis Doctolib à chaque essai.'**
  String repairInProgress(int n, int max);

  /// No description provided for @repairedAgo.
  ///
  /// In fr, this message translates to:
  /// **'Réparée automatiquement {ago}'**
  String repairedAgo(String ago);

  /// No description provided for @alertActive.
  ///
  /// In fr, this message translates to:
  /// **'Alerte active'**
  String get alertActive;

  /// No description provided for @zoneApproxParen.
  ///
  /// In fr, this message translates to:
  /// **'(environ {dist} à vol d\'oiseau)'**
  String zoneApproxParen(String dist);

  /// No description provided for @zoneTownsCount.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 commune} other{{n} communes}}'**
  String zoneTownsCount(int n);

  /// No description provided for @slotIgnored.
  ///
  /// In fr, this message translates to:
  /// **'Créneau ignoré'**
  String get slotIgnored;

  /// No description provided for @dayIgnored.
  ///
  /// In fr, this message translates to:
  /// **'Journée du {date} ignorée'**
  String dayIgnored(String date);

  /// No description provided for @doctorIgnored.
  ///
  /// In fr, this message translates to:
  /// **'{name} ignoré'**
  String doctorIgnored(String name);

  /// No description provided for @ignoredAll.
  ///
  /// In fr, this message translates to:
  /// **'{slots} ignorés, seuls les nouveaux vous seront signalés'**
  String ignoredAll(String slots);

  /// No description provided for @allRestored.
  ///
  /// In fr, this message translates to:
  /// **'Tout a été réactivé'**
  String get allRestored;

  /// No description provided for @snoozeFor.
  ///
  /// In fr, this message translates to:
  /// **'Mettre en pause pendant'**
  String get snoozeFor;

  /// No description provided for @hoursCount.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 heure} other{{n} heures}}'**
  String hoursCount(int n);

  /// No description provided for @daysCount.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 jour} other{{n} jours}}'**
  String daysCount(int n);

  /// No description provided for @copyTitle.
  ///
  /// In fr, this message translates to:
  /// **'{title} (copie)'**
  String copyTitle(String title);

  /// No description provided for @renotified.
  ///
  /// In fr, this message translates to:
  /// **'Les créneaux actuels seront notifiés à nouveau'**
  String get renotified;

  /// No description provided for @deleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette alerte ?'**
  String get deleteConfirm;

  /// No description provided for @pointOnMap.
  ///
  /// In fr, this message translates to:
  /// **'Point choisi sur la carte'**
  String get pointOnMap;

  /// No description provided for @locationOff.
  ///
  /// In fr, this message translates to:
  /// **'La localisation du téléphone est désactivée.'**
  String get locationOff;

  /// No description provided for @locationDeniedForever.
  ///
  /// In fr, this message translates to:
  /// **'Localisation refusée. Autorisez-la dans les paramètres de l\'app, ou choisissez un point sur la carte.'**
  String get locationDeniedForever;

  /// No description provided for @locationDenied.
  ///
  /// In fr, this message translates to:
  /// **'Localisation refusée. Vous pouvez choisir un point sur la carte ou taper une adresse.'**
  String get locationDenied;

  /// No description provided for @positionNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Position introuvable ({error})'**
  String positionNotFound(String error);

  /// No description provided for @needPoint.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez d\'abord un point de départ.'**
  String get needPoint;

  /// No description provided for @findingTowns.
  ///
  /// In fr, this message translates to:
  /// **'Recherche des communes de la zone...'**
  String get findingTowns;

  /// No description provided for @preparingTown.
  ///
  /// In fr, this message translates to:
  /// **'Préparation de {name} sur Doctolib ({i}/{n})'**
  String preparingTown(String name, int i, int n);

  /// No description provided for @pointChosen.
  ///
  /// In fr, this message translates to:
  /// **'Point choisi'**
  String get pointChosen;

  /// No description provided for @zonePrepFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de préparer la zone : {error}'**
  String zonePrepFailed(String error);

  /// No description provided for @zoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Zone de recherche'**
  String get zoneTitle;

  /// No description provided for @addressOptional.
  ///
  /// In fr, this message translates to:
  /// **'Adresse (facultatif)'**
  String get addressOptional;

  /// No description provided for @myPosition.
  ///
  /// In fr, this message translates to:
  /// **'Ma position'**
  String get myPosition;

  /// No description provided for @tapMapHint.
  ///
  /// In fr, this message translates to:
  /// **'Touchez la carte pour placer votre point de départ, ou utilisez « Ma position » ou une adresse.'**
  String get tapMapHint;

  /// No description provided for @circle.
  ///
  /// In fr, this message translates to:
  /// **'Cercle'**
  String get circle;

  /// No description provided for @travelTime.
  ///
  /// In fr, this message translates to:
  /// **'Temps de trajet'**
  String get travelTime;

  /// No description provided for @radiusLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rayon : {dist} à vol d\'oiseau'**
  String radiusLabel(String dist);

  /// No description provided for @atMost.
  ///
  /// In fr, this message translates to:
  /// **'Au plus {minutes} min {phrase}'**
  String atMost(int minutes, String phrase);

  /// No description provided for @travelEstimate.
  ///
  /// In fr, this message translates to:
  /// **'Estimation : environ {dist} à vol d\'oiseau. Calculée avec des vitesses moyennes en ville (attente et marche comprises pour les transports) ; les horaires réels ne sont pas consultés.'**
  String travelEstimate(String dist);

  /// No description provided for @validateZone.
  ///
  /// In fr, this message translates to:
  /// **'Valider la zone'**
  String get validateZone;

  /// No description provided for @showWholeZone.
  ///
  /// In fr, this message translates to:
  /// **'Voir toute la zone'**
  String get showWholeZone;

  /// No description provided for @centerOnPoint.
  ///
  /// In fr, this message translates to:
  /// **'Recentrer sur le point'**
  String get centerOnPoint;

  /// No description provided for @journal.
  ///
  /// In fr, this message translates to:
  /// **'Journal'**
  String get journal;

  /// No description provided for @journalBody.
  ///
  /// In fr, this message translates to:
  /// **'Ce que l\'app a fait, vérification par vérification : de quoi s\'assurer qu\'elle tourne bien en arrière-plan, et voir à quelle heure les créneaux se libèrent.'**
  String get journalBody;

  /// No description provided for @journalEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité pour le moment.'**
  String get journalEmpty;

  /// No description provided for @journalClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer le journal'**
  String get journalClear;

  /// No description provided for @journalBackground.
  ///
  /// In fr, this message translates to:
  /// **'arrière-plan'**
  String get journalBackground;

  /// No description provided for @journalManual.
  ///
  /// In fr, this message translates to:
  /// **'manuel'**
  String get journalManual;

  /// No description provided for @journalFound.
  ///
  /// In fr, this message translates to:
  /// **'{title} : {slots}, dont {fresh} nouveau(x)'**
  String journalFound(String title, String slots, int fresh);

  /// No description provided for @journalNothing.
  ///
  /// In fr, this message translates to:
  /// **'{title} : rien dans la fenêtre'**
  String journalNothing(String title);

  /// No description provided for @journalError.
  ///
  /// In fr, this message translates to:
  /// **'{title} : {error}'**
  String journalError(String title, String error);

  /// No description provided for @journalBusiestHour.
  ///
  /// In fr, this message translates to:
  /// **'Heure où les nouveaux créneaux apparaissent le plus souvent : {hour}'**
  String journalBusiestHour(String hour);

  /// No description provided for @journalCallAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Appel accepté'**
  String get journalCallAccepted;

  /// No description provided for @journalCallDeclined.
  ///
  /// In fr, this message translates to:
  /// **'Appel refusé'**
  String get journalCallDeclined;

  /// No description provided for @journalCallMissed.
  ///
  /// In fr, this message translates to:
  /// **'Appel manqué'**
  String get journalCallMissed;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
