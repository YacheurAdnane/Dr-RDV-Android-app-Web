import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../doctolib_api.dart';
import '../models.dart';
import '../notifications.dart';
import '../zone.dart';
import 'app_state.dart';
import 'zone_page.dart';
import '../i18n.dart';

/// Creates or edits one alert.
///
/// Mirrors the Doctolib search bar on purpose: you type what you need, it
/// suggests specialities and practitioners, and you can pin several
/// specialities at once so any matching practitioner in town counts.
class EditWatchPage extends StatefulWidget {
  const EditWatchPage({super.key, required this.state, this.existing});

  final AppState state;
  final WatchConfig? existing;

  @override
  State<EditWatchPage> createState() => _EditWatchPageState();
}

class _EditWatchPageState extends State<EditWatchPage> {
  /// Shares the persisted guard so that the requests the user generates by
  /// typing count against the same daily budget as the background checks, and
  /// a block hit here pauses those too.
  ///
  /// The gap is shorter than the background one on purpose: this traffic is a
  /// person typing in a search box, which is exactly what the site expects.
  late final DoctolibApi _api = DoctolibApi(
    guard: widget.state.guard,
    minGap: const Duration(milliseconds: 400),
  );

  final TextEditingController _queryCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _titleCtrl = TextEditingController();

  Timer? _queryDebounce;
  Timer? _cityDebounce;

  List<SpecialityRef> _specSuggestions = [];
  List<ProfileSuggestion> _profileSuggestions = [];
  List<PlaceSuggestion> _citySuggestions = [];
  bool _searching = false;
  bool _resolvingCity = false;
  bool _loadingMotives = false;
  String? _error;

  // Working copy of the alert being built.
  late WatchKind _kind;
  final List<SpecialityRef> _specialities = [];
  PlaceRef? _place;
  Zone? _zone;
  String _cityLabel = '';
  DoctorRef? _doctor;
  List<VisitMotive> _motives = [];
  final Set<int> _selectedMotives = {};

  WindowMode _mode = WindowMode.nextDays;
  int _horizonDays = 3;
  DateTimeRange? _range;

  AlertStyle _alertStyle = AlertStyle.normal;
  int _hourFrom = 0;
  int _hourTo = 24;
  Set<int> _weekdays = {1, 2, 3, 4, 5, 6, 7};
  bool _onlyNewPatients = false;
  TeleconsultMode _teleconsult = TeleconsultMode.any;
  bool _titleTouched = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _kind = e?.kind ?? WatchKind.speciality;
    if (e != null) {
      _specialities.addAll(e.specialities);
      _place = e.place;
      _zone = e.zone;
      _cityLabel = e.place?.name ?? '';
      _cityCtrl.text = _cityLabel;
      _doctor = e.doctor;
      _selectedMotives.addAll(e.motiveIds);
      _mode = e.mode;
      _horizonDays = e.horizonDays;
      if (e.from != null && e.to != null) {
        _range = DateTimeRange(start: e.from!, end: e.to!);
      }
      _alertStyle = e.alertStyle;
      _hourFrom = e.hourFrom;
      _hourTo = e.hourTo;
      _weekdays = {...e.weekdays};
      _onlyNewPatients = e.onlyNewPatients;
      _teleconsult = e.teleconsult;
      _titleCtrl.text = e.title;
      _titleTouched = true;
      if (e.kind == WatchKind.doctor && e.doctor != null) {
        _loadMotives(e.doctor!.slug);
      }
    }
  }

  @override
  void dispose() {
    _queryDebounce?.cancel();
    _cityDebounce?.cancel();
    _queryCtrl.dispose();
    _cityCtrl.dispose();
    _titleCtrl.dispose();
    _api.close();
    // Persist whatever budget the search bar consumed.
    widget.state.store.saveGuard(widget.state.guard);
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Suggestions
  // -------------------------------------------------------------------------

  void _onQueryChanged(String value) {
    _queryDebounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _specSuggestions = [];
        _profileSuggestions = [];
      });
      return;
    }
    _queryDebounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _searching = true);
      try {
        final res = await _api.autocomplete(value);
        if (!mounted) return;
        setState(() {
          _specSuggestions = res.specialities;
          // Doctolib's autocomplete is nationwide and ignores any location we
          // send it, so the city the user picked first is applied here: matches
          // in that city float to the top, the rest are kept but set apart.
          _profileSuggestions = _rankByCity(res.profiles);
          _error = null;
        });
      } on DoctolibException catch (e) {
        if (mounted) setState(() => _error = e.message);
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  /// True when a suggested profile sits in the city the user chose.
  ///
  /// Slug comparison rather than string equality so "Lyon 8" still counts as
  /// Lyon, and accents never decide the answer.
  bool _isHere(ProfileSuggestion p) {
    if (_cityLabel.isEmpty) return false;
    final city = DoctolibApi.slugify(_cityLabel);
    final theirs = DoctolibApi.slugify(p.city);
    return theirs == city || theirs.startsWith('$city-') || city.startsWith('$theirs-');
  }

  List<ProfileSuggestion> _rankByCity(List<ProfileSuggestion> profiles) {
    if (_cityLabel.isEmpty) return profiles.take(6).toList();
    final here = profiles.where(_isHere).toList();
    final elsewhere = profiles.where((p) => !_isHere(p)).toList();
    return [...here.take(6), ...elsewhere.take(3)];
  }

  void _onCityChanged(String value) {
    _cityDebounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _citySuggestions = []);
      return;
    }
    _cityDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final res = await _api.placeAutocomplete(value);
        if (mounted) setState(() => _citySuggestions = res.take(6).toList());
      } on DoctolibException catch (e) {
        if (mounted) setState(() => _error = e.message);
      }
    });
  }

  Future<void> _pickCity(PlaceSuggestion s) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _resolvingCity = true;
      _citySuggestions = [];
      _cityCtrl.text = s.city;
      _error = null;
    });
    try {
      final place = await _api.resolvePlace(
        s.city,
        specialitySlug: _specialities.isEmpty
            ? 'medecin-generaliste'
            : _specialities.first.slug,
      );
      if (!mounted) return;
      setState(() {
        _place = place;
        _cityLabel = place.name;
        _cityCtrl.text = place.name;
      });
      _autoTitle();
    } on DoctolibException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _resolvingCity = false);
    }
  }

  Future<void> _pickProfile(ProfileSuggestion p) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _kind = WatchKind.doctor;
      _specialities.clear();
      _profileSuggestions = [];
      _specSuggestions = [];
      _queryCtrl.clear();
      _doctor = DoctorRef(
        key: 'profile-${p.profileId}',
        profileId: int.tryParse(p.profileId) ?? 0,
        practiceId: 0,
        displayName: p.displayName,
        specialityName: p.speciality,
        city: p.city,
        address: '',
        link: p.link,
        agendaIds: const [],
        visitMotiveId: null,
        visitMotiveName: '',
        allowNewPatients: true,
        telehealth: false,
      );
      _motives = [];
      _selectedMotives.clear();
    });
    _autoTitle();
    await _loadMotives(p.slug);
  }

  Future<void> _loadMotives(String slug) async {
    setState(() {
      _loadingMotives = true;
      _error = null;
    });
    try {
      final info = await _api.bookingInfo(slug);
      if (!mounted) return;
      setState(() {
        _motives = info.motives;
        if (_selectedMotives.isEmpty && info.motives.isNotEmpty) {
          _selectedMotives.add(info.motives.first.id);
        }
        final d = _doctor;
        if (d != null && d.practiceId == 0 && info.practiceIds.isNotEmpty) {
          _doctor = DoctorRef(
            key: d.key,
            profileId: d.profileId,
            practiceId: info.practiceIds.first,
            displayName:
                info.profileName.isEmpty ? d.displayName : info.profileName,
            specialityName:
                info.speciality.isEmpty ? d.specialityName : info.speciality,
            city: d.city,
            address: d.address,
            link: d.link,
            agendaIds: d.agendaIds,
            visitMotiveId: d.visitMotiveId,
            visitMotiveName: d.visitMotiveName,
            allowNewPatients: d.allowNewPatients,
            telehealth: d.telehealth,
          );
        }
      });
      _autoTitle();
    } on DoctolibException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loadingMotives = false);
    }
  }

  void _toggleSpeciality(SpecialityRef s) {
    setState(() {
      _kind = WatchKind.speciality;
      _doctor = null;
      _motives = [];
      if (_specialities.contains(s)) {
        _specialities.remove(s);
      } else {
        _specialities.add(s);
      }
      _queryCtrl.clear();
      _specSuggestions = [];
      _profileSuggestions = [];
    });
    _autoTitle();
  }

  void _autoTitle() {
    if (_titleTouched) return;
    final title = _kind == WatchKind.doctor
        ? (_doctor?.displayName ?? '')
        : [
            _specialities.map((s) => s.name).join(' / '),
            if (_cityLabel.isNotEmpty) _cityLabel,
          ].where((s) => s.isNotEmpty).join(' — ');
    _titleCtrl.text = title;
  }

  // -------------------------------------------------------------------------
  // Save
  // -------------------------------------------------------------------------

  String? get _validationError {
    if (_kind == WatchKind.speciality) {
      if (_specialities.isEmpty) return tr.errNeedSpeciality;
      if (_place == null) return tr.errNeedCity;
    } else {
      if (_doctor == null) return tr.errNeedDoctor;
      if (_motives.isNotEmpty && _selectedMotives.isEmpty) {
        return tr.errNeedMotive;
      }
    }
    if (_weekdays.isEmpty) return tr.errNeedWeekday;
    if (_hourFrom >= _hourTo) return tr.errEmptyHours;
    if (_mode == WindowMode.dateRange && _range == null) {
      return tr.errNeedDates;
    }
    return null;
  }

  Future<void> _save() async {
    final problem = _validationError;
    if (problem != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(problem)));
      return;
    }

    final existing = widget.existing;
    final watch = WatchConfig(
      id: existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      title: _titleCtrl.text.trim().isEmpty
          ? tr.alertFallbackTitle
          : _titleCtrl.text.trim(),
      kind: _kind,
      specialities: List.of(_specialities),
      place: _place,
      zone: _kind == WatchKind.speciality ? _zone : null,
      doctor: _doctor,
      motiveIds: _selectedMotives.toList(),
      mode: _mode,
      horizonDays: _horizonDays,
      from: _range?.start,
      to: _range?.end,
      alertStyle: _alertStyle,
      onlyNewPatients: _onlyNewPatients,
      teleconsult: _teleconsult,
      hourFrom: _hourFrom,
      hourTo: _hourTo,
      weekdays: {..._weekdays},
      maxDoctors: existing?.maxDoctors ?? 40,
      enabled: existing?.enabled ?? true,
      seen: existing?.seen,
    );

    if (existing != null) {
      // Filters changed: previously announced slots may no longer qualify, so
      // keep the seen set but drop the cached results.
      watch.lastHits = const [];
      watch.knownDoctorKeys = const [];
      await widget.state.updateWatch(watch);
    } else {
      await widget.state.addWatch(watch);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? tr.editAlert : tr.newAlert),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(tr.save),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (_error != null)
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber,
                        color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // The city comes first on purpose: Doctolib's suggestion endpoint is
          // nationwide, so knowing the city is what makes the practitioner list
          // useful instead of a list of every Dr Martin in France.
          _sectionTitle(tr.stepWhere),
          TextField(
            controller: _cityCtrl,
            onChanged: _onCityChanged,
            decoration: InputDecoration(
              hintText: tr.cityHint,
              prefixIcon: const Icon(Icons.place_outlined),
              suffixIcon: _resolvingCity
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _place != null
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_citySuggestions.isNotEmpty)
            Card(
              margin: const EdgeInsets.only(top: 6),
              child: Column(
                children: [
                  for (final c in _citySuggestions)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.place_outlined),
                      title: Text(c.label),
                      onTap: () => _pickCity(c),
                    ),
                ],
              ),
            ),
          if (_place != null && _kind == WatchKind.speciality) ...[
            const SizedBox(height: 12),
            _zoneCard(theme),
          ],
          const SizedBox(height: 20),
          _sectionTitle(tr.stepWhat),
          TextField(
            controller: _queryCtrl,
            onChanged: _onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: tr.searchHint,
              helperText: _place == null
                  ? tr.searchHelperNoCity
                  : tr.searchHelperCity(_place!.name),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_specSuggestions.isNotEmpty || _profileSuggestions.isNotEmpty)
            _suggestionPanel(theme),
          const SizedBox(height: 12),
          if (_specialities.isNotEmpty) _specialityChips(theme),
          if (_kind == WatchKind.doctor && _doctor != null) _doctorCard(theme),
          if (_kind == WatchKind.doctor) _motiveSection(theme),
          const SizedBox(height: 24),
          _teleconsultSection(theme),
          const SizedBox(height: 24),
          _windowSection(theme),
          const SizedBox(height: 24),
          _alertStyleSection(theme),
          const SizedBox(height: 24),
          _filtersSection(theme),
          const SizedBox(height: 24),
          _sectionTitle(tr.alertName),
          TextField(
            controller: _titleCtrl,
            onChanged: (_) => _titleTouched = true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      );

  Widget _suggestionPanel(ThemeData theme) => Card(
        margin: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_specSuggestions.isNotEmpty) ...[
              _suggestionHeader(tr.specialities, theme),
              for (final s in _specSuggestions.take(6))
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.medical_services_outlined),
                  title: Text(s.name),
                  trailing: _specialities.contains(s)
                      ? const Icon(Icons.check, size: 18)
                      : null,
                  onTap: () => _toggleSpeciality(s),
                ),
            ],
            if (_profileSuggestions.any(_isHere)) ...[
              _suggestionHeader(
                _cityLabel.isEmpty
                    ? tr.practitionersAndPlaces
                    : tr.practitionersIn(_cityLabel),
                theme,
              ),
              for (final p in _profileSuggestions.where(_isHere))
                _profileTile(p),
            ],
            if (_profileSuggestions.any((p) => !_isHere(p))) ...[
              _suggestionHeader(
                _cityLabel.isEmpty ? tr.practitionersAndPlaces : tr.elsewhere,
                theme,
              ),
              for (final p in _profileSuggestions.where((p) => !_isHere(p)))
                _profileTile(p),
            ],
          ],
        ),
      );

  Widget _profileTile(ProfileSuggestion p) => ListTile(
        dense: true,
        leading: Icon(p.isOrganization
            ? Icons.local_hospital_outlined
            : Icons.person_outline),
        title: Text(p.displayName),
        subtitle: Text(
          [p.speciality, p.city].where((s) => s.isNotEmpty).join(' · '),
        ),
        onTap: () => _pickProfile(p),
      );

  Widget _suggestionHeader(String label, ThemeData theme) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _specialityChips(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr.specialityChipsHint,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in _specialities)
                InputChip(
                  label: Text(s.name),
                  onDeleted: () => _toggleSpeciality(s),
                ),
            ],
          ),
        ],
      );

  Widget _doctorCard(ThemeData theme) {
    final d = _doctor!;
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(d.displayName),
        subtitle: Text(
          [d.specialityName, d.city].where((s) => s.isNotEmpty).join(' · '),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
            _doctor = null;
            _motives = [];
            _selectedMotives.clear();
            _kind = WatchKind.speciality;
          }),
        ),
      ),
    );
  }

  Widget _motiveSection(ThemeData theme) {
    if (_doctor == null) return const SizedBox.shrink();
    if (_loadingMotives) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_motives.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          tr.noOnlineMotive,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.error),
        ),
      );
    }
    final byCategory = <String, List<VisitMotive>>{};
    for (final m in _motives) {
      byCategory.putIfAbsent(m.categoryName, () => []).add(m);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _sectionTitle(tr.motivesToWatch),
        for (final entry in byCategory.entries) ...[
          if (entry.key.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2),
              child: Text(
                entry.key,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
          for (final m in entry.value)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _selectedMotives.contains(m.id),
              title: Text(m.name),
              subtitle: m.telehealth ? Text(tr.teleOnline) : null,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selectedMotives.add(m.id);
                } else {
                  _selectedMotives.remove(m.id);
                }
              }),
            ),
        ],
      ],
    );
  }

  Widget _windowSection(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(tr.whenTitle),
          Text(
            tr.whenBody,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SegmentedButton<WindowMode>(
            segments: [
              ButtonSegment(
                value: WindowMode.nextDays,
                label: Text(tr.nextDays),
                icon: Icon(Icons.timelapse),
              ),
              ButtonSegment(
                value: WindowMode.dateRange,
                label: Text(tr.exactDates),
                icon: Icon(Icons.date_range),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 12),
          if (_mode == WindowMode.nextDays)
            Wrap(
              spacing: 8,
              children: [
                for (final d in [1, 2, 3, 5, 7, 14, 30])
                  ChoiceChip(
                    label: Text(d == 1 ? tr.h24 : tr.daysShort(d)),
                    selected: _horizonDays == d,
                    onSelected: (_) => setState(() => _horizonDays = d),
                  ),
              ],
            )
          else
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text(
                _range == null
                    ? tr.pickPeriod
                    : '${_range!.start.day}/${_range!.start.month} → '
                        '${_range!.end.day}/${_range!.end.month}',
              ),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 180)),
                  initialDateRange: _range,
                  locale: I18n.locale,
                );
                if (picked != null) setState(() => _range = picked);
              },
            ),
        ],
      );

  /// The optional zone. Skipping it keeps the alert city-wide, exactly as
  /// before zones existed.
  Widget _zoneCard(ThemeData theme) {
    final z = _zone;
    if (z == null) {
      return Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(Icons.radar, color: theme.colorScheme.primary),
          title: Text(tr.zoneCardTitle),
          subtitle: Text(
            tr.zoneCardBody,
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: _editZone,
        ),
      );
    }
    final towns = z.communes.map((c) => c.name).join(', ');
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.radar, color: theme.colorScheme.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    z.shortLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(onPressed: _editZone, child: Text(tr.edit)),
                IconButton(
                  tooltip: tr.removeZone,
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _zone = null),
                ),
              ],
            ),
            Text(
              tr.zoneFrom(z.label),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
            ),
            if (z.mode == RangeMode.travel)
              Text(
                tr.zoneApprox(formatKm(z.effectiveRadiusKm)),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
              ),
            if (towns.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                tr.zoneTowns(towns),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editZone() async {
    final place = _place;
    if (place == null) return;
    final result = await Navigator.of(context).push<Object?>(MaterialPageRoute(
      builder: (_) => ZonePage(
        api: _api,
        initial: _zone,
        fallbackCenter: LatLng(place.lat, place.lng),
        specialitySlug: _specialities.isEmpty
            ? 'medecin-generaliste'
            : _specialities.first.slug,
      ),
    ));
    if (!mounted) return;
    if (isZoneRemoval(result)) {
      setState(() => _zone = null);
    } else if (result is Zone) {
      setState(() => _zone = result);
    }
  }

  Widget _teleconsultSection(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(tr.teleTitle),
          Text(
            tr.teleBody,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SegmentedButton<TeleconsultMode>(
            segments: [
              ButtonSegment(
                value: TeleconsultMode.any,
                label: Text(tr.teleAny),
                icon: Icon(Icons.all_inclusive),
              ),
              ButtonSegment(
                value: TeleconsultMode.inPerson,
                label: Text(tr.teleSegInPerson),
                icon: Icon(Icons.meeting_room_outlined),
              ),
              ButtonSegment(
                value: TeleconsultMode.online,
                label: Text(tr.teleSegOnline),
                icon: Icon(Icons.videocam_outlined),
              ),
            ],
            selected: {_teleconsult},
            onSelectionChanged: (s) => setState(() => _teleconsult = s.first),
          ),
          const SizedBox(height: 8),
          Text(
            _teleconsult.description,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      );

  Widget _alertStyleSection(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(tr.howToAlert),
          Text(
            tr.howToAlertBody,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          for (final style in AlertStyle.values)
            RadioListTile<AlertStyle>(
              contentPadding: EdgeInsets.zero,
              value: style,
              groupValue: _alertStyle,
              onChanged: (v) => _pickAlertStyle(v),
              title: Row(
                children: [
                  Icon(
                    switch (style) {
                      AlertStyle.discreet => Icons.notifications_none,
                      AlertStyle.normal => Icons.notifications_active_outlined,
                      AlertStyle.call => Icons.phone_in_talk,
                    },
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(style.label),
                ],
              ),
              subtitle: Text(style.description),
            ),
          if (_alertStyle == AlertStyle.call)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tr.callHint,
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      );

  Future<void> _pickAlertStyle(AlertStyle? v) async {
    if (v == null) return;
    setState(() => _alertStyle = v);
    // Taking over the lock screen needs its own grant on Android 14+, so ask
    // at the moment the user opts into it rather than up front.
    if (v == AlertStyle.call) {
      await Notifications.instance.requestFullScreenPermission();
    }
  }

  Widget _filtersSection(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(tr.filters),
          Text(
            tr.filtersBody,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.schedule, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(tr.hourRange(I18n.hour(_hourFrom), I18n.hour(_hourTo))),
              ),
            ],
          ),
          RangeSlider(
            min: 0,
            max: 24,
            divisions: 24,
            values: RangeValues(_hourFrom.toDouble(), _hourTo.toDouble()),
            labels: RangeLabels(I18n.hour(_hourFrom), I18n.hour(_hourTo)),
            onChanged: (v) => setState(() {
              _hourFrom = v.start.round();
              _hourTo = v.end.round();
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.event_available, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(tr.acceptedDays)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text(I18n.weekdayNarrow(d)),
                  selected: _weekdays.contains(d),
                  onSelected: (v) => setState(() {
                    if (v) {
                      _weekdays.add(d);
                    } else {
                      _weekdays.remove(d);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _onlyNewPatients,
            onChanged: (v) => setState(() => _onlyNewPatients = v),
            title: Text(tr.acceptsNewPatients),
            subtitle: Text(
              tr.acceptsNewPatientsBody,
            ),
          ),

        ],
      );
}
