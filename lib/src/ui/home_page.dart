import 'package:flutter/material.dart';

import '../models.dart';
import '../notifications.dart';
import 'app_state.dart';
import 'common.dart';
import 'edit_watch_page.dart';
import 'journal_page.dart';
import 'settings_page.dart';
import 'watch_detail_page.dart';
import '../i18n.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.state});

  final AppState state;

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    Notifications.instance.onOpenWatch = _openWatchById;
    WidgetsBinding.instance.addPostFrameCallback((_) => _askPermission());
  }

  Future<void> _askPermission() async {
    final enabled = await Notifications.instance.areEnabled();
    if (!enabled) await Notifications.instance.requestPermission();
  }

  void _openWatchById(String id) {
    final watch = widget.state.byId(id);
    if (watch == null || !mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WatchDetailPage(state: widget.state, watchId: id),
    ));
  }

  Future<void> _newWatch() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EditWatchPage(state: widget.state),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(tr.homeTitle),
            actions: [
              IconButton(
                tooltip: tr.checkNow,
                onPressed: state.checking ? null : () => _checkAll(state),
                icon: state.checking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: tr.journal,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const JournalPage(),
                )),
                icon: const Icon(Icons.history),
              ),
              IconButton(
                tooltip: tr.settings,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SettingsPage(state: state),
                )),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _newWatch,
            icon: const Icon(Icons.add_alert),
            label: Text(tr.newAlert),
          ),
          body: state.loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => _checkAll(state),
                  child: state.watches.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: EmptyHint(
                                icon: Icons.notifications_active_outlined,
                                title: tr.noAlerts,
                                body:
                                    tr.noAlertsBody,
                                action: FilledButton.icon(
                                  onPressed: _newWatch,
                                  icon: const Icon(Icons.add),
                                  label: Text(tr.createAlert),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 96),
                          children: [
                            if (state.guard.isPaused) _pausedBanner(theme, state),
                            for (final w in state.watches)
                              _WatchCard(
                                watch: w,
                                state: state,
                                onOpen: () =>
                                    Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => WatchDetailPage(
                                    state: state,
                                    watchId: w.id,
                                  ),
                                )),
                              ),
                            _footer(theme, state),
                          ],
                        ),
                ),
        );
      },
    );
  }

  Future<void> _checkAll(AppState state) async {
    await state.checkNow();
    if (!mounted) return;
    final msg = state.lastMessage;
    if (msg != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Widget _pausedBanner(ThemeData theme, AppState state) => Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.pause_circle_outline,
                color: theme.colorScheme.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.guard.lastBlockMessage ??
                    tr.pausedFor(state.guard.pauseRemaining.inMinutes + 1),
                style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
              ),
            ),
          ],
        ),
      );

  Widget _footer(ThemeData theme, AppState state) {
    final est = state.requestEstimate;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr.footerSchedule(state.settings.intervalLabel, state.settings.quietLabel),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            tr.footerCost(est.perRun, est.perDay, state.settings.maxRequestsPerDay, state.guard.requestsToday),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _WatchCard extends StatelessWidget {
  const _WatchCard({
    required this.watch,
    required this.state,
    required this.onOpen,
  });

  final WatchConfig watch;
  final AppState state;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Ignored slots must not be advertised on the card either.
    final hits = watch.visibleHits;
    final next = hits.isEmpty ? null : hits.first;
    final freshCount =
        hits.where((h) => watch.freshIds.contains(h.id)).length;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    watch.kind == WatchKind.doctor
                        ? Icons.person_outline
                        : Icons.medical_services_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      watch.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (freshCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tr.newCount(freshCount),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onError,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  Switch(
                    value: watch.enabled,
                    onChanged: (v) => state.toggleWatch(watch, v),
                  ),
                ],
              ),
              Text(
                watch.subtitle,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _pill(theme, Icons.timelapse, watch.windowLabel),
                  _pill(
                    theme,
                    switch (watch.alertStyle) {
                      AlertStyle.discreet => Icons.notifications_none,
                      AlertStyle.normal => Icons.notifications_active_outlined,
                      AlertStyle.call => Icons.phone_in_talk,
                    },
                    watch.alertStyle.label,
                    highlight: watch.alertStyle == AlertStyle.call,
                  ),
                  if (watch.zone != null)
                    _pill(theme, Icons.radar, watch.zone!.shortLabel),
                  if (watch.teleconsult != TeleconsultMode.any)
                    _pill(
                      theme,
                      watch.teleconsult == TeleconsultMode.online
                          ? Icons.videocam_outlined
                          : Icons.meeting_room_outlined,
                      watch.teleconsult.label,
                    ),
                  if (watch.isSnoozed)
                    _pill(
                      theme,
                      Icons.snooze,
                      tr.snoozedUntil(hhmm(watch.snoozedUntil!)),
                    ),
                  if (watch.hasIgnores)
                    _pill(
                      theme,
                      Icons.notifications_off_outlined,
                      tr.ignoredCount(watch.ignoredCount),
                    ),
                  if (watch.filterLabel.isNotEmpty)
                    _pill(theme, Icons.filter_alt_outlined, watch.filterLabel),
                ],
              ),
              const SizedBox(height: 12),
              if (watch.lastError != null)
                Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 16, color: theme.colorScheme.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        watch.lastError!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              else if (next != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_available,
                          size: 18,
                          color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          hits.length == 1
                              ? '${dayLabel(next.when)} ${hhmm(next.when)} · ${next.doctorName}'
                              : tr.earliestOf(tr.slotsCount(hits.length), '${dayLabel(next.when)} ${hhmm(next.when)}'),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  tr.nothingInWindow,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              const SizedBox(height: 8),
              Text(
                '${tr.checkedAgo(relativeTime(watch.lastCheckedAt))}${watch.lastRequestCount > 0 ? ' · ${tr.requestsCount(watch.lastRequestCount)}' : ''}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(
    ThemeData theme,
    IconData icon,
    String label, {
    bool highlight = false,
  }) {
    final fg = highlight
        ? theme.colorScheme.onTertiaryContainer
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? theme.colorScheme.tertiaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          // Flexible: a long filter summary wraps inside the pill instead of
          // running off the card.
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
