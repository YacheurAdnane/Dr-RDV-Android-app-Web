import 'dart:ui';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../l10n/gen/app_localizations.dart';

export '../l10n/gen/app_localizations.dart';

/// The app's current language, reachable without a BuildContext.
///
/// Most text is produced far from any widget: notifications are written by
/// the background isolate, error messages by the HTTP client, labels by the
/// model. A single process-wide translator keeps all of them in the language
/// the user picked. The UI rebuilds from the top when the choice changes.
class I18n {
  I18n._();

  static const List<String> supported = ['fr', 'en', 'ar'];

  static Locale _locale = const Locale('fr');
  static AppLocalizations _t = lookupAppLocalizations(const Locale('fr'));

  static AppLocalizations get t => _t;
  static Locale get locale => _locale;
  static String get code => _locale.languageCode;
  static bool get isRtl => code == 'ar';

  /// `system`, `fr`, `en` or `ar` to a supported locale. The phone's language
  /// wins when it is one we speak; French otherwise, since the data itself
  /// (Doctolib's specialities and motives) is French.
  static Locale resolve(String setting) {
    if (supported.contains(setting)) return Locale(setting);
    final phone = PlatformDispatcher.instance.locale.languageCode;
    return Locale(supported.contains(phone) ? phone : 'fr');
  }

  static Future<void> apply(String setting) async {
    _locale = resolve(setting);
    _t = lookupAppLocalizations(_locale);
    await initializeDateFormatting(code);
  }

  // ---------------------------------------------------------------------------
  // Dates, times, distances
  // ---------------------------------------------------------------------------

  /// A Monday, to turn a weekday number into a date intl can name.
  static DateTime _weekdayDate(int weekday) =>
      DateTime(2024, 1, 1).add(Duration(days: weekday - 1));

  /// "L", "M", "M"... for chips and the date badge.
  static String weekdayNarrow(int weekday) =>
      DateFormat('EEEEE', code).format(_weekdayDate(weekday));

  /// "lun.", "Mon", "الاثنين".
  static String weekdayShort(int weekday) =>
      DateFormat('E', code).format(_weekdayDate(weekday));

  static String weekdayLong(DateTime d) => DateFormat('EEEE', code).format(d);

  static String monthShort(DateTime d) => DateFormat('MMM', code).format(d);

  /// French writes 14h30; English and Arabic write 14:30.
  static String time(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return code == 'fr' ? '${h}h$m' : '$h:$m';
  }

  /// "8h" in French, "8:00" otherwise.
  static String hour(int h) => code == 'fr' ? '${h}h' : '$h:00';

  /// "Aujourd'hui", "Demain", "jeudi", "jeudi 3 oct.".
  static String day(DateTime d, {bool short = false}) {
    final now = DateTime.now();
    final diff = DateTime(d.year, d.month, d.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (diff == 0) return short ? t.todayShort : t.today;
    if (diff == 1) return short ? t.tomorrowShort : t.tomorrow;
    final name = short ? weekdayShort(d.weekday) : weekdayLong(d);
    if (diff < 7) return name;
    return '$name ${d.day} ${monthShort(d)}';
  }

  static String ago(DateTime? d) {
    if (d == null) return t.never;
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return t.justNow;
    if (diff.inMinutes < 60) return t.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return t.hoursAgo(diff.inHours);
    return t.daysAgo(diff.inDays);
  }

  /// "500 m", "2,5 km" (French and Arabic comma), "2.5 km" (English).
  static String km(double km) {
    if (km < 1) return '${(km * 1000).round()} ${t.unitM}';
    var s = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
    if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
    if (code != 'en') s = s.replaceAll('.', ',');
    return '$s ${t.unitKm}';
  }

  /// "3/10" style day/month.
  static String dayMonth(DateTime d) => '${d.day}/${d.month}';
}

/// Shorthand used everywhere text is produced.
AppLocalizations get tr => I18n.t;
