import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_providers.dart';
import 'views/home_view.dart';

class JpsExplorerApp extends ConsumerStatefulWidget {
  const JpsExplorerApp({super.key});

  @override
  ConsumerState<JpsExplorerApp> createState() => _JpsExplorerAppState();
}

class _JpsExplorerAppState extends ConsumerState<JpsExplorerApp> {
  @override
  void initState() {
    super.initState();
    loadSettings(ref);
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    final service = ref.read(nearbyNotificationProvider);
    await service.initialize();
    ref.read(nearbyEnabledProvider.notifier).state = service.isEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(appThemeProvider);
    final language = ref.watch(appLanguageProvider);

    final ThemeMode themeMode;
    switch (appTheme) {
      case AppTheme.light:
        themeMode = ThemeMode.light;
      case AppTheme.dark:
        themeMode = ThemeMode.dark;
      case AppTheme.system:
        themeMode = ThemeMode.system;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      locale: language != null ? Locale(language) : null,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ja'),
      ],
      home: const HomeView(),
    );
  }
}
