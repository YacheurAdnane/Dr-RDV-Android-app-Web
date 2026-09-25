import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../doctolib_api.dart';
import '../geo_api.dart';
import '../models.dart';
import '../zone.dart';
import '../i18n.dart';

/// Optional step of an alert: limit it to practitioners near a point.
///
/// The point comes from the phone's position, a tap on the map or a typed
/// address. The limit is a circle, or a travel time turned into one. On
/// "Valider", the towns the zone overlaps are found and resolved on Doctolib
/// once, so routine checks cost nothing extra to set up.
class ZonePage extends StatefulWidget {
  const ZonePage({
    super.key,
    required this.api,
    required this.fallbackCenter,
    this.initial,
    this.specialitySlug = 'medecin-generaliste',
  });

  final DoctolibApi api;

  /// Where the map opens when there is no zone yet: the alert's city.
  final LatLng fallbackCenter;
  final Zone? initial;
  final String specialitySlug;

  @override
  State<ZonePage> createState() => _ZonePageState();
}

/// The zone is drawn in a strong red: it must stand out against any map tile,
/// in light and dark theme alike.
const Color _zoneRed = Color(0xFFE53935);

/// Street level: close enough to recognise the neighbourhood.
const double _focusZoom = 15;

class _ZonePageState extends State<ZonePage> {
  final GeoApi _geo = GeoApi();
  final MapController _map = MapController();
  final TextEditingController _addressCtrl = TextEditingController();

  late LatLng _point;
  String _label = '';
  bool _pointChosen = false;

  RangeMode _mode = RangeMode.radius;
  double _radiusKm = 3;
  int _minutes = 30;
  TravelMode _travel = TravelMode.transit;

  List<GeoAddress> _suggestions = [];
  Timer? _typing;
  Timer? _reverseDebounce;
  bool _locating = false;
  String? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    final z = widget.initial;
    if (z != null) {
      _point = LatLng(z.lat, z.lng);
      _label = z.label;
      _pointChosen = true;
      _mode = z.mode;
      _radiusKm = z.radiusKm;
      _minutes = z.minutes;
      _travel = z.travel;
    } else {
      _point = widget.fallbackCenter;
    }
  }

  @override
  void dispose() {
    _typing?.cancel();
    _reverseDebounce?.cancel();
    _addressCtrl.dispose();
    _geo.close();
    super.dispose();
  }

  double get _radius =>
      _mode == RangeMode.radius ? _radiusKm : radiusForMinutes(_minutes, _travel);

  void _fit() {
    final ne = offsetPoint(_point.latitude, _point.longitude, _radius * 1.15, 45);
    final sw = offsetPoint(_point.latitude, _point.longitude, _radius * 1.15, 225);
    _map.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(LatLng(sw.lat, sw.lng), LatLng(ne.lat, ne.lng)),
      padding: const EdgeInsets.all(24),
    ));
  }

  /// Zooms onto the starting point.
  void _focusPoint() => _map.move(_point, _focusZoom);

  /// [focus] zooms onto the new point: wanted when it came from the GPS or an
  /// address (it may be anywhere), not when the user just tapped the map
  /// (they are already looking at it).
  void _movePoint(LatLng p, {String? label, bool focus = false}) {
    setState(() {
      _point = p;
      _pointChosen = true;
      _error = null;
      if (label != null) _label = label;
    });
    if (focus) _focusPoint();
    if (label == null) {
      // Name the pin after a short pause, so dragging around the map does not
      // fire a lookup on every tap.
      _reverseDebounce?.cancel();
      _reverseDebounce = Timer(const Duration(milliseconds: 500), () async {
        try {
          final a = await _geo.reverse(p.latitude, p.longitude);
          if (mounted && a != null) setState(() => _label = a.label);
        } catch (_) {
          if (mounted) setState(() => _label = tr.pointOnMap);
        }
      });
    }
  }

  Future<void> _useMyPosition() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _fail(tr.locationOff,
            action: Geolocator.openLocationSettings);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _fail(tr.locationDeniedForever,
            action: Geolocator.openAppSettings);
        return;
      }
      if (perm == LocationPermission.denied) {
        _fail(tr.locationDenied);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      _movePoint(LatLng(pos.latitude, pos.longitude), focus: true);
    } catch (e) {
      _fail(tr.positionNotFound('$e'));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _fail(String message, {Future<bool> Function()? action}) {
    if (!mounted) return;
    setState(() => _error = message);
    if (action != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        action: SnackBarAction(label: tr.androidSettings, onPressed: action),
      ));
    }
  }

  void _onAddressChanged(String v) {
    _typing?.cancel();
    if (v.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _typing = Timer(const Duration(milliseconds: 350), () async {
      try {
        final list = await _geo.searchAddress(v);
        if (mounted) setState(() => _suggestions = list);
      } catch (e) {
        if (mounted) setState(() => _error = '$e');
      }
    });
  }

  Future<void> _validate() async {
    if (!_pointChosen) {
      setState(() => _error = tr.needPoint);
      return;
    }
    setState(() {
      _progress = tr.findingTowns;
      _error = null;
    });
    try {
      final communes = await _geo.communesInZone(
        _point.latitude,
        _point.longitude,
        _radius,
      );
      final places = <PlaceRef>[];
      final kept = <Commune>[];
      for (var i = 0; i < communes.length; i++) {
        final c = communes[i];
        setState(() => _progress =
            tr.preparingTown(c.name, i + 1, communes.length));
        try {
          places.add(await widget.api
              .resolvePlace(c.name, specialitySlug: widget.specialitySlug));
          kept.add(c);
        } on DoctolibException {
          // A hamlet Doctolib has no page for: nobody to find there anyway.
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(Zone(
        lat: _point.latitude,
        lng: _point.longitude,
        label: _label.isEmpty ? tr.pointChosen : _label,
        mode: _mode,
        radiusKm: _radiusKm,
        minutes: _minutes,
        travel: _travel,
        places: places,
        communes: kept,
      ));
    } catch (e) {
      if (mounted) {
        setState(() {
          _progress = null;
          _error = tr.zonePrepFailed('$e');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _progress != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr.zoneTitle),
        actions: [
          if (widget.initial != null)
            TextButton(
              onPressed: busy ? null : () => Navigator.of(context).pop(const _Remove()),
              child: Text(tr.delete),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addressCtrl,
                    onChanged: _onAddressChanged,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: tr.addressOptional,
                      prefixIcon: Icon(Icons.home_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: _locating || busy ? null : _useMyPosition,
                  icon: _locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(tr.myPosition),
                ),
              ],
            ),
          ),
          if (_suggestions.isNotEmpty)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  for (final a in _suggestions)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.place_outlined),
                      title: Text(a.label),
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _addressCtrl.text = a.label;
                        setState(() => _suggestions = []);
                        _movePoint(LatLng(a.lat, a.lng), label: a.label, focus: true);
                      },
                    ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _point,
                    // Opens on the city chosen in step 1, close enough to
                    // find one's street.
                    initialZoom: 13,
                    onTap: busy ? null : (_, p) => _movePoint(p),
                    onMapReady: () {
                      if (_pointChosen) _fit();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'fr.rdvwatch.rdv_watch',
                    ),
                    if (_pointChosen)
                      CircleLayer(circles: [
                        CircleMarker(
                          point: _point,
                          radius: _radius * 1000,
                          useRadiusInMeter: true,
                          color: _zoneRed.withValues(alpha: 0.18),
                          borderColor: _zoneRed,
                          borderStrokeWidth: 3,
                        ),
                      ]),
                    if (_pointChosen)
                      MarkerLayer(markers: [
                        Marker(
                          point: _point,
                          width: 44,
                          height: 44,
                          alignment: Alignment.topCenter,
                          child: const Icon(Icons.location_pin,
                              size: 44, color: _zoneRed),
                        ),
                      ]),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () => launchUrl(
                            Uri.parse('https://www.openstreetmap.org/copyright'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_pointChosen)
                  Positioned(
                    right: 12,
                    bottom: 40,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'focus',
                          tooltip: tr.centerOnPoint,
                          onPressed: _focusPoint,
                          child: const Icon(Icons.my_location),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'fit',
                          tooltip: tr.showWholeZone,
                          onPressed: _fit,
                          child: const Icon(Icons.zoom_out_map),
                        ),
                      ],
                    ),
                  ),
                if (!_pointChosen)
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 12,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          tr.tapMapHint,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _controls(theme, busy),
        ],
      ),
    );
  }

  Widget _controls(ThemeData theme, bool busy) => Material(
        elevation: 8,
        color: theme.colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_label.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.location_pin,
                          size: 16, color: theme.colorScheme.error),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                SegmentedButton<RangeMode>(
                  segments: [
                    ButtonSegment(
                      value: RangeMode.radius,
                      label: Text(tr.circle),
                      icon: Icon(Icons.radio_button_unchecked),
                    ),
                    ButtonSegment(
                      value: RangeMode.travel,
                      label: Text(tr.travelTime),
                      icon: Icon(Icons.directions),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: busy
                      ? null
                      : (s) {
                          setState(() => _mode = s.first);
                          if (_pointChosen) _fit();
                        },
                ),
                const SizedBox(height: 8),
                if (_mode == RangeMode.radius) ...[
                  Text(tr.radiusLabel(formatKm(_radiusKm)),
                      style: theme.textTheme.titleSmall),
                  Slider(
                    min: 0.5,
                    max: 30,
                    divisions: 59,
                    value: _radiusKm,
                    label: formatKm(_radiusKm),
                    onChanged: busy ? null : (v) => setState(() => _radiusKm = v),
                    onChangeEnd: (_) {
                      if (_pointChosen) _fit();
                    },
                  ),
                ] else ...[
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final t in TravelMode.values)
                        ChoiceChip(
                          avatar: Icon(
                            switch (t) {
                              TravelMode.walk => Icons.directions_walk,
                              TravelMode.bike => Icons.directions_bike,
                              TravelMode.transit => Icons.directions_bus,
                              TravelMode.car => Icons.directions_car,
                            },
                            size: 18,
                          ),
                          label: Text(t.label),
                          selected: _travel == t,
                          onSelected: busy
                              ? null
                              : (_) {
                                  setState(() => _travel = t);
                                  if (_pointChosen) _fit();
                                },
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(tr.atMost(_minutes, _travel.phrase),
                      style: theme.textTheme.titleSmall),
                  Slider(
                    min: 5,
                    max: 90,
                    divisions: 17,
                    value: _minutes.toDouble(),
                    label: tr.minutesShort(_minutes),
                    onChanged:
                        busy ? null : (v) => setState(() => _minutes = v.round()),
                    onChangeEnd: (_) {
                      if (_pointChosen) _fit();
                    },
                  ),
                  Text(
                    tr.travelEstimate(formatKm(_radius)),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: busy ? null : _validate,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  label: Text(_progress ?? tr.validateZone),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Popped instead of a [Zone] when the user removes the zone.
class _Remove {
  const _Remove();
}

/// Helper for callers: a popped value means "zone removed" when it is this.
bool isZoneRemoval(Object? result) => result is _Remove;
