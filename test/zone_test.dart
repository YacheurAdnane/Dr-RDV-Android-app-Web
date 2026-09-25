import 'package:flutter_test/flutter_test.dart';
import 'package:rdv_watch/src/i18n.dart';
import 'package:rdv_watch/src/models.dart';
import 'package:rdv_watch/src/zone.dart';

void main() {
  // Labels are translated; the assertions below are written in French.
  setUpAll(() => I18n.apply('fr'));

  group('distance', () {
    test('haversine matches a known distance', () {
      // Lyon Bellecour -> Villeurbanne Gratte-Ciel is about 3.9 km.
      final d = haversineKm(45.7578, 4.8320, 45.7719, 4.8802);
      expect(d, closeTo(4.0, 0.3));
    });

    test('offsetPoint lands at the requested distance', () {
      for (final bearing in [0.0, 90.0, 180.0, 270.0, 33.0]) {
        final p = offsetPoint(45.76, 4.83, 5, bearing);
        expect(haversineKm(45.76, 4.83, p.lat, p.lng), closeTo(5, 0.01));
      }
    });
  });

  group('travel time', () {
    test('estimate and radius are inverses of each other', () {
      for (final mode in TravelMode.values) {
        for (final minutes in [15, 30, 50, 90]) {
          final r = radiusForMinutes(minutes, mode);
          if (r <= 0.3) continue; // clamped floor, not invertible
          expect(estimateMinutes(r, mode), closeTo(minutes, 0.01),
              reason: '$mode $minutes min');
        }
      }
    });

    test('faster modes reach further in the same time', () {
      double r(TravelMode m) => radiusForMinutes(40, m);
      expect(r(TravelMode.walk), lessThan(r(TravelMode.bike)));
      expect(r(TravelMode.bike), lessThan(r(TravelMode.car)));
      expect(r(TravelMode.transit), lessThan(r(TravelMode.car)));
    });

    test('50 min by public transport is a city-sized radius', () {
      final r = radiusForMinutes(50, TravelMode.transit);
      expect(r, inInclusiveRange(5, 10));
    });

    test('a budget shorter than the overhead still means "around here"', () {
      expect(radiusForMinutes(5, TravelMode.transit), 0.3);
    });
  });

  group('zone', () {
    Zone circle(double km) =>
        Zone(lat: 45.7720, lng: 4.8902, label: 'Maison', radiusKm: km);

    test('contains what is inside the circle, not what is outside', () {
      final z = circle(3);
      final near = offsetPoint(z.lat, z.lng, 2.5, 120);
      final far = offsetPoint(z.lat, z.lng, 3.5, 120);
      expect(z.contains(near.lat, near.lng), isTrue);
      expect(z.contains(far.lat, far.lng), isFalse);
    });

    test('a travel-time zone enforces its converted radius', () {
      final z = circle(3)
        ..mode = RangeMode.travel
        ..minutes = 50
        ..travel = TravelMode.transit;
      expect(z.effectiveRadiusKm, radiusForMinutes(50, TravelMode.transit));
      final p = offsetPoint(z.lat, z.lng, 5, 0);
      expect(z.contains(p.lat, p.lng), isTrue);
    });

    test('summaries read naturally', () {
      expect(circle(3).shortLabel, '3 km');
      expect(circle(0.5).shortLabel, '500 m');
      expect(circle(2.5).shortLabel, '2,5 km');
      final t = circle(3)
        ..mode = RangeMode.travel
        ..minutes = 50
        ..travel = TravelMode.transit;
      expect(t.shortLabel, '50 min en transports');
      expect(t.summary, contains('depuis Maison'));
    });

    test('survives a round trip inside its watch', () {
      final w = WatchConfig(
        id: 'z',
        title: 'z',
        kind: WatchKind.speciality,
        zone: Zone(
          lat: 45.77,
          lng: 4.89,
          label: '43 Rue Montgolfier',
          mode: RangeMode.travel,
          minutes: 50,
          travel: TravelMode.transit,
          communes: const [
            Commune(
                name: 'Bron', code: '69029', lat: 45.73, lng: 4.91, population: 42000),
          ],
          places: const [
            PlaceRef(
              id: 7052,
              name: 'Bron',
              slug: 'bron',
              country: 'fr',
              type: 'locality',
              lat: 45.73,
              lng: 4.91,
              neLat: 45.75,
              neLng: 4.94,
              swLat: 45.71,
              swLng: 4.88,
            ),
          ],
        ),
      );
      final back = WatchConfig.fromJson(w.toJson()).zone!;
      expect(back.mode, RangeMode.travel);
      expect(back.minutes, 50);
      expect(back.travel, TravelMode.transit);
      expect(back.communes.single.name, 'Bron');
      expect(back.places.single.id, 7052);
    });

    test('an alert without a zone stays without one', () {
      final w = WatchConfig(id: 'n', title: 'n', kind: WatchKind.speciality);
      expect(WatchConfig.fromJson(w.toJson()).zone, isNull);
    });
  });

  group('practitioner coordinates', () {
    test('survive a round trip on doctors and slots', () {
      const d = DoctorRef(
        key: 'k',
        profileId: 1,
        practiceId: 2,
        displayName: 'Dr X',
        specialityName: '',
        city: '',
        address: '',
        link: '/x',
        agendaIds: [3],
        visitMotiveId: 4,
        visitMotiveName: '',
        allowNewPatients: true,
        telehealth: false,
        lat: 45.1,
        lng: 4.2,
      );
      final back = DoctorRef.fromJson(d.toJson());
      expect(back.lat, 45.1);
      expect(back.lng, 4.2);

      final h = SlotHit(
        doctorKey: 'k',
        doctorName: 'Dr X',
        city: '',
        address: '',
        motive: '',
        bookingUrl: '',
        when: DateTime(2030),
        lat: 45.1,
        lng: 4.2,
        distanceKm: 1.25,
      );
      expect(SlotHit.fromJson(h.toJson()).distanceKm, 1.25);
    });
  });
}
