import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/services/localization_service.dart';
import 'features/auth/data/repository/auth_repository.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_routes.dart';
import 'core/widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create instances of services
  final localizationService = LocalizationService();
  final authRepository = AuthRepository();

  // Initialize services
  await localizationService.initialize();
  await authRepository.initialize();

  runApp(
    MyApp(
      localizationService: localizationService,
      authRepository: authRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  final LocalizationService localizationService;
  final AuthRepository authRepository;
  
  // Create navigatorKey once and reuse it across rebuilds
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const MyApp({
    super.key,
    required this.localizationService,
    required this.authRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocalizationService>(
          create: (_) => localizationService,
        ),
        ChangeNotifierProvider<AuthRepository>(create: (_) => authRepository),
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
            supportedLocales: const [Locale('en', 'US'), Locale('ar', 'SA')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale != null &&
                  localization.isLanguageSupported(locale.languageCode)) {
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
            navigatorKey: navigatorKey,
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
