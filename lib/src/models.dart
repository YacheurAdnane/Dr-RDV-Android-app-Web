import 'dart:convert';

import 'zone.dart';
import 'i18n.dart';

// ---------------------------------------------------------------------------
// Doctolib reference objects
// ---------------------------------------------------------------------------

/// A city / locality shaped the way Doctolib's search API wants it.
///
/// The search endpoint rejects any place without a GPS point and a viewport,
/// so we keep exactly the fields it validates and drop the rest (the raw blob
/// carries a few hundred postcodes we have no use for).
class PlaceRef {
  const PlaceRef({
    required this.id,
    required this.name,
    required this.slug,
    required this.country,
    required this.type,
    required this.lat,
    required this.lng,
    required this.neLat,
    required this.neLng,
    required this.swLat,
    required this.swLng,
  });

  final int id;
  final String name;
  final String slug;
  final String country;
  final String type;
  final double lat;
  final double lng;
  final double neLat;
  final double neLng;
  final double swLat;
  final double swLng;

  /// The `location.place` payload of `POST /patient-health-search/api/v1/hcp/search`.
  Map<String, dynamic> toSearchPayload() => {
        'id': id,
        'name': name,
        'slug': slug,
        'country': country,
        'type': type,
        'gpsPoint': {'lat': lat, 'lng': lng},
        'viewport': {
          'northeast': {'lat': neLat, 'lng': neLng},
          'southwest': {'lat': swLat, 'lng': swLng},
        },
      };

  /// Parses the `window.place = {...}` blob embedded in a Doctolib search page.
  static PlaceRef? fromWindowPlace(Map<String, dynamic> j) {
    final gps = j['gpsPoint'] as Map<String, dynamic>?;
    final vp = j['viewport'] as Map<String, dynamic>?;
    if (gps == null || vp == null) return null;
    final ne = vp['northeast'] as Map<String, dynamic>;
    final sw = vp['southwest'] as Map<String, dynamic>;
    return PlaceRef(
      id: (j['id'] as num).toInt(),
      name: j['name'] as String? ?? '',
      slug: j['slug'] as String? ?? '',
      country: j['country'] as String? ?? 'fr',
      type: j['type'] as String? ?? 'locality',
      lat: (gps['lat'] as num).toDouble(),
      lng: (gps['lng'] as num).toDouble(),
      neLat: (ne['lat'] as num).toDouble(),
      neLng: (ne['lng'] as num).toDouble(),
      swLat: (sw['lat'] as num).toDouble(),
      swLng: (sw['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'country': country,
        'type': type,
        'lat': lat,
        'lng': lng,
        'neLat': neLat,
        'neLng': neLng,
        'swLat': swLat,
        'swLng': swLng,
      };

  factory PlaceRef.fromJson(Map<String, dynamic> j) => PlaceRef(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        slug: j['slug'] as String,
        country: j['country'] as String,
        type: j['type'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        neLat: (j['neLat'] as num).toDouble(),
        neLng: (j['neLng'] as num).toDouble(),
        swLat: (j['swLat'] as num).toDouble(),
        swLng: (j['swLng'] as num).toDouble(),
      );
}

/// A city suggestion coming out of `/patient_app/place_autocomplete.json`.
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.label,
    required this.city,
    required this.country,
    required this.isLocality,
  });

  final String label;
  final String city;
  final String country;
  final bool isLocality;
}

/// A speciality ("Pediatre", "Dermatologue", ...) as suggested by Doctolib.
class SpecialityRef {
  const SpecialityRef({required this.id, required this.slug, required this.name});

  final String id;
  final String slug;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'slug': slug, 'name': name};

  factory SpecialityRef.fromJson(Map<String, dynamic> j) => SpecialityRef(
        id: j['id'] as String,
        slug: j['slug'] as String,
        name: j['name'] as String,
      );

  @override
  bool operator ==(Object other) => other is SpecialityRef && other.slug == slug;

  @override
  int get hashCode => slug.hashCode;
}

/// A practitioner profile suggestion, used when searching a doctor by name.
class ProfileSuggestion {
  const ProfileSuggestion({
    required this.profileId,
    required this.displayName,
    required this.speciality,
    required this.city,
    required this.link,
    required this.isOrganization,
  });

  final String profileId;
  final String displayName;
  final String speciality;
  final String city;
  final String link;
  final bool isOrganization;

  /// `/pediatre/lyon/zoe-germont` becomes `zoe-germont`.
  String get slug => _lastPathSegment(link);
}

/// A practitioner + practice + visit motive triplet: everything the
/// availabilities endpoint needs in order to answer.
class DoctorRef {
  const DoctorRef({
    required this.key,
    required this.profileId,
    required this.practiceId,
    required this.displayName,
    required this.specialityName,
    required this.city,
    required this.address,
    required this.link,
    required this.agendaIds,
    required this.visitMotiveId,
    required this.visitMotiveName,
    required this.allowNewPatients,
    required this.telehealth,
    this.lat,
    this.lng,
  });

  /// Where the practice is, when Doctolib says. Needed for zone filtering.
  final double? lat;
  final double? lng;

  final String key;
  final int profileId;
  final int practiceId;
  final String displayName;
  final String specialityName;
  final String city;
  final String address;
  final String link;
  final List<int> agendaIds;
  final int? visitMotiveId;
  final String visitMotiveName;
  final bool allowNewPatients;
  final bool telehealth;

  String get bookingUrl =>
      link.startsWith('http') ? link : 'https://www.doctolib.fr$link';

  String get slug => _lastPathSegment(link);

  DoctorRef copyWith({
    List<int>? agendaIds,
    int? visitMotiveId,
    String? visitMotiveName,
  }) =>
      DoctorRef(
        key: key,
        profileId: profileId,
        practiceId: practiceId,
        displayName: displayName,
        specialityName: specialityName,
        city: city,
        address: address,
        link: link,
        agendaIds: agendaIds ?? this.agendaIds,
        visitMotiveId: visitMotiveId ?? this.visitMotiveId,
        visitMotiveName: visitMotiveName ?? this.visitMotiveName,
        allowNewPatients: allowNewPatients,
        telehealth: telehealth,
        lat: lat,
        lng: lng,
      );

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'key': key,
        'profileId': profileId,
        'practiceId': practiceId,
        'displayName': displayName,
        'specialityName': specialityName,
        'city': city,
        'address': address,
        'link': link,
        'agendaIds': agendaIds,
        'visitMotiveId': visitMotiveId,
        'visitMotiveName': visitMotiveName,
        'allowNewPatients': allowNewPatients,
        'telehealth': telehealth,
      };

  factory DoctorRef.fromJson(Map<String, dynamic> j) => DoctorRef(
        key: j['key'] as String,
        profileId: (j['profileId'] as num).toInt(),
        practiceId: (j['practiceId'] as num).toInt(),
        displayName: j['displayName'] as String,
        specialityName: j['specialityName'] as String? ?? '',
        city: j['city'] as String? ?? '',
        address: j['address'] as String? ?? '',
        link: j['link'] as String? ?? '',
        agendaIds:
            (j['agendaIds'] as List? ?? []).map((e) => (e as num).toInt()).toList(),
        visitMotiveId: (j['visitMotiveId'] as num?)?.toInt(),
        visitMotiveName: j['visitMotiveName'] as String? ?? '',
        allowNewPatients: j['allowNewPatients'] as bool? ?? true,
        telehealth: j['telehealth'] as bool? ?? false,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
      );
}

/// A visit motive offered by one practitioner.
class VisitMotive {
  const VisitMotive({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.agendaIds,
    required this.practiceIds,
    required this.telehealth,
  });

  final int id;
  final String name;
  final String categoryName;
  final List<int> agendaIds;
  final List<int> practiceIds;
  final bool telehealth;
}

/// One free slot found for one practitioner.
class SlotHit {
  const SlotHit({
    required this.doctorKey,
    required this.doctorName,
    required this.city,
    required this.address,
    required this.motive,
    required this.bookingUrl,
    required this.when,
    this.speciality = '',
    this.telehealth = false,
    this.lat,
    this.lng,
    this.distanceKm,
  });

  final double? lat;
  final double? lng;

  /// From the alert's zone origin, when the alert has a zone.
  final double? distanceKm;

  final String doctorKey;
  final String doctorName;
  final String city;
  final String address;

  /// The visit motive, e.g. "Premiere consultation". Shown as a tag so the
  /// user knows what kind of appointment it is before opening it.
  final String motive;
  final String bookingUrl;
  final DateTime when;

  /// e.g. "Medecin generaliste".
  final String speciality;

  /// Video consultation rather than at the practice.
  final bool telehealth;

  /// Stable identity, used to remember which slots were already announced.
  String get id => '$doctorKey|${when.toIso8601String()}';

  Map<String, dynamic> toJson() => {
        'doctorKey': doctorKey,
        'doctorName': doctorName,
        'city': city,
        'address': address,
        'motive': motive,
        'bookingUrl': bookingUrl,
        'when': when.toIso8601String(),
        'speciality': speciality,
        'telehealth': telehealth,
        'lat': lat,
        'lng': lng,
        'distanceKm': distanceKm,
      };

  factory SlotHit.fromJson(Map<String, dynamic> j) => SlotHit(
        doctorKey: j['doctorKey'] as String,
        doctorName: j['doctorName'] as String,
        city: j['city'] as String? ?? '',
        address: j['address'] as String? ?? '',
        motive: j['motive'] as String? ?? '',
        bookingUrl: j['bookingUrl'] as String? ?? '',
        when: DateTime.parse(j['when'] as String),
        speciality: j['speciality'] as String? ?? '',
        telehealth: j['telehealth'] as bool? ?? false,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        distanceKm: (j['distanceKm'] as num?)?.toDouble(),
      );
}

// ---------------------------------------------------------------------------
// The user's watches
// ---------------------------------------------------------------------------

enum WatchKind { speciality, doctor }

/// How loudly a watch is allowed to interrupt you.
///
/// Chosen per alert, because urgency is a property of the appointment: a
/// paediatrician for a sick child is worth a ringing phone, a routine check-up
/// in three weeks is not.
enum AlertStyle {
  /// Appears in the shade, no sound.
  discreet,

  /// Normal notification with the usual sound.
  normal,

  /// Rings like an incoming call, on the ringtone volume, until you act,
  /// and takes over the lock screen.
  call,
}

extension AlertStyleLabel on AlertStyle {
  String get label => switch (this) {
        AlertStyle.discreet => tr.styleDiscreet,
        AlertStyle.normal => tr.styleNormal,
        AlertStyle.call => tr.styleCall,
      };

  String get description => switch (this) {
        AlertStyle.discreet =>
          tr.styleDiscreetDesc,
        AlertStyle.normal =>
          tr.styleNormalDesc,
        AlertStyle.call =>
          tr.styleCallDesc,
      };
}

/// Where the appointment happens.
enum TeleconsultMode {
  /// Both are fine.
  any,

  /// Only appointments at the practice.
  inPerson,

  /// Only video consultations.
  online,
}

extension TeleconsultLabel on TeleconsultMode {
  String get label => switch (this) {
        TeleconsultMode.any => tr.teleAny,
        TeleconsultMode.inPerson => tr.teleInPerson,
        TeleconsultMode.online => tr.teleOnline,
      };

  String get description => switch (this) {
        TeleconsultMode.any =>
          tr.teleAnyDesc,
        TeleconsultMode.inPerson =>
          tr.teleInPersonDesc,
        TeleconsultMode.online =>
          tr.teleOnlineDesc,
      };

  String get shortLabel => switch (this) {
        TeleconsultMode.any => '',
        TeleconsultMode.inPerson => tr.teleShortInPerson,
        TeleconsultMode.online => tr.teleShortOnline,
      };
}

/// A ringtone the "call me" alerts can use.
///
/// Either one of the phone's own sounds (by content URI) or one bundled with
/// the app in `res/raw`. Android fixes a channel's sound when the channel is
/// created, so each ringtone gets a channel of its own.
class CallSound {
  const CallSound(this.id, {this.uri, this.raw});

  final String id;

  String get label => switch (id) {
        'system_ringtone' => tr.soundSystemRingtone,
        'system_alarm' => tr.soundSystemAlarm,
        'classic' => tr.soundClassic,
        'digital' => tr.soundDigital,
        'soft' => tr.soundSoft,
        'marimba' => tr.soundMarimba,
        'urgent' => tr.soundUrgent,
        _ => id,
      };

  /// System sound, e.g. `content://settings/system/ringtone`.
  final String? uri;

  /// Bundled sound, the file name in `android/app/src/main/res/raw`.
  final String? raw;

  static const List<CallSound> all = [
    CallSound('system_ringtone',
        uri: 'content://settings/system/ringtone'),
    CallSound('system_alarm',
        uri: 'content://settings/system/alarm_alert'),
    CallSound('classic', raw: 'ring_classic'),
    CallSound('digital', raw: 'ring_digital'),
    CallSound('soft', raw: 'ring_soft'),
    CallSound('marimba', raw: 'ring_marimba'),
    CallSound('urgent', raw: 'ring_urgent'),
  ];

  static CallSound byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}

enum WindowMode {
  /// "anything bookable in the next N days"
  nextDays,

  /// "anything bookable between two explicit dates"
  dateRange,
}

class WatchConfig {
  WatchConfig({
    required this.id,
    required this.title,
    required this.kind,
    this.specialities = const [],
    this.place,
    this.zone,
    this.doctor,
    this.motiveIds = const [],
    this.mode = WindowMode.nextDays,
    this.horizonDays = 3,
    this.from,
    this.to,
    this.alertStyle = AlertStyle.normal,
    this.onlyNewPatients = false,
    this.teleconsult = TeleconsultMode.any,
    this.hourFrom = 0,
    this.hourTo = 24,
    Set<int>? weekdays,
    this.maxDoctors = 40,
    this.enabled = true,
    this.snoozedUntil,
    this.lastCheckedAt,
    this.lastError,
    this.lastHits = const [],
    Set<String>? seen,
    Set<String>? ignoredSlots,
    Set<String>? ignoredDates,
    Set<String>? ignoredDoctors,
    Set<String>? freshIds,
  })  : seen = seen ?? <String>{},
        ignoredSlots = ignoredSlots ?? <String>{},
        ignoredDates = ignoredDates ?? <String>{},
        ignoredDoctors = ignoredDoctors ?? <String>{},
        freshIds = freshIds ?? <String>{},
        weekdays = weekdays ?? {1, 2, 3, 4, 5, 6, 7};

  final String id;
  String title;
  WatchKind kind;

  /// Speciality watches: one or several specialities, searched together.
  List<SpecialityRef> specialities;
  PlaceRef? place;

  /// Optional area around the user. Null: the whole city, as before.
  Zone? zone;

  /// Doctor watches: a single practitioner and the motives to keep an eye on.
  DoctorRef? doctor;
  List<int> motiveIds;

  WindowMode mode;
  int horizonDays;
  DateTime? from;
  DateTime? to;

  /// How this particular alert is announced. Set when the alert is created.
  AlertStyle alertStyle;

  bool onlyNewPatients;

  /// At the practice, by video, or either.
  TeleconsultMode teleconsult;

  /// Only keep slots starting at or after [hourFrom] and strictly before
  /// [hourTo]. Doctolib offers nothing of the sort; it is the difference
  /// between "a slot exists" and "a slot I could actually attend".
  int hourFrom;
  int hourTo;

  /// Weekdays the user is willing to go, `DateTime.monday`..`DateTime.sunday`.
  Set<int> weekdays;

  int maxDoctors;
  bool enabled;

  /// Temporarily muted until this instant, without losing the configuration.
  DateTime? snoozedUntil;

  DateTime? lastCheckedAt;
  String? lastError;
  List<SlotHit> lastHits;

  /// Slots already announced, so they are not announced twice.
  Set<String> seen;

  /// Three levels of "not this one", because a slot can be wrong for three
  /// different reasons: the time, the whole day, or the practitioner.
  ///
  /// Ignored items are dropped before anything is notified and hidden from the
  /// list, but kept so the user can undo.
  Set<String> ignoredSlots;

  /// Dates as `yyyy-MM-dd`.
  Set<String> ignoredDates;

  /// Practitioner keys. Also saves requests: an ignored practitioner is never
  /// queried again.
  Set<String> ignoredDoctors;

  /// Slots found on the last check that had never been seen before. Shown
  /// highlighted until the user opens the alert.
  Set<String> freshIds;

  /// Practitioners already known to have something inside the window. In frugal
  /// mode only the newcomers cost an extra request.
  List<String> knownDoctorKeys = const [];

  /// Requests spent on the last check, shown in the UI so the cost is visible.
  int lastRequestCount = 0;

  /// Failed checks in a row, each one already retried after an automatic
  /// repair. The error is only shown to the user from the third one on; a
  /// single hiccup that the repair fixes is not worth alarming anyone about.
  int errorStreak = 0;

  /// Last time the alert rebuilt itself from fresh Doctolib data.
  DateTime? lastRepairAt;

  /// Failures before the error is surfaced.
  static const int errorThreshold = 3;

  /// Start of the window the user cares about; never in the past.
  DateTime get windowStart {
    final now = DateTime.now();
    if (mode == WindowMode.dateRange && from != null) {
      return from!.isAfter(now) ? from! : now;
    }
    return now;
  }

  /// End of the window the user cares about.
  DateTime get windowEnd {
    if (mode == WindowMode.dateRange && to != null) {
      return DateTime(to!.year, to!.month, to!.day, 23, 59, 59);
    }
    final d = DateTime.now().add(Duration(days: horizonDays));
    return DateTime(d.year, d.month, d.day, 23, 59, 59);
  }

  /// Calendar days from [windowStart] to [windowEnd], inclusive.
  ///
  /// Measured from the start of the window, not from today, so a date range
  /// three weeks out scans those days only instead of everything in between.
  int get daysToScan {
    final s = windowStart;
    final first = DateTime(s.year, s.month, s.day);
    final span = windowEnd.difference(first).inDays + 1;
    return span.clamp(1, 60);
  }

  String get windowLabel {
    if (mode == WindowMode.dateRange && from != null && to != null) {
      String f(DateTime d) =>
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
      return tr.windowRange(f(from!), f(to!));
    }
    if (horizonDays == 1) return tr.window24h;
    return tr.windowDays(horizonDays);
  }

  /// True when the slot passes every client-side filter of this watch.
  bool accepts(DateTime slot) {
    if (slot.isBefore(windowStart) || slot.isAfter(windowEnd)) return false;
    if (!weekdays.contains(slot.weekday)) return false;
    if (slot.hour < hourFrom || slot.hour >= hourTo) return false;
    return true;
  }

  /// True when the user has explicitly told us not to hear about this one.
  bool isIgnored(SlotHit hit) =>
      ignoredSlots.contains(hit.id) ||
      ignoredDates.contains(dateKey(hit.when)) ||
      ignoredDoctors.contains(hit.doctorKey);

  bool get hasIgnores =>
      ignoredSlots.isNotEmpty ||
      ignoredDates.isNotEmpty ||
      ignoredDoctors.isNotEmpty;

  int get ignoredCount =>
      ignoredSlots.length + ignoredDates.length + ignoredDoctors.length;

  /// Everything currently matching, minus what the user muted.
  List<SlotHit> get visibleHits =>
      lastHits.where((h) => !isIgnored(h)).toList();

  bool get isSnoozed =>
      snoozedUntil != null && DateTime.now().isBefore(snoozedUntil!);

  /// Whether the watch should actually be polled right now.
  bool get isActive => enabled && !isSnoozed;

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  bool get hasHourFilter => hourFrom != 0 || hourTo != 24;

  bool get hasWeekdayFilter => weekdays.length != 7;

  String get filterLabel {
    final bits = <String>[];
    if (hasHourFilter) {
      bits.add('${I18n.hour(hourFrom)}-${I18n.hour(hourTo)}');
    }
    if (hasWeekdayFilter) {
      final sorted = weekdays.toList()..sort();
      bits.add(sorted.map(I18n.weekdayShort).join(' '));
    }
    if (onlyNewPatients) bits.add(tr.filterNewPatients);
    if (teleconsult != TeleconsultMode.any) bits.add(teleconsult.shortLabel);
    return bits.join(' · ');
  }

  String get subtitle {
    if (kind == WatchKind.doctor) {
      final d = doctor;
      if (d == null) return tr.doctorFallback;
      return d.city.isEmpty ? d.displayName : '${d.displayName} — ${d.city}';
    }
    final specs = specialities.map((s) => s.name).join(' · ');
    final city = place?.name ?? '';
    return specs.isEmpty ? city : '$specs — $city';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'kind': kind.name,
        'specialities': specialities.map((s) => s.toJson()).toList(),
        'place': place?.toJson(),
        'zone': zone?.toJson(),
        'doctor': doctor?.toJson(),
        'motiveIds': motiveIds,
        'mode': mode.name,
        'horizonDays': horizonDays,
        'from': from?.toIso8601String(),
        'to': to?.toIso8601String(),
        'alertStyle': alertStyle.name,
        'onlyNewPatients': onlyNewPatients,
        'teleconsult': teleconsult.name,
        'hourFrom': hourFrom,
        'hourTo': hourTo,
        'weekdays': weekdays.toList(),
        'maxDoctors': maxDoctors,
        'enabled': enabled,
        'snoozedUntil': snoozedUntil?.toIso8601String(),
        'ignoredSlots': ignoredSlots.toList(),
        'ignoredDates': ignoredDates.toList(),
        'ignoredDoctors': ignoredDoctors.toList(),
        'freshIds': freshIds.toList(),
        'lastCheckedAt': lastCheckedAt?.toIso8601String(),
        'lastError': lastError,
        'lastHits': lastHits.map((h) => h.toJson()).toList(),
        'knownDoctorKeys': knownDoctorKeys,
        'lastRequestCount': lastRequestCount,
        'errorStreak': errorStreak,
        'lastRepairAt': lastRepairAt?.toIso8601String(),
        // Capped: an unbounded set would grow forever in SharedPreferences.
        'seen': seen.toList().reversed.take(600).toList(),
      };

  factory WatchConfig.fromJson(Map<String, dynamic> j) => WatchConfig(
        id: j['id'] as String,
        title: j['title'] as String,
        kind: WatchKind.values.firstWhere(
          (k) => k.name == j['kind'],
          orElse: () => WatchKind.speciality,
        ),
        specialities: (j['specialities'] as List? ?? [])
            .map((e) => SpecialityRef.fromJson(e as Map<String, dynamic>))
            .toList(),
        place: j['place'] == null
            ? null
            : PlaceRef.fromJson(j['place'] as Map<String, dynamic>),
        zone: j['zone'] == null
            ? null
            : Zone.fromJson(j['zone'] as Map<String, dynamic>),
        doctor: j['doctor'] == null
            ? null
            : DoctorRef.fromJson(j['doctor'] as Map<String, dynamic>),
        motiveIds:
            (j['motiveIds'] as List? ?? []).map((e) => (e as num).toInt()).toList(),
        mode: WindowMode.values.firstWhere(
          (m) => m.name == j['mode'],
          orElse: () => WindowMode.nextDays,
        ),
        horizonDays: (j['horizonDays'] as num?)?.toInt() ?? 3,
        from: j['from'] == null ? null : DateTime.parse(j['from'] as String),
        to: j['to'] == null ? null : DateTime.parse(j['to'] as String),
        alertStyle: AlertStyle.values.firstWhere(
          (a) => a.name == j['alertStyle'],
          orElse: () => AlertStyle.normal,
        ),
        onlyNewPatients: j['onlyNewPatients'] as bool? ?? false,
        teleconsult: _readTeleconsult(j),
        hourFrom: (j['hourFrom'] as num?)?.toInt() ?? 0,
        hourTo: (j['hourTo'] as num?)?.toInt() ?? 24,
        weekdays: (j['weekdays'] as List?)
            ?.map((e) => (e as num).toInt())
            .toSet(),
        maxDoctors: (j['maxDoctors'] as num?)?.toInt() ?? 40,
        enabled: j['enabled'] as bool? ?? true,
        snoozedUntil: j['snoozedUntil'] == null
            ? null
            : DateTime.tryParse(j['snoozedUntil'] as String),
        ignoredSlots: _readStringSet(j['ignoredSlots']),
        ignoredDates: _readStringSet(j['ignoredDates']),
        ignoredDoctors: _readStringSet(j['ignoredDoctors']),
        freshIds: _readStringSet(j['freshIds']),
        lastCheckedAt: j['lastCheckedAt'] == null
            ? null
            : DateTime.parse(j['lastCheckedAt'] as String),
        lastError: j['lastError'] as String?,
        lastHits: (j['lastHits'] as List? ?? [])
            .map((e) => SlotHit.fromJson(e as Map<String, dynamic>))
            .toList(),
        seen: ((j['seen'] as List? ?? []).map((e) => e as String)).toSet(),
      )
        ..knownDoctorKeys =
            (j['knownDoctorKeys'] as List? ?? []).map((e) => e as String).toList()
        ..lastRequestCount = (j['lastRequestCount'] as num?)?.toInt() ?? 0
        ..errorStreak = (j['errorStreak'] as num?)?.toInt() ?? 0
        ..lastRepairAt = j['lastRepairAt'] == null
            ? null
            : DateTime.tryParse(j['lastRepairAt'] as String);

  String encode() => jsonEncode(toJson());
}

// ---------------------------------------------------------------------------
// App-wide settings
// ---------------------------------------------------------------------------

class AppSettings {
  AppSettings({
    this.intervalMinutes = 30,
    this.quietFromHour = 22,
    this.quietToHour = 7,
    this.quietEnabled = true,
    this.groupNotifications = true,
    this.frugalMode = true,
    this.maxRequestsPerDay = 800,
    this.onboardingDone = false,
    this.statusNotification = true,
    this.callSound = 'system_ringtone',
    this.callSeconds = 45,
    this.language = 'system',
    this.themeMode = 'system',
  });

  /// `system`, `fr`, `en` or `ar`.
  String language;

  /// `system`, `light` or `dark`.
  String themeMode;

  /// Ringtone of the "call me" alerts, a [CallSound.id].
  String callSound;

  /// How long a call rings before it gives up and leaves an ordinary
  /// notification instead.
  int callSeconds;

  /// The permanent "watch is running" notification, the way a security app
  /// keeps a badge in the shade. Silent, low priority, updated after each
  /// check so the last result is always one glance away.
  bool statusNotification;

  /// False until the first-run walkthrough has been completed.
  bool onboardingDone;

  /// Android never runs periodic work more often than every 15 minutes.
  int intervalMinutes;
  int quietFromHour;
  int quietToHour;
  bool quietEnabled;

  /// One notification per watch instead of one per slot.
  bool groupNotifications;

  /// Ask Doctolib for exact times only for practitioners that were not already
  /// known to have something in the window. Turns a routine check into one or
  /// two requests instead of a dozen, which is the single biggest thing that
  /// keeps the app under any rate limit.
  bool frugalMode;

  /// Hard ceiling on requests per 24 h, across every watch.
  int maxRequestsPerDay;

  /// Plain-language name for the current ceiling, for people who should not
  /// have to think in HTTP requests.
  String get budgetLabel {
    if (maxRequestsPerDay <= 200) return tr.budgetVeryCautious;
    if (maxRequestsPerDay <= 400) return tr.budgetCautious;
    if (maxRequestsPerDay <= 800) return tr.budgetBalanced;
    if (maxRequestsPerDay <= 1500) return tr.budgetReactive;
    return tr.budgetMax;
  }

  /// How often the check runs, said the way a person would say it.
  String get intervalLabel {
    if (intervalMinutes < 60) return tr.intervalMinutes(intervalMinutes);
    final h = intervalMinutes ~/ 60;
    return h == 1 ? tr.intervalHour : tr.intervalHours(h);
  }

  String get quietLabel => quietEnabled
      ? tr.quietRange(I18n.hour(quietFromHour), I18n.hour(quietToHour))
      : tr.quietNone;

  bool get isQuietNow {
    if (!quietEnabled) return false;
    final h = DateTime.now().hour;
    if (quietFromHour == quietToHour) return false;
    if (quietFromHour < quietToHour) {
      return h >= quietFromHour && h < quietToHour;
    }
    return h >= quietFromHour || h < quietToHour;
  }

  Map<String, dynamic> toJson() => {
        'intervalMinutes': intervalMinutes,
        'quietFromHour': quietFromHour,
        'quietToHour': quietToHour,
        'quietEnabled': quietEnabled,
        'groupNotifications': groupNotifications,
        'frugalMode': frugalMode,
        'maxRequestsPerDay': maxRequestsPerDay,
        'onboardingDone': onboardingDone,
        'statusNotification': statusNotification,
        'callSound': callSound,
        'callSeconds': callSeconds,
        'language': language,
        'themeMode': themeMode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        intervalMinutes: (j['intervalMinutes'] as num?)?.toInt() ?? 30,
        quietFromHour: (j['quietFromHour'] as num?)?.toInt() ?? 22,
        quietToHour: (j['quietToHour'] as num?)?.toInt() ?? 7,
        quietEnabled: j['quietEnabled'] as bool? ?? true,
        groupNotifications: j['groupNotifications'] as bool? ?? true,
        frugalMode: j['frugalMode'] as bool? ?? true,
        maxRequestsPerDay: (j['maxRequestsPerDay'] as num?)?.toInt() ?? 800,
        onboardingDone: j['onboardingDone'] as bool? ?? false,
        statusNotification: j['statusNotification'] as bool? ?? true,
        callSound: j['callSound'] as String? ?? 'system_ringtone',
        callSeconds: (j['callSeconds'] as num?)?.toInt() ?? 45,
        language: j['language'] as String? ?? 'system',
        themeMode: j['themeMode'] as String? ?? 'system',
      );
}

Set<String> _readStringSet(Object? raw) =>
    (raw as List? ?? const []).map((e) => e as String).toSet();

/// Reads the appointment-location preference, migrating the `excludeTelehealth`
/// boolean written by builds before the three-way choice existed.
TeleconsultMode _readTeleconsult(Map<String, dynamic> j) {
  final name = j['teleconsult'];
  if (name is String) {
    return TeleconsultMode.values.firstWhere(
      (t) => t.name == name,
      orElse: () => TeleconsultMode.any,
    );
  }
  return j['excludeTelehealth'] == true
      ? TeleconsultMode.inPerson
      : TeleconsultMode.any;
}

String _lastPathSegment(String link) {
  final clean = link.split('?').first;
  final parts = clean.split('/').where((p) => p.isNotEmpty).toList();
  return parts.isEmpty ? '' : parts.last;
}
