// ignore_for_file: avoid_print
// Regression probe for the 15-day limit on /availabilities.json.
// Runs under the Flutter test runner (the client now uses Flutter's
// localisation), with real network access:
//
//   flutter test tool/chunk_check.dart --dart-define=ARGS=""

import 'package:flutter_test/flutter_test.dart';
import 'package:rdv_watch/src/i18n.dart';
import 'package:rdv_watch/src/doctolib_api.dart';

void main() {
  const raw = String.fromEnvironment('ARGS');
  final args = raw.isEmpty ? <String>[] : raw.split('~');
  test('live', () async {
    await I18n.apply('fr');
    await _run(args);
  }, timeout: const Timeout(Duration(minutes: 5)));
}

Future<void> _run(List<String> args) async {
  final api = DoctolibApi();
  try {
    for (final days in [7, 15, 16, 30, 45]) {
      final before = api.guard.requestsToday;
      final r = await api.availabilities(
        visitMotiveIds: [728530],
        agendaIds: [2073549],
        practiceIds: [111711],
        startDate: DateTime.now(),
        days: days,
      );
      print('$days j -> OK, ${r.slots.length} creneaux, '
          '${api.guard.requestsToday - before} requete(s), next=${r.nextSlot}');
    }
  } on DoctolibException catch (e) {
    print('ECHEC: $e');
  } finally {
    api.close();
  }
}
