import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';

/// Mock friend data model
class MockFriend {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isOnline;

  MockFriend({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
  });
}

/// Bottom sheet widget for inviting friends to an event
class InviteFriendsBottomSheet extends StatefulWidget {
  final String eventId;
  final Function(List<String>) onInvite;

  const InviteFriendsBottomSheet({
    super.key,
    required this.eventId,
    required this.onInvite,
  });

  @override
  State<InviteFriendsBottomSheet> createState() =>
      _InviteFriendsBottomSheetState();
}

class _InviteFriendsBottomSheetState
    extends State<InviteFriendsBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedFriendIds = {};
  List<MockFriend> _allFriends = [];
  List<MockFriend> _filteredFriends = [];

  @override
  void initState() {
    super.initState();
    _loadMockFriends();
    _searchController.addListener(_filterFriends);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load mock friends data
  void _loadMockFriends() {
    _allFriends = [
      MockFriend(
        id: '1',
        name: 'Sarah Ahmed',
        isOnline: true,
      ),
      MockFriend(
        id: '2',
        name: 'Mohamed Ali',
        isOnline: false,
      ),
      MockFriend(
        id: '3',
        name: 'Fatima Hassan',
        isOnline: true,
      ),
      MockFriend(
        id: '4',
        name: 'Omar Khaled',
        isOnline: false,
      ),
      MockFriend(
        id: '5',
        name: 'Layla Mahmoud',
        isOnline: true,
      ),
      MockFriend(
        id: '6',
        name: 'Ahmed Youssef',
        isOnline: false,
      ),
      MockFriend(
        id: '7',
        name: 'Nour Ibrahim',
        isOnline: true,
      ),
      MockFriend(
        id: '8',
        name: 'Youssef Mostafa',
        isOnline: false,
      ),
      MockFriend(
        id: '9',
        name: 'Mariam Tarek',
        isOnline: true,
      ),
      MockFriend(
        id: '10',
        name: 'Karim Samir',
        isOnline: false,
      ),
    ];
    _filteredFriends = _allFriends;
  }

  /// Filter friends based on search query
  void _filterFriends() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = _allFriends;
      } else {
        _filteredFriends = _allFriends
            .where((friend) =>
                friend.name.toLowerCase().contains(query))
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

  @override
  Widget build(BuildContext context) {
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
                    'Invite Friends',
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
                hintText: 'Search friends...',
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

          // Selected Count
          if (_selectedFriendIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${_selectedFriendIds.length} friend(s) selected',
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Friends List
          Expanded(
            child: _filteredFriends.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No friends found',
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredFriends.length,
                    itemBuilder: (context, index) {
                      final friend = _filteredFriends[index];
                      final isSelected =
                          _selectedFriendIds.contains(friend.id);

                      return _buildFriendItem(friend, isSelected);
                    },
                  ),
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
                          widget.onInvite(_selectedFriendIds.toList());
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
                        : 'Invite ${_selectedFriendIds.length} Friend(s)',
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

  /// Build individual friend item
  Widget _buildFriendItem(MockFriend friend, bool isSelected) {
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
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        friend.name[0].toUpperCase(),
                        style: AppStyles.headingSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (friend.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
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
                // Name
                Expanded(
                  child: Text(
                    friend.name,
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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

