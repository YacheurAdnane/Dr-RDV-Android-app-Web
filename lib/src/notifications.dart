import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

import 'calls.dart';
import 'journal.dart';
import 'models.dart';
import 'i18n.dart';

/// Local notifications. Nothing leaves the phone: there is no server, no push
/// token, no account. The app polls Doctolib itself and raises the notification
/// locally, which is also why it works without any backend.
class Notifications {
  Notifications._();

  static final Notifications instance = Notifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Getters, not constants: channel names follow the app language, and
  // Android updates a channel's name when it is created again.
  static AndroidNotificationChannel get _slotsChannel =>
      AndroidNotificationChannel(
    'slots',
    tr.chSlots,
    description: tr.chSlotsDesc,
    importance: Importance.high,
  );

  static AndroidNotificationChannel get _discreetChannel =>
      AndroidNotificationChannel(
    'slots_quiet',
    tr.chQuiet,
    description: tr.chQuietDesc,
    importance: Importance.low,
    playSound: false,
  );

  static AndroidNotificationChannel get _statusChannel =>
      AndroidNotificationChannel(
    'status',
    tr.chStatus,
    description: tr.chStatusDesc,
    importance: Importance.low,
  );

  bool _ready = false;

  /// Called with the watch id when the user taps a notification.
  void Function(String watchId)? onOpenWatch;

  /// Called when a ringing call should be shown full screen.
  void Function(IncomingCall call)? onShowCall;

  /// A notification tap that launched the app from cold, kept until the UI is
  /// ready to act on it.
  NotificationResponse? _launchResponse;

  Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (r) => handleResponse(r),
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationAction,
    );

    final android_ = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android_?.createNotificationChannel(_slotsChannel);
    await android_?.createNotificationChannel(_discreetChannel);
    await android_?.createNotificationChannel(_statusChannel);
    // Superseded call channels: the single alarm-stream one, then the v1
    // per-ringtone ones that also rang on the alarm stream.
    await android_?.deleteNotificationChannel('slots_call');
    for (final sound in CallSound.all) {
      await android_?.deleteNotificationChannel('call_${sound.id}_v1');
    }

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _launchResponse = launch!.notificationResponse;
    }
    _ready = true;
  }

  /// Re-creates the fixed channels, which renames them in Android's settings
  /// after a language change.
  Future<void> refreshChannels() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_slotsChannel);
    await android?.createNotificationChannel(_discreetChannel);
    await android?.createNotificationChannel(_statusChannel);
  }

  /// Acts on the notification that launched the app, if any. Called once the
  /// navigator exists.
  Future<void> processLaunch() async {
    final r = _launchResponse;
    _launchResponse = null;
    if (r != null) await handleResponse(r);
  }

  /// Every notification tap and button press lands here, from the UI isolate
  /// or from the background isolate the plugin spawns for "Refuser".
  Future<void> handleResponse(
    NotificationResponse r, {
    bool background = false,
  }) async {
    final payload = r.payload;
    if (payload == null || payload.isEmpty) return;
    final Map<String, dynamic> j;
    try {
      j = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return; // Payload from an older build.
    }

    if (IncomingCall.isCallPayload(j)) {
      final call = IncomingCall.fromJson(j);
      switch (r.actionId) {
        case 'accept':
          final url = await acceptCall(call);
          if (!background) await _open(url);
        case 'decline':
          await declineCall(call);
        default:
          // Body tap or full-screen launch: show the call screen, the phone
          // keeps ringing until a button is pressed.
          if (!background) onShowCall?.call(call);
      }
      return;
    }

    final id = j['watchId'] as String?;
    if (id != null && id.isNotEmpty && !background) onOpenWatch?.call(id);
  }

  static Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Android 14+ gates the lock-screen takeover behind its own grant.
  Future<bool> requestFullScreenPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestFullScreenIntentPermission();
    return granted ?? true;
  }

  /// Android 13+ will not show anything until the user grants this.
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<bool> areEnabled() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }

  /// One notification summarising every new slot found for a watch.
  ///
  /// For a "call me" alert this rings instead, and returns the call so the
  /// caller can wait for the missed-call fallback.
  Future<IncomingCall?> notifySlots({
    required WatchConfig watch,
    required List<SlotHit> hits,
    required bool grouped,
    AlertStyle? styleOverride,
    CallSound? sound,
    int callSeconds = 45,
  }) async {
    await init();
    if (hits.isEmpty) return null;
    final style = styleOverride ?? watch.alertStyle;

    if (style == AlertStyle.call) {
      return ringCall(
        watch: watch,
        hits: hits,
        sound: sound ?? CallSound.all.first,
        seconds: callSeconds,
      );
    }

    if (!grouped) {
      for (final h in hits.take(5)) {
        await _show(
          id: _idFor('${watch.id}|${h.id}'),
          title: '${_dayLabel(h.when)} ${_hhmm(h.when)} — ${h.doctorName}',
          body: _typeLine(h, withCity: true),
          watchId: watch.id,
          url: h.bookingUrl,
          style: style,
        );
      }
      return null;
    }

    final first = hits.first;
    final more = hits.length - 1;
    final title = hits.length == 1
        ? '${tr.slotsCount(1)} ${watch.windowLabel}'
        : '${tr.slotsCount(hits.length)} ${watch.windowLabel}';

    final lines = hits
        .take(6)
        .map((h) =>
            '${_dayLabel(h.when)} ${_hhmm(h.when)} · ${h.doctorName}'
            '${h.city.isEmpty ? '' : ' (${h.city})'}')
        .toList();

    await _show(
      id: _idFor(watch.id),
      title: '${watch.title} — $title',
      body: more == 0
          ? '${_dayLabel(first.when)} ${_hhmm(first.when)} · ${first.doctorName}'
          : lines.first,
      lines: lines,
      watchId: watch.id,
      url: first.bookingUrl,
      style: style,
    );
    return null;
  }

  /// "Medecin generaliste · Premiere consultation · video": what kind of
  /// appointment it is, readable from the notification itself.
  static String _typeLine(SlotHit h, {bool withCity = false}) => [
        h.speciality,
        h.motive,
        if (h.telehealth) tr.teleShortOnline,
        if (withCity) h.city,
      ].where((s) => s.isNotEmpty).join(' · ');

  // ---------------------------------------------------------------------------
  // "Call me"
  // ---------------------------------------------------------------------------

  /// v2: ringtone stream. Android freezes a channel's sound settings when the
  /// channel is created, so changing the stream means new channel ids.
  static String _callChannelId(CallSound s) => 'call_${s.id}_v2';

  /// Calls ring on the phone's *ringtone* volume, the way WhatsApp and
  /// Messenger calls do, so they are heard even with notification sounds off.
  static const AudioAttributesUsage _callUsage =
      AudioAttributesUsage.notificationRingtone;

  Future<void> _ensureCallChannel(CallSound s) async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(AndroidNotificationChannel(
      _callChannelId(s),
      tr.chCall(s.label),
      description: tr.chCallDesc,
      importance: Importance.max,
      playSound: true,
      sound: _soundOf(s),
      audioAttributesUsage: _callUsage,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 800, 500, 800, 500, 800]),
    ));
  }

  static AndroidNotificationSound _soundOf(CallSound s) => s.raw != null
      ? RawResourceAndroidNotificationSound(s.raw)
      : UriAndroidNotificationSound(s.uri!);

  /// Rings like an incoming call until the user answers, refuses, or
  /// [seconds] elapse.
  ///
  /// Green ("Voir le RDV") opens the booking page. Red ("Refuser") and no
  /// answer both leave an ordinary notification behind, so nothing is lost.
  Future<IncomingCall> ringCall({
    required WatchConfig watch,
    required List<SlotHit> hits,
    required CallSound sound,
    required int seconds,
  }) async {
    await init();
    await _ensureCallChannel(sound);

    final first = hits.first;
    final call = IncomingCall(
      // Epoch seconds: unique per ring, and lets the ledger prune by age.
      callId: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      watchId: watch.id,
      watchTitle: watch.title,
      url: first.bookingUrl,
      doctorName: first.doctorName,
      speciality: first.speciality,
      motive: first.motive,
      city: first.city,
      when: first.when,
      telehealth: first.telehealth,
      slotCount: hits.length,
      fallbackTitle: hits.length == 1
          ? tr.slotAvailable(watch.title)
          : tr.slotsAvailableTitle(watch.title, tr.slotsCount(hits.length)),
      fallbackBody: '${_dayLabel(first.when)} ${_hhmm(first.when)} · '
          '${first.doctorName} · ${_typeLine(first)}',
    );

    final more = hits.length > 1
        ? '\n${tr.moreSlots(hits.length - 1)}'
        : '';

    await _plugin.show(
      call.callId,
      tr.callTitle('${_dayLabel(first.when)} ${_hhmm(first.when)}'),
      '${first.doctorName} · ${_typeLine(first)}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _callChannelId(sound),
          tr.chCall(sound.label),
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.call,
          visibility: NotificationVisibility.public,
          fullScreenIntent: true,
          ongoing: true,
          autoCancel: false,
          sound: _soundOf(sound),
          audioAttributesUsage: _callUsage,
          additionalFlags: Int32List.fromList(<int>[_flagInsistent]),
          timeoutAfter: seconds * 1000,
          styleInformation: BigTextStyleInformation(
            '${first.doctorName}\n${_typeLine(first, withCity: true)}$more',
          ),
          actions: [
            AndroidNotificationAction(
              'decline',
              tr.decline,
              titleColor: Color(0xFFD32F2F),
              cancelNotification: true,
              showsUserInterface: false,
            ),
            AndroidNotificationAction(
              'accept',
              tr.viewAppointment,
              titleColor: Color(0xFF2E7D32),
              cancelNotification: true,
              showsUserInterface: true,
            ),
          ],
        ),
      ),
      payload: jsonEncode(call.toJson()),
    );
    return call;
  }

  /// Green button: stop ringing and hand back the booking URL to open.
  ///
  /// Even if the call already timed out, answering still leads to the slot.
  Future<String> acceptCall(IncomingCall call) async {
    await init();
    await _plugin.cancel(call.callId);
    if (await CallLedger.claim(call.callId)) {
      await _logCall(call, JournalKind.callAccepted);
    }
    return call.url;
  }

  /// Red button: stop ringing, leave an ordinary notification.
  Future<void> declineCall(IncomingCall call) async {
    await init();
    await _plugin.cancel(call.callId);
    if (await CallLedger.claim(call.callId)) {
      await _showFallback(call, missed: false);
      await _logCall(call, JournalKind.callDeclined);
    }
  }

  /// Waits for the ring to run out; if nobody answered, leaves an ordinary
  /// notification. Safe to await from the background task.
  Future<void> awaitMissedCall(IncomingCall call, int seconds) async {
    await Future.delayed(Duration(seconds: seconds + 3));
    if (!await CallLedger.claim(call.callId)) return;
    await init();
    await _plugin.cancel(call.callId);
    await _showFallback(call, missed: true);
    await _logCall(call, JournalKind.callMissed);
  }

  /// Test calls from the settings screen have no watch and stay out of it.
  static Future<void> _logCall(IncomingCall call, JournalKind kind) async {
    if (call.watchId.isEmpty) return;
    await Journal.add(JournalEntry(
      at: DateTime.now(),
      kind: kind,
      title: call.watchTitle,
      detail: call.doctorName,
    ));
  }

  Future<void> _showFallback(IncomingCall call, {required bool missed}) async {
    await _show(
      id: _idFor('fallback|${call.callId}'),
      title: missed ? tr.missedCall(call.fallbackTitle) : call.fallbackTitle,
      body: call.fallbackBody,
      watchId: call.watchId,
      url: call.url,
      style: AlertStyle.normal,
    );
  }

  /// Rings with [sound] so the user can hear it and try both buttons.
  Future<IncomingCall> previewCall(CallSound sound, {int seconds = 20}) {
    final when = DateTime.now().add(const Duration(days: 1, hours: 2));
    final watch = WatchConfig(id: '', title: tr.sampleTest, kind: WatchKind.speciality);
    return ringCall(
      watch: watch,
      sound: sound,
      seconds: seconds,
      hits: [
        SlotHit(
          doctorKey: 'test',
          doctorName: tr.sampleDoctor,
          city: 'Lyon',
          address: '',
          motive: tr.sampleMotive,
          speciality: tr.sampleSpeciality,
          bookingUrl: 'https://www.doctolib.fr/',
          when: when,
        ),
      ],
    );
  }

  /// Fixed id: the status notification is always updated in place, never
  /// stacked.
  static const int _statusId = 424242;

  /// The permanent "everything is running" badge, in the spirit of a security
  /// app's status bar entry. Silent and low priority, rewritten after every
  /// check so the shade always carries the current state.
  Future<void> showStatus({
    required int activeWatches,
    required int totalWatches,
    required int slotCount,
    required DateTime? lastCheck,
    String? problem,
    List<String> lines = const [],
  }) async {
    await init();

    final when = _ago(lastCheck);
    final String title;
    if (problem != null) {
      title = tr.statusInterrupted;
    } else if (activeWatches == 0) {
      title = totalWatches == 0
          ? tr.statusNoAlerts
          : tr.statusAllPaused;
    } else {
      title = slotCount > 0
          ? tr.statusSlots(slotCount)
          : tr.statusActive;
    }

    final summary = problem ??
        [
          tr.statusActiveCount(activeWatches, totalWatches),
          tr.statusChecked(when),
        ].join(' · ');

    await _plugin.show(
      _statusId,
      title,
      summary,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _statusChannel.id,
          _statusChannel.name,
          channelDescription: _statusChannel.description,
          importance: Importance.low,
          priority: Priority.low,
          // Sticky, like an antivirus badge, but dismissible on Android 14+.
          ongoing: true,
          autoCancel: false,
          silent: true,
          showWhen: false,
          category: AndroidNotificationCategory.status,
          styleInformation: lines.isEmpty
              ? BigTextStyleInformation(summary, contentTitle: title)
              : InboxStyleInformation(
                  lines,
                  contentTitle: title,
                  summaryText: summary,
                ),
        ),
      ),
      payload: jsonEncode({'watchId': '', 'url': ''}),
    );
  }

  Future<void> hideStatus() async {
    await init();
    await _plugin.cancel(_statusId);
  }

  /// Fires a sample alert so the user can hear what a style actually does
  /// before trusting it with a real appointment.
  Future<void> showSample(AlertStyle style, {CallSound? sound}) async {
    await init();
    if (style == AlertStyle.call) {
      // A real ring with both buttons, short enough not to be a nuisance.
      const seconds = 20;
      final call = await previewCall(sound ?? CallSound.all.first, seconds: seconds);
      awaitMissedCall(call, seconds);
      return;
    }
    final when = DateTime.now().add(const Duration(days: 1, hours: 3));
    await _show(
      id: _idFor('sample'),
      title: tr.sampleTitle(style.label),
      body: '${_dayLabel(when)} ${_hhmm(when)} · ${tr.sampleDoctor} (${tr.sampleTest})',
      watchId: '',
      url: 'https://www.doctolib.fr/',
      style: style,
    );
  }

  static String _ago(DateTime? d) => I18n.ago(d);

  /// Low-importance note for errors and safety pauses.
  Future<void> notifyStatus(String title, String body) async {
    await init();
    await _plugin.show(
      _idFor('status:$title'),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _statusChannel.id,
          _statusChannel.name,
          channelDescription: _statusChannel.description,
          importance: Importance.low,
          priority: Priority.low,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String watchId,
    required String url,
    required AlertStyle style,
    List<String>? lines,
  }) async {
    final channel = switch (style) {
      AlertStyle.call => _slotsChannel,
      AlertStyle.discreet => _discreetChannel,
      AlertStyle.normal => _slotsChannel,
    };

    final details = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: switch (style) {
        AlertStyle.call => Importance.max,
        AlertStyle.discreet => Importance.low,
        AlertStyle.normal => Importance.high,
      },
      priority: switch (style) {
        AlertStyle.call => Priority.max,
        AlertStyle.discreet => Priority.low,
        AlertStyle.normal => Priority.high,
      },
      playSound: style != AlertStyle.discreet,
      category: style == AlertStyle.call
          ? AndroidNotificationCategory.call
          : AndroidNotificationCategory.reminder,
      // The three things that make it behave like an incoming call: take over
      // the lock screen, ring on the ringtone volume, and keep ringing (FLAG_INSISTENT)
      // until the notification is acted on.
      fullScreenIntent: style == AlertStyle.call,
      audioAttributesUsage: style == AlertStyle.call
          ? _callUsage
          : AudioAttributesUsage.notification,
      additionalFlags: style == AlertStyle.call
          ? Int32List.fromList(<int>[_flagInsistent])
          : null,
      vibrationPattern: style == AlertStyle.call
          ? Int64List.fromList([0, 600, 400, 600, 400, 600])
          : null,
      styleInformation: lines != null && lines.length > 1
          ? InboxStyleInformation(lines, contentTitle: title)
          : BigTextStyleInformation(body, contentTitle: title),
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: details),
      payload: jsonEncode({'watchId': watchId, 'url': url}),
    );
  }

  /// `Notification.FLAG_INSISTENT` — repeat the sound until the user responds.
  static const int _flagInsistent = 4;

  /// Stable small positive int from an arbitrary key.
  static int _idFor(String key) => key.hashCode & 0x7fffffff;

  static String _hhmm(DateTime d) => I18n.time(d);

  static String _dayLabel(DateTime d) => I18n.day(d, short: true);
}
