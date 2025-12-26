import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/profile/presentation/models/home_models.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';

class HomeController extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  bool _isFetching = false; // Prevent duplicate calls
  
  // Reactive variable for dashboard data
  final Rxn<DashboardModel> dashboardData = Rxn<DashboardModel>();
  
  final ApiService _apiService = ApiService();

  // Getters for convenience
  DashboardModel? get data => dashboardData.value;
  bool get isNewUser => dashboardData.value?.isNewUser ?? true;
  List<Wishlist> get myWishlists => dashboardData.value?.myWishlists ?? [];
  List<Event> get upcomingOccasions => dashboardData.value?.upcomingOccasions ?? [];
  List<WishlistItem> get friendActivity => dashboardData.value?.friendActivity ?? [];
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
      
      // Parse the response
      final dashboardModel = DashboardModel.fromJson(response);
      
      // Update reactive variable
      dashboardData.value = dashboardModel;
      
      isLoading = false;
      errorMessage = null;
      _isFetching = false;
      notifyListeners();
    } on ApiException catch (e) {
      isLoading = false;
      errorMessage = e.message;
      _isFetching = false;
      notifyListeners();
    } catch (e) {
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

