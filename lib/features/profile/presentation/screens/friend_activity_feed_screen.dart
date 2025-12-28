import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/profile/presentation/models/home_models.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

class FriendActivityFeedScreen extends StatefulWidget {
  const FriendActivityFeedScreen({super.key});

  @override
  State<FriendActivityFeedScreen> createState() => _FriendActivityFeedScreenState();
}

class _FriendActivityFeedScreenState extends State<FriendActivityFeedScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<FriendActivity> _allActivities = []; // All activities from API
  List<FriendActivity> _displayedActivities = []; // Activities currently displayed
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 10;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreActivities();
      }
    }
  }

  Future<void> _loadActivities({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _allActivities = [];
        _displayedActivities = [];
        _hasMore = true;
      });
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getFriendActivity();

      final data = response['data'] as Map<String, dynamic>? ?? response;
      final activityData = data['friendActivity'] as List<dynamic>? ?? [];
      
      final allActivities = activityData
          .map((item) => _convertItemToActivity(
                WishlistItem.fromJson(item as Map<String, dynamic>),
              ))
          .toList();

      setState(() {
        _allActivities = allActivities;
        _currentPage = 1;
        _updateDisplayedActivities();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load activities. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _updateDisplayedActivities() {
    final startIndex = 0;
    final endIndex = (_currentPage * _limit).clamp(0, _allActivities.length);
    _displayedActivities = _allActivities.sublist(startIndex, endIndex);
    _hasMore = endIndex < _allActivities.length;
  }

  Future<void> _loadMoreActivities() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate loading delay for better UX
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _currentPage++;
      _updateDisplayedActivities();
      _isLoadingMore = false;
    });
  }

  FriendActivity _convertItemToActivity(WishlistItem item) {
    // Get owner info from nested wishlist.owner
    final ownerName = item.wishlist?.owner?.fullName ?? 'Someone';
    final ownerId = item.wishlist?.owner?.id;
    final ownerImage = item.wishlist?.owner?.profileImage;

    // Format action text
    final action = 'added ${item.name} to their wishlist';
    final timeAgo = _calculateTimeAgo(item.createdAt);

    return FriendActivity(
      id: item.id,
      friendName: ownerName,
      friendId: ownerId,
      action: action,
      timeAgo: timeAgo,
      imageUrl: item.imageUrl,
      avatarUrl: ownerImage,
    );
  }

  String _calculateTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Happening Now ⚡',
          style: AppStyles.headingMedium,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadActivities(refresh: true),
        color: AppColors.primary,
        child: _isLoading && _displayedActivities.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
                : _errorMessage != null && _displayedActivities.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadActivities(refresh: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _displayedActivities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No activities yet',
                              style: AppStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: _displayedActivities.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _displayedActivities.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }

                          final activity = _displayedActivities[index];
                          return _ActivityTile(activity: activity);
                        },
                      ),
      ),
    );
  }
}

/// Activity Tile Widget (reused from active_dashboard.dart)
class _ActivityTile extends StatelessWidget {
  final FriendActivity activity;

  const _ActivityTile({required this.activity});

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Extract item name from action string (e.g., "added watch to their wishlist" -> "watch")
    final itemName = activity.action
        .replaceAll(RegExp(r'^added '), '')
        .replaceAll(RegExp(r' to their wishlist$'), '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          GestureDetector(
            onTap: activity.friendId != null
                ? () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.friendProfile,
                      arguments: {'userId': activity.friendId},
                    );
                  }
                : null,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: activity.avatarUrl != null
                  ? NetworkImage(activity.avatarUrl!)
                  : null,
              child: activity.avatarUrl == null
                  ? Text(
                      _getInitials(activity.friendName),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: activity.friendName,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: activity.action,
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.timeAgo,
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Item Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.card_giftcard_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

