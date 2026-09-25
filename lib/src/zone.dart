import 'dart:math' as math;

import 'models.dart';
import 'i18n.dart';

/// How the zone is bounded.
enum RangeMode {
  /// A plain circle, in kilometres, as the crow flies. Exact.
  radius,

  /// A travel time, converted to a circle with average door-to-door speeds.
  travel,
}

/// How the user would get to the appointment.
enum TravelMode { walk, bike, transit, car }

extension TravelModeInfo on TravelMode {
  String get label => switch (this) {
        TravelMode.walk => tr.travelWalk,
        TravelMode.bike => tr.travelBike,
        TravelMode.transit => tr.travelTransit,
        TravelMode.car => tr.travelCar,
      };

  /// "en bus", "a pied": reads naturally after a duration.
  String get phrase => switch (this) {
        TravelMode.walk => tr.phraseWalk,
        TravelMode.bike => tr.phraseBike,
        TravelMode.transit => tr.phraseTransit,
        TravelMode.car => tr.phraseCar,
      };

  /// Average door-to-door speed in km/h along the actual route, in a French
  /// city. Deliberately conservative: better to include a practitioner who
  /// turns out 5 minutes further than to miss one.
  double get speedKmh => switch (this) {
        TravelMode.walk => 4.5,
        TravelMode.bike => 14,
        TravelMode.transit => 15,
        TravelMode.car => 28,
      };

  /// Fixed minutes lost regardless of distance: walking to the stop and
  /// waiting for the bus, parking the car, locking the bike.
  double get overheadMinutes => switch (this) {
        TravelMode.walk => 0,
        TravelMode.bike => 2,
        TravelMode.transit => 10,
        TravelMode.car => 5,
      };
}

/// Streets are not straight lines. Road distance is typically 1.2-1.4 times
/// the straight-line distance in a French city.
const double kDetourFactor = 1.3;

/// Estimated minutes to cover a straight-line distance.
double estimateMinutes(double straightKm, TravelMode mode) =>
    mode.overheadMinutes + straightKm * kDetourFactor / mode.speedKmh * 60;

/// Straight-line radius reachable within [minutes], the inverse of
/// [estimateMinutes]. Never below 300 m, so a very short budget still means
/// "around here" rather than "nowhere".
double radiusForMinutes(int minutes, TravelMode mode) {
  final usable = minutes - mode.overheadMinutes;
  final km = usable * mode.speedKmh / 60 / kDetourFactor;
  return math.max(0.3, km);
}

/// Great-circle distance in kilometres.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

/// The point [km] away from ([lat], [lng]) in the direction [bearingDeg].
({double lat, double lng}) offsetPoint(
  double lat,
  double lng,
  double km,
  double bearingDeg,
) {
  const r = 6371.0;
  final d = km / r;
  final b = bearingDeg * math.pi / 180;
  final p1 = lat * math.pi / 180;
  final l1 = lng * math.pi / 180;
  final p2 = math.asin(
    math.sin(p1) * math.cos(d) + math.cos(p1) * math.sin(d) * math.cos(b),
  );
  final l2 = l1 +
      math.atan2(
        math.sin(b) * math.sin(d) * math.cos(p1),
        math.cos(d) - math.sin(p1) * math.sin(p2),
      );
  return (lat: p2 * 180 / math.pi, lng: l2 * 180 / math.pi);
}

/// A town searched on behalf of the zone, before it is resolved to a
/// Doctolib place.
class Commune {
  const Commune({
    required this.name,
    required this.code,
    required this.lat,
    required this.lng,
    required this.population,
  });

  final String name;
  final String code;
  final double lat;
  final double lng;
  final int population;

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'lat': lat,
        'lng': lng,
        'population': population,
      };

  factory Commune.fromJson(Map<String, dynamic> j) => Commune(
        name: j['name'] as String,
        code: j['code'] as String? ?? '',
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        population: (j['population'] as num?)?.toInt() ?? 0,
      );
}

/// An optional area around the user. Without one, an alert covers the whole
/// city it was created for; with one, it covers exactly the practitioners
/// inside the area, even across town borders.
class Zone {
  Zone({
    required this.lat,
    required this.lng,
    required this.label,
    this.mode = RangeMode.radius,
    this.radiusKm = 3,
    this.minutes = 30,
    this.travel = TravelMode.transit,
    this.places = const [],
    this.communes = const [],
  });

  /// The starting point: home, current position, or a point on the map.
  double lat;
  double lng;
  String label;

  RangeMode mode;
  double radiusKm;
  int minutes;
  TravelMode travel;

  /// Doctolib places searched for this zone, one per town it touches.
  List<PlaceRef> places;

  /// The towns themselves, kept for display.
  List<Commune> communes;

  /// The straight-line radius actually enforced.
  double get effectiveRadiusKm =>
      mode == RangeMode.radius ? radiusKm : radiusForMinutes(minutes, travel);

  bool contains(double lat, double lng) =>
      haversineKm(this.lat, this.lng, lat, lng) <= effectiveRadiusKm;

  double distanceKm(double lat, double lng) =>
      haversineKm(this.lat, this.lng, lat, lng);

  /// "3 km autour de" / "30 min en transports depuis".
  String get summary {
    if (mode == RangeMode.radius) {
      return tr.zoneAround(formatKm(radiusKm), label);
    }
    return tr.zoneFromTravel(minutes, travel.phrase, label);
  }

  /// Short form for chips: "3 km", "30 min en transports".
  String get shortLabel => mode == RangeMode.radius
      ? formatKm(radiusKm)
      : tr.zoneShortTravel(minutes, travel.phrase);

  /// How long the trip to a point at [km] would take, for display.
  String travelHint(double km) {
    final t = mode == RangeMode.travel ? travel : TravelMode.transit;
    final m = estimateMinutes(km, t).round();
    return tr.tripMinutes(m, t.phrase);
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'label': label,
        'mode': mode.name,
        'radiusKm': radiusKm,
        'minutes': minutes,
        'travel': travel.name,
        'places': places.map((p) => p.toJson()).toList(),
        'communes': communes.map((c) => c.toJson()).toList(),
      };

  factory Zone.fromJson(Map<String, dynamic> j) => Zone(
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        label: j['label'] as String? ?? '',
        mode: RangeMode.values.firstWhere(
          (m) => m.name == j['mode'],
          orElse: () => RangeMode.radius,
        ),
        radiusKm: (j['radiusKm'] as num?)?.toDouble() ?? 3,
        minutes: (j['minutes'] as num?)?.toInt() ?? 30,
        travel: TravelMode.values.firstWhere(
          (t) => t.name == j['travel'],
          orElse: () => TravelMode.transit,
        ),
        places: (j['places'] as List? ?? [])
            .map((e) => PlaceRef.fromJson(e as Map<String, dynamic>))
            .toList(),
        communes: (j['communes'] as List? ?? [])
            .map((e) => Commune.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

String formatKm(double km) => I18n.km(km);
