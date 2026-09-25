import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rdv_watch/src/calls.dart';
import 'package:rdv_watch/src/i18n.dart';
import 'package:rdv_watch/src/journal.dart';
import 'package:rdv_watch/src/models.dart';
import 'package:rdv_watch/src/zone.dart';
import 'package:rdv_watch/src/ui/app_state.dart';
import 'package:rdv_watch/src/ui/call_screen.dart';
import 'package:rdv_watch/src/ui/edit_watch_page.dart';
import 'package:rdv_watch/src/ui/home_page.dart';
import 'package:rdv_watch/src/ui/journal_page.dart';
import 'package:rdv_watch/src/ui/onboarding_page.dart';
import 'package:rdv_watch/src/ui/settings_page.dart';
import 'package:rdv_watch/src/ui/watch_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every screen, in every language and theme, on a phone-sized display.
///
/// Arabic mirrors the whole layout and English/Arabic strings have different
/// lengths from the French ones the screens were designed with; an overflow
/// or a crash in any combination fails here instead of on someone's phone.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The real Android notification plugin, talking to a mocked platform.
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async => switch (call.method) {
        'areNotificationsEnabled' => true,
        'initialize' => true,
        _ => null,
      },
    );
    // permission_handler asks the platform; answer "granted".
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (call) async => 1,
    );
  });

  final now = DateTime.now();
  SlotHit hit(int h, {bool video = false, double? km}) => SlotHit(
        doctorKey: 'dr-$h',
        doctorName: 'Dr Marie-Christine Delacroix-Beaumont',
        city: 'Villeurbanne',
        address: '43 Rue Montgolfier',
        motive: 'Première consultation de médecine générale',
        speciality: 'Médecin généraliste',
        telehealth: video,
        bookingUrl: 'https://www.doctolib.fr/x',
        when: DateTime(now.year, now.month, now.day).add(Duration(days: 1, hours: h)),
        lat: 45.77,
        lng: 4.89,
        distanceKm: km,
      );

  WatchConfig watch() => WatchConfig(
        id: 'w',
        title: 'Médecin généraliste — Villeurbanne et alentours',
        kind: WatchKind.speciality,
        specialities: const [
          SpecialityRef(id: '1', slug: 'medecin-generaliste', name: 'Médecin généraliste'),
        ],
        alertStyle: AlertStyle.call,
        teleconsult: TeleconsultMode.inPerson,
        hourFrom: 8,
        hourTo: 19,
        weekdays: {1, 2, 3, 4, 5},
        onlyNewPatients: true,
        zone: Zone(
          lat: 45.77,
          lng: 4.89,
          label: '43 Rue Montgolfier 69100 Villeurbanne',
          mode: RangeMode.travel,
          minutes: 50,
          travel: TravelMode.transit,
        ),
        lastCheckedAt: now.subtract(const Duration(minutes: 12)),
        lastHits: [hit(9, km: 1.2), hit(10, video: true), hit(15, km: 6.4)],
        ignoredDoctors: {'dr-other'},
      )..errorStreak = 1;

  Future<void> show(WidgetTester tester, String lang, Brightness b, Widget page) async {
    await I18n.apply(lang);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      locale: I18n.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00778B), brightness: b),
      ),
      home: page,
    ));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<AppState> state() async {
    final s = AppState();
    await s.store.saveWatches([watch()]);
    s.watches = [watch()];
    s.loading = false;
    return s;
  }

  for (final lang in I18n.supported) {
    for (final b in Brightness.values) {
      final tag = '$lang/${b.name}';

      testWidgets('home $tag', (t) async {
        await show(t, lang, b, HomePage(state: await state()));
        expect(find.byType(Scaffold), findsWidgets);
      });

      testWidgets('alert detail $tag', (t) async {
        await show(t, lang, b, WatchDetailPage(state: await state(), watchId: 'w'));
        expect(find.text(tr.check), findsOneWidget);
      });

      testWidgets('settings $tag', (t) async {
        await show(t, lang, b, SettingsPage(state: await state()));
        await t.drag(find.byType(ListView), const Offset(0, -3000));
        await t.pump();
      });

      testWidgets('new alert $tag', (t) async {
        await show(t, lang, b, EditWatchPage(state: await state()));
        await t.drag(find.byType(ListView), const Offset(0, -4000));
        await t.pump();
      });

      testWidgets('edit alert with zone $tag', (t) async {
        final s = await state();
        final w = watch()
          ..place = const PlaceRef(
            id: 6917, name: 'Villeurbanne', slug: 'villeurbanne', country: 'fr',
            type: 'locality', lat: 45.77, lng: 4.88, neLat: 45.8, neLng: 4.92,
            swLat: 45.75, swLng: 4.85,
          );
        await show(t, lang, b, EditWatchPage(state: s, existing: w));
        await t.drag(find.byType(ListView), const Offset(0, -4000));
        await t.pump();
      });

      testWidgets('onboarding $tag', (t) async {
        final s = await state();
        await show(t, lang, b, OnboardingPage(state: s, onDone: () {}));
        expect(find.text(tr.appTitle), findsWidgets);
      });

      testWidgets('journal $tag', (t) async {
        await Journal.addAll([
          JournalEntry(at: now, kind: JournalKind.found, title: watch().title, slots: 3, fresh: 2, background: true),
          JournalEntry(at: now, kind: JournalKind.nothing, title: watch().title),
          JournalEntry(at: now, kind: JournalKind.error, title: watch().title, detail: 'Doctolib a répondu 400'),
          JournalEntry(at: now, kind: JournalKind.callMissed, title: watch().title, detail: 'Dr X'),
        ]);
        await show(t, lang, b, const JournalPage());
        await t.pump(const Duration(milliseconds: 100));
      });

      testWidgets('call screen $tag', (t) async {
        final call = IncomingCall(
          callId: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          watchId: 'w',
          watchTitle: watch().title,
          url: 'https://www.doctolib.fr/x',
          doctorName: 'Dr Marie-Christine Delacroix-Beaumont',
          speciality: 'Médecin généraliste',
          motive: 'Première consultation de médecine générale',
          city: 'Villeurbanne',
          when: now.add(const Duration(days: 1)),
          telehealth: false,
          slotCount: 4,
          fallbackTitle: '',
          fallbackBody: '',
        );
        await show(t, lang, b, CallScreen(call: call, seconds: 45));
        expect(find.text(tr.viewAppointment), findsOneWidget);
        // Dispose, so its countdown timer does not outlive the test.
        await t.pumpWidget(const SizedBox());
      });
    }
  }

  test('Arabic lays the app out right to left', () async {
    await I18n.apply('ar');
    expect(I18n.isRtl, isTrue);
    await I18n.apply('fr');
  });
}
