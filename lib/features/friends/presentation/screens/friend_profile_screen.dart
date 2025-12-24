import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/friends/data/models/friend_event_model.dart';
import 'package:wish_listy/features/friends/data/models/friend_wishlist_model.dart';
import 'package:wish_listy/features/friends/presentation/controllers/friend_profile_controller.dart';

class FriendProfileScreen extends StatefulWidget {
  final String friendId;

  const FriendProfileScreen({super.key, required this.friendId});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  late final FriendProfileController _controller;

  static const double _expandedHeaderHeight = 260.0;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      FriendProfileController(friendId: widget.friendId),
      tag: widget.friendId,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<FriendProfileController>(tag: widget.friendId)) {
      Get.delete<FriendProfileController>(tag: widget.friendId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF2F8),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFDF2F8), // pink-50
              Color(0xFFF3E8FF), // purple-50
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: _expandedHeaderHeight,
              backgroundColor: Colors.transparent,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.textPrimary,
                ),
              ),
              // IMPORTANT: No chat icons / message actions here.
              actions: const [],
              flexibleSpace: FlexibleSpaceBar(
                background: _PatternedHeader(controller: _controller),
              ),
            ),

            // Carved / bottom-sheet effect: pull the white sheet up to overlap header.
            SliverToBoxAdapter(
              child: Transform(
                transform: Matrix4.translationValues(0.0, -20.0, 0.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 18,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _BodyContent(controller: _controller),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternedHeader extends StatelessWidget {
  final FriendProfileController controller;

  const _PatternedHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFDF2F8),
                Color(0xFFF3E8FF),
              ],
            ),
          ),
          child: Stack(
            children: [
              _softBubble(
                left: -110,
                top: -60,
                size: 260,
                color: const Color(0xFF9333EA).withOpacity(0.05),
              ),
              _softBubble(
                right: -140,
                top: 30,
                size: 300,
                color: const Color(0xFFEC4899).withOpacity(0.05),
              ),
              _softBubble(
                left: 40,
                bottom: -160,
                size: 320,
                color: const Color(0xFF6B46C1).withOpacity(0.04),
              ),
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Obx(() {
                        final p = controller.profile.value;
                        final user = p?.user;

                        final fullName = (user?.fullName.isNotEmpty ?? false)
                            ? user!.fullName
                            : 'Friend';
                        final profileImage = user?.profileImage;

                        final counts = p?.counts;
                        final wishlistsCount = counts?.wishlists ?? 0;
                        final friendsCount = counts?.friends ?? 0;
                        final eventsCount = counts?.events ?? 0;

                        final isFriend = p?.friendshipStatus.isFriend ?? false;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Avatar(
                              fullName: fullName,
                              imageUrl: profileImage,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    fullName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isFriend) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            _GlassStatsContainer(
                              wishlists: wishlistsCount,
                              friends: friendsCount,
                              events: eventsCount,
                            ),
                            // Intentionally no "Add Friend" button in header (prevents overflow).
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _softBubble({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 120,
              spreadRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String fullName;
  final String? imageUrl;

  const _Avatar({required this.fullName, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final initial = fullName.trim().isNotEmpty
        ? fullName.trim()[0].toUpperCase()
        : 'F';

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
        child: hasImage
            ? null
            : Text(
                initial,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }
}

class _GlassStatsContainer extends StatelessWidget {
  final int wishlists;
  final int friends;
  final int events;

  const _GlassStatsContainer({
    required this.wishlists,
    required this.friends,
    required this.events,
  });

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 50,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      constraints: const BoxConstraints(
        minHeight: 50,
        maxHeight: 60,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _buildStatItem(context, 'Wishlists', wishlists.toString()),
          ),
          Container(
            width: 1,
            height: 14,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildStatItem(context, 'Friends', friends.toString()),
          ),
          Container(
            width: 1,
            height: 14,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildStatItem(context, 'Events', events.toString()),
          ),
        ],
      ),
    );
  }
}

class _BodyContent extends StatelessWidget {
  final FriendProfileController controller;
  const _BodyContent({required this.controller});

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wishlists Section Header
          const Text(
            'Wishlists 🎁',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          // Spacing after header
          const SizedBox(height: 8),
          // Wishlists Content
          Obx(() {
            final isLoading = controller.isLoading.value;
            final list = controller.wishlists;
            if (isLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (list.isEmpty) {
              return _buildEmptyState(
                icon: Icons.card_giftcard,
                title: 'No public wishlists',
                subtitle: 'This friend hasn\'t shared any lists yet.',
              );
            }

            return ListView.separated(
              itemCount: list.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final w = list[index];
                return _WishlistGridCard(
                  wishlist: w,
                  controller: controller,
                  onTap: () {
                    final friendName =
                        controller.profile.value?.user.fullName ?? 'Friend';
                    Navigator.pushNamed(
                      context,
                      AppRoutes.wishlistItems,
                      arguments: {
                        'wishlistId': w.id,
                        'wishlistName': w.name,
                        'totalItems': w.itemCount,
                        'purchasedItems': 0,
                        'isFriendWishlist': true,
                        'friendName': friendName,
                      },
                    );
                  },
                );
              },
            );
          }),
          // Large spacing between sections
          const SizedBox(height: 40),
          // Events Section Header
          const Text(
            'Upcoming Events 📅',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          // Spacing after header
          const SizedBox(height: 16),
          // Events Content
          Obx(() {
            final isLoading = controller.isLoading.value;
            final list = controller.events;
            if (isLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (list.isEmpty) {
              return _buildEmptyState(
                icon: Icons.event_busy,
                title: 'No upcoming events',
                subtitle: 'Nothing scheduled at the moment.',
              );
            }

            return ListView.separated(
              itemCount: list.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final e = list[index];
                return _EventTicketCard(
                  event: e,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.eventDetails,
                      arguments: {'eventId': e.id},
                    );
                  },
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _WishlistGridCard extends StatelessWidget {
  final FriendWishlistModel wishlist;
  final FriendProfileController controller;
  final VoidCallback onTap;

  const _WishlistGridCard({
    required this.wishlist,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryData = controller.getCategoryIcon(wishlist.category);
    final privacyIcon = controller.getPrivacyIcon(wishlist.privacy);
    final previewItems = wishlist.previewItems.take(3).toList();
    final hasMore = wishlist.itemCount > 3;
    final hasItems = wishlist.itemCount > 0;
    final hasDescription = wishlist.description != null &&
        wishlist.description!.trim().isNotEmpty;

    // Format category name
    String categoryName = (wishlist.category ?? 'Other').trim();
    if (categoryName.isEmpty) categoryName = 'Other';
    if (categoryName.toLowerCase() == 'general') categoryName = 'Other';
    categoryName = categoryName[0].toUpperCase() + categoryName.substring(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Top Section: Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. The Hero Icon (Left Side) - LARGE & COLORFUL
                  Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      color: categoryData.color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      categoryData.icon,
                      size: 22,
                      color: categoryData.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // B. Title & Metadata (Right Side)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                wishlist.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              privacyIcon,
                              color: Colors.grey,
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Metadata Row
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: categoryData.color.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                categoryName,
                                style: TextStyle(
                                  color: categoryData.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '• ${wishlist.itemCount} ${wishlist.itemCount == 1 ? 'Wish' : 'Wishes'}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        if (hasDescription) ...[
                          const SizedBox(height: 8),
                          Text(
                            wishlist.description!.trim(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // 2. Divider (always shown)
              const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade200,
              ),
              const SizedBox(height: 12),

              // 3. Middle Section: Bubbles Preview (only if has items)
              if (hasItems)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Wishes',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ..._buildPreviewBubbles(previewItems, hasMore),
                  ],
                ),

              // 4. Bottom Section: Empty State (Only if 0 items)
              if (!hasItems)
                Row(
                  children: [
                    Icon(
                      Icons.volunteer_activism,
                      size: 14,
                      color: Colors.purple.shade200,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'No wishes yet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPreviewBubbles(
      List<PreviewItem> previewItems, bool hasMore) {
    final bubbles = <Widget>[
      for (final item in previewItems)
        _FriendIconBubble(
          itemName: item.name ?? '',
          background: Colors.purple.shade50,
        ),
    ];

    if (hasMore) {
      bubbles.add(_FriendMoreCountBubble(
          count: wishlist.itemCount - previewItems.length));
    }

    final spaced = <Widget>[];
    for (int i = 0; i < bubbles.length; i++) {
      spaced.add(bubbles[i]);
      if (i != bubbles.length - 1) spaced.add(const SizedBox(width: 8));
    }
    return spaced;
  }
}

class _FriendIconBubble extends StatelessWidget {
  final String itemName;
  final Color background;

  const _FriendIconBubble({
    required this.itemName,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.card_giftcard,
        size: 18,
        color: AppColors.primary,
      ),
    );
  }
}

class _FriendPlaceholderBubble extends StatelessWidget {
  const _FriendPlaceholderBubble();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: CustomPaint(
        painter: _DashedCirclePainter(
          color: Colors.grey.withOpacity(0.45),
          strokeWidth: 1.3,
        ),
        child: Center(
          child: Icon(
            Icons.add,
            size: 16,
            color: Colors.grey.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

class _FriendMoreCountBubble extends StatelessWidget {
  final int count;

  const _FriendMoreCountBubble({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '+$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _DashedCircle extends StatelessWidget {
  final double size;
  const _DashedCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DashedCirclePainter(
          color: Colors.grey.shade300,
          strokeWidth: 1.3,
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _DashedCirclePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - strokeWidth;

    const dashCount = 12;
    const gapRatio = 0.55;
    final full = (2 * 3.141592653589793) / dashCount;
    final dash = full * gapRatio;
    final gap = full - dash;

    double start = -3.141592653589793 / 2;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        dash,
        false,
        paint,
      );
      start += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

class _EventTicketCard extends StatelessWidget {
  final FriendEventModel event;
  final VoidCallback onTap;

  const _EventTicketCard({
    required this.event,
    required this.onTap,
  });

  static const _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  ({IconData icon, Color color, Color textColor, String label})
      _getEventTypeStyle(String? type) {
    final t = (type ?? '').toLowerCase().trim();
    switch (t) {
      case 'birthday':
        return (
          icon: Icons.cake,
          color: Colors.pink.shade100,
          textColor: Colors.pink.shade700,
          label: 'Birthday',
        );
      case 'anniversary':
        return (
          icon: Icons.favorite,
          color: Colors.red.shade100,
          textColor: Colors.red.shade700,
          label: 'Anniversary',
        );
      case 'graduation':
        return (
          icon: Icons.school,
          color: Colors.blue.shade100,
          textColor: Colors.blue.shade700,
          label: 'Graduation',
        );
      case 'meeting':
        return (
          icon: Icons.business_center,
          color: Colors.orange.shade100,
          textColor: Colors.orange.shade700,
          label: 'Meeting',
        );
      default:
        return (
          icon: Icons.event,
          color: Colors.purple.shade50,
          textColor: Colors.purple.shade700,
          label: t.isEmpty ? 'Event' : t[0].toUpperCase() + t.substring(1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = event.date;
    final month = (date != null && date.month >= 1 && date.month <= 12)
        ? _months[date.month - 1]
        : '--';
    final day = date != null ? date.day.toString() : '--';

    // Get status badge text
    String statusText = 'Upcoming';
    if (event.status != null) {
      statusText = event.status!.split('_').map((s) {
        return s[0].toUpperCase() + s.substring(1);
      }).join(' ');
    } else if (event.mode == 'online') {
      statusText = 'Online';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A. Header Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Box
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          month,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          day,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title & Location (Expanded)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location ?? '—',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Badges Column (Trailing)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusPill(
                        text: statusText,
                        background: Colors.grey.shade100,
                        foreground: Colors.grey.shade700,
                      ),
                      if (event.type != null && event.type!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _EventTypeBadge(
                          type: event.type!,
                          style: _getEventTypeStyle(event.type),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              // B. Body Section (Description)
              if (event.description != null &&
                  event.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  event.description!.trim(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // C. Linked Wishlist Section
              if (event.wishlist != null) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.wishlistItems,
                      arguments: {
                        'wishlistId': event.wishlist!.id,
                        'wishlistName': event.wishlist!.name,
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          color: Colors.purple.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.wishlist!.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.purple.shade900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap to view wishes',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.purple.shade700,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // D. Invited Guests Section
              if (event.invitedFriends.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInvitedGuests(event.invitedFriends),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitedGuests(List<FriendEventInvitedFriendModel> invitedFriends) {
    // Take first 3 friends
    final displayFriends = invitedFriends.take(3).toList();
    final overflowCount = invitedFriends.length > 3 ? invitedFriends.length - 3 : 0;

    // Helper to get initials from fullName
    String getInitials(String fullName) {
      if (fullName.isEmpty) return '?';
      final parts = fullName.trim().split(' ');
      if (parts.length >= 2) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
      }
      return fullName[0].toUpperCase();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Invited Guests',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Avatars Row
        Row(
          children: [
            ...displayFriends.asMap().entries.map((entry) {
              final index = entry.key;
              final friend = entry.value;
              final hasImage = friend.profileImage != null &&
                  friend.profileImage!.isNotEmpty;
              
              return Transform.translate(
                offset: Offset(index > 0 ? -6.0 : 0.0, 0.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 17,
                    backgroundImage: hasImage
                        ? NetworkImage(friend.profileImage!)
                        : null,
                    onBackgroundImageError: hasImage ? (_, __) {} : null,
                    backgroundColor: Colors.purple.shade100,
                    child: !hasImage
                        ? Text(
                            getInitials(friend.fullName),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            }),
            // Overflow Badge
            if (overflowCount > 0)
              Transform.translate(
                offset: const Offset(-6.0, 0.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade400,
                  child: Text(
                    '+$overflowCount',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _EventTypeBadge extends StatelessWidget {
  final String type;
  final ({IconData icon, Color color, Color textColor, String label}) style;

  const _EventTypeBadge({
    required this.type,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            style.icon,
            size: 14,
            color: style.textColor,
          ),
          const SizedBox(width: 4),
          Text(
            style.label,
            style: TextStyle(
              color: style.textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _StatusPill({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}


