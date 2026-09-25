import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'engine.dart';
import 'i18n.dart';
import 'notifications.dart';
import 'store.dart';

const String kPeriodicTask = 'rdv-watch-periodic';
const String kUniqueName = 'rdv-watch-periodic-unique';

/// Entry point of the background isolate.
///
/// This runs with no Flutter UI attached, so everything it needs (preferences,
/// notification channels) has to be re-initialised from scratch.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final store = Store();
      // Notifications are written here, so they need the user's language.
      await I18n.apply((await store.loadSettings()).language);
      await Notifications.instance.init();
      final engine = CheckEngine(store: store);
      await engine.runAll(notify: true, awaitCalls: true, background: true);
      return true;
    } catch (e) {
      // Returning false makes WorkManager retry with its own backoff, which is
      // the right behaviour for a transient network failure.
      debugPrint('Background check failed: $e');
      return false;
    }
  });
}

class BackgroundScheduler {
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  /// (Re)registers the periodic check.
  ///
  /// Android clamps periodic work to a 15 minute minimum and will happily run
  /// it later than asked when the device is dozing; that is a platform
  /// guarantee we cannot argue with, so the UI says so plainly.
  static Future<void> schedule(int minutes) async {
    final period = Duration(minutes: minutes < 15 ? 15 : minutes);
    await Workmanager().cancelByUniqueName(kUniqueName);
    await Workmanager().registerPeriodicTask(
      kUniqueName,
      kPeriodicTask,
      frequency: period,
      initialDelay: const Duration(minutes: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 10),
    );
  }

  static Future<void> cancel() => Workmanager().cancelByUniqueName(kUniqueName);
}
