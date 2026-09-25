import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/background.dart';
import 'src/calls.dart';
import 'src/i18n.dart';
import 'src/notifications.dart';
import 'src/store.dart';
import 'src/ui/app_state.dart';
import 'src/ui/call_screen.dart';
import 'src/ui/home_page.dart';
import 'src/ui/onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Language first: notification channels are named at init, in that language.
  await I18n.apply((await Store().loadSettings()).language);
  await Notifications.instance.init();
  await BackgroundScheduler.init();

  final state = AppState();
  await state.load();
  await BackgroundScheduler.schedule(state.settings.intervalMinutes);

  runApp(RdvWatchApp(state: state));
}

class RdvWatchApp extends StatefulWidget {
  const RdvWatchApp({super.key, required this.state});

  final AppState state;

  @override
  State<RdvWatchApp> createState() => _RdvWatchAppState();
}

class _RdvWatchAppState extends State<RdvWatchApp> with WidgetsBindingObserver {
  /// Lets notification callbacks, which have no BuildContext, open screens.
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Notifications.instance.onShowCall = _showCall;
    // A call answered from the lock screen may be what launched the app.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Notifications.instance.processLaunch(),
    );
  }

  void _showCall(IncomingCall call) {
    final nav = _navigator.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CallScreen(
        call: call,
        seconds: widget.state.settings.callSeconds,
      ),
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The background isolate writes results while the UI is away.
    if (state == AppLifecycleState.resumed) widget.state.reloadFromDisk();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00778B),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00778B),
      brightness: Brightness.dark,
    );

    // Rebuilt whenever settings change, so a new language or theme applies
    // at once: Arabic flips the whole layout right-to-left through the locale.
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) => MaterialApp(
        navigatorKey: _navigator,
        onGenerateTitle: (_) => tr.appTitle,
        debugShowCheckedModeBanner: false,
        theme: _theme(scheme),
        darkTheme: _theme(darkScheme),
        themeMode: switch (widget.state.settings.themeMode) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        },
        locale: I18n.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: widget.state.settings.onboardingDone
            ? HomePage(state: widget.state)
            : OnboardingPage(
                state: widget.state,
                onDone: () => setState(() {}),
              ),
      ),
    );
  }

  ThemeData _theme(ColorScheme scheme) => ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          surfaceTintColor: scheme.surfaceTint,
        ),
      );
}
