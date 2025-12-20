import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/friends/data/repository/friends_repository.dart';
import 'package:wish_listy/features/friends/data/models/friendship_model.dart';
import 'package:wish_listy/core/services/api_service.dart';

/// Bottom sheet widget for inviting friends to an event
class InviteFriendsBottomSheet extends StatefulWidget {
  final List<String> initiallySelectedIds; // Pre-selected friend IDs (for edit mode)
  final void Function(List<String>) onInvite; // Callback with selected friend IDs
  final void Function(List<Friend>)? onInviteWithFriends; // Optional callback with full friend data

  const InviteFriendsBottomSheet({
    super.key,
    this.initiallySelectedIds = const [],
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
    _selectedFriendIds = Set.from(widget.initiallySelectedIds);
    _searchController.addListener(_filterFriends);
    _scrollController.addListener(_onScroll);
    _loadFriends();
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
        _errorMessage = 'Failed to load friends. Please try again.';
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

  /// Filter friends based on search query
  /// Searches by name, username, email, or phone
  void _filterFriends() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = List.from(_allFriends);
      } else {
        _filteredFriends = _allFriends
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
    });
  }

  /// Toggle friend selection
  void _toggleFriendSelection(String friendId) {
    setState(() {
      if (_selectedFriendIds.contains(friendId)) {
        _selectedFriendIds.remove(friendId);
      } else {
        _selectedFriendIds.add(friendId);
      }
    });
  }

  /// Toggle select all friends
  void _toggleSelectAll() {
    setState(() {
      final allSelected = _allFriends.every(
        (friend) => _selectedFriendIds.contains(friend.id),
      );

      if (allSelected) {
        // Deselect all
        _selectedFriendIds.clear();
      } else {
        // Select all loaded friends
        _selectedFriendIds = _allFriends.map((friend) => friend.id).toSet();
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _allFriends.isNotEmpty &&
                              _allFriends.every((friend) =>
                                  _selectedFriendIds.contains(friend.id))
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
                          _allFriends.isNotEmpty &&
                                  _allFriends.every((friend) =>
                                      _selectedFriendIds.contains(friend.id))
                              ? Icons.check
                              : Icons.add,
                          size: 16,
                          color: _allFriends.isNotEmpty &&
                                  _allFriends.every((friend) =>
                                      _selectedFriendIds.contains(friend.id))
                              ? Colors.white
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _allFriends.isNotEmpty &&
                                  _allFriends.every((friend) =>
                                      _selectedFriendIds.contains(friend.id))
                              ? localization.translate('events.deselectAll')
                              : localization.translate('events.selectAll'),
                          style: AppStyles.bodySmall.copyWith(
                            color: _allFriends.isNotEmpty &&
                                    _allFriends.every((friend) =>
                                        _selectedFriendIds.contains(friend.id))
                                ? Colors.white
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Selected Count
          if (_selectedFriendIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${_selectedFriendIds.length} ${localization.translate('events.selected')}',
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
                        ? 'Select Friends'
                        : 'Invite ${_selectedFriendIds.length} Friend${_selectedFriendIds.length > 1 ? 's' : ''}',
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
              'Loading friends...',
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
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (_filteredFriends.isEmpty && !_isLoadingFriends) {
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
                  ? 'No friends found'
                  : 'No friends available',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : AppColors.border.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleFriendSelection(friend.id),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
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
                // Name and username
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.fullName,
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
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
                    ],
                  ),
                ),
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                      width: 2,
                    ),
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
