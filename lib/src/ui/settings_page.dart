import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models.dart';
import '../notifications.dart';
import 'app_state.dart';
import '../i18n.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.state});

  final AppState state;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppSettings _s;

  @override
  void initState() {
    super.initState();
    final o = widget.state.settings;
    _s = AppSettings(
      intervalMinutes: o.intervalMinutes,
      quietFromHour: o.quietFromHour,
      quietToHour: o.quietToHour,
      quietEnabled: o.quietEnabled,
      groupNotifications: o.groupNotifications,
      frugalMode: o.frugalMode,
      maxRequestsPerDay: o.maxRequestsPerDay,
      statusNotification: o.statusNotification,
      callSound: o.callSound,
      callSeconds: o.callSeconds,
      language: o.language,
      themeMode: o.themeMode,
      // Must be carried over, or saving any setting would replay the
      // first-run walkthrough on the next launch.
      onboardingDone: o.onboardingDone,
    );
  }

  Future<void> _apply() async {
    await widget.state.saveSettings(_s);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final est = widget.state.requestEstimate;
    final guard = widget.state.guard;

    return Scaffold(
      appBar: AppBar(title: Text(tr.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _header(theme, tr.appearance),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(tr.language),
            trailing: DropdownButton<String>(
              value: _s.language,
              items: [
                DropdownMenuItem(value: 'system', child: Text(tr.langSystem)),
                // Each language is named in itself, so it can be found even by
                // someone who cannot read the current one.
                const DropdownMenuItem(value: 'fr', child: Text('Français')),
                const DropdownMenuItem(value: 'en', child: Text('English')),
                const DropdownMenuItem(value: 'ar', child: Text('العربية')),
              ],
              onChanged: (v) async {
                if (v == null) return;
                _s.language = v;
                await _apply();
                if (mounted) setState(() {});
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'system',
                  label: Text(tr.themeSystem),
                  icon: const Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: 'light',
                  label: Text(tr.themeLight),
                  icon: const Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: 'dark',
                  label: Text(tr.themeDark),
                  icon: const Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {_s.themeMode},
              onSelectionChanged: (v) {
                setState(() => _s.themeMode = v.first);
                _apply();
              },
            ),
          ),

          _header(theme, tr.frequencyTitle),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(tr.searchEvery(_s.intervalLabel)),
            subtitle: Text(
              tr.frequencyBody,
            ),
            isThreeLine: true,
            trailing: DropdownButton<int>(
              value: _s.intervalMinutes,
              items: const [15, 30, 60, 120, 180, 360]
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m < 60 ? tr.minutesShort(m) : tr.hoursShort(m ~/ 60)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _s.intervalMinutes = v);
                _apply();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              _s.intervalMinutes <= 15
                  ? tr.freq15Advice
                  : _s.intervalMinutes <= 60
                      ? tr.freqBalancedAdvice
                      : tr.freqSlowAdvice,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.battery_charging_full),
            title: Text(tr.allowBackground),
            subtitle: Text(
              tr.allowBackgroundBody,
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Permission.ignoreBatteryOptimizations.request();
              final ok = await Permission.ignoreBatteryOptimizations.isGranted;
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok
                    ? tr.batteryGranted
                    : tr.backgroundRestricted),
                action: ok
                    ? null
                    : SnackBarAction(
                        label: tr.androidSettings,
                        onPressed: openAppSettings,
                      ),
              ));
            },
          ),
          SwitchListTile(
            value: _s.quietEnabled,
            onChanged: (v) {
              setState(() => _s.quietEnabled = v);
              _apply();
            },
            title: Text(tr.quietHours),
            subtitle: Text(
              _s.quietEnabled
                  ? tr.quietOnBody(I18n.hour(_s.quietFromHour), I18n.hour(_s.quietToHour))
                  : tr.quietOffBody,
            ),
            isThreeLine: _s.quietEnabled,
          ),
          if (_s.quietEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(tr.fromLabel),
                  Expanded(
                    child: Slider(
                      min: 0,
                      max: 23,
                      divisions: 23,
                      value: _s.quietFromHour.toDouble(),
                      label: I18n.hour(_s.quietFromHour),
                      onChanged: (v) =>
                          setState(() => _s.quietFromHour = v.round()),
                      onChangeEnd: (_) => _apply(),
                    ),
                  ),
                  Text(tr.toLabel),
                  Expanded(
                    child: Slider(
                      min: 0,
                      max: 23,
                      divisions: 23,
                      value: _s.quietToHour.toDouble(),
                      label: I18n.hour(_s.quietToHour),
                      onChanged: (v) =>
                          setState(() => _s.quietToHour = v.round()),
                      onChangeEnd: (_) => _apply(),
                    ),
                  ),
                ],
              ),
            ),

          _header(theme, tr.notifications),
          SwitchListTile(
            value: _s.groupNotifications,
            onChanged: (v) {
              setState(() => _s.groupNotifications = v);
              _apply();
            },
            title: Text(tr.groupByAlert),
            subtitle: Text(
              tr.groupByAlertBody,
            ),
          ),
          SwitchListTile(
            value: _s.statusNotification,
            onChanged: (v) {
              setState(() => _s.statusNotification = v);
              _apply();
              if (!v) Notifications.instance.hideStatus();
            },
            secondary: const Icon(Icons.shield_outlined),
            title: Text(tr.statusBadge),
            subtitle: Text(
              tr.statusBadgeBody,
            ),
            isThreeLine: true,
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(tr.allowNotifications),
            subtitle: Text(tr.needAndroid13),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final ok = await Notifications.instance.requestPermission();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok
                    ? tr.notifGranted
                    : tr.notifRefused),
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.volume_up_outlined),
            title: Text(tr.testAlert),
            subtitle: Text(
              tr.testAlertBody,
            ),
            trailing: PopupMenuButton<AlertStyle>(
              icon: const Icon(Icons.play_circle_outline),
              onSelected: (s) async {
                await Notifications.instance
                    .showSample(s, sound: CallSound.byId(_s.callSound));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr.sampleSent(s.label))),
                );
              },
              itemBuilder: (_) => [
                for (final s in AlertStyle.values)
                  PopupMenuItem(value: s, child: Text(s.label)),
              ],
            ),
          ),

          _header(theme, tr.callModeTitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              tr.callModeBody,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          for (final sound in CallSound.all)
            RadioListTile<String>(
              value: sound.id,
              groupValue: _s.callSound,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _s.callSound = v);
                _apply();
              },
              title: Text(sound.label),
              subtitle: Text(sound.raw != null
                  ? tr.soundBundled
                  : tr.soundSystem),
              secondary: IconButton(
                tooltip: tr.listen,
                icon: const Icon(Icons.play_circle_outline),
                onPressed: () async {
                  final call = await Notifications.instance
                      .previewCall(sound, seconds: 12);
                  Notifications.instance.awaitMissedCall(call, 12);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(tr.testCallSent(sound.label)),
                  ));
                },
              ),
            ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(tr.ringDuration),
            subtitle: Text(
              tr.ringDurationBody(_s.callSeconds),
            ),
            trailing: DropdownButton<int>(
              value: _s.callSeconds,
              items: const [20, 30, 45, 60, 90]
                  .map((v) => DropdownMenuItem(value: v, child: Text(tr.secondsShort(v))))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _s.callSeconds = v);
                _apply();
              },
            ),
          ),

          _header(theme, tr.blockTitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              tr.blockBody,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          SwitchListTile(
            value: _s.frugalMode,
            onChanged: (v) {
              setState(() => _s.frugalMode = v);
              _apply();
            },
            title: Text(tr.frugalTitle),
            subtitle: Text(
              tr.frugalBody,
            ),
            isThreeLine: true,
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: Text(tr.safetyLimit(_s.budgetLabel)),
            subtitle: Text(
              tr.safetyLimitBody(_s.maxRequestsPerDay, guard.requestsToday),
            ),
            isThreeLine: true,
            trailing: DropdownButton<int>(
              value: _s.maxRequestsPerDay,
              items: const [200, 400, 800, 1500, 3000]
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(AppSettings(maxRequestsPerDay: m).budgetLabel),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _s.maxRequestsPerDay = v);
                _apply();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.insights,
                            size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(tr.estimate,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr.estimateBody(_s.intervalLabel, _s.quietLabel, est.perRun, est.perDay, _s.maxRequestsPerDay),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (est.perDay > _s.maxRequestsPerDay) ...[
                      const SizedBox(height: 8),
                      Text(
                        tr.overLimit,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (guard.isPaused || guard.lastBlockMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Card(
                color: theme.colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guard.lastBlockMessage ?? tr.safetyPause,
                        style: TextStyle(
                            color: theme.colorScheme.onTertiaryContainer),
                      ),
                      if (guard.isPaused)
                        Text(
                          tr.resumeIn(guard.pauseRemaining.inMinutes + 1),
                          style: TextStyle(
                              color: theme.colorScheme.onTertiaryContainer),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          _header(theme, tr.about),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(tr.howItWorks),
            subtitle: Text(
              tr.howItWorksBody,
            ),
            isThreeLine: true,
          ),
          ListTile(
            leading: Icon(Icons.gavel_outlined),
            title: Text(tr.personalUse),
            subtitle: Text(
              tr.personalUseBody,
            ),
            isThreeLine: true,
          ),
        ],
      ),
    );
  }

  Widget _header(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
        child: Text(
          text.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      );
}
