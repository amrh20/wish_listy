import 'package:flutter/foundation.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/profile/data/models/activity_model.dart';

/// Activity Provider - Handles activity data with pagination
class ActivityProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Activity> _activities = [];
  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  final int _limit = 10;

  // Getters
  List<Activity> get activities => _activities;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasNextPage => _hasNextPage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Fetch activities with pagination
  /// [isRefresh] - If true, resets to page 1 and clears existing activities
  Future<void> fetchActivities({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _activities = [];
      _hasNextPage = true;
    }

    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch activities from /api/activities with pagination
      final response = await _apiService.getActivities(
        page: _currentPage,
        limit: _limit,
      );

      // Response structure: {success: true, data: [...], pagination: {...}}
      // or {data: [...], pagination: {...}}
      List<dynamic> activitiesList = [];
      Map<String, dynamic>? pagination;
      
      if (response is Map<String, dynamic>) {
        // Check if data is directly an array
        if (response['data'] != null && response['data'] is List) {
          activitiesList = response['data'] as List<dynamic>;
          pagination = response['pagination'] as Map<String, dynamic>?;
        } 
        // Check if data is an object containing activities array
        else if (response['data'] != null && response['data'] is Map) {
          final data = response['data'] as Map<String, dynamic>;
          final activities = data['activities'];
          final dataArray = data['data'];
          
          if (activities != null && activities is List) {
            activitiesList = activities as List<dynamic>;
          } else if (dataArray != null && dataArray is List) {
            activitiesList = dataArray as List<dynamic>;
          } else {
            activitiesList = [];
          }
          
          pagination = data['pagination'] as Map<String, dynamic>? ?? 
                      response['pagination'] as Map<String, dynamic>?;
        }
        // Fallback: try to get activities from root
        else {
          final activities = response['activities'];
          if (activities != null && activities is List) {
            activitiesList = activities as List<dynamic>;
          } else {
            activitiesList = [];
          }
          pagination = response['pagination'] as Map<String, dynamic>?;
        }
      }
      
      // Ensure activitiesList is always a List before calling .map()
      if (activitiesList is! List) {
        activitiesList = [];
      }
      
      // Parse activities with error handling
      final newActivities = activitiesList
          .map((item) {
            try {
              if (item is Map<String, dynamic>) {
                return Activity.fromJson(item);
              }
              return null;
            } catch (e) {
              return null;
            }
          })
          .whereType<Activity>()
          .toList();

      // Check pagination info from backend
      if (pagination != null) {
        final currentPage = pagination['currentPage'] as int? ?? 
                          pagination['page'] as int? ?? 
                          _currentPage;
        final totalPages = pagination['totalPages'] as int? ?? 
                          pagination['total_pages'] as int? ?? 1;
        _hasNextPage = pagination['hasNextPage'] as bool? ?? 
                      (currentPage < totalPages);
      } else {
        // If no pagination info, check if we got a full page
        _hasNextPage = newActivities.length >= _limit;
      }

      if (isRefresh) {
        _activities = newActivities;
      } else {
        _activities.addAll(newActivities);
      }

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e, stackTrace) {
      _isLoading = false;
      _errorMessage = 'Failed to load activities. Please try again.';
      notifyListeners();
    }
  }

  /// Load initial activities (first page) - Legacy method for backward compatibility
  /// Fetches 10 items from /api/activities endpoint with pagination
  @Deprecated('Use fetchActivities instead')
  Future<void> loadActivities({bool refresh = false}) async {
    await fetchActivities(isRefresh: refresh);
  }

  /// Load more activities (next page)
  /// Fetches next 10 items from /api/activities endpoint
  Future<void> loadMoreActivities() async {
    if (_isLoadingMore || !_hasNextPage) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final response = await _apiService.getActivities(
        page: _currentPage,
        limit: _limit,
      );

      // Response structure: {success: true, data: [...], pagination: {...}}
      List<dynamic> activitiesList = [];
      Map<String, dynamic>? pagination;
      
      if (response is Map<String, dynamic>) {
        // Check if data is directly an array
        if (response['data'] != null && response['data'] is List) {
          activitiesList = response['data'] as List<dynamic>;
          pagination = response['pagination'] as Map<String, dynamic>?;
        } 
        // Check if data is an object containing activities array
        else if (response['data'] != null && response['data'] is Map) {
          final data = response['data'] as Map<String, dynamic>;
          final activities = data['activities'];
          final dataArray = data['data'];
          
          if (activities != null && activities is List) {
            activitiesList = activities as List<dynamic>;
          } else if (dataArray != null && dataArray is List) {
            activitiesList = dataArray as List<dynamic>;
          } else {
            activitiesList = [];
          }
          
          pagination = data['pagination'] as Map<String, dynamic>? ?? 
                      response['pagination'] as Map<String, dynamic>?;
        }
        // Fallback: try to get activities from root
        else {
          final activities = response['activities'];
          if (activities != null && activities is List) {
            activitiesList = activities as List<dynamic>;
          } else {
            activitiesList = [];
          }
          pagination = response['pagination'] as Map<String, dynamic>?;
        }
      }
      
      // Ensure activitiesList is always a List before calling .map()
      if (activitiesList is! List) {
        activitiesList = [];
      }
      
      final newActivities = activitiesList
          .map((item) {
            try {
              if (item is Map<String, dynamic>) {
                return Activity.fromJson(item);
              }
              return null;
            } catch (e) {
              return null;
            }
          })
          .whereType<Activity>()
          .toList();

      // Check pagination info from backend
      if (pagination != null) {
        final currentPage = pagination['currentPage'] as int? ?? 
                          pagination['page'] as int? ?? 
                          _currentPage;
        final totalPages = pagination['totalPages'] as int? ?? 
                          pagination['total_pages'] as int? ?? 1;
        _hasNextPage = pagination['hasNextPage'] as bool? ?? 
                      (currentPage < totalPages);
      } else {
        // If no pagination info, check if we got a full page
        _hasNextPage = newActivities.length >= _limit;
      }

      _activities.addAll(newActivities);
      _isLoadingMore = false;
      notifyListeners();
    } catch (e, stackTrace) {
      _currentPage--; // Revert page on error
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Refresh activities (reset and load from page 1)
  Future<void> refresh() async {
    await fetchActivities(isRefresh: true);
  }

  /// Clear all activities
  void clear() {
    _activities = [];
    _currentPage = 1;
    _hasNextPage = true;
    _errorMessage = null;
    notifyListeners();
  }
}

