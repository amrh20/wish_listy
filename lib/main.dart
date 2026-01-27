import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (required for Firebase Messaging)
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
    // Continue app execution even if Firebase fails (e.g., on emulators without Firebase config)
  }

  // Register global background handler for FCM messages.
  // This must be done after Firebase.initializeApp and before runApp.
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('✅ FirebaseMessaging background handler registered');
  } catch (e) {
    debugPrint('⚠️ Failed to register FirebaseMessaging background handler: $e');
  }

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
  
  // Initialize AppStyles language cache (must be after LocalizationService.initialize)
  await AppStyles.initializeLanguageCache();
  
  // Initialize API service language code (must be after LocalizationService)
  final apiService = ApiService();
  await apiService.initializeLanguageCode();
  
  try {
    await authRepository.initialize().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('⚠️ Auth initialization timeout - continuing anyway');
      },
    );
  } catch (e) {
    debugPrint('❌ Error during auth initialization: $e - continuing anyway');
  }

  // Create NotificationsCubit instance immediately to ensure listener is registered
  // This must be done before runApp to ensure it's available when Socket connects
  final notificationsCubit = NotificationsCubit();
  debugPrint('✅ main.dart: NotificationsCubit created immediately');

  // Initialize FCM service so it can:
  // - keep the FCM token in sync with the backend
  // - handle notification taps from background/terminated states
  // - configure foreground presentation options
  try {
    await FcmService().initialize(
      authRepository: authRepository,
      notificationsCubit: notificationsCubit,
    );
    debugPrint('✅ FcmService initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Error initializing FcmService: $e');
  }

  runApp(
    MyApp(
      localizationService: localizationService,
      authRepository: authRepository,
      guestDataRepository: guestDataRepository,
      notificationsCubit: notificationsCubit,
    ),
  );
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
