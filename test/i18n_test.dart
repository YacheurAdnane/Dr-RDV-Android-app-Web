import 'package:flutter_test/flutter_test.dart';
import 'package:rdv_watch/src/i18n.dart';
import 'package:rdv_watch/src/models.dart';
import 'package:rdv_watch/src/zone.dart';

void main() {
  tearDownAll(() => I18n.apply('fr'));

  test('each language speaks its own words', () async {
    await I18n.apply('fr');
    expect(tr.settings, 'Réglages');
    await I18n.apply('en');
    expect(tr.settings, 'Settings');
    await I18n.apply('ar');
    expect(tr.settings, 'الإعدادات');
    expect(I18n.isRtl, isTrue);
  });

  test('plurals follow each language', () async {
    await I18n.apply('fr');
    expect(tr.slotsCount(1), '1 créneau');
    expect(tr.slotsCount(3), '3 créneaux');
    await I18n.apply('en');
    expect(tr.slotsCount(1), '1 slot');
    expect(tr.slotsCount(3), '3 slots');
    await I18n.apply('ar');
    expect(tr.slotsCount(2), 'موعدان');
    expect(tr.slotsCount(5), '5 مواعيد');
  });

  test('times and distances are written the local way', () async {
    final t = DateTime(2030, 1, 7, 14, 5);
    await I18n.apply('fr');
    expect(I18n.time(t), '14h05');
    expect(I18n.km(2.5), '2,5 km');
    await I18n.apply('en');
    expect(I18n.time(t), '14:05');
    expect(I18n.km(2.5), '2.5 km');
    await I18n.apply('ar');
    expect(I18n.km(2.5), '2,5 كم');
  });

  test('weekday names come from the locale, not a French table', () async {
    await I18n.apply('en');
    expect(I18n.weekdayShort(DateTime.monday), 'Mon');
    await I18n.apply('fr');
    expect(I18n.weekdayShort(DateTime.monday), startsWith('lun'));
  });

  test('model labels switch language with the app', () async {
    final w = WatchConfig(id: 'w', title: 'w', kind: WatchKind.speciality, horizonDays: 3);
    await I18n.apply('en');
    expect(w.windowLabel, 'within 3 days');
    expect(AlertStyle.call.label, 'Call me');
    expect(TravelMode.transit.phrase, 'by public transport');
    await I18n.apply('fr');
    expect(w.windowLabel, 'sous 3 jours');
    expect(AlertStyle.call.label, "M'appeler");
  });

  test('"system" picks a supported language or falls back to French', () {
    final l = I18n.resolve('system').languageCode;
    expect(I18n.supported, contains(l));
    expect(I18n.resolve('en').languageCode, 'en');
    expect(I18n.resolve('xx').languageCode, isIn(I18n.supported));
  });
}
