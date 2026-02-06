import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/widgets/custom_text_field.dart';
import 'package:wish_listy/core/widgets/unified_page_header.dart';
import 'package:wish_listy/core/widgets/unified_tab_bar.dart';
import 'package:wish_listy/core/widgets/unified_page_container.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/theme/app_theme.dart' as theme;
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/friends/data/repository/friends_repository.dart';
import 'package:wish_listy/features/friends/data/models/friendship_model.dart';
import 'package:wish_listy/features/notifications/presentation/cubit/notifications_cubit.dart';

class FriendsScreen extends StatefulWidget {
  final int? initialTabIndex;
  
  const FriendsScreen({super.key, this.initialTabIndex});

  @override
  FriendsScreenState createState() => FriendsScreenState();
}

class FriendsScreenState extends State<FriendsScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Repository
  final _friendsRepository = FriendsRepository();

  // Friends list state
  List<Friend> _friends = [];
  bool _isLoadingFriends = false;
  String? _friendsError;

  // Friend requests state
  List<FriendRequest> _friendRequests = [];
  bool _isLoadingRequests = false;
  String? _requestsError;

  // Pagination state
  int _currentPage = 1;
  int _totalFriends = 0;
  bool _hasMoreFriends = true;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMoreFriends = false;

  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTabIndex ?? 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialIndex);
    _initializeAnimations();
    _startAnimations();
    _searchController.addListener(_onSearchChanged);
    
    // Set up scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  /// Switch to a specific tab programmatically
  void switchToTab(int index) {
    if (index >= 0 && index < _tabController.length) {
      _tabController.animateTo(index);
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load data when screen becomes visible (is current route)
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (isCurrent && !_hasLoadedOnce) {
      _hasLoadedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadFriends();
          _loadFriendRequests();
        }
      });
    }
  }

  void _onScroll() {
    // Detect when user scrolls to bottom to load more friends
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMoreFriends &&
        _hasMoreFriends &&
        !_isLoadingFriends) {
      _loadMoreFriends();
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _animationController.forward();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Keep alive
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          body: UnifiedPageBackground(
            child: DecorativeBackground(
              showGifts: false,
              child: Column(
                children: [
                  // Unified Page Header with Integrated Tabs
                  UnifiedPageHeader(
                    title: localization.translate('ui.friends'),

                    showSearch: true,
                    searchHint: localization.translate('ui.searchFriends'),
                    searchController: _searchController,
                    onSearchChanged: (query) {
                      _onSearchChanged();
                    },
                    actions: [
                      HeaderAction(
                        icon: Icons.add_rounded,
                        iconColor: AppColors.primary,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.addFriend,
                          );
                        },
                      ),
                    ],
                    tabs: [
                      UnifiedTab(
                        label: localization.translate('ui.myFriends'),
                        icon: Icons.people_rounded,
                      ),
                      UnifiedTab(
                        label: localization.translate('ui.requests'),
                      ),
                    ],
                    selectedTabIndex: _tabController.index,
                    onTabChanged: (index) {
                      _tabController.animateTo(index);
                      setState(() {});
                    },
                    selectedTabColor: AppColors.primary,
                  ),

                  // Tab Content in rounded container
                  Expanded(
                    child: UnifiedPageContainer(
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildMyFriendsTab(localization),
                                _buildFriendRequestsTab(localization),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildMyFriendsTab(LocalizationService localization) {
    // Show loading state
    if (_isLoadingFriends && _friends.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state
    if (_friendsError != null && _friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _friendsError!,
              style: AppStyles.bodyMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Retry',
              onPressed: () => _loadFriends(resetPage: true),
              variant: ButtonVariant.primary,
            ),
          ],
        ),
      );
    }

    final filteredFriends = _getFilteredFriends();

    return RefreshIndicator(
      onRefresh: _refreshFriends,
      color: AppColors.primary,
      child: filteredFriends.isEmpty
          ? _buildEmptyState()
          : AnimationLimiter(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: filteredFriends.length +
                    (_isLoadingMoreFriends ? 1 : 0) +
                    1, // +1 for bottom padding
                itemBuilder: (context, index) {
                  // Loading indicator at bottom for pagination
                  if (index == filteredFriends.length) {
                    if (_isLoadingMoreFriends) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return const SizedBox(
                      height: 100,
                    ); // Bottom padding for FAB
                  }
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildFriendCard(
                          filteredFriends[index],
                          localization,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyStateInline(LocalizationService localization) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(36),
            ),
            child: Icon(
              Icons.people_outline,
              size: 34,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? localization.translate('friends.noFriendsYet')
                : localization.translate('friends.noFriendsFound'),
            style: AppStyles.headingMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            _searchQuery.isEmpty
                ? localization.translate('friends.startConnectingWithFriends')
                : localization.translate('friends.tryAdjustingSearchTerms'),
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 18),
            CustomButton(
              text: localization.translate('friends.addFriends'),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.addFriend,
                );
              },
              variant: ButtonVariant.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFriendRequestsTab(LocalizationService localization) {
    // Show loading state
    if (_isLoadingRequests && _friendRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state
    if (_requestsError != null && _friendRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _requestsError!,
              style: AppStyles.bodyMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Retry',
              onPressed: _loadFriendRequests,
              variant: ButtonVariant.primary,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshFriendRequests,
      color: AppColors.primary,
      child: _friendRequests.isEmpty
          ? _buildEmptyFriendRequests()
          : AnimationLimiter(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _friendRequests.length + 1,
                itemBuilder: (context, index) {
                  // Last item: show "Add Friend" button under the list
                  if (index == _friendRequests.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 100),
                      child: Center(
                        child: CustomButton(
                          text: localization.translate('friends.addFriend'),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.addFriend,
                            );
                          },
                          variant: ButtonVariant.primary,
                        ),
                      ),
                    );
                  }
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildFriendRequestCard(_friendRequests[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildFriendCard(Friend friend, LocalizationService localization) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewFriendProfile(friend),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.secondary.withValues(
                    alpha: 0.1,
                  ),
                  backgroundImage: friend.profileImage != null
                      ? NetworkImage(friend.profileImage!)
                      : null,
                  child: friend.profileImage == null
                      ? Text(
                          friend.fullName.isNotEmpty
                              ? friend.fullName[0].toUpperCase()
                              : (friend.handle != null && friend.handle!.isNotEmpty)
                                  ? friend.handle![0].toUpperCase()
                                  : '?',
                          style: AppStyles.headingSmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),

                const SizedBox(width: 12),

                // Friend Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.fullName.isNotEmpty
                            ? friend.fullName
                            : friend.getDisplayHandle(),
                        style: AppStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (friend.fullName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          friend.getDisplayHandle(),
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.favorite_outline,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${friend.wishlistCount} ${localization.translate('ui.wishlists')}',
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow icon to indicate clickable
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendRequestCard(FriendRequest request) {
    final fromUser = request.from;
    final senderName = fromUser.fullName.isNotEmpty
        ? fromUser.fullName
        : fromUser.getDisplayHandle();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Clickable Profile Picture
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateToFriendProfile(fromUser.id),
                    borderRadius: BorderRadius.circular(24),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                      backgroundImage: fromUser.profileImage != null
                          ? NetworkImage(fromUser.profileImage!)
                          : null,
                      child: fromUser.profileImage == null
                          ? Text(
                              senderName.isNotEmpty
                                  ? senderName[0].toUpperCase()
                                  : '?',
                              style: AppStyles.bodyLarge.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Request Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clickable Name
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _navigateToFriendProfile(fromUser.id),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              senderName,
                              style: AppStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (fromUser.fullName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          fromUser.getDisplayHandle(),
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Time
                Text(
                  _formatRequestTime(request.createdAt),
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => _handleFriendRequest(request, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error.withOpacity(0.5),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        Provider.of<LocalizationService>(context, listen: false).translate('dialogs.decline'),
                        style: AppStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => _handleFriendRequest(request, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        Provider.of<LocalizationService>(context, listen: false).translate('dialogs.accept'),
                        style: AppStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    // Important: Empty state still needs to be scrollable so RefreshIndicator works.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: theme.AppTheme.spacing32,
                  vertical: theme.AppTheme.spacing40,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        Icons.people_outline,
                        size: 40,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: theme.AppTheme.spacing16),
                    Consumer<LocalizationService>(
                      builder: (context, localization, child) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _searchQuery.isEmpty
                                  ? localization.translate('friends.noFriendsYet')
                                  : localization.translate('friends.noFriendsFound'),
                              style: AppStyles.headingMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: theme.AppTheme.spacing12),
                            Text(
                              _searchQuery.isEmpty
                                  ? localization.translate('friends.startConnectingWithFriends')
                                  : localization.translate('friends.tryAdjustingSearchTerms'),
                              style: AppStyles.bodyMedium.copyWith(
                                color: AppColors.textTertiary,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: theme.AppTheme.spacing24),
                              CustomButton(
                                text: localization.translate('friends.addFriends'),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.addFriend,
                                  );
                                },
                                variant: ButtonVariant.gradient,
                                gradientColors: [
                                  AppColors.secondary,
                                  AppColors.primary,
                                ],
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyFriendRequests() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.person_add_outlined,
              size: 60,
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 24),
          Consumer<LocalizationService>(
            builder: (context, localization, child) {
              return Column(
                children: [
                  Text(
                    localization.translate('friends.noFriendRequests'),
                    style: AppStyles.headingMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localization.translate('friends.noFriendRequestsDescription'),
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: localization.translate('friends.addFriend'),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.addFriend,
                      );
                    },
                    variant: ButtonVariant.primary,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper Methods
  List<Friend> _getFilteredFriends() {
    if (_searchQuery.isEmpty) return _friends;

    return _friends.where((friend) {
      final fullName = friend.fullName.toLowerCase();
      final handle = (friend.handle ?? '').toLowerCase();
      return fullName.contains(_searchQuery) ||
          handle.contains(_searchQuery);
    }).toList();
  }

  String _formatRequestTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Load friends from API
  Future<void> _loadFriends({bool resetPage = false, bool forceShowLoading = false}) async {
    // Don't make API calls for guest users
    final authService = Provider.of<AuthRepository>(context, listen: false);
    if (authService.isGuest) {
      debugPrint('⚠️ FriendsScreen: Skipping API call for guest user');
      return;
    }

    if (resetPage) {
      setState(() {
        _currentPage = 1;
        _hasMoreFriends = true;
      });
    }

    if (_isLoadingFriends || (_isLoadingMoreFriends && !resetPage)) return;

    // Smart Loading: Only show loading if data doesn't exist yet
    // If data exists, refresh in background without showing loading indicator
    final hasExistingData = _friends.isNotEmpty;
    if (!hasExistingData || forceShowLoading) {
      setState(() {
        if (resetPage) {
          _isLoadingFriends = true;
        } else {
          _isLoadingMoreFriends = true;
        }
        _friendsError = null;
      });
    } else {
      debugPrint('🔄 FriendsScreen: Background refresh (no loading indicator)');
      // Still clear error message
      if (_friendsError != null) {
        setState(() {
          _friendsError = null;
        });
      }
    }

    try {
      final response = await _friendsRepository.getFriends(
        page: _currentPage,
        limit: 10,
      );

      if (!mounted) return;

      final friends = response['friends'] as List<Friend>;
      final total = response['total'] as int;
      final currentPage = response['page'] as int;

      setState(() {
        if (resetPage || currentPage == 1) {
          _friends = friends;
        } else {
          _friends.addAll(friends);
        }
        _totalFriends = total;
        _currentPage = currentPage;
        _hasMoreFriends = _friends.length < total;
        _isLoadingFriends = false;
        _isLoadingMoreFriends = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _friendsError = e.message;
        _isLoadingFriends = false;
        _isLoadingMoreFriends = false;
      });
    } catch (e) {
      if (!mounted) return;
      final localization = Provider.of<LocalizationService>(context, listen: false);
      setState(() {
        _friendsError = localization.translate('friends.failedToLoadFriends');
        _isLoadingFriends = false;
        _isLoadingMoreFriends = false;
      });
    }
  }

  /// Load more friends (pagination)
  Future<void> _loadMoreFriends() async {
    if (!_hasMoreFriends || _isLoadingMoreFriends || _isLoadingFriends) return;

    setState(() {
      _currentPage++;
    });

    await _loadFriends();
  }

  /// Load friend requests from API
  /// Refresh friends and friend requests data
  /// This method is called when the Friends tab is tapped
  void refreshFriends() {
    debugPrint('🔄 FriendsScreen: Refreshing friends data...');
    _loadFriends(resetPage: true);
    _loadFriendRequests();
  }

  Future<void> _loadFriendRequests({bool forceShowLoading = false}) async {
    // Don't make API calls for guest users
    final authService = Provider.of<AuthRepository>(context, listen: false);
    if (authService.isGuest) {
      debugPrint('⚠️ FriendsScreen: Skipping friend requests API call for guest user');
      return;
    }

    // Smart Loading: Only show loading if data doesn't exist yet
    final hasExistingData = _friendRequests.isNotEmpty;
    if (!hasExistingData || forceShowLoading) {
      setState(() {
        _isLoadingRequests = true;
        _requestsError = null;
      });
    } else {
      debugPrint('🔄 FriendsScreen: Background refresh requests (no loading indicator)');
      if (_requestsError != null) {
        setState(() {
          _requestsError = null;
        });
      }
    }

    try {
      final requests = await _friendsRepository.getFriendRequests();

      if (!mounted) return;

      setState(() {
        _friendRequests = requests;
        _isLoadingRequests = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _requestsError = e.message;
        _isLoadingRequests = false;
      });
    } catch (e) {
      if (!mounted) return;
      final localization = Provider.of<LocalizationService>(context, listen: false);
      setState(() {
        _requestsError = localization.translate('friends.failedToLoadFriendRequests');
        _isLoadingRequests = false;
      });
    }
  }

  // Action Handlers
  Future<void> _handleFriendRequest(FriendRequest request, bool accept) async {
    try {
      if (accept) {
        await _friendsRepository.acceptFriendRequest(requestId: request.id);
      } else {
        await _friendsRepository.rejectFriendRequest(requestId: request.id);
      }

      if (!mounted) return;

      // Remove request from list
      setState(() {
        _friendRequests.remove(request);
      });

      // Refresh notification list and badge so bell count updates immediately
      context.read<NotificationsCubit>().loadNotifications();
      context.read<NotificationsCubit>().getUnreadCount();

      // If accepted, reload friends list
      if (accept) {
        await _loadFriends(resetPage: true);
      }

      final localization = Provider.of<LocalizationService>(context, listen: false);
      final message = accept
          ? localization.translate('notifications.friendRequestAccepted')
          : localization.translate('notifications.friendRequestDeclined');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                accept ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(message),
            ],
          ),
          backgroundColor: accept ? AppColors.success : AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(e.message)),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final localization = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text(localization.translate('dialogs.failedToProcessFriendRequest')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _viewFriendProfile(Friend friend) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.friendProfile,
      arguments: {'friendId': friend.id},
    );

    if (!mounted) return;
    if (result is Map && result['unfriended'] == true) {
      await _loadFriends(resetPage: true);
    }
  }

  /// Navigate to friend profile screen
  Future<void> _navigateToFriendProfile(String friendId) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.friendProfile,
      arguments: {'friendId': friendId},
    );

    if (!mounted) return;
    if (result is Map && result['unfriended'] == true) {
      await _loadFriends(resetPage: true);
    }
  }

  void _showAddFriendDialog() {
    final emailController = TextEditingController();
    final localization = Provider.of<LocalizationService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(localization.translate('dialogs.addFriend')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localization.translate('friends.enterFriendEmailDescription'),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: emailController,
              label: localization.translate('friends.emailAddress'),
              hint: localization.translate('friends.emailAddressPlaceholder'),
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localization.translate('common.cancel')),
          ),
          CustomButton(
            text: localization.translate('friends.sendRequest'),
            onPressed: () {
              // Send friend request logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.send, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(localization.translate('dialogs.friendRequestSent')),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            variant: ButtonVariant.primary,
            size: ButtonSize.small,
            fullWidth: false,
          ),
        ],
      ),
    );
  }



  Future<void> _refreshFriends() async {
    // Reset pagination and reload friends
    await _loadFriends(resetPage: true);
  }

  Future<void> _refreshFriendRequests() async {
    // Reload friend requests
    await _loadFriendRequests();
  }
}
