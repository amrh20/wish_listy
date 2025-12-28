import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/profile/presentation/models/home_models.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';
import 'package:wish_listy/features/profile/data/models/activity_model.dart';

class HomeController extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  bool _isFetching = false; // Prevent duplicate calls
  
  // Reactive variable for dashboard data
  final Rxn<DashboardModel> dashboardData = Rxn<DashboardModel>();
  
  final ApiService _apiService = ApiService();

  // Getters for convenience - always return non-null lists
  DashboardModel? get data => dashboardData.value;
  bool get isNewUser => dashboardData.value?.isNewUser ?? true;
  
  // Ensure these getters always return non-null lists, never null
  List<Wishlist> get myWishlists {
    final wishlists = dashboardData.value?.myWishlists;
    return wishlists ?? [];
  }
  
  List<Event> get upcomingOccasions {
    final occasions = dashboardData.value?.upcomingOccasions;
    return occasions ?? [];
  }
  
  List<Activity> get latestActivityPreview {
    final activities = dashboardData.value?.latestActivityPreview;
    return activities ?? [];
  }
  
  bool get isHeaderLoading => dashboardData.value == null && isLoading;

  Future<void> fetchDashboardData() async {
    // Prevent duplicate calls
    if (_isFetching) {
      return;
    }
    
    _isFetching = true;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getDashboardData();
      
      // Ensure response is a Map before parsing
      if (response is! Map<String, dynamic>) {
        throw Exception('Invalid response format: expected Map, got ${response.runtimeType}');
      }
      
      // Parse the response with error handling
      try {
        final dashboardModel = DashboardModel.fromJson(response);
        
        // Validate that all lists are non-null before setting
        if (dashboardModel.myWishlists == null || 
            dashboardModel.upcomingOccasions == null || 
            dashboardModel.latestActivityPreview == null) {
          throw Exception('Dashboard model contains null lists');
        }
        
        // Update reactive variable
        dashboardData.value = dashboardModel;
        
        isLoading = false;
        errorMessage = null;
        _isFetching = false;
        notifyListeners();
      } catch (parseError) {
        debugPrint('❌ HomeController: Error parsing dashboard data: $parseError');
        debugPrint('   Response data: $response');
        // Set empty dashboard model on error to prevent null errors
        dashboardData.value = DashboardModel(
          user: DashboardUser(firstName: 'User'),
          stats: DashboardStats(wishlistsCount: 0, unreadNotificationsCount: 0),
          myWishlists: [],
          upcomingOccasions: [],
          latestActivityPreview: [],
        );
        isLoading = false;
        errorMessage = 'Failed to parse dashboard data. Please try again.';
        _isFetching = false;
        notifyListeners();
      }
    } on ApiException catch (e) {
      isLoading = false;
      errorMessage = e.message;
      _isFetching = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ HomeController: Error loading dashboard data: $e');
      isLoading = false;
      errorMessage = 'Failed to load dashboard data. Please try again.';
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetchDashboardData();
  }
}

