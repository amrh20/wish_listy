import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/friends/data/models/friend_event_model.dart';
import 'package:wish_listy/features/friends/data/models/friend_wishlist_model.dart';
import 'package:wish_listy/features/friends/data/repository/friends_repository.dart';
import 'package:wish_listy/features/friends/presentation/controllers/friend_profile_controller.dart';
import 'package:wish_listy/features/notifications/presentation/cubit/notifications_cubit.dart';

class FriendProfileScreen extends StatefulWidget {
  final String friendId;

  const FriendProfileScreen({super.key, required this.friendId});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  late final FriendProfileController _controller;

  static const double _expandedHeaderHeight = 350.0; // Increased to accommodate handle field + Quick Actions buttons

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
        child: RefreshIndicator(
          onRefresh: _refreshProfile,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                  shape: const CircleBorder(),
                ),
              ),
              // No actions needed - Quick Actions are shown below stats
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
      ),
    );
  }

  Future<void> _refreshProfile() async {
    await _controller.fetchProfile();
  }

  Future<void> _handleAddFriend() async {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    try {
      await _controller.sendFriendRequest();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.send, color: Colors.white),
              const SizedBox(width: 8),
              Text(localization.translate('friends.friendRequestSent')),
            ],
          ),
          backgroundColor: AppColors.primary,
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text(localization.translate('friends.failedToSendFriendRequest')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _handleAcceptRequest() async {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final requestId = _controller.incomingRequestId.value.isNotEmpty
        ? _controller.incomingRequestId.value
        : null;
    try {
      await _controller.acceptIncomingRequest();
      if (!mounted) return;
      _removeFriendRequestNotification(friendUserId: widget.friendId, requestId: requestId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(localization.translate('friends.friendRequestAccepted')),
            ],
          ),
          backgroundColor: AppColors.success,
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text(localization.translate('friends.failedToAcceptFriendRequest')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _handleDeclineRequest() async {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final requestId = _controller.incomingRequestId.value.isNotEmpty
        ? _controller.incomingRequestId.value
        : null;
    try {
      await _controller.declineIncomingRequest();
      if (!mounted) return;
      _removeFriendRequestNotification(friendUserId: widget.friendId, requestId: requestId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cancel, color: Colors.white),
              const SizedBox(width: 8),
              Text(localization.translate('friends.friendRequestDeclined')),
            ],
          ),
          backgroundColor: AppColors.error,
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text(localization.translate('friends.failedToRejectFriendRequest')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _handleUnfriend() async {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final profile = _controller.profile.value;
    final friendName = profile?.user.fullName ?? localization.translate('friends.friend');

    // Show confirmation dialog
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.surface,
          title: Text(
            localization.translate('dialogs.removeFriendTitle'),
            style: AppStyles.headingSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            localization.translate('dialogs.removeFriendMessage', args: {'name': friendName}),
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                localization.translate('dialogs.cancel'),
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                localization.translate('friends.removeFriend'),
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true || !mounted) return;

    try {
      final friendsRepository = FriendsRepository();
      await friendsRepository.removeFriend(friendId: widget.friendId);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(localization.translate('friends.friendRemoved')),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

      // Navigate back
      if (mounted) {
        Navigator.pop(context, {
          'unfriended': true,
          'friendId': widget.friendId,
        });
      }
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localization.translate('friends.failedToRemoveFriend') ?? 'Failed to remove friend. Please try again.',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _removeFriendRequestNotification({
    required String friendUserId,
    String? requestId,
  }) {
    try {
      context.read<NotificationsCubit>().resolveFriendRequestNotification(
            friendUserId: friendUserId,
            requestId: requestId,
          );
    } catch (_) {
      // If NotificationsCubit isn't provided in the current widget tree, ignore.
    }
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Obx(() {
                    final localization = Provider.of<LocalizationService>(context, listen: false);
                    final p = controller.profile.value;
                    final user = p?.user;

                    final fullName = (user?.fullName.isNotEmpty ?? false)
                        ? user!.fullName
                        : localization.translate('friends.friend');
                    final profileImage = user?.profileImage;

                    final counts = p?.counts;
                    final wishlistsCount = counts?.wishlists ?? 0;
                    final friendsCount = counts?.friends ?? 0;
                    final eventsCount = counts?.events ?? 0;

                    final isFriend = controller.isFriend.value;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Avatar(
                          fullName: fullName,
                          imageUrl: profileImage,
                        ),
                        const SizedBox(height: 8),
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
                                textAlign: TextAlign.center,
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
                        // Handle below name - always show (will display "User #ID" if handle is null)
                        if (user != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            user.getDisplayHandle(),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 6),
                        _GlassStatsContainer(
                          wishlists: wishlistsCount,
                          friends: friendsCount,
                          events: eventsCount,
                        ),
                        const SizedBox(height: 8),
                        _RelationshipQuickActions(
                          isFriend: controller.isFriend.value,
                          hasIncomingRequest:
                              controller.hasIncomingRequest.value,
                          isRequestSent:
                              controller.hasOutgoingRequest.value,
                          isBusy: controller.isSendingFriendRequest.value ||
                              controller.isLoading.value,
                          onRemove: () => (context.findAncestorStateOfType<
                                  _FriendProfileScreenState>())
                              ?._handleUnfriend(),
                          onAccept: () => (context.findAncestorStateOfType<
                                  _FriendProfileScreenState>())
                              ?._handleAcceptRequest(),
                          onDecline: () => (context.findAncestorStateOfType<
                                  _FriendProfileScreenState>())
                              ?._handleDeclineRequest(),
                          onAdd: () => (context.findAncestorStateOfType<
                                  _FriendProfileScreenState>())
                              ?._handleAddFriend(),
                        ),
                      ],
                    );
                  }),
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
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final initial = fullName.trim().isNotEmpty
        ? fullName.trim()[0].toUpperCase()
        : localization.translate('friends.friendInitial');

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

class _RelationshipQuickActions extends StatelessWidget {
  final bool isFriend;
  final bool hasIncomingRequest;
  final bool isRequestSent;
  final bool isBusy;
  final VoidCallback? onRemove;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onAdd;

  const _RelationshipQuickActions({
    required this.isFriend,
    required this.hasIncomingRequest,
    required this.isRequestSent,
    required this.isBusy,
    required this.onRemove,
    required this.onAccept,
    required this.onDecline,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);

    // Keep the header flexible: use Wrap instead of Row to avoid overflow.
    if (isBusy) {
      return const SizedBox(
        height: 34,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // 1) Friend -> Remove Friend
    if (isFriend) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          _QuickActionButton(
            text: localization.translate('friends.removeFriend'),
            icon: Icons.person_remove_outlined,
            backgroundColor: AppColors.error.withOpacity(0.08),
            foregroundColor: AppColors.error,
            borderColor: AppColors.error.withOpacity(0.25),
            onTap: onRemove,
          ),
        ],
      );
    }

    // 2) Incoming request -> Accept / Decline
    if (hasIncomingRequest) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          _QuickActionButton(
            text: localization.translate('friends.acceptRequest'),
            icon: Icons.check_circle_outline,
            backgroundColor: AppColors.success.withOpacity(0.10),
            foregroundColor: AppColors.success,
            borderColor: AppColors.success.withOpacity(0.25),
            onTap: onAccept,
          ),
          _QuickActionButton(
            text: localization.translate('friends.declineRequest'),
            icon: Icons.cancel_outlined,
            backgroundColor: AppColors.error.withOpacity(0.08),
            foregroundColor: AppColors.error,
            borderColor: AppColors.error.withOpacity(0.25),
            onTap: onDecline,
          ),
        ],
      );
    }

    // 3) Not friend + no incoming request -> Add Friend (or Pending)
    if (isRequestSent) {
      return Wrap(
        alignment: WrapAlignment.center,
        children: [
          _QuickActionButton(
            text: localization.translate('friends.requestPending'),
            icon: Icons.hourglass_bottom,
            backgroundColor: AppColors.textTertiary.withOpacity(0.10),
            foregroundColor: AppColors.textTertiary,
            borderColor: AppColors.textTertiary.withOpacity(0.20),
            onTap: null,
          ),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        _QuickActionButton(
          text: localization.translate('friends.sendRequest'),
          icon: Icons.person_add_alt_1_outlined,
          backgroundColor: AppColors.primary.withOpacity(0.10),
          foregroundColor: AppColors.primary,
          borderColor: AppColors.primary.withOpacity(0.25),
          onTap: onAdd,
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.text,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foregroundColor, size: 18),
              const SizedBox(width: 8),
              Text(
                text,
                style: AppStyles.bodyMedium.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ),
        const SizedBox(height: 2),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
            child: _buildStatItem(context, localization.translate('friends.wishlists'), wishlists.toString()),
          ),
          Container(
            width: 1,
            height: 20,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildStatItem(context, localization.translate('navigation.friends'), friends.toString()),
          ),
          Container(
            width: 1,
            height: 20,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildStatItem(context, localization.translate('navigation.events'), events.toString()),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

  /// Build skeleton loading list for wishlist cards
  Widget _buildWishlistSkeletonList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _buildWishlistCardSkeleton();
      },
    );
  }

  /// Build a single wishlist card skeleton
  Widget _buildWishlistCardSkeleton() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Section: Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Skeleton
              Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              // Title & Metadata Skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 80,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Privacy Icon Skeleton
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          // Divider
          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 12),
          // Bubbles Preview Skeleton
          Row(
            children: [
              Container(
                width: 50,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              ...List.generate(3, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  /// Build skeleton loading list for event cards
  Widget _buildEventSkeletonList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildEventCardSkeleton();
      },
    );
  }

  /// Build a single event card skeleton
  Widget _buildEventCardSkeleton() {
    return Container(
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
          // Header Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Box Skeleton
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              // Title & Location Skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 150,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // Badges Column Skeleton
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 70,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 60,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Description Skeleton
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 200,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wishlists Section Header
          Builder(
            builder: (context) {
              final localization = Provider.of<LocalizationService>(context, listen: false);
              return Text(
                '${localization.translate('friends.wishlists')} 🎁',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              );
            },
          ),
          // Spacing after header
          const SizedBox(height: 8),
          // Wishlists Content
          Obx(() {
            final localization = Provider.of<LocalizationService>(context, listen: false);
            final isLoading = controller.isLoading.value;
            final list = controller.wishlists;
            if (isLoading) {
              return _buildWishlistSkeletonList();
            }
            if (list.isEmpty) {
              return _buildEmptyState(
                icon: Icons.card_giftcard,
                title: localization.translate('friends.noPublicWishlists'),
                subtitle: localization.translate('friends.noPublicWishlistsDescription'),
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
                    final localization = Provider.of<LocalizationService>(context, listen: false);
                    final friendName =
                        controller.profile.value?.user.fullName ?? localization.translate('friends.friend');
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
          Builder(
            builder: (context) {
              final localization = Provider.of<LocalizationService>(context, listen: false);
              return Text(
                '${localization.translate('friends.upcomingEvents')} 📅',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              );
            },
          ),
          // Spacing after header
          const SizedBox(height: 16),
          // Events Content
          Obx(() {
            final isLoading = controller.isLoading.value;
            final list = controller.events;
            if (isLoading) {
              return _buildEventSkeletonList();
            }
            if (list.isEmpty) {
              final localization = Provider.of<LocalizationService>(context, listen: false);
              return _buildEmptyState(
                icon: Icons.event_busy,
                title: localization.translate('friends.noUpcomingEvents'),
                subtitle: localization.translate('friends.nothingScheduled'),
              );
            }

            return ListView.separated(
              itemCount: list.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final e = list[index];
                final localization = Provider.of<LocalizationService>(context, listen: false);
                return _EventTicketCard(
                  event: e,
                  localization: localization,
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
                            Builder(
                              builder: (context) {
                                final localization = Provider.of<LocalizationService>(context, listen: false);
                                return Text(
                                  '• ${wishlist.itemCount} ${wishlist.itemCount == 1 ? localization.translate('friends.wish') : localization.translate('friends.wishes')}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                );
                              },
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
                    Builder(
                      builder: (context) {
                        final localization = Provider.of<LocalizationService>(context, listen: false);
                        return Text(
                          localization.translate('friends.wishes'),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
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
                      child: Builder(
                        builder: (context) {
                          final localization = Provider.of<LocalizationService>(context, listen: false);
                          return Text(
                            localization.translate('friends.noWishesYet'),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
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
  final LocalizationService localization;
  final VoidCallback onTap;

  const _EventTicketCard({
    required this.event,
    required this.localization,
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
          label: localization.translate('events.birthday'),
        );
      case 'anniversary':
        return (
          icon: Icons.favorite,
          color: Colors.red.shade100,
          textColor: Colors.red.shade700,
          label: localization.translate('events.anniversary'),
        );
      case 'graduation':
        return (
          icon: Icons.school,
          color: Colors.blue.shade100,
          textColor: Colors.blue.shade700,
          label: localization.translate('events.graduation'),
        );
      case 'meeting':
        return (
          icon: Icons.business_center,
          color: Colors.orange.shade100,
          textColor: Colors.orange.shade700,
          label: localization.translate('events.meeting'),
        );
      default:
        return (
          icon: Icons.event,
          color: Colors.purple.shade50,
          textColor: Colors.purple.shade700,
          label: t.isEmpty ? localization.translate('events.other') : t[0].toUpperCase() + t.substring(1),
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
    String statusText = localization.translate('friends.upcoming');
    if (event.status != null) {
      statusText = event.status!.split('_').map((s) {
        return s[0].toUpperCase() + s.substring(1);
      }).join(' ');
    } else if (event.mode == 'online') {
      statusText = localization.translate('friends.online');
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
                              Builder(
                                builder: (context) {
                                  final localization = Provider.of<LocalizationService>(context, listen: false);
                                  return Text(
                                    localization.translate('friends.tapToViewWishes'),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                  );
                                },
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
          child: Builder(
            builder: (context) {
              final localization = Provider.of<LocalizationService>(context, listen: false);
              return Text(
                localization.translate('friends.invitedGuests'),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
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


