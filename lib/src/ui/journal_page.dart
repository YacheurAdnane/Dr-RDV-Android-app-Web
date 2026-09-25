import 'package:flutter/material.dart';

import '../i18n.dart';
import '../journal.dart';

/// What the app did, check by check.
///
/// Answers the two questions a watcher app always raises: "is it actually
/// running while my phone is in my pocket?" (entries marked background) and
/// "when do slots tend to appear?" (the busiest-hour insight on top).
class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  List<JournalEntry>? _entries;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await Journal.load();
    if (mounted) setState(() => _entries = e);
  }

  Future<void> _clear() async {
    await Journal.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _entries;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr.journal),
        actions: [
          if (entries != null && entries.isNotEmpty)
            IconButton(
              tooltip: tr.journalClear,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _clear,
            ),
        ],
      ),
      body: entries == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      tr.journalBody,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  if (Journal.busiestHour(entries) case final h?)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: theme.colorScheme.primaryContainer,
                        child: ListTile(
                          leading: Icon(Icons.insights,
                              color: theme.colorScheme.onPrimaryContainer),
                          title: Text(
                            tr.journalBusiestHour(I18n.hour(h)),
                            style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer),
                          ),
                        ),
                      ),
                    ),
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(child: Text(tr.journalEmpty)),
                    ),
                  ..._grouped(theme, entries),
                ],
              ),
            ),
    );
  }

  Iterable<Widget> _grouped(ThemeData theme, List<JournalEntry> entries) sync* {
    String? day;
    for (final e in entries) {
      final d = I18n.day(e.at);
      if (d != day) {
        day = d;
        yield Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            d,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }
      yield _tile(theme, e);
    }
  }

  Widget _tile(ThemeData theme, JournalEntry e) {
    final (icon, color) = switch (e.kind) {
      JournalKind.found => (Icons.event_available, theme.colorScheme.primary),
      JournalKind.nothing => (Icons.search_off, theme.colorScheme.outline),
      JournalKind.error => (Icons.error_outline, theme.colorScheme.error),
      JournalKind.callAccepted => (Icons.call, Colors.green),
      JournalKind.callDeclined => (Icons.call_end, theme.colorScheme.error),
      JournalKind.callMissed => (Icons.phone_missed, theme.colorScheme.error),
    };
    final text = switch (e.kind) {
      JournalKind.found => tr.journalFound(e.title, tr.slotsCount(e.slots), e.fresh),
      JournalKind.nothing => tr.journalNothing(e.title),
      JournalKind.error => tr.journalError(e.title, e.detail ?? ''),
      JournalKind.callAccepted => '${tr.journalCallAccepted} · ${e.title}',
      JournalKind.callDeclined => '${tr.journalCallDeclined} · ${e.title}',
      JournalKind.callMissed => '${tr.journalCallMissed} · ${e.title}',
    };
    final isCall = e.kind.name.startsWith('call');
    final meta = [
      I18n.time(e.at),
      if (!isCall) e.background ? tr.journalBackground : tr.journalManual,
      if (isCall && e.detail != null) e.detail!,
    ].join(' · ');
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(
        text,
        style: e.kind == JournalKind.found && e.fresh > 0
            ? const TextStyle(fontWeight: FontWeight.w700)
            : null,
      ),
      subtitle: Text(meta),
    );
  }
}
