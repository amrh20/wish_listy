import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/friends/data/repository/friends_repository.dart';
import 'package:wish_listy/features/friends/data/models/friendship_model.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';

/// Bottom sheet widget for inviting friends to an event.
class InviteFriendsBottomSheet extends StatefulWidget {
  final List<String> initiallySelectedIds; // Pre-selected friend IDs (for edit mode)
  final Map<String, InvitationStatus>? friendStatuses; // Map of friend ID to their response status (for disabling responded friends)
  final void Function(List<String>) onInvite; // Callback with selected friend IDs
  final void Function(List<Friend>)? onInviteWithFriends; // Optional callback with full friend data

  const InviteFriendsBottomSheet({
    super.key,
    this.initiallySelectedIds = const [],
    this.friendStatuses,
    required this.onInvite,
    this.onInviteWithFriends,
  });

  @override
  State<InviteFriendsBottomSheet> createState() =>
      _InviteFriendsBottomSheetState();
}

class _InviteFriendsBottomSheetState extends State<InviteFriendsBottomSheet> {
  final FriendsRepository _friendsRepository = FriendsRepository();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Friend> _allFriends = [];
  List<Friend> _filteredFriends = [];
  Set<String> _selectedFriendIds = {};

  // Pagination state
  int _currentPage = 1;
  bool _hasMoreFriends = false;
  bool _isLoadingFriends = false;
  bool _isLoadingMoreFriends = false;
  int _totalFriends = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-select friends, including those who have responded (they will be disabled)
    _selectedFriendIds = Set.from(widget.initiallySelectedIds);
    _searchController.addListener(_filterFriends);
    _scrollController.addListener(_onScroll);
    _loadFriends();
  }

  /// Check if a friend has already responded (status != pending)
  bool _hasResponded(String friendId) {
    if (widget.friendStatuses == null) return false;
    final status = widget.friendStatuses![friendId];
    return status != null && status != InvitationStatus.pending;
  }

  /// Count of selected friends that are displayable (excludes responded).
  /// Used for "X Selected" and "Invite X Friends" when in invite-more mode.
  int get _displayableSelectedCount {
    if (widget.friendStatuses == null) return _selectedFriendIds.length;
    return _selectedFriendIds
        .where((id) => !_hasResponded(id))
        .length;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Handle scroll to load more friends when near bottom
  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8) {
      if (_hasMoreFriends && !_isLoadingMoreFriends && !_isLoadingFriends) {
        _loadMoreFriends();
      }
    }
  }

  /// Load friends from API
  Future<void> _loadFriends({bool resetPage = false}) async {
    if (resetPage) {
      setState(() {
        _currentPage = 1;
        _hasMoreFriends = false;
        _errorMessage = null;
      });
    }

    if (_isLoadingFriends || (_isLoadingMoreFriends && !resetPage)) return;

    setState(() {
      if (resetPage) {
        _isLoadingFriends = true;
      } else {
        _isLoadingMoreFriends = true;
      }
      _errorMessage = null;
    });

    try {
      final response = await _friendsRepository.getFriends(
        page: _currentPage,
        limit: 20,
      );

      if (!mounted) return;

      final friends = response['friends'] as List<Friend>;
      final total = response['total'] as int;
      final currentPage = response['page'] as int;

      setState(() {
        if (resetPage || currentPage == 1) {
          _allFriends = friends;
        } else {
          // Append new friends to existing list
          _allFriends.addAll(friends);
        }
        _totalFriends = total;
        _currentPage = currentPage;
        _hasMoreFriends = _allFriends.length < total;
        _isLoadingFriends = false;
        _isLoadingMoreFriends = false;
        
        // Apply current search filter
        _filterFriends();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoadingFriends = false;
        _isLoadingMoreFriends = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = Provider.of<LocalizationService>(context, listen: false)
            .translate('events.failedToLoadFriendsTryAgain');
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

  /// Get list of friends that can be shown in the list.
  /// When friendStatuses is provided (e.g. "Invite More" from event details),
  /// exclude friends who have already responded (accepted, declined, maybe).
  /// Only show: friends not yet invited, or invited but still pending.
  List<Friend> _getDisplayableFriends(List<Friend> friends) {
    if (widget.friendStatuses == null) return friends;
    return friends.where((friend) => !_hasResponded(friend.id)).toList();
  }

  /// Whether friend was already invited (in invite-more mode)
  bool _wasInvited(String friendId) {
    return widget.initiallySelectedIds.contains(friendId);
  }

  /// Sort displayable friends: not invited first, then invited pending
  List<Friend> _sortDisplayableFriends(List<Friend> friends) {
    if (widget.friendStatuses == null) return friends;
    final sorted = List<Friend>.from(friends);
    sorted.sort((a, b) {
      final aInvited = _wasInvited(a.id);
      final bInvited = _wasInvited(b.id);
      if (!aInvited && bInvited) return -1; // a first
      if (aInvited && !bInvited) return 1;  // b first
      return 0;
    });
    return sorted;
  }

  /// Filter friends based on search query and exclusion of responded friends
  /// Searches by name, username, email, or phone
  void _filterFriends() {
    final query = _searchController.text.toLowerCase().trim();
    final displayableFriends = _getDisplayableFriends(_allFriends);

    setState(() {
      List<Friend> filtered;
      if (query.isEmpty) {
        filtered = List.from(displayableFriends);
      } else {
        filtered = displayableFriends
            .where((friend) {
              // Search by full name
              if (friend.fullName.toLowerCase().contains(query)) {
                return true;
              }
              // Search by username
              if (friend.username.toLowerCase().contains(query)) {
                return true;
              }
              // Search by email (if available)
              if (friend.email != null && friend.email!.toLowerCase().contains(query)) {
                return true;
              }
              // Search by phone (if available)
              if (friend.phone != null && friend.phone!.toLowerCase().contains(query)) {
                return true;
              }
              return false;
            })
            .toList();
      }
      _filteredFriends = _sortDisplayableFriends(filtered);
    });
  }

  /// Toggle friend selection (only if friend hasn't responded)
  void _toggleFriendSelection(String friendId) {
    // Don't allow toggling if friend has already responded
    if (_hasResponded(friendId)) return;
    
    setState(() {
      if (_selectedFriendIds.contains(friendId)) {
        _selectedFriendIds.remove(friendId);
      } else {
        _selectedFriendIds.add(friendId);
      }
    });
  }

  /// Toggle select all friends (only among displayable friends - excludes those who already responded)
  void _toggleSelectAll() {
    final displayableFriends = _getDisplayableFriends(_allFriends);

    setState(() {
      final allDisplayableSelected = displayableFriends.isNotEmpty &&
          displayableFriends.every(
            (friend) => _selectedFriendIds.contains(friend.id),
          );

      if (allDisplayableSelected) {
        // Deselect all displayable (keep responded friends in selection - they stay invited)
        for (final friend in displayableFriends) {
          _selectedFriendIds.remove(friend.id);
        }
      } else {
        // Select all displayable friends
        for (final friend in displayableFriends) {
          _selectedFriendIds.add(friend.id);
        }
      }
    });
  }

  /// Get initials from full name
  String _getInitials(String fullName) {
    if (fullName.isEmpty) return '?';
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    localization.translate('events.inviteFriends'),
                    style: AppStyles.headingSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: localization.translate('events.searchFriendsHint'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.border.withOpacity(0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.border.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Select All Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localization.translate('events.selectAll'),
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                GestureDetector(
                  onTap: _toggleSelectAll,
                  child: Builder(
                    builder: (context) {
                      final displayableFriends =
                          _getDisplayableFriends(_allFriends);
                      final allDisplayableSelected = displayableFriends
                              .isNotEmpty &&
                          displayableFriends.every((friend) =>
                              _selectedFriendIds.contains(friend.id));

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: allDisplayableSelected
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              allDisplayableSelected
                                  ? Icons.check
                                  : Icons.add,
                              size: 16,
                              color: allDisplayableSelected
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              allDisplayableSelected
                                  ? localization
                                      .translate('events.deselectAll')
                                  : localization
                                      .translate('events.selectAll'),
                              style: AppStyles.bodySmall.copyWith(
                                color: allDisplayableSelected
                                    ? Colors.white
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
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
          ),

          const SizedBox(height: 8),

          // Selected Count (shows displayable selected only when filtering responded friends)
          if (_displayableSelectedCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '$_displayableSelectedCount ${localization.translate('events.selected')}',
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Friends List
          Expanded(
            child: _buildFriendsList(localization),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: AppColors.border.withOpacity(0.5),
                ),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedFriendIds.isEmpty
                      ? null
                      : () {
                          final selectedIds = _selectedFriendIds.toList();
                          widget.onInvite(selectedIds);
                          
                          // Also call onInviteWithFriends if provided
                          if (widget.onInviteWithFriends != null) {
                            final selectedFriends = _allFriends
                                .where((friend) => selectedIds.contains(friend.id))
                                .toList();
                            widget.onInviteWithFriends!(selectedFriends);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _selectedFriendIds.isEmpty
                        ? localization.translate('events.selectFriends')
                        : localization
                            .translate('events.inviteFriendsCount')
                            .replaceAll('{count}', '$_displayableSelectedCount'),
                    style: AppStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build friends list with loading, error, and empty states
  Widget _buildFriendsList(LocalizationService localization) {
    // Loading state (initial load)
    if (_isLoadingFriends && _allFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              localization.translate('events.loadingFriends'),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Error state
    if (_errorMessage != null && _allFriends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadFriends(resetPage: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(localization.translate('app.retry')),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (_filteredFriends.isEmpty && !_isLoadingFriends) {
      final displayableFriends = _getDisplayableFriends(_allFriends);
      final allResponded = widget.friendStatuses != null &&
          _allFriends.isNotEmpty &&
          displayableFriends.isEmpty &&
          _searchController.text.isEmpty;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isNotEmpty
                  ? Icons.person_search_outlined
                  : Icons.people_outline,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? localization.translate('friends.noFriendsFound') ??
                      'No friends found'
                  : allResponded
                      ? localization.translate(
                              'events.allFriendsRespondedToEvent') ??
                          'All your friends have already responded to this event'
                      : localization.translate('friends.noFriends') ??
                          'No friends available',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Friends list
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredFriends.length + (_isLoadingMoreFriends ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at bottom for pagination
        if (index == _filteredFriends.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final friend = _filteredFriends[index];
        final isSelected = _selectedFriendIds.contains(friend.id);

        return _buildFriendItem(friend, isSelected);
      },
    );
  }

  /// Build individual friend item
  Widget _buildFriendItem(Friend friend, bool isSelected) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final hasResponded = _hasResponded(friend.id);
    final status = widget.friendStatuses?[friend.id];
    final wasInvited = _wasInvited(friend.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : hasResponded
                ? AppColors.background.withOpacity(0.5)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : hasResponded
                  ? AppColors.border.withOpacity(0.2)
              : AppColors.border.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasResponded ? null : () => _toggleFriendSelection(friend.id),
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: hasResponded ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: friend.profileImage != null &&
                            friend.profileImage!.isNotEmpty
                        ? NetworkImage(friend.profileImage!)
                        : null,
                    child: friend.profileImage == null ||
                            friend.profileImage!.isEmpty
                        ? Text(
                            _getInitials(friend.fullName),
                        style: AppStyles.headingSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                          )
                        : null,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.fullName,
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: hasResponded
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (friend.username.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '@${friend.username}',
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (wasInvited && !hasResponded && widget.friendStatuses != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.send_outlined,
                                  size: 12,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  localization.translate('events.invitationSent') ??
                                      'Invitation Sent',
                                  style: AppStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (hasResponded && status != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                _getStatusIcon(status),
                                size: 12,
                                color: _getStatusColor(status),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getStatusText(status, localization),
                                style: AppStyles.caption.copyWith(
                                  color: _getStatusColor(status),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                        ],
                      ],
                    ),
                  ),
                  Tooltip(
                    message: hasResponded
                        ? (localization.translate('events.alreadyResponded') ??
                            'Already responded')
                        : '',
                    child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                          color: hasResponded
                              ? AppColors.border.withOpacity(0.3)
                              : isSelected
                          ? AppColors.primary
                          : AppColors.border,
                      width: 2,
                    ),
                        color: hasResponded
                            ? AppColors.background
                            : isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                  ),
                      child: hasResponded
                          ? Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: AppColors.textSecondary,
                            )
                          : isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                    ),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get status color based on invitation status
  Color _getStatusColor(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.accepted:
        return AppColors.success; // Green
      case InvitationStatus.declined:
        return AppColors.error; // Red
      case InvitationStatus.maybe:
        return AppColors.warning; // Orange/Yellow
      case InvitationStatus.pending:
      default:
        return AppColors.textSecondary; // Grey
    }
  }

  /// Get status icon based on invitation status
  IconData _getStatusIcon(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.accepted:
        return Icons.check_circle;
      case InvitationStatus.declined:
        return Icons.cancel;
      case InvitationStatus.maybe:
        return Icons.help_outline;
      case InvitationStatus.pending:
      default:
        return Icons.access_time;
    }
  }

  /// Get status text based on invitation status
  String _getStatusText(InvitationStatus status, LocalizationService localization) {
    switch (status) {
      case InvitationStatus.accepted:
        return localization.translate('events.accepted') ?? 'Accepted';
      case InvitationStatus.declined:
        return localization.translate('events.declined') ?? 'Declined';
      case InvitationStatus.maybe:
        return localization.translate('events.maybe') ?? 'Maybe';
      case InvitationStatus.pending:
      default:
        return localization.translate('events.pending') ?? 'Pending';
    }
  }
}
