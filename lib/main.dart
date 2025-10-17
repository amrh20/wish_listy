import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/localization_service.dart';
import 'services/auth_service.dart';
import 'utils/app_theme.dart';
import 'utils/app_routes.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create instances of services
  final localizationService = LocalizationService();
  final authService = AuthService();
  
  // Initialize services
  await localizationService.initialize();
  await authService.initialize();
  
  runApp(MyApp(
    localizationService: localizationService,
    authService: authService,
  ));
}

class MyApp extends StatelessWidget {
  final LocalizationService localizationService;
  final AuthService authService;
  
  const MyApp({
    super.key,
    required this.localizationService,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocalizationService>(
          create: (_) => localizationService,
        ),
        ChangeNotifierProvider<AuthService>(
          create: (_) => authService,
        ),
      ],
      child: Consumer<LocalizationService>(
        builder: (context, localization, child) {
          return MaterialApp(
            title: 'Wish Listy',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            locale: Locale(localization.currentLanguage),
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('ar', 'SA'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale != null && localization.isLanguageSupported(locale.languageCode)) {
                return locale;
              }
              return const Locale('en');
            },
            onGenerateRoute: AppRoutes.onGenerateRoute,
            routes: AppRoutes.routes,
            initialRoute: AppRoutes.splash,
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const SplashScreen(),
              );
            },
            restorationScopeId: 'wish_listy_app',
            navigatorKey: GlobalKey<NavigatorState>(),
            builder: (context, child) {
              // Apply RTL/LTR direction based on language
              return Directionality(
                textDirection: localization.textDirection,
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}