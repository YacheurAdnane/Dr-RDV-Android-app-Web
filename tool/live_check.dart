// ignore_for_file: avoid_print — this is a command-line probe; printing is the
// entire output of the tool.

// Exercises the Doctolib client against the live site, end to end.
//
// Deliberately kept out of test/ so a routine `flutter test` never hits the
// network. Run it when a Doctolib response shape looks like it may have moved.

// Runs under the Flutter test runner (the client now uses Flutter's
// localisation), with real network access:
//
//   flutter test tool/live_check.dart --dart-define=ARGS="pediatre~Lyon"

import 'package:flutter_test/flutter_test.dart';
import 'package:rdv_watch/src/i18n.dart';
import 'package:rdv_watch/src/doctolib_api.dart';
import 'package:rdv_watch/src/models.dart';

void main() {
  const raw = String.fromEnvironment('ARGS');
  final args = raw.isEmpty ? <String>[] : raw.split('~');
  test('live', () async {
    await I18n.apply('fr');
    await _run(args);
  }, timeout: const Timeout(Duration(minutes: 5)));
}

Future<void> _run(List<String> args) async {
  final query = args.isNotEmpty ? args[0] : 'pediatre';
  final city = args.length > 1 ? args[1] : 'Lyon';

  final api = DoctolibApi();
  var step = 0;
  void ok(String label, [String? detail]) {
    step++;
    print('  [$step] OK  $label${detail == null ? '' : '  ->  $detail'}');
  }

  try {
    print('\n=== 1. Autocomplete "$query" ===');
    final ac = await api.autocomplete(query);
    if (ac.specialities.isEmpty) throw StateError('no speciality suggested');
    ok('specialites', ac.specialities.take(3).map((s) => s.name).join(', '));
    ok('praticiens',
        '${ac.profiles.length} profils, ex. ${ac.profiles.isEmpty ? '-' : ac.profiles.first.displayName}');
    final spec = ac.specialities.first;

    print('\n=== 2. Autocomplete ville "$city" ===');
    final places = await api.placeAutocomplete(city);
    if (places.isEmpty) throw StateError('no place suggested');
    ok('villes', places.take(3).map((p) => p.label).join(' | '));

    print('\n=== 3. Resolution de la ville ===');
    final place = await api.resolvePlace(places.first.city,
        specialitySlug: spec.slug);
    ok('place', '${place.name} (id ${place.id}) @ ${place.lat},${place.lng}');

    print('\n=== 4. Recherche sans filtre ===');
    final all = await api.searchDoctors(keyword: spec.slug, place: place);
    ok('total', '${all.total} praticiens, ${all.doctors.length} sur la page 1');

    print('\n=== 5. Recherche filtree "dispo sous 3 jours" ===');
    final soon = await api.searchDoctors(
      keyword: spec.slug,
      place: place,
      availableBefore: DateTime.now().add(const Duration(days: 3)),
    );
    ok('total filtre', '${soon.total} praticiens');
    if (soon.total > all.total) {
      throw StateError('the filter widened the result set, which cannot be');
    }

    final pool = soon.doctors.isNotEmpty ? soon.doctors : all.doctors;
    if (pool.isEmpty) throw StateError('no practitioner to probe');
    final doctor = pool.firstWhere((d) => d.visitMotiveId != null,
        orElse: () => pool.first);
    ok('cible',
        '${doctor.displayName} — motif ${doctor.visitMotiveId} — agendas ${doctor.agendaIds}');

    print('\n=== 6. Creneaux du praticien ===');
    final avail = await api.availabilities(
      visitMotiveIds: [doctor.visitMotiveId!],
      agendaIds: doctor.agendaIds,
      practiceIds: doctor.practiceId == 0 ? const [] : [doctor.practiceId],
      startDate: DateTime.now(),
      days: 7,
    );
    ok('creneaux sur 7 jours', '${avail.slots.length}');
    for (final s in avail.slots.take(5)) {
      print('        - $s');
    }
    if (avail.slots.isEmpty) {
      ok('prochain creneau connu', '${avail.nextSlot ?? 'aucun'}');
    }

    print('\n=== 7. Fiche de reservation ===');
    final info = await api.bookingInfo(doctor.slug);
    ok('profil', '${info.profileName} (${info.speciality})');
    ok('motifs', '${info.motives.length}');
    for (final m in info.motives.take(4)) {
      print('        - [${m.id}] ${m.name}'
          '${m.categoryName.isEmpty ? '' : ' (${m.categoryName})'}');
    }

    print('\n=== 8. Filtrage cote app ===');
    final watch = WatchConfig(
      id: 'live',
      title: 'live',
      kind: WatchKind.speciality,
      horizonDays: 3,
      hourFrom: 8,
      hourTo: 19,
      weekdays: {1, 2, 3, 4, 5},
    );
    final kept = avail.slots.where(watch.accepts).toList();
    ok('retenus par les filtres',
        '${kept.length} / ${avail.slots.length} (sous 3 j, 8h-19h, en semaine)');

    print('\nRequetes consommees : ${api.guard.requestsToday}');
    print('TOUT EST VERT\n');
  } catch (e) {
    print('\nECHEC : $e');
    print('Requetes consommees : ${api.guard.requestsToday}\n');
  } finally {
    api.close();
  }
}
