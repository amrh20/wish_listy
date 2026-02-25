import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/profile/presentation/models/home_models.dart';
import 'package:wish_listy/features/wishlists/presentation/widgets/index.dart';
import 'package:wish_listy/features/profile/presentation/screens/main_navigation.dart';
import 'package:wish_listy/features/profile/presentation/widgets/minimal_wishlist_card.dart';
import 'package:wish_listy/features/profile/data/models/activity_model.dart';
import 'package:wish_listy/features/profile/presentation/widgets/activity_card.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/friends/presentation/widgets/suggested_friends_section.dart';
import 'package:wish_listy/features/wishlists/data/models/reservation_model.dart';
import 'package:wish_listy/features/wishlists/presentation/cubit/pending_reservations_cubit.dart';
import 'package:wish_listy/features/wishlists/presentation/utils/reservation_expiry_helper.dart';

/// Active dashboard with all sections for users with data
class ActiveDashboard extends StatelessWidget {
  final List<UpcomingOccasion> occasions;
  final List<WishlistSummary> wishlists;
  final List<Activity> activities; // Changed from FriendActivity to Activity

  const ActiveDashboard({
    super.key,
    List<UpcomingOccasion>? occasions,
    List<WishlistSummary>? wishlists,
    List<Activity>? activities,
  }) : occasions = occasions ?? const [],
       wishlists = wishlists ?? const [],
       activities = activities ?? const [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: My Wishlists (moved to top, always visible)
        MyWishlistsSection(wishlists: wishlists),
        const SizedBox(height: 24),
        // Section 1.5: Pending Reservations (horizontal)
        const PendingReservationsSection(),
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
  final List<UpcomingOccasion>? occasions;

  const UpcomingOccasionsSection({super.key, this.occasions});

  @override
  Widget build(BuildContext context) {
    // Add null safety check - ensure occasions is not null and not empty
    final safeOccasions = occasions ?? [];
    if (safeOccasions.isEmpty) return const SizedBox.shrink();

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
                  '${Provider.of<LocalizationService>(context, listen: false).translate('cards.friendsEvents')} 🎂',
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
                  Provider.of<LocalizationService>(context, listen: false).translate('home.viewAll'),
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
            itemCount: safeOccasions.length,
            itemBuilder: (context, index) {
              return _OccasionCard(occasion: safeOccasions[index]);
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
                        text: '${Provider.of<LocalizationService>(context, listen: false).translate('cards.hostedBy')} ',
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
                '${Provider.of<LocalizationService>(context, listen: false).translate('cards.hostedBy')} ${occasion.hostName}',
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
  final List<WishlistSummary>? wishlists;

  const MyWishlistsSection({super.key, this.wishlists});

  @override
  Widget build(BuildContext context) {
    // Add null safety check and limit to 3 items
    final safeWishlists = wishlists ?? [];
    if (safeWishlists.isEmpty) {
      return _buildEmptyState(context);
    }
    final displayWishlists = safeWishlists.take(3).toList();
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
                '${Provider.of<LocalizationService>(context, listen: false).translate('cards.myWishlists')} 🎁',
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
                  Provider.of<LocalizationService>(context, listen: false).translate('home.viewAll'),
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
                  children: (displayWishlists ?? [])
                      .where((wishlist) => wishlist != null)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                        final index = entry.key;
                        final wishlist = entry.value;
                        final filteredList = (displayWishlists ?? [])
                            .where((w) => w != null)
                            .toList();
                        // Remove bottom margin from last item
                        return Container(
                          margin: EdgeInsets.only(bottom: index < filteredList.length - 1 ? 8 : 0),
                          child: MinimalWishlistCard(
                            wishlist: wishlist,
                          ),
                        );
                      })
                      .toList(),
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
              Provider.of<LocalizationService>(context, listen: false).translate('details.youDontHaveWishlistYet'),
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
                    Provider.of<LocalizationService>(context, listen: false).translate('cards.createWishlist'),
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

/// Section: Pending Reservations (Horizontal List)
class PendingReservationsSection extends StatelessWidget {
  const PendingReservationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);

    return BlocProvider(
      create: (_) => PendingReservationsCubit()..loadPendingReservations(),
      child: BlocBuilder<PendingReservationsCubit, PendingReservationsState>(
        builder: (context, state) {
          if (state is PendingReservationsLoading ||
              state is PendingReservationsInitial) {
            return const _PendingReservationsSkeleton();
          }

          if (state is PendingReservationsError) {
            // Silent fail on Home – this section is non-critical
            return const SizedBox.shrink();
          }

          if (state is! PendingReservationsSuccess ||
              state.reservations.isEmpty) {
            return const SizedBox.shrink();
          }

          final reservations = state.reservations;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        localization.translate('home.pendingReservationsTitle') ??
                            'Don\'t forget these gifts! 🎁',
                        style: AppStyles.headingMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        // Switch to Wishlists tab (index 1) and then Reservations sub-tab (index 1)
                        MainNavigation.switchToTab(
                          context,
                          1,
                          wishlistsTabIndex: 1,
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        localization.translate('home.viewAll') ?? 'View All',
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
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: reservations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final reservation = reservations[index];
                    return PendingReservationCard(reservation: reservation);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Lightweight skeleton while pending reservations are loading.
class _PendingReservationsSkeleton extends StatelessWidget {
  const _PendingReservationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 180,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return Container(
                width: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textTertiary.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image placeholder
                      Container(
                        height: 90,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Title placeholder
                      Container(
                        height: 14,
                        width: 140,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Owner row placeholder
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Badge placeholder
                      Container(
                        height: 18,
                        width: 120,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class PendingReservationCard extends StatelessWidget {
  final PendingReservation reservation;

  const PendingReservationCard({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final item = reservation.item;
    final owner = reservation.owner ?? reservation.wishlist?.owner;
    final ownerName = owner?.fullName ?? owner?.username ?? '';

    // Expiry formatting
    ReservationExpiryFormat? expiryFormat;
    if (reservation.reservedUntil != null) {
      expiryFormat =
          formatReservationExpiry(reservation.reservedUntil!, localization);
    }

    final bgColor = AppColors.primary.withOpacity(0.08);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.itemDetails,
          arguments: item,
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.textTertiary.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Image / Placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 90,
                width: double.infinity,
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withOpacity(0.12),
                              AppColors.accent.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.card_giftcard,
                            size: 32,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            // Item name
            Text(
              item.name,
              style: AppStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Owner row
            if (ownerName.isNotEmpty)
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: bgColor,
                    backgroundImage: owner?.profileImage != null &&
                            owner!.profileImage!.isNotEmpty
                        ? NetworkImage(owner.profileImage!)
                        : null,
                    child: (owner?.profileImage == null ||
                            owner!.profileImage!.isEmpty)
                        ? const Icon(
                            Icons.person_outline,
                            size: 16,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localization.translate(
                            'details.forOwner',
                            args: {'name': ownerName},
                          ) ??
                          'For $ownerName',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Expiry badge
              if (expiryFormat != null)
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: expiryFormat.isUrgent
                          ? AppColors.error.withOpacity(0.08)
                          : AppColors.warning.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      localization.translate(
                            'home.expiresIn',
                            args: {'time': expiryFormat.text},
                          ) ??
                          '${expiryFormat.text} ⏳',
                      style: AppStyles.caption.copyWith(
                        color: expiryFormat.isUrgent
                            ? AppColors.error
                            : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section 3: Friend Activity (Vertical List - Preview Mode: Max 3 items)
class FriendActivitySection extends StatelessWidget {
  final List<Activity>? activities; // Changed from FriendActivity to Activity

  const FriendActivitySection({super.key, this.activities});

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    
    // Add null safety check before accessing activities
    final safeActivities = activities ?? [];
    
    // Limit to maximum 3 items for preview (as per new API structure)
    // Ensure displayActivities is never null and filter out any null items
    final displayActivities = (safeActivities.length > 3 
        ? safeActivities.take(3).toList() 
        : safeActivities)
        .where((activity) => activity != null)
        .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Suggested Friends Section (People You May Know)
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: SuggestedFriendsSection(
            localization: localization,
          ),
        ),
        // Activities Section (only show if there are activities)
        if (displayActivities.isNotEmpty) ...[
          // Header with Title and View All
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${localization.translate('cards.happeningNow')} ⚡',
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
                    localization.translate('home.viewAll'),
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
          // Vertical List (limited to 3 items) - Using ActivityCard widget
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: displayActivities
                  .map((activity) => ActivityCard(activity: activity))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

