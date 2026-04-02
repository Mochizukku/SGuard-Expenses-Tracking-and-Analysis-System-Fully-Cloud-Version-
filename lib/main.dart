import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/api_config.dart';
import 'config/firebase_options.dart';
import 'data/services/app_settings_controller.dart';
import 'presentation/pages/splashscreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Debug: Print API configuration on startup
  debugPrint(ApiConfig.getConfigInfo());

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AppSettingsController.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyImmersiveMode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyImmersiveMode();
    }
  }

  Future<void> _applyImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettingsData>(
      valueListenable: AppSettingsController.instance.settings,
      builder: (context, settings, _) {
        final accentColor = AppSettingsController.accentColorFromKey(
          settings.personalization.accentColorKey,
        );
        final textScale = settings.personalization.largeText ? 1.08 : 1.0;
        final pageTransitions = settings.personalization.reduceMotion
            ? const <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
                TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
              }
            : const <TargetPlatform, PageTransitionsBuilder>{};

        ThemeData buildTheme(Brightness brightness) {
          final scheme = ColorScheme.fromSeed(
            seedColor: accentColor,
            brightness: brightness,
          );
          return ThemeData(
            colorScheme: scheme,
            scaffoldBackgroundColor: scheme.surface,
            useMaterial3: true,
            pageTransitionsTheme: PageTransitionsTheme(builders: pageTransitions),
            textTheme: ThemeData(brightness: brightness).textTheme.apply(
                  fontSizeFactor: textScale,
                ),
          );
        }

        return MaterialApp(
          title: 'SGuard',
          debugShowCheckedModeBanner: false,
          themeMode: settings.personalization.themeMode,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          home: const SplashScreen(),
        );
      },
    );
  }
}
