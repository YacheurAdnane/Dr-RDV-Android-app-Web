import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../zone.dart';
import '../i18n.dart';

/// Locale-aware helpers, kept under their old names for the screens.
String hhmm(DateTime d) => I18n.time(d);

String dayLabel(DateTime d) => I18n.day(d);

String relativeTime(DateTime? d) => I18n.ago(d);

Future<void> openBooking(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr.cannotOpenDoctolib)),
    );
  }
}

/// What the user asked us to forget about, at three levels of bluntness.
enum IgnoreScope { slot, date, doctor }

/// A slot, rendered as a tappable row that opens the Doctolib booking page.
///
/// A freshly found slot is drawn in the "new" accent so that, after muting a
/// batch, anything that appears later still stands out at a glance.
class SlotTile extends StatelessWidget {
  const SlotTile({
    super.key,
    required this.hit,
    this.isNew = false,
    this.muted = false,
    this.onIgnore,
    this.onRestore,
    this.zone,
  });

  /// The alert's zone, to phrase the distance as a trip ("~14 min en bus").
  final Zone? zone;

  final SlotHit hit;
  final bool isNew;
  final bool muted;
  final void Function(IgnoreScope scope)? onIgnore;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.error;

    final badgeBg = muted
        ? theme.colorScheme.surfaceContainerHighest
        : isNew
            ? accent
            : theme.colorScheme.surfaceContainerHighest;
    final badgeFg = muted
        ? theme.colorScheme.outline
        : isNew
            ? theme.colorScheme.onError
            : theme.colorScheme.onSurfaceVariant;

    return Opacity(
      opacity: muted ? 0.45 : 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                I18n.weekdayNarrow(hit.when.weekday),
                style: theme.textTheme.labelSmall?.copyWith(color: badgeFg),
              ),
              Text(
                '${hit.when.day}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: badgeFg,
                ),
              ),
            ],
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                '${hhmm(hit.when)} · ${hit.doctorName}',
                overflow: TextOverflow.ellipsis,
                style: muted
                    ? TextStyle(decoration: TextDecoration.lineThrough)
                    : null,
              ),
            ),
            if (isNew && !muted) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tr.newBadge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onError,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            AppointmentTags(hit: hit, zone: zone),
            if (hit.address.isNotEmpty || hit.city.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                [hit.address, hit.city].where((s) => s.isNotEmpty).join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: muted
            ? IconButton(
                tooltip: tr.restore,
                icon: const Icon(Icons.undo),
                onPressed: onRestore,
              )
            : onIgnore == null
                ? const Icon(Icons.open_in_new, size: 18)
                : PopupMenuButton<Object>(
                    tooltip: tr.more,
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (v) {
                      if (v is IgnoreScope) {
                        onIgnore!(v);
                      } else if (v == _directions) {
                        openDirections(context, hit);
                      }
                    },
                    itemBuilder: (_) => [
                      if (hit.lat != null && hit.lng != null && !hit.telehealth)
                        PopupMenuItem(
                          value: _directions,
                          child: ListTile(
                            leading: Icon(Icons.directions),
                            title: Text(tr.directions),
                          ),
                        ),
                      PopupMenuItem(
                        value: IgnoreScope.slot,
                        child: ListTile(
                          leading: Icon(Icons.schedule),
                          title: Text(tr.ignoreSlot),
                        ),
                      ),
                      PopupMenuItem(
                        value: IgnoreScope.date,
                        child: ListTile(
                          leading: const Icon(Icons.event_busy),
                          title: Text(tr.ignoreDay(I18n.dayMonth(hit.when))),
                        ),
                      ),
                      PopupMenuItem(
                        value: IgnoreScope.doctor,
                        child: ListTile(
                          leading: const Icon(Icons.person_off_outlined),
                          title: Text(tr.ignoreDoctor(hit.doctorName)),
                        ),
                      ),
                    ],
                  ),
        onTap: muted ? onRestore : () => openBooking(context, hit.bookingUrl),
      ),
    );
  }
}

const String _directions = 'directions';

/// Opens the phone's maps app with directions to the practice.
///
/// `geo:` hands the choice to whatever maps app the user prefers; the Google
/// Maps web link is the fallback when none claims it.
Future<void> openDirections(BuildContext context, SlotHit hit) async {
  final lat = hit.lat, lng = hit.lng;
  if (lat == null || lng == null) return;
  final label = Uri.encodeComponent(
    [hit.doctorName, hit.address, hit.city].where((s) => s.isNotEmpty).join(', '),
  );
  final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
  if (await launchUrl(geo, mode: LaunchMode.externalApplication)) return;
  final web = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=transit',
  );
  final ok = await launchUrl(web, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr.noMapsApp)),
    );
  }
}

/// What kind of appointment a slot is, as small grey tags:
/// `● Medecin generaliste` `Premiere consultation` `Video`.
///
/// Read before tapping, so a "suivi" slot is not mistaken for a first visit
/// and a video slot is not mistaken for one at the practice.
class AppointmentTags extends StatelessWidget {
  const AppointmentTags({super.key, required this.hit, this.zone});

  final SlotHit hit;
  final Zone? zone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grey = theme.colorScheme.onSurfaceVariant;
    final bg = theme.colorScheme.surfaceContainerHighest;

    Widget tag(String text, {IconData? icon, bool dot = false}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline,
                    shape: BoxShape.circle,
                  ),
                ),
              if (icon != null) ...[
                Icon(icon, size: 12, color: grey),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: grey),
                ),
              ),
            ],
          ),
        );

    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: [
        if (hit.speciality.isNotEmpty) tag(hit.speciality, dot: true),
        if (hit.motive.isNotEmpty) tag(hit.motive, dot: true),
        if (hit.telehealth) tag(tr.video, icon: Icons.videocam_outlined),
        if (hit.distanceKm != null && !hit.telehealth)
          tag(
            zone == null
                ? formatKm(hit.distanceKm!)
                : '${formatKm(hit.distanceKm!)} · ${zone!.travelHint(hit.distanceKm!)}',
            icon: Icons.near_me_outlined,
          ),
      ],
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
