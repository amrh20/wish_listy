import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/constants/bottom_sheet_vectors.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/widgets/custom_text_field.dart';
import 'package:wish_listy/core/widgets/decorated_bottom_sheet.dart';
import 'package:wish_listy/core/widgets/unified_page_header.dart';
import 'package:wish_listy/core/widgets/unified_tab_bar.dart';
import 'package:wish_listy/core/widgets/unified_page_container.dart';
import 'package:wish_listy/core/services/localization_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock data
  final List<Friend> _friends = [
    Friend(
      id: '1',
      name: 'Sarah Johnson',
      email: 'sarah@example.com',
      profilePicture: null,
      mutualFriends: 12,
      lastActive: DateTime.now().subtract(Duration(minutes: 30)),
      isOnline: true,
      wishlistCount: 3,
    ),
    Friend(
      id: '2',
      name: 'Ahmed Ali',
      email: 'ahmed@example.com',
      profilePicture: null,
      mutualFriends: 8,
      lastActive: DateTime.now().subtract(Duration(hours: 2)),
      isOnline: false,
      wishlistCount: 5,
    ),
    Friend(
      id: '3',
      name: 'Emma Watson',
      email: 'emma@example.com',
      profilePicture: null,
      mutualFriends: 15,
      lastActive: DateTime.now().subtract(Duration(minutes: 5)),
      isOnline: true,
      wishlistCount: 2,
    ),
    Friend(
      id: '4',
      name: 'Mike Thompson',
      email: 'mike@example.com',
      profilePicture: null,
      mutualFriends: 6,
      lastActive: DateTime.now().subtract(Duration(days: 1)),
      isOnline: false,
      wishlistCount: 4,
    ),
  ];

  final List<FriendRequest> _friendRequests = [
    FriendRequest(
      id: '1',
      senderId: 'user1',
      senderName: 'Lisa Chen',
      senderEmail: 'lisa@example.com',
      senderProfilePicture: null,
      mutualFriends: 5,
      sentAt: DateTime.now().subtract(Duration(hours: 3)),
      message: 'Hi! We met at the tech conference last week.',
    ),
    FriendRequest(
      id: '2',
      senderId: 'user2',
      senderName: 'David Brown',
      senderEmail: 'david@example.com',
      senderProfilePicture: null,
      mutualFriends: 2,
      sentAt: DateTime.now().subtract(Duration(days: 2)),
      message: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAnimations();
    _startAnimations();
    _searchController.addListener(_onSearchChanged);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    subtitle:
                        '${_friends.length} ${localization.translate('friends.friends')}',
                    showSearch: true,
                    searchHint: localization.translate('ui.searchFriends'),
                    searchController: _searchController,
                    onSearchChanged: (query) {
                      _onSearchChanged();
                    },
                    actions: [
                      HeaderAction(
                        icon: Icons.sync_rounded,
                        onTap: _syncContacts,
                      ),
                      HeaderAction(
                        icon: Icons.more_vert_rounded,
                        onTap: () {
                          _showOptionsMenu(context);
                        },
                      ),
                    ],
                    tabs: [
                      UnifiedTab(
                        label: localization.translate('ui.myFriends'),
                        icon: Icons.people_rounded,
                        badgeCount: _getFilteredFriends().length,
                      ),
                      UnifiedTab(
                        label: localization.translate('ui.requests'),
                        badgeCount: _friendRequests.length,
                        badgeColor: AppColors.accent,
                      ),
                    ],
                    selectedTabIndex: _tabController.index,
                    onTabChanged: (index) {
                      _tabController.animateTo(index);
                      setState(() {});
                    },
                    selectedTabColor: AppColors.secondary,
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
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddFriendDialog,
            backgroundColor: AppColors.secondary,
            heroTag: 'friends_fab',
            child: Icon(Icons.person_add_rounded, color: Colors.white),
          ),
        );
      },
    );
  }

  void _showOptionsMenu(BuildContext context) {
    DecoratedBottomSheet.show(
      context: context,
      vectorType: BottomSheetVectorType.settings,
      children: [
        ListTile(
          leading: Icon(
            Icons.contact_page_outlined,
            color: AppColors.textPrimary,
          ),
          title: Text(
            'Import Contacts',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          onTap: () {
            Navigator.pop(context);
            _importContacts();
          },
        ),
        ListTile(
          leading: Icon(
            Icons.privacy_tip_outlined,
            color: AppColors.textPrimary,
          ),
          title: Text(
            'Privacy Settings',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          onTap: () {
            Navigator.pop(context);
            _openPrivacySettings();
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMyFriendsTab(LocalizationService localization) {
    final filteredFriends = _getFilteredFriends();

    return RefreshIndicator(
      onRefresh: _refreshFriends,
      color: AppColors.secondary,
      child: filteredFriends.isEmpty
          ? _buildEmptyState()
          : AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredFriends.length + 1, // +1 for bottom padding
                itemBuilder: (context, index) {
                  if (index == filteredFriends.length) {
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

  Widget _buildFriendRequestsTab(LocalizationService localization) {
    return RefreshIndicator(
      onRefresh: _refreshFriends,
      color: AppColors.secondary,
      child: _friendRequests.isEmpty
          ? _buildEmptyFriendRequests()
          : AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _friendRequests.length + 1,
                itemBuilder: (context, index) {
                  if (index == _friendRequests.length) {
                    return const SizedBox(height: 100);
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
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.secondary.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        friend.name[0].toUpperCase(),
                        style: AppStyles.headingSmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Online Status
                    if (friend.isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                // Friend Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        style: AppStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${friend.mutualFriends} ${localization.translate('ui.mutualFriends')}',
                              style: AppStyles.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.favorite_outline,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${friend.wishlistCount} ${localization.translate('ui.wishlists')}',
                              style: AppStyles.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        friend.isOnline
                            ? localization.translate('ui.onlineNow')
                            : '${localization.translate('ui.lastSeen')} ${_formatLastActive(friend.lastActive)}',
                        style: AppStyles.caption.copyWith(
                          color: friend.isOnline
                              ? AppColors.success
                              : AppColors.textTertiary,
                          fontWeight: friend.isOnline
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendRequestCard(FriendRequest request) {
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
                // Profile Picture
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                  child: Text(
                    request.senderName[0].toUpperCase(),
                    style: AppStyles.bodyLarge.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Request Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.senderName,
                        style: AppStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${request.mutualFriends} mutual friends',
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Time
                Text(
                  _formatRequestTime(request.sentAt),
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),

            // Message
            if (request.message != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${request.message}"',
                  style: AppStyles.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Decline',
                    onPressed: () => _handleFriendRequest(request, false),
                    variant: ButtonVariant.outline,
                    customColor: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Accept',
                    onPressed: () => _handleFriendRequest(request, true),
                    variant: ButtonVariant.primary,
                    customColor: AppColors.success,
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
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.people_outline,
              size: 60,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty ? 'No Friends Yet' : 'No Friends Found',
            style: AppStyles.headingMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty
                ? 'Start connecting with friends to share wishlists and make gift-giving more meaningful.'
                : 'Try adjusting your search terms to find friends.',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 32),
            CustomButton(
              text: 'Add Friends',
              onPressed: _showAddFriendDialog,
              variant: ButtonVariant.gradient,
              gradientColors: [AppColors.secondary, AppColors.primary],
            ),
          ],
        ],
      ),
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
          Text(
            'No Friend Requests',
            style: AppStyles.headingMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'When people send you friend requests, they\'ll appear here for you to accept or decline.',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper Methods
  List<Friend> _getFilteredFriends() {
    if (_searchQuery.isEmpty) return _friends;

    return _friends.where((friend) {
      return friend.name.toLowerCase().contains(_searchQuery) ||
          friend.email.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatRequestTime(DateTime sentAt) {
    final now = DateTime.now();
    final difference = now.difference(sentAt);

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Action Handlers
  void _handleFriendRequest(FriendRequest request, bool accept) {
    setState(() {
      _friendRequests.remove(request);
      if (accept) {
        // Add to friends list
        _friends.add(
          Friend(
            id: request.senderId,
            name: request.senderName,
            email: request.senderEmail,
            profilePicture: request.senderProfilePicture,
            mutualFriends: request.mutualFriends,
            lastActive: DateTime.now(),
            isOnline: false,
            wishlistCount: 0,
          ),
        );
      }
    });

    final message = accept
        ? 'Friend request accepted!'
        : 'Friend request declined';

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
  }

  void _viewFriendProfile(Friend friend) {
    AppRoutes.pushNamed(
      context,
      AppRoutes.friendProfile,
      arguments: {'friendId': friend.id},
    );
  }

  void _showAddFriendDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Friend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your friend\'s email address to send them a friend request.',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: emailController,
              label: 'Email Address',
              hint: 'friend@example.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          CustomButton(
            text: 'Send Request',
            onPressed: () {
              // Send friend request logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.send, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Friend request sent!'),
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

  void _syncContacts() {
    // Sync contacts functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contacts synced successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _importContacts() {
    // Import contacts functionality
  }

  void _openPrivacySettings() {
    // Open privacy settings
  }

  Future<void> _refreshFriends() async {
    // Refresh friends data
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Update data
    });
  }
}

// Mock data models
class Friend {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final int mutualFriends;
  final DateTime lastActive;
  final bool isOnline;
  final int wishlistCount;

  Friend({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    required this.mutualFriends,
    required this.lastActive,
    required this.isOnline,
    required this.wishlistCount,
  });
}

class FriendRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String? senderProfilePicture;
  final int mutualFriends;
  final DateTime sentAt;
  final String? message;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    this.senderProfilePicture,
    required this.mutualFriends,
    required this.sentAt,
    this.message,
  });
}
