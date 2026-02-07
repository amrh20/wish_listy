import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'core/services/localization_service.dart';
import 'core/services/api_service.dart';
import 'features/auth/data/repository/auth_repository.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_styles.dart';
import 'core/utils/app_routes.dart';
import 'core/widgets/splash_screen.dart';
import 'core/storage/adapters/wishlist_type_adapter.dart';
import 'core/storage/adapters/price_range_adapter.dart';
import 'core/storage/adapters/wishlist_item_adapter.dart';
import 'core/storage/adapters/wishlist_adapter.dart';
import 'features/wishlists/data/repository/guest_data_repository.dart';
import 'features/wishlists/data/models/wishlist_model.dart';
import 'features/notifications/presentation/cubit/notifications_cubit.dart';
import 'features/profile/presentation/providers/activity_provider.dart';
import 'core/services/deep_link_service.dart';
import 'core/navigation/app_route_observer.dart';
import 'core/services/fcm_service.dart';

/// Print debug token for App Check (waits 5 seconds before trying)
Future<void> _printDebugToken() async {
  // Wait 5 seconds for App Check to initialize
  await Future.delayed(const Duration(seconds: 5));
  
  try {
    final token = await FirebaseAppCheck.instance.getToken();
    if (token != null && token.isNotEmpty) {
      // Print in a very visible format
    }
  } catch (e) {
  }
}

/// Initialize Firebase App Check with Play Integrity provider
/// Handles debug token for development builds
Future<void> _initializeAppCheck() async {
  if (kDebugMode) {
    // For development: Use debug provider to bypass verification
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
      
      
      // Wait 5 seconds then try to get and print debug token
      _printDebugToken();
    } catch (e) {
      // Continue execution - Phone Auth might still work if App Check isn't strictly enforced
    }
  } else {
    // For production: Use Play Integrity (Android) and DeviceCheck/AppAttest (iOS)
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );
    } catch (e) {
      // In production, this is more critical, but we'll continue anyway
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (required for Firebase Messaging)
  // MUST use firebase_options.dart to ensure correct apiKey
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Continue app execution even if Firebase fails (e.g., on emulators without Firebase config)
  }

  // Initialize Firebase App Check with Play Integrity provider
  // MUST happen AFTER Firebase.initializeApp() and BEFORE runApp()
  try {
    await _initializeAppCheck();
  } catch (e) {
    // Continue app execution even if App Check fails
  }

  // Register global background handler for FCM messages.
  // This must be done after Firebase.initializeApp and before runApp.
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
  }

  // Initialize Hive for guest local storage (must run first)
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(WishlistTypeAdapter());
  Hive.registerAdapter(WishlistVisibilityAdapter());
  Hive.registerAdapter(ItemPriorityAdapter());
  Hive.registerAdapter(ItemStatusAdapter());
  Hive.registerAdapter(PriceRangeAdapter());
  Hive.registerAdapter(WishlistItemAdapter());
  Hive.registerAdapter(WishlistAdapter());

  // Create instances of services
  final localizationService = LocalizationService();
  final authRepository = AuthRepository();
  final guestDataRepository = GuestDataRepository();

  // Phase 1: Run Hive openBox and LocalizationService in parallel
  await Future.wait([
    Hive.openBox<Wishlist>('guest_wishlists'),
    Hive.openBox<WishlistItem>('guest_wishlist_items'),
    localizationService.initialize(),
  ]);

  // Phase 2: Use language from LocalizationService (no extra SharedPreferences read)
  AppStyles.updateLanguageCache(localizationService.currentLanguage);
  final apiService = ApiService();
  apiService.setLanguageCode(localizationService.currentLanguage);

  try {
    await authRepository.initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
      },
    );
  } catch (e) {
  }

  // Create NotificationsCubit instance immediately to ensure listener is registered
  final notificationsCubit = NotificationsCubit();

  // Prevent black screen on build errors - show helpful error widget instead
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                details.exception.toString(),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(
    MyApp(
      localizationService: localizationService,
      authRepository: authRepository,
      guestDataRepository: guestDataRepository,
      notificationsCubit: notificationsCubit,
    ),
  );

  // Phase 1: Defer FCM init so it doesn't block the first frame
  // Initialize FCM after runApp() but ensure auth state is ready
  // Note: authRepository.initialize() already completed above, so isAuthenticated is accurate
  FcmService()
      .initialize(
        authRepository: authRepository,
        notificationsCubit: notificationsCubit,
      )
      .then((_) => debugPrint('✅ FcmService initialized successfully'))
      .catchError((e) => debugPrint('⚠️ Error initializing FcmService: $e'));
}

class MyApp extends StatefulWidget {
  final LocalizationService localizationService;
  final AuthRepository authRepository;
  final GuestDataRepository guestDataRepository;
  final NotificationsCubit notificationsCubit;
  
  // Create navigatorKey once and reuse it across rebuilds
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const MyApp({
    super.key,
    required this.localizationService,
    required this.authRepository,
    required this.guestDataRepository,
    required this.notificationsCubit,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize deep link handler after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService().initialize(MyApp.navigatorKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocalizationService>(
          create: (_) => widget.localizationService,
        ),
        ChangeNotifierProvider<AuthRepository>(create: (_) => widget.authRepository),
        Provider<GuestDataRepository>(create: (_) => widget.guestDataRepository),
        BlocProvider<NotificationsCubit>.value(
          value: widget.notificationsCubit, // Use the pre-created instance
        ),
        ChangeNotifierProvider<ActivityProvider>(
          create: (_) => ActivityProvider(),
        ),
      ],
      child: Consumer<LocalizationService>(
        builder: (context, localization, child) {
          final currentLocale = Locale(localization.currentLanguage);
          return MaterialApp(
            title: 'Wish Listy',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(locale: currentLocale),
            darkTheme: AppTheme.darkTheme(locale: currentLocale),
            themeMode: ThemeMode.system,
            locale: currentLocale,
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
            navigatorKey: MyApp.navigatorKey,
            navigatorObservers: [appRouteObserver],
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
