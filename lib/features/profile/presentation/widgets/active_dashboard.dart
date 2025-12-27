import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/profile/presentation/models/home_models.dart';
import 'package:wish_listy/features/wishlists/presentation/widgets/wishlist_card_widget.dart';
import 'package:wish_listy/features/profile/presentation/screens/main_navigation.dart';
import 'package:wish_listy/features/profile/presentation/widgets/minimal_wishlist_card.dart';

/// Active dashboard with all sections for users with data
class ActiveDashboard extends StatelessWidget {
  final List<UpcomingOccasion> occasions;
  final List<WishlistSummary> wishlists;
  final List<FriendActivity> activities;

  const ActiveDashboard({
    super.key,
    required this.occasions,
    required this.wishlists,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: My Wishlists (moved to top, always visible)
        MyWishlistsSection(wishlists: wishlists),
        const SizedBox(height: 32),
        // Section 2: Upcoming Occasions
        UpcomingOccasionsSection(occasions: occasions),
        const SizedBox(height: 32),
        // Section 3: Friend Activity
        FriendActivitySection(activities: activities),
      ],
    );
  }
}

/// Section 1: Upcoming Occasions (Horizontal List)
class UpcomingOccasionsSection extends StatelessWidget {
  final List<UpcomingOccasion> occasions;

  const UpcomingOccasionsSection({super.key, required this.occasions});

  @override
  Widget build(BuildContext context) {
    if (occasions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Title and View All
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Friends\' Events 🎂',
                  style: AppStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  // Navigate to Events Tab (Tab index 2) and open Invited tab (index 1)
                  MainNavigation.switchToTab(context, 2, eventsTabIndex: 1);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Horizontal List
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: occasions.length,
            itemBuilder: (context, index) {
              return _OccasionCard(occasion: occasions[index]);
            },
          ),
        ),
      ],
    );
  }
}

/// Occasion Card Widget
class _OccasionCard extends StatelessWidget {
  final UpcomingOccasion occasion;

  const _OccasionCard({required this.occasion});

  Color _getTypeColor() {
    switch (occasion.type.toLowerCase()) {
      case 'birthday':
        return Colors.pink;
      case 'anniversary':
        return Colors.red;
      case 'graduation':
        return Colors.blue;
      case 'housewarming':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon() {
    switch (occasion.type.toLowerCase()) {
      case 'birthday':
        return Icons.cake_rounded;
      case 'anniversary':
        return Icons.favorite_rounded;
      case 'graduation':
        return Icons.school_rounded;
      case 'housewarming':
        return Icons.home_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor();
    final daysUntil = occasion.daysUntil;
    final status = occasion.invitationStatus;

    return InkWell(
      onTap: () {
        // Navigate to event details
        Navigator.pushNamed(
          context,
          AppRoutes.eventDetails,
          arguments: {'eventId': occasion.id},
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: typeColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon + Event Name (centered vertically)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center, // Fix 1: Center alignment
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: typeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                // Event Name (Main Title - Bold)
                Expanded(
                  child: Text(
                    occasion.name,
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Host Name (Clickable - Fix 2)
            if (occasion.hostId != null && occasion.hostId!.isNotEmpty)
              GestureDetector(
                onTap: () {
                  // Navigate to friend profile
                  Navigator.pushNamed(
                    context,
                    AppRoutes.friendProfile,
                    arguments: {'friendId': occasion.hostId!},
                  );
                },
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: AppStyles.bodySmall.copyWith(
                      fontSize: 12,
                    ),
                    children: [
                      // "Hosted by" in black
                      TextSpan(
                        text: 'Hosted by ',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                      // Name in primary color, larger font, and clickable
                      TextSpan(
                        text: occasion.hostName ?? '',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 13, // Slightly larger
                          fontWeight: FontWeight.w600, // Bold to indicate clickable
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Text(
                'Hosted by ${occasion.hostName}',
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            // Bottom Row: Date Badge + Status Badge (Fix 3)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // Days Until Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    daysUntil == 0
                        ? 'Today'
                        : daysUntil == 1
                            ? 'Tomorrow'
                            : '$daysUntil days',
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Status Badge (if pending, accepted, declined, or maybe)
                if (status != null && 
                    status != 'not_invited' && 
                    (status == 'pending' || status == 'accepted' || status == 'declined' || status == 'maybe'))
                  _buildStatusBadge(status!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.orange.shade200,
            width: 1,
          ),
        ),
        child: Text(
          'Invited 📩',
          style: TextStyle(
            color: Colors.orange.shade900,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (status == 'accepted') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.success.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          'Going ✅',
          style: TextStyle(
            color: AppColors.success,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (status == 'declined') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          'Declined ❌',
          style: TextStyle(
            color: AppColors.error,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (status == 'maybe') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.blue.shade200,
            width: 1,
          ),
        ),
        child: Text(
          'Maybe 🤔',
          style: TextStyle(
            color: Colors.blue.shade900,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Section 1: My Wishlists (Vertical List - Max 3 items, always visible)
class MyWishlistsSection extends StatelessWidget {
  final List<WishlistSummary> wishlists;

  const MyWishlistsSection({super.key, required this.wishlists});

  @override
  Widget build(BuildContext context) {
    // Limit to 3 items
    final displayWishlists = wishlists.take(3).toList();
    final isEmpty = displayWishlists.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with View All button (always visible)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Wishlists 🎁',
                style: AppStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Switch to Wishlists tab (Index 1)
                  MainNavigation.switchToTab(context, 1);
                },
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
        ),
        const SizedBox(height: 8),
        // Content: Either wishlist cards or empty state
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: isEmpty
              ? _buildEmptyState(context)
              : Column(
                  children: displayWishlists.asMap().entries.map((entry) {
                    final index = entry.key;
                    final wishlist = entry.value;
                    // Remove bottom margin from last item
                    return Container(
                      margin: EdgeInsets.only(bottom: index < displayWishlists.length - 1 ? 8 : 0),
                      child: MinimalWishlistCard(
                        wishlist: wishlist,
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  /// Empty state placeholder card
  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'You don\'t have a wishlist yet. Let\'s create your first one! 🎁',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.createWishlist,
                    arguments: {
                      'previousRoute': AppRoutes.mainNavigation,
                    },
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Create Wishlist',
                    style: AppStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Section 3: Friend Activity (Vertical List - Preview Mode: Max 5 items)
class FriendActivitySection extends StatelessWidget {
  final List<FriendActivity> activities;

  const FriendActivitySection({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return const SizedBox.shrink();

    // Limit to maximum 5 items for preview
    final displayActivities = activities.length > 5 
        ? activities.take(5).toList() 
        : activities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Title and View All
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Happening Now ⚡',
                  style: AppStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  // Navigate to Friend Activity Feed
                  Navigator.pushNamed(
                    context,
                    AppRoutes.friendActivityFeed,
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Vertical List (limited to 5 items)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: displayActivities.map((activity) {
              return _ActivityTile(activity: activity);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Activity Tile Widget
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
    final itemName = activity.action.replaceAll(RegExp(r'^added '), '').replaceAll(RegExp(r' to their wishlist$'), '');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Leading: Avatar of owner (Clickable)
          GestureDetector(
            onTap: activity.friendId != null && activity.friendId!.isNotEmpty
                ? () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.friendProfile,
                      arguments: {'friendId': activity.friendId!},
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
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Content: Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title: "ownerName added itemName to their wishlist" (Name is clickable)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: RichText(
                        text: TextSpan(
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            TextSpan(
                              text: activity.friendName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: activity.friendId != null && activity.friendId!.isNotEmpty
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontSize: 14, // Slightly larger to indicate clickable
                              ),
                              recognizer: activity.friendId != null && activity.friendId!.isNotEmpty
                                  ? (TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.friendProfile,
                                        arguments: {'friendId': activity.friendId!},
                                      );
                                    })
                                  : null,
                            ),
                            const TextSpan(text: ' added '),
                            TextSpan(
                              text: itemName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: ' to their wishlist'),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Subtitle: Time ago
                Text(
                  activity.timeAgo,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Trailing: Small image of the item or generic gift icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: activity.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      activity.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.card_giftcard_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  )
                : Icon(
                    Icons.card_giftcard_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
          ),
        ],
      ),
    );
  }
}

