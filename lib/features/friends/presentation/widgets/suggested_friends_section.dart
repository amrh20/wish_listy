import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/friends/data/repository/friends_repository.dart';
import 'package:wish_listy/features/friends/data/models/suggestion_user_model.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'dart:math' as math;

class SuggestedFriendsSection extends StatefulWidget {
  final LocalizationService localization;

  const SuggestedFriendsSection({
    super.key,
    required this.localization,
  });

  @override
  State<SuggestedFriendsSection> createState() => _SuggestedFriendsSectionState();
}

class _SuggestedFriendsSectionState extends State<SuggestedFriendsSection> with SingleTickerProviderStateMixin {
  List<SuggestionUser> _suggestions = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _requestedFriends = {}; // Track sent requests
  final Map<String, String> _requestIds = {}; // Track request IDs for canceling
  final FriendsRepository _friendsRepository = FriendsRepository();
  final Map<String, bool> _isLoadingAction = {}; // Track loading state per friend action
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final suggestions = await _friendsRepository.getSuggestions();
      
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load suggestions. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDismiss(String userId, int index) async {
    // Optimistic update: Remove immediately from UI
    if (mounted) {
      setState(() {
        _suggestions.removeAt(index);
      });
    }

    // Call API in background (silent failure - UI already updated)
    try {
      await _friendsRepository.dismissSuggestion(targetUserId: userId);
    } catch (e) {
      // Silent failure - UI already updated optimistically
      debugPrint('Failed to dismiss suggestion: $e');
    }
  }

  Future<void> _handleAddFriend(String friendId) async {
    if (_isLoadingAction[friendId] == true) return;
    
    setState(() {
      _isLoadingAction[friendId] = true;
    });

    try {
      final response = await _friendsRepository.sendFriendRequest(toUserId: friendId);
      
      // Extract requestId from response
      final requestId = (response['_id'] ?? response['id'] ?? response['requestId'] ?? response['request_id'])?.toString();
      
      if (mounted) {
        setState(() {
          _requestedFriends.add(friendId);
          if (requestId != null && requestId.isNotEmpty) {
            _requestIds[friendId] = requestId;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(widget.localization.translate('friends.friendRequestSent')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text(widget.localization.translate('friends.failedToSendRequest')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAction[friendId] = false;
        });
      }
    }
  }

  Future<void> _handleCancelRequest(String friendId) async {
    if (_isLoadingAction[friendId] == true) return;
    
    final requestId = _requestIds[friendId];
    if (requestId == null || requestId.isEmpty) {
      // If no requestId, just remove from local state (fallback)
      setState(() {
        _requestedFriends.remove(friendId);
        _requestIds.remove(friendId);
      });
      return;
    }
    
    setState(() {
      _isLoadingAction[friendId] = true;
    });

    try {
      await _friendsRepository.cancelFriendRequest(requestId: requestId);
      
      if (mounted) {
        setState(() {
          _requestedFriends.remove(friendId);
          _requestIds.remove(friendId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(widget.localization.translate('friends.friendRequestCancelled')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text(widget.localization.translate('friends.failedToCancelRequest')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAction[friendId] = false;
        });
      }
    }
  }

  void _navigateToFriendProfile(String friendId) {
    Navigator.pushNamed(
      context,
      AppRoutes.friendProfile,
      arguments: {'friendId': friendId},
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state with skeleton
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: 200,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: _buildSkeletonList(),
          ),
        ],
      );
    }

    // Show error state (optional - could show empty or retry button)
    if (_errorMessage != null && _suggestions.isEmpty) {
      return const SizedBox.shrink(); // Hide section on error
    }

    // Hide if no suggestions
    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            widget.localization.translate('friends.peopleYouMayKnow'),
            style: AppStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final friend = _suggestions[index];
              final isRequested = _requestedFriends.contains(friend.id);
              return Padding(
                padding: EdgeInsets.only(right: index < _suggestions.length - 1 ? 12 : 0),
                child: _SuggestionUserCard(
                  suggestion: friend,
                  localization: widget.localization,
                  isRequested: isRequested,
                  isLoading: _isLoadingAction[friend.id] ?? false,
                  onDismiss: () => _handleDismiss(friend.id, index),
                  onTap: () => _navigateToFriendProfile(friend.id),
                  onAdd: () => _handleAddFriend(friend.id),
                  onCancel: () => _handleCancelRequest(friend.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build skeleton loading list
  Widget _buildSkeletonList() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Create pulsing effect using sine wave - lighter and smoother
        final pulseValue = (0.15 +
            (0.2 *
                (0.5 +
                    0.5 * (1 + (2 * _animationController.value - 1).abs()))));

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3, // Show 3 skeleton cards
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(right: index < 2 ? 12 : 0),
              child: _SuggestionSkeletonCard(pulseValue: pulseValue),
            );
          },
        );
      },
    );
  }
}

class _SuggestionUserCard extends StatefulWidget {
  final SuggestionUser suggestion;
  final LocalizationService localization;
  final bool isRequested;
  final bool isLoading;
  final VoidCallback onDismiss;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onCancel;

  const _SuggestionUserCard({
    required this.suggestion,
    required this.localization,
    required this.isRequested,
    required this.isLoading,
    required this.onDismiss,
    required this.onTap,
    required this.onAdd,
    required this.onCancel,
  });

  @override
  State<_SuggestionUserCard> createState() => _SuggestionUserCardState();
}

class _SuggestionUserCardState extends State<_SuggestionUserCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      scale: _pressed ? 0.98 : 1.0,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Dismiss (X)
            Positioned(
              top: 6,
              right: 6,
              child: InkWell(
                onTap: widget.onDismiss,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar (tappable)
                  GestureDetector(
                    onTap: widget.onTap,
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.cardPurple,
                      backgroundImage: (widget.suggestion.profileImage != null &&
                              widget.suggestion.profileImage!.isNotEmpty)
                          ? NetworkImage(widget.suggestion.profileImage!)
                          : null,
                      child: (widget.suggestion.profileImage == null ||
                              widget.suggestion.profileImage!.isEmpty)
                          ? Icon(
                              Icons.person_rounded,
                              color: AppColors.primary,
                              size: 30,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Name (tappable)
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Text(
                      widget.suggestion.fullName,
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.localization.translate(
                      'friends.mutualFriendsCount',
                      args: {'count': widget.suggestion.mutualFriendsCount.toString()},
                    ),
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: widget.isLoading
                        ? const SizedBox(
                            height: 36,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: widget.isRequested
                                  ? widget.onCancel
                                  : widget.onAdd,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.isRequested
                                    ? AppColors.textTertiary.withOpacity(0.1)
                                    : AppColors.primary,
                                foregroundColor: widget.isRequested
                                    ? AppColors.textSecondary
                                    : Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                widget.isRequested
                                    ? widget.localization.translate('wishlists.undo')
                                    : widget.localization.translate('add'),
                                style: AppStyles.bodyMedium.copyWith(
                                  color: widget.isRequested
                                      ? AppColors.textSecondary
                                      : Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton card for suggestion user card
class _SuggestionSkeletonCard extends StatelessWidget {
  final double pulseValue;

  const _SuggestionSkeletonCard({required this.pulseValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar skeleton
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200.withOpacity(pulseValue),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 12),
            // Name skeleton
            Container(
              width: 100,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey.shade200.withOpacity(pulseValue),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            // Mutual friends count skeleton
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade200.withOpacity(pulseValue),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Spacer(),
            // Button skeleton
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200.withOpacity(pulseValue),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
