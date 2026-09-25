// ignore_for_file: avoid_print — command-line probe; printing is its output.

// Exercises the zone pipeline against the live services:
//
// address -> point -> towns in the circle -> Doctolib places -> practitioners
// available soon in each town -> kept only if inside the circle.

// Runs under the Flutter test runner (the client now uses Flutter's
// localisation), with real network access:
//
//   flutter test tool/zone_check.dart --dart-define=ARGS="43 rue Montgolfier Villeurbanne~medecin-generaliste~3"

import 'package:flutter_test/flutter_test.dart';
import 'package:rdv_watch/src/i18n.dart';
import 'package:rdv_watch/src/doctolib_api.dart';
import 'package:rdv_watch/src/geo_api.dart';
import 'package:rdv_watch/src/models.dart';
import 'package:rdv_watch/src/zone.dart';

void main() {
  const raw = String.fromEnvironment('ARGS');
  final args = raw.isEmpty ? <String>[] : raw.split('~');
  test('live', () async {
    await I18n.apply('fr');
    await _run(args);
  }, timeout: const Timeout(Duration(minutes: 5)));
}

Future<void> _run(List<String> args) async {
  final address = args.isNotEmpty ? args[0] : '43 rue Montgolfier Villeurbanne';
  final spec = args.length > 1 ? args[1] : 'medecin-generaliste';
  final km = args.length > 2 ? double.parse(args[2]) : 3.0;

  final geo = GeoApi();
  final api = DoctolibApi();
  try {
    final hits = await geo.searchAddress(address);
    if (hits.isEmpty) throw StateError('adresse introuvable');
    final a = hits.first;
    print('[1] Adresse       -> ${a.label} (${a.lat}, ${a.lng})');

    final back = await geo.reverse(a.lat, a.lng);
    print('[2] Inverse       -> ${back?.label}');

    final communes = await geo.communesInZone(a.lat, a.lng, km);
    print('[3] Communes ${formatKm(km)} -> ${communes.map((c) => c.name).join(', ')}');

    final zone = Zone(lat: a.lat, lng: a.lng, label: a.label, radiusKm: km);
    final places = <PlaceRef>[];
    for (final c in communes) {
      try {
        places.add(await api.resolvePlace(c.name, specialitySlug: spec));
      } on DoctolibException catch (e) {
        print('    (ignoree : ${c.name} — $e)');
      }
    }
    print('[4] Lieux Doctolib -> ${places.map((p) => '${p.name}#${p.id}').join(', ')}');

    final soon = DateTime.now().add(const Duration(days: 7));
    var total = 0;
    final inside = <String, (DoctorRef, double)>{};
    for (final p in places) {
      final page = await api.searchDoctors(
        keyword: spec,
        place: p,
        availableBefore: soon,
      );
      total += page.doctors.length;
      for (final d in page.doctors) {
        if (d.lat == null || d.lng == null) continue;
        final dist = zone.distanceKm(d.lat!, d.lng!);
        if (dist <= km) inside.putIfAbsent(d.key, () => (d, dist));
      }
      print('    ${p.name.padRight(22)} ${page.doctors.length} praticiens (page 1)');
    }
    final list = inside.values.toList()..sort((x, y) => x.$2.compareTo(y.$2));
    print('[5] Dans le cercle -> ${list.length} sur $total');
    for (final (d, dist) in list.take(6)) {
      print('    ${formatKm(dist).padLeft(7)}  ${d.displayName} — ${d.city}');
    }
    final cityOnly = list.where((e) => e.$1.city == places.first.name).length;
    print('    dont hors de ${places.first.name} : ${list.length - cityOnly}');

    print('[6] Transports 50 min -> rayon ~${formatKm(radiusForMinutes(50, TravelMode.transit))}');
    print('\nRequetes Doctolib : ${api.guard.requestsToday}');
    print('TOUT EST VERT');
  } catch (e) {
    print('ECHEC : $e');
  } finally {
    geo.close();
    api.close();
  }
}
