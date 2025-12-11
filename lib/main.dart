import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/localization_service.dart';
import 'features/auth/data/repository/auth_repository.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_routes.dart';
import 'core/widgets/splash_screen.dart';
import 'core/storage/adapters/wishlist_type_adapter.dart';
import 'core/storage/adapters/price_range_adapter.dart';
import 'core/storage/adapters/wishlist_item_adapter.dart';
import 'core/storage/adapters/wishlist_adapter.dart';
import 'features/wishlists/data/repository/guest_data_repository.dart';
import 'features/wishlists/data/models/wishlist_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for guest local storage
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(WishlistTypeAdapter());
  Hive.registerAdapter(WishlistVisibilityAdapter());
  Hive.registerAdapter(ItemPriorityAdapter());
  Hive.registerAdapter(ItemStatusAdapter());
  Hive.registerAdapter(PriceRangeAdapter());
  Hive.registerAdapter(WishlistItemAdapter());
  Hive.registerAdapter(WishlistAdapter());
  
  // Open Hive boxes for guest data
  await Hive.openBox<Wishlist>('guest_wishlists');
  await Hive.openBox<WishlistItem>('guest_wishlist_items');

  // Create instances of services
  final localizationService = LocalizationService();
  final authRepository = AuthRepository();
  final guestDataRepository = GuestDataRepository();

  // Initialize services
  await localizationService.initialize();
  await authRepository.initialize();

  runApp(
    MyApp(
      localizationService: localizationService,
      authRepository: authRepository,
      guestDataRepository: guestDataRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  final LocalizationService localizationService;
  final AuthRepository authRepository;
  final GuestDataRepository guestDataRepository;
  
  // Create navigatorKey once and reuse it across rebuilds
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const MyApp({
    super.key,
    required this.localizationService,
    required this.authRepository,
    required this.guestDataRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocalizationService>(
          create: (_) => localizationService,
        ),
        ChangeNotifierProvider<AuthRepository>(create: (_) => authRepository),
        Provider<GuestDataRepository>(create: (_) => guestDataRepository),
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
