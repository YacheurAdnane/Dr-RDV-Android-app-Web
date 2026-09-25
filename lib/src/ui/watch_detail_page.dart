import 'package:flutter/material.dart';

import '../models.dart';
import '../zone.dart';
import 'app_state.dart';
import 'common.dart';
import 'edit_watch_page.dart';
import '../i18n.dart';

class WatchDetailPage extends StatefulWidget {
  const WatchDetailPage({super.key, required this.state, required this.watchId});

  final AppState state;
  final String watchId;

  @override
  State<WatchDetailPage> createState() => _WatchDetailPageState();
}

class _WatchDetailPageState extends State<WatchDetailPage> {
  /// Which slots were new when this page opened.
  ///
  /// Captured once so the "NOUVEAU" markers stay put while the user reads,
  /// instead of vanishing the instant the watch is marked as read.
  Set<String> _wasNew = {};
  bool _captured = false;

  /// Earliest first (default) or nearest first, when distances are known.
  bool _byDistance = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  Future<void> _markRead() async {
    final watch = widget.state.byId(widget.watchId);
    if (watch == null) return;
    if (!_captured) {
      _wasNew = {...watch.freshIds};
      _captured = true;
    }
    if (watch.freshIds.isNotEmpty) {
      watch.freshIds.clear();
      await widget.state.updateWatch(watch);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final watch = widget.state.byId(widget.watchId);
        if (watch == null) {
          return Scaffold(body: Center(child: Text(tr.alertDeleted)));
        }
        final theme = Theme.of(context);
        final visible = watch.visibleHits;
        final muted = watch.lastHits.where(watch.isIgnored).toList();
        final hasDistances = visible.any((h) => h.distanceKm != null);
        final nearest = _byDistance && hasDistances;

        final byDay = <String, List<SlotHit>>{};
        if (nearest) {
          final sorted = [...visible]..sort((a, b) =>
              (a.distanceKm ?? double.infinity)
                  .compareTo(b.distanceKm ?? double.infinity));
          byDay[tr.nearestFirst] = sorted;
        } else {
          for (final h in visible) {
            byDay.putIfAbsent(dayLabel(h.when), () => []).add(h);
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(watch.title, overflow: TextOverflow.ellipsis),
            actions: [
              if (visible.isNotEmpty)
                IconButton(
                  tooltip: tr.ignoreAll,
                  icon: const Icon(Icons.notifications_off_outlined),
                  onPressed: () => _ignoreAll(watch),
                ),
              IconButton(
                tooltip: tr.edit,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      EditWatchPage(state: widget.state, existing: watch),
                )),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  switch (v) {
                    case 'delete':
                      await _confirmDelete(watch);
                    case 'reset':
                      await _resetSeen(watch);
                    case 'snooze':
                      await _snooze(watch);
                    case 'wake':
                      await _wake(watch);
                    case 'duplicate':
                      await _duplicate(watch);
                    case 'restoreAll':
                      await _restoreAll(watch);
                  }
                },
                itemBuilder: (_) => [
                  if (watch.isSnoozed)
                    PopupMenuItem(
                      value: 'wake',
                      child: ListTile(
                        leading: Icon(Icons.play_arrow),
                        title: Text(tr.resumeNow),
                      ),
                    )
                  else
                    PopupMenuItem(
                      value: 'snooze',
                      child: ListTile(
                        leading: Icon(Icons.snooze),
                        title: Text(tr.snoozeMenu),
                      ),
                    ),
                  if (watch.hasIgnores)
                    PopupMenuItem(
                      value: 'restoreAll',
                      child: ListTile(
                        leading: Icon(Icons.restore_from_trash),
                        title: Text(tr.restoreAll),
                      ),
                    ),
                  PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: Icon(Icons.copy_all_outlined),
                      title: Text(tr.duplicate),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'reset',
                    child: ListTile(
                      leading: Icon(Icons.restart_alt),
                      title: Text(tr.renotify),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text(tr.delete),
                    ),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: widget.state.checking ? null : () => _check(watch),
            icon: widget.state.checking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            label: Text(tr.check),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              _summary(theme, watch),
              if (watch.lastError != null) _errorCard(theme, watch),
              if (hasDistances)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(tr.earliest),
                        icon: Icon(Icons.schedule),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(tr.nearest),
                        icon: Icon(Icons.near_me_outlined),
                      ),
                    ],
                    selected: {_byDistance},
                    onSelectionChanged: (s) =>
                        setState(() => _byDistance = s.first),
                  ),
                ),
              const SizedBox(height: 8),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: EmptyHint(
                    icon: Icons.event_busy,
                    title: muted.isEmpty
                        ? tr.noSlotsWindow(watch.windowLabel)
                        : tr.allIgnored,
                    body: muted.isEmpty
                        ? tr.keepsChecking
                        : tr.ignoredHidden,
                  ),
                )
              else
                for (final entry in byDay.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      entry.key,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (final h in entry.value)
                    SlotTile(
                      hit: h,
                      zone: watch.zone,
                      isNew: _wasNew.contains(h.id),
                      onIgnore: (scope) => _ignore(watch, h, scope),
                    ),
                ],
              if (muted.isNotEmpty) _mutedSection(theme, watch, muted),
            ],
          ),
        );
      },
    );
  }

  Widget _errorCard(ThemeData theme, WatchConfig watch) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Card(
          color: theme.colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.error_outline,
                    color: theme.colorScheme.onErrorContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    watch.lastError!,
                    style:
                        TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _mutedSection(
    ThemeData theme,
    WatchConfig watch,
    List<SlotHit> muted,
  ) {
    final doctors = watch.ignoredDoctors
        .map((key) => watch.lastHits
            .firstWhere(
              (h) => h.doctorKey == key,
              orElse: () => SlotHit(
                doctorKey: key,
                doctorName: key,
                city: '',
                address: '',
                motive: '',
                bookingUrl: '',
                when: DateTime.now(),
              ),
            )
            .doctorName)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              Icon(Icons.notifications_off_outlined,
                  size: 18, color: theme.colorScheme.outline),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr.ignoredHeader(watch.ignoredCount),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
              TextButton(
                onPressed: () => _restoreAll(watch),
                child: Text(tr.restoreAll),
              ),
            ],
          ),
        ),
        if (doctors.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final key in watch.ignoredDoctors)
                  InputChip(
                    avatar: const Icon(Icons.person_off_outlined, size: 16),
                    label: Text(
                      doctors[watch.ignoredDoctors.toList().indexOf(key)],
                      overflow: TextOverflow.ellipsis,
                    ),
                    onDeleted: () => _unignoreDoctor(watch, key),
                  ),
              ],
            ),
          ),
        if (watch.ignoredDates.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final d in watch.ignoredDates)
                  InputChip(
                    avatar: const Icon(Icons.event_busy, size: 16),
                    label: Text(d),
                    onDeleted: () => _unignoreDate(watch, d),
                  ),
              ],
            ),
          ),
        for (final h in muted.take(20))
          SlotTile(
            hit: h,
            muted: true,
            onRestore: () => _restoreSlot(watch, h),
          ),
      ],
    );
  }

  Widget _summary(ThemeData theme, WatchConfig watch) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(theme, Icons.search, watch.subtitle),
                if (watch.zone != null) ...[
                  const SizedBox(height: 10),
                  _row(theme, Icons.radar, _zoneText(watch.zone!)),
                ],
                const SizedBox(height: 10),
                _row(theme, Icons.timelapse, tr.slotsWindow(watch.windowLabel)),
                if (watch.teleconsult != TeleconsultMode.any) ...[
                  const SizedBox(height: 10),
                  _row(
                    theme,
                    watch.teleconsult == TeleconsultMode.online
                        ? Icons.videocam_outlined
                        : Icons.meeting_room_outlined,
                    watch.teleconsult.label,
                  ),
                ],
                const SizedBox(height: 10),
                _row(
                  theme,
                  switch (watch.alertStyle) {
                    AlertStyle.discreet => Icons.notifications_none,
                    AlertStyle.normal => Icons.notifications_active_outlined,
                    AlertStyle.call => Icons.phone_in_talk,
                  },
                  watch.alertStyle == AlertStyle.call
                      ? tr.ringsLikeCall
                      : watch.alertStyle.label,
                ),
                if (watch.filterLabel.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _row(theme, Icons.filter_alt_outlined, watch.filterLabel),
                ],
                const SizedBox(height: 10),
                _row(
                  theme,
                  Icons.update,
                  '${tr.lastCheck(relativeTime(watch.lastCheckedAt))}${watch.lastRequestCount > 0 ? ' · ${tr.requestsCount(watch.lastRequestCount)}' : ''}',
                ),
                if (watch.errorStreak > 0 && watch.lastError == null) ...[
                  const SizedBox(height: 10),
                  _row(
                    theme,
                    Icons.build_circle_outlined,
                    tr.repairInProgress(watch.errorStreak, WatchConfig.errorThreshold),
                  ),
                ] else if (watch.lastRepairAt != null &&
                    DateTime.now().difference(watch.lastRepairAt!).inHours < 24) ...[
                  const SizedBox(height: 10),
                  _row(
                    theme,
                    Icons.build_circle_outlined,
                    tr.repairedAgo(relativeTime(watch.lastRepairAt)),
                  ),
                ],
                if (watch.isSnoozed) ...[
                  const SizedBox(height: 10),
                  _row(
                    theme,
                    Icons.snooze,
                    tr.snoozedUntilCap(hhmm(watch.snoozedUntil!)),
                  ),
                ],
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: watch.enabled,
                  title: Text(tr.alertActive),
                  onChanged: (v) => widget.state.toggleWatch(watch, v),
                ),
              ],
            ),
          ),
        ),
      );

  String _zoneText(Zone z) {
    final base = z.summary;
    final approx = z.mode == RangeMode.travel
        ? ' ${tr.zoneApproxParen(formatKm(z.effectiveRadiusKm))}'
        : '';
    final towns = z.communes.isEmpty
        ? ''
        : ' — ${tr.zoneTownsCount(z.communes.length)}';
    return '$base$approx$towns';
  }

  Widget _row(ThemeData theme, IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      );

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _ignore(
    WatchConfig watch,
    SlotHit hit,
    IgnoreScope scope,
  ) async {
    final String message;
    switch (scope) {
      case IgnoreScope.slot:
        watch.ignoredSlots.add(hit.id);
        message = tr.slotIgnored;
      case IgnoreScope.date:
        watch.ignoredDates.add(WatchConfig.dateKey(hit.when));
        message = tr.dayIgnored(I18n.dayMonth(hit.when));
      case IgnoreScope.doctor:
        watch.ignoredDoctors.add(hit.doctorKey);
        message = tr.doctorIgnored(hit.doctorName);
    }
    await widget.state.updateWatch(watch);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: tr.undo,
        onPressed: () => _undoIgnore(watch, hit, scope),
      ),
    ));
  }

  Future<void> _undoIgnore(
    WatchConfig watch,
    SlotHit hit,
    IgnoreScope scope,
  ) async {
    switch (scope) {
      case IgnoreScope.slot:
        watch.ignoredSlots.remove(hit.id);
      case IgnoreScope.date:
        watch.ignoredDates.remove(WatchConfig.dateKey(hit.when));
      case IgnoreScope.doctor:
        watch.ignoredDoctors.remove(hit.doctorKey);
    }
    await widget.state.updateWatch(watch);
  }

  Future<void> _ignoreAll(WatchConfig watch) async {
    final count = watch.visibleHits.length;
    final previous = {...watch.ignoredSlots};
    watch.ignoredSlots.addAll(watch.visibleHits.map((h) => h.id));
    watch.freshIds.clear();
    await widget.state.updateWatch(watch);
    if (!mounted) return;
    setState(() => _wasNew = {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(tr.ignoredAll(tr.slotsCount(count))),
      action: SnackBarAction(
        label: tr.undo,
        onPressed: () async {
          watch.ignoredSlots
            ..clear()
            ..addAll(previous);
          await widget.state.updateWatch(watch);
        },
      ),
    ));
  }

  Future<void> _restoreSlot(WatchConfig watch, SlotHit hit) async {
    watch.ignoredSlots.remove(hit.id);
    watch.ignoredDates.remove(WatchConfig.dateKey(hit.when));
    watch.ignoredDoctors.remove(hit.doctorKey);
    await widget.state.updateWatch(watch);
  }

  Future<void> _unignoreDoctor(WatchConfig watch, String key) async {
    watch.ignoredDoctors.remove(key);
    // The practitioner was skipped entirely while ignored, so their slots have
    // to be fetched again before they can reappear.
    watch.knownDoctorKeys =
        watch.knownDoctorKeys.where((k) => k != key).toList();
    await widget.state.updateWatch(watch);
  }

  Future<void> _unignoreDate(WatchConfig watch, String key) async {
    watch.ignoredDates.remove(key);
    await widget.state.updateWatch(watch);
  }

  Future<void> _restoreAll(WatchConfig watch) async {
    watch.ignoredSlots.clear();
    watch.ignoredDates.clear();
    watch.ignoredDoctors.clear();
    watch.knownDoctorKeys = const [];
    await widget.state.updateWatch(watch);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr.allRestored)),
    );
  }

  Future<void> _snooze(WatchConfig watch) async {
    final hours = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(tr.snoozeFor),
        children: [
          for (final h in [1, 3, 8, 24, 72])
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(h),
              child: Text(h < 24 ? tr.hoursCount(h) : tr.daysCount(h ~/ 24)),
            ),
        ],
      ),
    );
    if (hours == null) return;
    watch.snoozedUntil = DateTime.now().add(Duration(hours: hours));
    await widget.state.updateWatch(watch);
  }

  Future<void> _wake(WatchConfig watch) async {
    watch.snoozedUntil = null;
    await widget.state.updateWatch(watch);
  }

  Future<void> _duplicate(WatchConfig watch) async {
    final copy = WatchConfig.fromJson(watch.toJson())
      ..lastHits = const []
      ..knownDoctorKeys = const []
      ..lastCheckedAt = null
      ..lastError = null;
    final fresh = WatchConfig(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      title: tr.copyTitle(copy.title),
      kind: copy.kind,
      specialities: copy.specialities,
      place: copy.place,
      zone: copy.zone,
      doctor: copy.doctor,
      motiveIds: copy.motiveIds,
      mode: copy.mode,
      horizonDays: copy.horizonDays,
      from: copy.from,
      to: copy.to,
      alertStyle: copy.alertStyle,
      onlyNewPatients: copy.onlyNewPatients,
      teleconsult: copy.teleconsult,
      hourFrom: copy.hourFrom,
      hourTo: copy.hourTo,
      weekdays: {...copy.weekdays},
      maxDoctors: copy.maxDoctors,
    );
    await widget.state.addWatch(fresh);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => EditWatchPage(state: widget.state, existing: fresh),
    ));
  }

  Future<void> _check(WatchConfig watch) async {
    await widget.state.checkNow(watchId: watch.id, notify: false);
    if (!mounted) return;
    setState(() {
      final w = widget.state.byId(widget.watchId);
      if (w != null) _wasNew = {...w.freshIds};
    });
    await _markRead();
    if (!mounted) return;
    final msg = widget.state.lastMessage;
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _resetSeen(WatchConfig watch) async {
    watch.seen.clear();
    await widget.state.updateWatch(watch);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr.renotified),
      ),
    );
  }

  Future<void> _confirmDelete(WatchConfig watch) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr.deleteConfirm),
        content: Text(watch.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(tr.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.state.deleteWatch(watch.id);
    if (mounted) Navigator.of(context).pop();
  }
}
