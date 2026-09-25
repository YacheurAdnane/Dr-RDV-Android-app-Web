import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'rate_guard.dart';
import 'i18n.dart';

/// Thrown when Doctolib answers something we cannot use.
class DoctolibException implements Exception {
  DoctolibException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isBlocked => statusCode == 403 || statusCode == 429;

  @override
  String toString() => message;
}

class HcpSearchPage {
  const HcpSearchPage({required this.total, required this.doctors});

  final int total;
  final List<DoctorRef> doctors;
}

class BookingInfo {
  const BookingInfo({
    required this.profileName,
    required this.speciality,
    required this.motives,
    required this.practiceIds,
  });

  final String profileName;
  final String speciality;
  final List<VisitMotive> motives;
  final List<int> practiceIds;
}

class AvailabilityResult {
  const AvailabilityResult({required this.slots, required this.nextSlot});

  /// Every free slot inside the scanned window, in chronological order.
  final List<DateTime> slots;

  /// The first slot *after* the scanned window, when Doctolib volunteers it.
  final DateTime? nextSlot;
}

/// A thin client over the JSON endpoints doctolib.fr's own web front-end calls.
///
/// None of these need a session cookie or a CSRF token; they are the same
/// requests the public website issues while you browse it. They are also
/// undocumented, so every response is parsed defensively and a shape change
/// surfaces as a [DoctolibException] rather than a crash.
class DoctolibApi {
  DoctolibApi({
    http.Client? client,
    RateGuard? guard,
    this.minGap = const Duration(milliseconds: 900),
  })  : _client = client ?? http.Client(),
        guard = guard ?? RateGuard();

  static const String base = 'https://www.doctolib.fr';

  /// Floor between two requests. A random jitter is added on top so the traffic
  /// never looks like a metronome.
  final Duration minGap;

  /// Daily budget, backoff and pause state. Shared with the caller so it can be
  /// persisted between runs.
  final RateGuard guard;

  final http.Client _client;
  DateTime _lastCall = DateTime.fromMillisecondsSinceEpoch(0);

  /// Resolved places are stable, so we only pay for the HTML page once.
  final Map<String, PlaceRef> _placeCache = {};

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
    'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
  };

  void close() => _client.close();

  Future<void> _throttle() async {
    final wait = minGap + RateGuard.jitter();
    final since = DateTime.now().difference(_lastCall);
    if (since < wait) await Future.delayed(wait - since);
    _lastCall = DateTime.now();
  }

  Future<http.Response> _send(http.BaseRequest Function() build) async {
    if (guard.isPaused) {
      throw DoctolibException(
        guard.lastBlockMessage ??
            tr.guardPaused(guard.pauseRemaining.inMinutes + 1),
      );
    }
    if (guard.budgetExhausted) {
      throw DoctolibException(
        tr.guardQuota(guard.maxRequestsPerDay),
      );
    }

    await _throttle();
    http.Response? last;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        // Exponential backoff with jitter between retries of one request.
        await Future.delayed(
          Duration(milliseconds: 900 * attempt * attempt) + RateGuard.jitter(600),
        );
      }
      guard.recordRequest();
      try {
        final streamed =
            await _client.send(build()).timeout(const Duration(seconds: 25));
        last = await http.Response.fromStream(streamed);
      } catch (e) {
        if (attempt == 2) throw DoctolibException(tr.apiNetwork('$e'));
        continue;
      }

      // 206 is what the paginated search returns for a partial result set.
      if (last.statusCode == 200 || last.statusCode == 206) {
        guard.recordSuccess();
        return last;
      }
      // Being told to slow down is the one signal worth obeying immediately:
      // stop the whole run and stay away for a while.
      if (last.statusCode == 403 || last.statusCode == 429) {
        guard.recordBlock(last.statusCode);
        throw DoctolibException(
          guard.lastBlockMessage!,
          statusCode: last.statusCode,
        );
      }
      if (last.statusCode >= 500) continue;
      break;
    }
    throw DoctolibException(
      tr.apiStatus('${last?.statusCode ?? '?'}', _reason(last)),
      statusCode: last?.statusCode,
    );
  }

  /// Doctolib usually explains a 4xx in the body (`{"error": ["..."]}`).
  /// Surfacing it turns "400" into something that says what to fix.
  static String _reason(http.Response? res) {
    if (res == null) return '';
    try {
      final j = jsonDecode(utf8.decode(res.bodyBytes));
      final err = j is Map ? (j['error'] ?? j['errors'] ?? j['message']) : null;
      final text = err is List ? err.join(', ') : err?.toString();
      if (text == null || text.isEmpty) return '';
      return ' : ${text.length > 120 ? '${text.substring(0, 120)}...' : text}';
    } catch (_) {
      return '';
    }
  }

  Future<http.Response> _get(String path, {String accept = 'application/json'}) {
    return _send(() {
      final req = http.Request('GET', Uri.parse('$base$path'));
      req.headers.addAll({..._headers, 'Accept': accept});
      req.followRedirects = true;
      return req;
    });
  }

  Future<http.Response> _post(String path, Object body) {
    return _send(() {
      final req = http.Request('POST', Uri.parse('$base$path'));
      req.headers.addAll({
        ..._headers,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      });
      req.body = jsonEncode(body);
      req.followRedirects = true;
      return req;
    });
  }

  // -------------------------------------------------------------------------
  // Search bar
  // -------------------------------------------------------------------------

  /// What the Doctolib search bar suggests as you type: specialities on one
  /// side, named practitioners and clinics on the other.
  Future<({List<SpecialityRef> specialities, List<ProfileSuggestion> profiles})>
      autocomplete(String query) async {
    if (query.trim().length < 2) {
      return (specialities: <SpecialityRef>[], profiles: <ProfileSuggestion>[]);
    }
    final res = await _post(
      '/patient-health-search/api/v1/autocomplete',
      {'query': query.trim()},
    );
    final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

    final specialities = <SpecialityRef>[];
    for (final e in (j['searchEntries'] as List? ?? [])) {
      final m = e as Map<String, dynamic>;
      if (m['kind'] != 'SPECIALITY') continue;
      specialities.add(SpecialityRef(
        id: '${m['id']}',
        slug: m['slug'] as String? ?? '',
        name: m['name'] as String? ?? '',
      ));
    }

    final profiles = <ProfileSuggestion>[];
    for (final e in (j['profiles'] as List? ?? [])) {
      final m = e as Map<String, dynamic>;
      final first = (m['firstName'] as String? ?? '').trim();
      final name = (m['name'] as String? ?? '').trim();
      profiles.add(ProfileSuggestion(
        profileId: '${m['profileId']}',
        displayName: first.isEmpty ? name : '$first $name',
        speciality: m['speciality'] as String? ??
            m['organizationStatus'] as String? ??
            '',
        city: m['city'] as String? ?? '',
        link: m['link'] as String? ?? '',
        isOrganization: m['type'] == 'ORGANIZATION',
      ));
    }
    return (specialities: specialities, profiles: profiles);
  }

  /// City suggestions for the "Ou ?" field.
  Future<List<PlaceSuggestion>> placeAutocomplete(String query) async {
    if (query.trim().length < 2) return [];
    final res = await _get(
      '/patient_app/place_autocomplete.json?query=${Uri.encodeQueryComponent(query.trim())}',
    );
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final types = (m['types'] as List? ?? []).cast<String>();
      return PlaceSuggestion(
        label: m['label'] as String? ?? m['description'] as String? ?? '',
        city: m['city'] as String? ?? '',
        country: m['country'] as String? ?? '',
        isLocality: types.contains('locality'),
      );
    }).where((p) => p.city.isNotEmpty).toList();
  }

  /// Turns a city name into the full place object the search endpoint demands.
  ///
  /// Doctolib never exposes that object through an API; it only ships it inside
  /// the `window.place = {...}` script of a search results page. So we load one
  /// such page and read it out. Results are cached for the life of the client.
  Future<PlaceRef> resolvePlace(String cityName, {String specialitySlug = 'medecin-generaliste'}) async {
    final citySlug = slugify(cityName);
    final cacheKey = citySlug;
    final cached = _placeCache[cacheKey];
    if (cached != null) return cached;

    // The speciality half of the URL only has to exist; try the caller's first,
    // then a speciality that is available in every French town.
    for (final spec in {specialitySlug, 'medecin-generaliste'}) {
      final http.Response res;
      try {
        res = await _get('/$spec/$citySlug', accept: 'text/html');
      } on DoctolibException {
        continue;
      }
      final html = utf8.decode(res.bodyBytes, allowMalformed: true);
      final match = RegExp(r'window\.place\s*=\s*(\{.*?\});', dotAll: true)
          .firstMatch(html);
      if (match == null) continue;
      try {
        final raw = jsonDecode(match.group(1)!) as Map<String, dynamic>;
        final place = PlaceRef.fromWindowPlace(raw);
        if (place != null) {
          _placeCache[cacheKey] = place;
          return place;
        }
      } on FormatException {
        continue;
      }
    }
    throw DoctolibException(tr.apiCityNotFound(cityName));
  }

  // -------------------------------------------------------------------------
  // Practitioner search
  // -------------------------------------------------------------------------

  /// One page (20 results) of practitioners for a speciality in a city.
  ///
  /// [availableBefore] is the interesting one: Doctolib filters server-side on
  /// it, so asking for "someone bookable in the next 3 days" costs a single
  /// request instead of polling every practitioner in town.
  Future<HcpSearchPage> searchDoctors({
    required String keyword,
    required PlaceRef place,
    int page = 0,
    DateTime? availableBefore,
    bool? telehealth,
  }) async {
    final filters = <String, dynamic>{};
    if (availableBefore != null) {
      filters['availabilitiesBefore'] = _isoOffset(availableBefore);
    }
    if (telehealth == true) filters['telehealth'] = true;

    final res = await _post(
      '/patient-health-search/api/v1/hcp/search?page=$page',
      {
        'keyword': keyword,
        'location': {'place': place.toSearchPayload()},
        'filters': filters,
      },
    );
    final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final doctors = <DoctorRef>[];
    for (final e in (j['healthcareProviders'] as List? ?? [])) {
      final d = _parseDoctor(e as Map<String, dynamic>);
      if (d != null) doctors.add(d);
    }
    return HcpSearchPage(
      total: (j['total'] as num?)?.toInt() ?? doctors.length,
      doctors: doctors,
    );
  }

  DoctorRef? _parseDoctor(Map<String, dynamic> m) {
    final refs = m['references'] as Map<String, dynamic>?;
    final motive = m['matchedVisitMotive'] as Map<String, dynamic>?;
    final booking = m['onlineBooking'] as Map<String, dynamic>?;
    if (refs == null) return null;

    final agendaIds = ((motive?['agendaIds'] ?? booking?['agendaIds']) as List? ?? [])
        .map((e) => (e as num).toInt())
        .toList();
    if (agendaIds.isEmpty) return null;

    final loc = m['location'] as Map<String, dynamic>? ?? const {};
    final first = (m['firstName'] as String? ?? '').trim();
    final last = (m['name'] as String? ?? '').trim();
    final title = (m['title'] as String? ?? '').trim();
    final display = [title, first, last]
        .where((s) => s.isNotEmpty)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    return DoctorRef(
      key: m['id'] as String? ?? '${refs['id']}-${refs['practiceId']}',
      profileId: (refs['id'] as num).toInt(),
      practiceId: (refs['practiceId'] as num?)?.toInt() ?? 0,
      displayName: display.isEmpty ? tr.doctorFallback : display,
      specialityName:
          (m['speciality'] as Map<String, dynamic>?)?['name'] as String? ?? '',
      city: loc['city'] as String? ?? '',
      address: loc['address'] as String? ?? '',
      link: m['link'] as String? ?? '',
      agendaIds: agendaIds,
      visitMotiveId: (motive?['visitMotiveId'] as num?)?.toInt(),
      visitMotiveName: motive?['name'] as String? ?? '',
      allowNewPatients: motive?['allowNewPatients'] as bool? ?? true,
      telehealth: booking?['telehealth'] as bool? ?? false,
      lat: (loc['lat'] as num?)?.toDouble(),
      lng: (loc['lng'] as num?)?.toDouble(),
    );
  }

  // -------------------------------------------------------------------------
  // One practitioner's booking configuration
  // -------------------------------------------------------------------------

  /// The motives, agendas and practices of a single practitioner: what the
  /// booking funnel loads when you open their Doctolib page.
  Future<BookingInfo> bookingInfo(String profileSlug) async {
    final res = await _get(
      '/online_booking/api/slot_selection_funnel/v1/info.json'
      '?profile_slug=${Uri.encodeQueryComponent(profileSlug)}&locale=fr',
    );
    final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final data = j['data'] as Map<String, dynamic>?;
    if (data == null) throw DoctolibException(tr.apiBadProfile);

    final categories = <int, String>{};
    for (final e in (data['visit_motive_categories'] as List? ?? [])) {
      final m = e as Map<String, dynamic>;
      categories[(m['id'] as num).toInt()] = m['name'] as String? ?? '';
    }

    // agenda id -> the motives that agenda accepts, and where.
    final agendasByMotive = <int, List<int>>{};
    final practicesByMotive = <int, Set<int>>{};
    for (final e in (data['agendas'] as List? ?? [])) {
      final a = e as Map<String, dynamic>;
      if (a['booking_temporary_disabled'] == true) continue;
      final agendaId = (a['id'] as num).toInt();
      final practiceId = (a['practice_id'] as num?)?.toInt();
      for (final v in (a['visit_motive_ids'] as List? ?? [])) {
        final vid = (v as num).toInt();
        (agendasByMotive[vid] ??= []).add(agendaId);
        if (practiceId != null) (practicesByMotive[vid] ??= {}).add(practiceId);
      }
    }

    final motives = <VisitMotive>[];
    for (final e in (data['visit_motives'] as List? ?? [])) {
      final m = e as Map<String, dynamic>;
      final id = (m['id'] as num).toInt();
      final agendas = agendasByMotive[id] ?? const <int>[];
      if (agendas.isEmpty) continue;
      motives.add(VisitMotive(
        id: id,
        name: m['name'] as String? ?? tr.motiveFallback,
        categoryName:
            categories[(m['visit_motive_category_id'] as num?)?.toInt() ?? -1] ?? '',
        agendaIds: agendas,
        practiceIds: (practicesByMotive[id] ?? const <int>{}).toList(),
        telehealth: m['telehealth'] as bool? ?? false,
      ));
    }

    final practiceIds = <int>{};
    for (final e in (data['places'] as List? ?? [])) {
      for (final p in ((e as Map<String, dynamic>)['practice_ids'] as List? ?? [])) {
        practiceIds.add((p as num).toInt());
      }
    }

    final profile = data['profile'] as Map<String, dynamic>? ?? const {};
    return BookingInfo(
      profileName: profile['name_with_title'] as String? ?? profileSlug,
      speciality: profile['subtitle'] as String? ?? '',
      motives: motives,
      practiceIds: practiceIds.toList(),
    );
  }

  // -------------------------------------------------------------------------
  // Availabilities
  // -------------------------------------------------------------------------

  /// Free slots for a given motive / agenda / practice combination.
  ///
  /// [days] is capped by Doctolib itself; asking for more than a fortnight in
  /// one call tends to come back trimmed, which is fine because we only ever
  /// care about the near future.
  /// Doctolib refuses any `limit` above this with a 400
  /// (`"limit: must be less than or equal to 15"`).
  static const int maxDaysPerCall = 15;

  /// Free slots for a given motive / agenda / practice combination.
  ///
  /// Covers [days] days from [startDate]. The endpoint serves at most
  /// [maxDaysPerCall] days per request, so longer windows are fetched in
  /// consecutive chunks. The loop stops early when Doctolib reports that the
  /// next free slot lies beyond the window, so a long window with nothing in
  /// it still costs a single request.
  Future<AvailabilityResult> availabilities({
    required List<int> visitMotiveIds,
    required List<int> agendaIds,
    required List<int> practiceIds,
    required DateTime startDate,
    int days = 7,
  }) async {
    final total = days.clamp(1, 60);
    final firstDay = DateTime(startDate.year, startDate.month, startDate.day);
    final windowEnd = firstDay.add(Duration(days: total));

    final slots = <DateTime>[];
    DateTime? next;
    var offset = 0;
    while (offset < total) {
      final chunk = (total - offset).clamp(1, maxDaysPerCall);
      final res = await _availabilityChunk(
        visitMotiveIds: visitMotiveIds,
        agendaIds: agendaIds,
        practiceIds: practiceIds,
        start: firstDay.add(Duration(days: offset)),
        days: chunk,
      );
      slots.addAll(res.slots);
      next = res.nextSlot;
      offset += chunk;
      // Nothing more until after the window: the remaining chunks would
      // come back empty.
      if (res.slots.isEmpty && (next == null || !next.isBefore(windowEnd))) {
        break;
      }
    }
    slots.sort();
    return AvailabilityResult(slots: slots, nextSlot: next);
  }

  Future<AvailabilityResult> _availabilityChunk({
    required List<int> visitMotiveIds,
    required List<int> agendaIds,
    required List<int> practiceIds,
    required DateTime start,
    required int days,
  }) async {
    final q = <String, String>{
      'start_date': _isoDate(start),
      'visit_motive_ids': visitMotiveIds.join('-'),
      'agenda_ids': agendaIds.join('-'),
      'insurance_sector': 'public',
      'destroy_temporary': 'true',
      'limit': '${days.clamp(1, maxDaysPerCall)}',
    };
    if (practiceIds.isNotEmpty) q['practice_ids'] = practiceIds.join('-');

    final query = q.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final res = await _get('/availabilities.json?$query');
    final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

    final slots = <DateTime>[];
    for (final e in (j['availabilities'] as List? ?? [])) {
      for (final s in ((e as Map<String, dynamic>)['slots'] as List? ?? [])) {
        // Slots are either plain ISO strings or objects carrying a start_date.
        final raw = s is String ? s : (s as Map<String, dynamic>)['start_date'];
        if (raw is! String) continue;
        final dt = DateTime.tryParse(raw);
        if (dt != null) slots.add(dt.toLocal());
      }
    }

    final next = j['next_slot'];
    return AvailabilityResult(
      slots: slots,
      nextSlot: next is String ? DateTime.tryParse(next)?.toLocal() : null,
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// `availabilitiesBefore` is deserialised as a Java OffsetDateTime, so the
  /// offset is mandatory.
  static String _isoOffset(DateTime d) {
    final local = d.toLocal();
    final off = local.timeZoneOffset;
    final sign = off.isNegative ? '-' : '+';
    final abs = off.abs();
    final hh = abs.inHours.toString().padLeft(2, '0');
    final mm = (abs.inMinutes % 60).toString().padLeft(2, '0');
    String p(int v, [int w = 2]) => v.toString().padLeft(w, '0');
    return '${p(local.year, 4)}-${p(local.month)}-${p(local.day)}'
        'T${p(local.hour)}:${p(local.minute)}:${p(local.second)}$sign$hh:$mm';
  }

  /// Doctolib city slugs are accent-free, lowercase and hyphenated:
  /// "Saint-Etienne" -> "saint-etienne", "Lyon 8" -> "lyon-8".
  static String slugify(String input) {
    const from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿœæ';
    const to = 'aaaaaaceeeeiiiinooooouuuuyyoa';
    final buffer = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      final ch = String.fromCharCode(rune);
      final idx = from.indexOf(ch);
      buffer.write(idx >= 0 ? to[idx] : ch);
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r"['’]"), '-')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
