import 'dart:convert';

import 'package:http/http.dart' as http;

import 'zone.dart';
import 'i18n.dart';

class GeoAddress {
  const GeoAddress({
    required this.label,
    required this.lat,
    required this.lng,
    required this.city,
  });

  final String label;
  final double lat;
  final double lng;
  final String city;
}

/// French government geocoding: the national address base (BAN) served by the
/// IGN Geoplateforme, and the official list of communes.
///
/// Free, keyless, and run by the State rather than an ad company, which
/// matters for a home address. It is only contacted while the user sets up a
/// zone; routine checks never send the location anywhere.
class GeoApi {
  GeoApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _headers = {'User-Agent': 'AlertesRDV/1.0 (application Android)'};

  void close() => _client.close();

  Future<dynamic> _get(Uri uri) async {
    final res = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw GeoException(tr.geoUnavailable(res.statusCode));
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  /// Addresses matching what the user typed.
  Future<List<GeoAddress>> searchAddress(String query) async {
    if (query.trim().length < 3) return [];
    final j = await _get(Uri.https('data.geopf.fr', '/geocodage/search', {
      'q': query.trim(),
      'limit': '6',
    })) as Map<String, dynamic>;
    return _features(j);
  }

  /// The closest address to a point, for a readable label under a map pin.
  Future<GeoAddress?> reverse(double lat, double lng) async {
    final j = await _get(Uri.https('data.geopf.fr', '/geocodage/reverse', {
      'lat': '$lat',
      'lon': '$lng',
      'limit': '1',
    })) as Map<String, dynamic>;
    final list = _features(j);
    return list.isEmpty ? null : list.first;
  }

  List<GeoAddress> _features(Map<String, dynamic> j) {
    final out = <GeoAddress>[];
    for (final f in (j['features'] as List? ?? [])) {
      final m = f as Map<String, dynamic>;
      final coords = (m['geometry'] as Map<String, dynamic>)['coordinates'] as List;
      final p = m['properties'] as Map<String, dynamic>;
      out.add(GeoAddress(
        label: p['label'] as String? ?? '',
        lng: (coords[0] as num).toDouble(),
        lat: (coords[1] as num).toDouble(),
        city: p['city'] as String? ?? '',
      ));
    }
    return out;
  }

  /// The commune containing a point, or null at sea or abroad.
  Future<Commune?> communeAt(double lat, double lng) async {
    final list = await _get(Uri.https('geo.api.gouv.fr', '/communes', {
      'lat': '$lat',
      'lon': '$lng',
      'fields': 'nom,code,centre,population',
    })) as List;
    if (list.isEmpty) return null;
    final m = list.first as Map<String, dynamic>;
    final centre = (m['centre'] as Map<String, dynamic>?)?['coordinates'] as List?;
    return Commune(
      name: m['nom'] as String,
      code: m['code'] as String? ?? '',
      lng: centre == null ? lng : (centre[0] as num).toDouble(),
      lat: centre == null ? lat : (centre[1] as num).toDouble(),
      population: (m['population'] as num?)?.toInt() ?? 0,
    );
  }

  /// The communes a circle overlaps, found by probing points across it.
  ///
  /// Rings at a third, two thirds and the full radius, denser further out,
  /// so no town wider than roughly the spacing between probes slips through.
  /// Capped at [max] (each town costs one Doctolib request per check): the
  /// origin's own town first, then by population, since that is where
  /// practitioners are.
  Future<List<Commune>> communesInZone(
    double lat,
    double lng,
    double radiusKm, {
    int max = 8,
  }) async {
    final probes = <({double lat, double lng})>[(lat: lat, lng: lng)];
    for (final (frac, count) in [(1 / 3, 6), (2 / 3, 10), (1.0, 14)]) {
      for (var i = 0; i < count; i++) {
        probes.add(offsetPoint(lat, lng, radiusKm * frac, 360 / count * i));
      }
    }

    final found = <String, Commune>{};
    Commune? home;
    // Small batches: polite to the service and still quick.
    for (var i = 0; i < probes.length; i += 6) {
      final batch = probes.skip(i).take(6);
      final results = await Future.wait(batch.map((p) async {
        try {
          return await communeAt(p.lat, p.lng);
        } on Exception {
          return null;
        }
      }));
      for (final c in results) {
        if (c != null) found.putIfAbsent(c.code, () => c);
      }
      if (i == 0 && results.isNotEmpty) home = results.first;
    }

    final rest = found.values.where((c) => c.code != home?.code).toList()
      ..sort((a, b) => b.population.compareTo(a.population));
    return [if (home != null) home, ...rest].take(max).toList();
  }
}

class GeoException implements Exception {
  GeoException(this.message);
  final String message;
  @override
  String toString() => message;
}
