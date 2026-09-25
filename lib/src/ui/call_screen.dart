import 'dart:async';

import 'package:flutter/material.dart';

import '../calls.dart';
import '../notifications.dart';
import 'common.dart';
import '../i18n.dart';

/// The incoming-call screen, shown over the lock screen when a "call me"
/// alert rings.
///
/// The ringing itself comes from the notification, so it keeps going whatever
/// happens to this screen, and stops the instant either button is pressed:
///
/// * green ("Voir le RDV") opens the Doctolib booking page straight away;
/// * red ("Refuser") stops the ring and leaves an ordinary notification, so
///   the slot is still one tap away later.
///
/// Doing nothing lets it ring out; the same ordinary notification is left.
class CallScreen extends StatefulWidget {
  const CallScreen({super.key, required this.call, required this.seconds});

  final IncomingCall call;
  final int seconds;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  Timer? _ticker;
  late int _left = _remaining();
  bool _busy = false;

  int _remaining() {
    // The call may have been ringing for a while before this screen opened.
    final started =
        DateTime.fromMillisecondsSinceEpoch(widget.call.callId * 1000);
    final gone = DateTime.now().difference(started).inSeconds;
    return (widget.seconds - gone).clamp(0, widget.seconds);
  }

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _left = _remaining());
      if (_left <= 0) {
        _ticker?.cancel();
        // Rang out. The missed-call notification is posted by whoever started
        // the ring; this screen just gets out of the way.
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    final url = await Notifications.instance.acceptCall(widget.call);
    if (!mounted) return;
    Navigator.of(context).pop();
    await openBooking(context, url);
  }

  Future<void> _decline() async {
    if (_busy) return;
    setState(() => _busy = true);
    await Notifications.instance.declineCall(widget.call);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.call;
    const bg = Color(0xFF0E1B24);
    const fg = Colors.white;
    final dim = Colors.white.withValues(alpha: 0.65);

    return PopScope(
      // The back gesture counts as "not now": same as refusing.
      canPop: _busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _decline();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Column(
              children: [
                Text(
                  tr.callAvailable,
                  style: TextStyle(color: dim, fontSize: 15, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  c.watchTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: dim, fontSize: 13),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) {
                    final t = _pulse.value;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120 + 60 * t,
                          height: 120 + 60 * t,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.12 * (1 - t)),
                          ),
                        ),
                        child!,
                      ],
                    );
                  },
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00778B),
                    ),
                    child: Icon(
                      c.telehealth ? Icons.videocam : Icons.medical_services,
                      color: fg,
                      size: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  c.doctorName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: fg,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tr.callWhen(dayLabel(c.when), hhmm(c.when)),
                  style: const TextStyle(
                    color: fg,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                // The appointment type, in grey with a dot, as everywhere else.
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (c.speciality.isNotEmpty) _tag(c.speciality),
                    if (c.motive.isNotEmpty) _tag(c.motive),
                    if (c.telehealth) _tag(tr.video),
                    if (c.city.isNotEmpty) _tag(c.city),
                  ],
                ),
                if (c.slotCount > 1) ...[
                  const SizedBox(height: 12),
                  Text(
                    tr.moreSlots(c.slotCount - 1),
                    style: TextStyle(color: dim, fontSize: 13),
                  ),
                ],
                const Spacer(),
                Text(
                  tr.callRingingLeft(_left),
                  style: TextStyle(color: dim, fontSize: 12),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _roundButton(
                      color: const Color(0xFFD32F2F),
                      icon: Icons.call_end,
                      label: tr.decline,
                      onTap: _decline,
                    ),
                    _roundButton(
                      color: const Color(0xFF2E7D32),
                      icon: Icons.call,
                      label: tr.viewAppointment,
                      onTap: _accept,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
            ),
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _roundButton({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      Column(
        children: [
          Material(
            color: color,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _busy ? null : onTap,
              child: SizedBox(
                width: 76,
                height: 76,
                child: Icon(icon, color: Colors.white, size: 34),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      );
}
