import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../notifications.dart';
import 'app_state.dart';
import '../i18n.dart';

/// First-run walkthrough.
///
/// Exists because three things have to be true before this app can work at
/// all, and two of them are Android settings the user must grant by hand. A
/// watcher that silently never fires is worse than no watcher, so we ask up
/// front rather than letting them discover it a week later.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.state, required this.onDone});

  final AppState state;
  final VoidCallback onDone;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pages = PageController();
  int _index = 0;

  bool _notificationsGranted = false;
  bool _batteryGranted = false;
  bool _checkedBattery = false;

  late int _quietFrom = widget.state.settings.quietFromHour;
  late int _quietTo = widget.state.settings.quietToHour;
  late bool _quietEnabled = widget.state.settings.quietEnabled;

  static const int _stepCount = 4;

  @override
  void initState() {
    super.initState();
    _refreshPermissions();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _refreshPermissions() async {
    final notif = await Notifications.instance.areEnabled();
    final battery = await Permission.ignoreBatteryOptimizations.isGranted;
    if (!mounted) return;
    setState(() {
      _notificationsGranted = notif;
      _batteryGranted = battery;
      _checkedBattery = true;
    });
  }

  Future<void> _askNotifications() async {
    await Notifications.instance.requestPermission();
    // The "call me" style takes over the lock screen, which Android 14 gates
    // separately. Asking here costs nothing if the OS does not require it.
    await Notifications.instance.requestFullScreenPermission();
    await _refreshPermissions();
  }

  Future<void> _askBattery() async {
    await Permission.ignoreBatteryOptimizations.request();
    await _refreshPermissions();
  }

  Future<void> _finish() async {
    final s = widget.state.settings;
    s.quietEnabled = _quietEnabled;
    s.quietFromHour = _quietFrom;
    s.quietToHour = _quietTo;
    s.onboardingDone = true;
    await widget.state.saveSettings(s);
    widget.onDone();
  }

  void _next() {
    if (_index >= _stepCount - 1) {
      _finish();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  for (var i = 0; i < _stepCount; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= _index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) {
                  setState(() => _index = i);
                  _refreshPermissions();
                },
                children: [
                  _welcomeStep(theme),
                  _notificationStep(theme),
                  _batteryStep(theme),
                  _quietStep(theme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  if (_index > 0 && _index < _stepCount - 1)
                    TextButton(
                      onPressed: _next,
                      child: Text(tr.later),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _next,
                    icon: Icon(_index == _stepCount - 1
                        ? Icons.check
                        : Icons.arrow_forward),
                    label: Text(
                      _index == _stepCount - 1 ? tr.start : tr.next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String body,
    List<Widget> children = const [],
  }) =>
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon,
                  size: 36, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 24),
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              body,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      );

  Widget _welcomeStep(ThemeData theme) => _step(
        theme: theme,
        icon: Icons.event_available,
        title: tr.appTitle,
        body: tr.obWelcomeBody,
        children: [
          Text(tr.obLanguage, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (code, name) in const [
                ('fr', 'Français'),
                ('en', 'English'),
                ('ar', 'العربية'),
              ])
                ChoiceChip(
                  label: Text(name),
                  selected: I18n.code == code,
                  onSelected: (_) => _setLanguage(code),
                ),
            ],
          ),
        ],
      );

  /// Applies at once: the rest of the walkthrough is then read in it.
  Future<void> _setLanguage(String code) async {
    final s = widget.state.settings..language = code;
    await widget.state.saveSettings(s);
    if (mounted) setState(() {});
  }

  Widget _notificationStep(ThemeData theme) => _step(
        theme: theme,
        icon: Icons.notifications_active_outlined,
        title: tr.allowNotifications,
        body: tr.obNotifBody,
        children: [
          _statusCard(
            theme,
            granted: _notificationsGranted,
            grantedText: tr.notifGranted,
            pendingText: tr.notifPending,
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _askNotifications,
            icon: const Icon(Icons.notifications),
            label: Text(_notificationsGranted
                ? tr.checkAgain
                : tr.allowNotifications),
          ),
        ],
      );

  Widget _batteryStep(ThemeData theme) => _step(
        theme: theme,
        icon: Icons.battery_charging_full,
        title: tr.obBatteryTitle,
        body: tr.obBatteryBody,
        children: [
          if (_checkedBattery)
            _statusCard(
              theme,
              granted: _batteryGranted,
              grantedText: tr.batteryGranted,
              pendingText: tr.batteryPending,
            ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _askBattery,
            icon: const Icon(Icons.battery_saver),
            label: Text(_batteryGranted
                ? tr.checkAgain
                : tr.removeRestrictions),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: openAppSettings,
            icon: const Icon(Icons.settings),
            label: Text(tr.openAppSettings),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tr.obBatteryOem,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      );

  Widget _quietStep(ThemeData theme) => _step(
        theme: theme,
        icon: Icons.bedtime_outlined,
        title: tr.quietHours,
        body: tr.obQuietBody,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _quietEnabled,
            onChanged: (v) => setState(() => _quietEnabled = v),
            title: Text(tr.enableQuietHours),
            subtitle: Text(_quietEnabled
                ? tr.quietFromTo(I18n.hour(_quietFrom), I18n.hour(_quietTo))
                : tr.canRingAnytime),
          ),
          if (_quietEnabled) ...[
            const SizedBox(height: 8),
            Text(tr.quietStart(I18n.hour(_quietFrom)),
                style: theme.textTheme.labelLarge),
            Slider(
              min: 0,
              max: 23,
              divisions: 23,
              value: _quietFrom.toDouble(),
              label: I18n.hour(_quietFrom),
              onChanged: (v) => setState(() => _quietFrom = v.round()),
            ),
            Text(tr.quietEnd(I18n.hour(_quietTo)), style: theme.textTheme.labelLarge),
            Slider(
              min: 0,
              max: 23,
              divisions: 23,
              value: _quietTo.toDouble(),
              label: I18n.hour(_quietTo),
              onChanged: (v) => setState(() => _quietTo = v.round()),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            tr.changeLater,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      );

  Widget _statusCard(
    ThemeData theme, {
    required bool granted,
    required String grantedText,
    required String pendingText,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: granted
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              granted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: granted
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                granted ? grantedText : pendingText,
                style: TextStyle(
                  color: granted
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
}
