import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../utils/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/animated_background.dart';

class FriendProfileScreen extends StatefulWidget {
  final String friendId;

  const FriendProfileScreen({super.key, required this.friendId});

  @override
  _FriendProfileScreenState createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Mock friend data
  late FriendProfile _friendProfile;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadFriendProfile();
    _startAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );
  }

  void _loadFriendProfile() {
    // Mock friend profile data
    _friendProfile = FriendProfile(
      id: widget.friendId,
      name: 'Sarah Johnson',
      email: 'sarah@example.com',
      bio:
          'Love reading, traveling, and discovering new places. Always looking for unique gifts and special experiences to share with friends! 📚✈️',
      profilePicture: null,
      isOnline: true,
      lastActive: DateTime.now().subtract(Duration(minutes: 15)),
      friendsSince: DateTime.now().subtract(Duration(days: 180)),
      mutualFriends: 12,
      wishlistsCount: 3,
      eventsCount: 2,
      giftsGiven: 8,
      giftsReceived: 12,
      publicWishlists: [
        FriendWishlist(
          id: '1',
          name: 'My General Wishlist',
          itemCount: 15,
          lastUpdated: DateTime.now().subtract(Duration(days: 2)),
          previewItems: ['Kindle E-reader', 'Yoga Mat', 'Coffee Table Book'],
        ),
        FriendWishlist(
          id: '2',
          name: 'Travel Essentials',
          itemCount: 8,
          lastUpdated: DateTime.now().subtract(Duration(days: 5)),
          previewItems: [
            'Travel Backpack',
            'Portable Charger',
            'Travel Pillow',
          ],
        ),
      ],
      recentActivity: [
        FriendActivity(
          id: '1',
          action: 'added 2 new items to Travel Essentials wishlist',
          timestamp: DateTime.now().subtract(Duration(hours: 6)),
        ),
        FriendActivity(
          id: '2',
          action: 'created a new event: "Book Club Meetup"',
          timestamp: DateTime.now().subtract(Duration(days: 3)),
        ),
        FriendActivity(
          id: '3',
          action: 'marked "Wireless Headphones" as received',
          timestamp: DateTime.now().subtract(Duration(days: 7)),
        ),
      ],
    );
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          // Content
          RefreshIndicator(
            onRefresh: _refreshProfile,
            color: AppColors.secondary,
            child: CustomScrollView(
              slivers: [
                // Profile Header
                _buildSliverAppBar(),

                // Profile Content
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Friendship Info
                                _buildFriendshipInfo(),
                                const SizedBox(height: 24),

                                // Stats Cards
                                _buildStatsSection(),
                                const SizedBox(height: 24),

                                // Public Wishlists
                                _buildWishlistsSection(),
                                const SizedBox(height: 24),

                                // Recent Activity
                                _buildRecentActivity(),
                                const SizedBox(height: 24),

                                // Mutual Friends
                                _buildMutualFriends(),
                                const SizedBox(
                                  height: 32,
                                ), // Reduced bottom padding
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 320,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.secondary, AppColors.primary],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Profile Picture
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _friendProfile.name[0].toUpperCase(),
                            style: AppStyles.headingLarge.copyWith(
                              color: AppColors.secondary,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Online Status
                      if (_friendProfile.isOnline)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Name
                  Text(
                    _friendProfile.name,
                    style: AppStyles.headingMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _friendProfile.isOnline
                              ? AppColors.success
                              : AppColors.textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _friendProfile.isOnline
                            ? 'Online now'
                            : 'Last seen ${_formatLastActive(_friendProfile.lastActive)}',
                        style: AppStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bio
                  if (_friendProfile.bio != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _friendProfile.bio!,
                        style: AppStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _sendMessage,
          icon: Icon(Icons.message_outlined, color: Colors.white),
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          icon: Icon(Icons.more_vert, color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'share_profile',
              child: Row(
                children: [
                  Icon(Icons.share_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Share Profile'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'mute',
              child: Row(
                children: [
                  Icon(Icons.notifications_off_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Mute Notifications'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block_outlined, size: 20, color: AppColors.error),
                  SizedBox(width: 12),
                  Text('Block User', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFriendshipInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.people_outline,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Friends since ${_formatFriendshipDate(_friendProfile.friendsSince)}',
                  style: AppStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_friendProfile.mutualFriends} mutual friends',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          CustomButton(
            text: 'Message',
            onPressed: _sendMessage,
            variant: ButtonVariant.outline,
            customColor: AppColors.success,
            size: ButtonSize.small,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Wishlists',
            value: '${_friendProfile.wishlistsCount}',
            icon: Icons.favorite_outline,
            color: AppColors.secondary,
            onTap: _viewAllWishlists,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Events',
            value: '${_friendProfile.eventsCount}',
            icon: Icons.event,
            color: AppColors.accent,
            onTap: _viewEvents,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Gifts Given',
            value: '${_friendProfile.giftsGiven}',
            icon: Icons.card_giftcard_outlined,
            color: AppColors.primary,
            onTap: _viewGiftHistory,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppStyles.headingSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Public Wishlists', style: AppStyles.headingSmall),
              TextButton(
                onPressed: _viewAllWishlists,
                child: Text(
                  'View All',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Column(
            children: _friendProfile.publicWishlists.map((wishlist) {
              return _buildWishlistCard(wishlist);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistCard(FriendWishlist wishlist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.favorite_outline,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wishlist.name,
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${wishlist.itemCount} items • Updated ${_formatLastUpdated(wishlist.lastUpdated)}',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Preview Items
          if (wishlist.previewItems.isNotEmpty) ...[
            Text(
              'Preview:',
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: wishlist.previewItems.take(3).map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item,
                    style: AppStyles.caption.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),

          CustomButton(
            text: 'View Wishlist',
            onPressed: () => _viewWishlist(wishlist),
            variant: ButtonVariant.outline,
            customColor: AppColors.secondary,
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Activity', style: AppStyles.headingSmall),
          const SizedBox(height: 16),

          Column(
            children: _friendProfile.recentActivity.map((activity) {
              return _buildActivityItem(activity);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(FriendActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_friendProfile.name} ${activity.action}',
                  style: AppStyles.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatActivityTime(activity.timestamp),
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutualFriends() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mutual Friends (${_friendProfile.mutualFriends})',
                style: AppStyles.headingSmall,
              ),
              TextButton(
                onPressed: _viewMutualFriends,
                child: Text(
                  'View All',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mock mutual friends preview
          Container(
            constraints: const BoxConstraints(minHeight: 80, maxHeight: 120),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          'F${index + 1}',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Friend ${index + 1}',
                        style: AppStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
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

  String _formatFriendshipDate(DateTime friendsSince) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[friendsSince.month - 1]} ${friendsSince.year}';
  }

  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  String _formatActivityTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  // Action Handlers
  void _handleMenuAction(String action) {
    switch (action) {
      case 'share_profile':
        _shareProfile();
        break;
      case 'mute':
        _muteNotifications();
        break;
      case 'block':
        _blockUser();
        break;
    }
  }

  void _sendMessage() {
    // Open messaging
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Messaging feature coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _viewAllWishlists() {
    // Navigate to all public wishlists
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing all ${_friendProfile.name}\'s public wishlists'),
        backgroundColor: AppColors.info,
      ),
    );

    // TODO: Navigate to a screen showing all public wishlists
    // This could be a dedicated screen or modal
  }

  void _viewEvents() {
    // Navigate to friend's events
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing ${_friendProfile.name}\'s events'),
        backgroundColor: AppColors.info,
      ),
    );

    // TODO: Navigate to a screen showing friend's public events
    // This could be a dedicated screen or modal
  }

  void _viewGiftHistory() {
    // Navigate to gift history
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing ${_friendProfile.name}\'s gift history'),
        backgroundColor: AppColors.info,
      ),
    );

    // TODO: Navigate to a screen showing friend's gift history
    // This could be a dedicated screen or modal
  }

  void _viewWishlist(FriendWishlist wishlist) {
    // Navigate to wishlist details
    Navigator.pushNamed(
      context,
      AppRoutes.wishlistItems,
      arguments: {
        'wishlistName': '${_friendProfile.name}\'s ${wishlist.name}',
        'wishlistId': wishlist.id,
        'totalItems': wishlist.itemCount,
        'purchasedItems': 0,
        'totalValue': 0.0,
        'isFriendWishlist': true,
        'friendName': _friendProfile.name,
      },
    );
  }

  void _viewMutualFriends() {
    // Navigate to mutual friends
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Viewing all ${_friendProfile.mutualFriends} mutual friends',
        ),
        backgroundColor: AppColors.info,
      ),
    );

    // TODO: Navigate to a screen showing all mutual friends
    // This could be a dedicated screen or modal
  }

  void _shareProfile() {
    // Share profile functionality
  }

  void _muteNotifications() {
    // Mute notifications
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notifications muted for ${_friendProfile.name}'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _blockUser() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block ${_friendProfile.name}?'),
        content: Text(
          'They won\'t be able to see your profile, send you messages, or interact with your content.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_friendProfile.name} has been blocked'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            child: Text('Block', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshProfile() async {
    // Refresh profile data
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Update profile data
    });
  }
}

// Mock data models
class FriendProfile {
  final String id;
  final String name;
  final String email;
  final String? bio;
  final String? profilePicture;
  final bool isOnline;
  final DateTime lastActive;
  final DateTime friendsSince;
  final int mutualFriends;
  final int wishlistsCount;
  final int eventsCount;
  final int giftsGiven;
  final int giftsReceived;
  final List<FriendWishlist> publicWishlists;
  final List<FriendActivity> recentActivity;

  FriendProfile({
    required this.id,
    required this.name,
    required this.email,
    this.bio,
    this.profilePicture,
    required this.isOnline,
    required this.lastActive,
    required this.friendsSince,
    required this.mutualFriends,
    required this.wishlistsCount,
    required this.eventsCount,
    required this.giftsGiven,
    required this.giftsReceived,
    required this.publicWishlists,
    required this.recentActivity,
  });
}

class FriendWishlist {
  final String id;
  final String name;
  final int itemCount;
  final DateTime lastUpdated;
  final List<String> previewItems;

  FriendWishlist({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.lastUpdated,
    required this.previewItems,
  });
}

class FriendActivity {
  final String id;
  final String action;
  final DateTime timestamp;

  FriendActivity({
    required this.id,
    required this.action,
    required this.timestamp,
  });
}
